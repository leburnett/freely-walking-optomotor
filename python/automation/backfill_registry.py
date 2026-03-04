"""
Backfill pipeline status for existing experiments.

Scans one or more data directories, infers each experiment's pipeline stage
from the files that are present, and writes per-experiment pipeline_status.json
files and a global registry.

Usage examples:
    # Dry-run against one path (no files written)
    python backfill_registry.py --scan-paths "D:\\FreeWalkOptomotor\\data" --dry-run

    # Scan network processed data
    python backfill_registry.py --scan-paths "\\\\prfs.hhmi.org\\reiserlab\\oaky-cokey\\data\\2_processed"

    # Scan all known locations (output goes to group drive by default)
    python backfill_registry.py --all

    # Group drive unavailable — save output files locally instead
    python backfill_registry.py --all --output-dir "C:\\Users\\labadmin\\Desktop"

    # Scan with explicit results cross-reference
    python backfill_registry.py --scan-paths "F:\\oakey-cokey\\DATA\\02_processed" \\
        --results-path "\\\\prfs.hhmi.org\\reiserlab\\oaky-cokey\\exp_results"
"""

import argparse
import glob
import json
import logging
import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

# Add repo root to path so we can import config and shared modules
REPO_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))

from python.automation.shared.file_ops import (
    is_folder_complete,
    list_date_folders,
    parse_experiment_path,
)
from python.automation.shared.logging_config import setup_logging
from python.automation.shared.registry import generate_status_page
from python.automation.shared.status import (
    PIPELINE_STAGES,
    STATUS_FILENAME,
    _get_machine_role,
    init_status,
    read_status,
    update_stage,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Known data locations (used by --all flag)
# ---------------------------------------------------------------------------
ALL_SCAN_PATHS = [
    r"D:\FreeWalkOptomotor\data",
    r"C:\MatlabRoot\FreeWalkOptomotor\data",
    r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\0_unprocessed",
    r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\1_tracked",
    r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\2_processed",
]

DEFAULT_RESULTS_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\exp_results"


def _classify_scan_root(scan_root):
    """Classify a scan root as 'network' or 'local'.

    Network paths start with ``\\\\prfs`` (UNC) or ``//prfs``.
    Everything else is considered local.
    """
    path_lower = scan_root.lower().replace("\\", "/")
    if path_lower.startswith("//prfs"):
        return "network"
    return "local"


# ---------------------------------------------------------------------------
# Experiment discovery
# ---------------------------------------------------------------------------

def is_experiment_folder(folder_path):
    """Check if a folder looks like an experiment time folder.

    An experiment folder contains at least one of:
    - A stamp_log* file
    - A LOG_*.mat file
    - A REC__cam_* file or directory
    """
    try:
        entries = os.listdir(folder_path)
    except OSError:
        return False

    for entry in entries:
        if entry.startswith("stamp_log"):
            return True
        if entry.startswith("LOG_") and entry.endswith(".mat"):
            return True
        if entry.startswith("REC__cam_"):
            return True
    return False


def discover_experiments(scan_path):
    """Walk a scan path and find all experiment time folders.

    Auto-detects both flat (date/time/) and hierarchical
    (date/protocol/strain/sex/time/) structures by looking for folders
    that contain experiment data files.

    Args:
        scan_path: Root directory to scan.

    Returns:
        List of dicts: [{"folder_path": str, "scan_root": str}, ...]
    """
    experiments = []

    if not os.path.isdir(scan_path):
        logger.warning(f"Scan path does not exist or is not accessible: {scan_path}")
        return experiments

    # Walk through date folders
    for date_name in list_date_folders(scan_path):
        date_path = os.path.join(scan_path, date_name)
        _walk_for_experiments(date_path, scan_path, experiments)

    logger.info(f"Found {len(experiments)} experiments in {scan_path}")
    return experiments


def _walk_for_experiments(path, scan_root, results):
    """Recursively walk to find experiment folders (leaf folders with data)."""
    if is_experiment_folder(path):
        results.append({"folder_path": path, "scan_root": scan_root})
        return  # Don't recurse further into experiment data

    try:
        entries = os.listdir(path)
    except OSError:
        return

    for entry in entries:
        sub = os.path.join(path, entry)
        if os.path.isdir(sub):
            _walk_for_experiments(sub, scan_root, results)


# ---------------------------------------------------------------------------
# Metadata extraction
# ---------------------------------------------------------------------------

def extract_metadata(folder_path, scan_root):
    """Extract experiment metadata from folder path and/or LOG file.

    Tries multiple strategies in order:
    1. Parse LOG*.mat file for metadata struct (most reliable, Oct 2024+)
    2. Parse hierarchical path (date/protocol/strain/sex/time/) — exact 5 levels
    3. Fall back to extracting what we can from path components

    LOG files are tried first because they contain authoritative metadata
    from the experiment itself, whereas path parsing can fail when the
    folder hierarchy has unexpected extra levels (e.g., sub-strain
    directories or duplicate date folders).

    Args:
        folder_path: Full path to the experiment time folder.
        scan_root: The root scan path (for computing relative path).

    Returns:
        Dict with keys: date, protocol, strain, sex, time.
    """
    # Strategy 1: Try to get metadata from the LOG*.mat file (most reliable)
    meta = _extract_metadata_from_log(folder_path)
    if meta is not None:
        return meta

    # Strategy 2: Try hierarchical path parsing (exact 5-level match only)
    meta = parse_experiment_path(folder_path, scan_root)
    if meta is not None:
        return meta

    # Strategy 3: Best-effort from path components
    return _extract_metadata_from_path_fallback(folder_path, scan_root)


def _extract_metadata_from_log(folder_path):
    """Parse LOG_*.mat to extract protocol, strain, sex from LOG.meta struct.

    Works with LOG files from October 2024 onwards that contain the
    LOG.meta struct with func_name, fly_strain, fly_sex fields.

    Returns:
        Dict with keys: date, protocol, strain, sex, time — or None if parsing fails.
    """
    try:
        from scipy.io import loadmat
    except ImportError:
        logger.debug("scipy not available — cannot parse LOG*.mat files")
        return None

    # Find LOG_*.mat file
    log_files = glob.glob(os.path.join(folder_path, "LOG_*.mat"))
    if not log_files:
        return None

    log_file = sorted(log_files)[0]  # First alphabetically if multiple

    try:
        data = loadmat(log_file, squeeze_me=True, simplify_cells=True)
    except Exception as e:
        logger.debug(f"Failed to load {log_file}: {e}")
        return None

    # Check for new-format LOG struct with meta field
    if "LOG" not in data:
        return None

    log_struct = data["LOG"]

    # Handle numpy void (struct) types
    if not hasattr(log_struct, "dtype") or log_struct.dtype.names is None:
        return None

    if "meta" not in log_struct.dtype.names:
        return None

    meta = log_struct["meta"]
    if hasattr(meta, "item"):
        meta = meta.item()

    # Extract fields from meta struct
    protocol = _safe_field(meta, "func_name", "unknown")
    strain = _safe_field(meta, "fly_strain", "unknown")
    sex = _safe_field(meta, "fly_sex", "unknown")

    # Derive date and time from folder path
    time_folder = os.path.basename(folder_path)
    date_folder = _find_date_in_path(folder_path)

    return {
        "date": date_folder or "unknown",
        "protocol": str(protocol),
        "strain": str(strain),
        "sex": str(sex),
        "time": time_folder,
    }


def _safe_field(struct, field_name, default="unknown"):
    """Safely extract a field from a numpy struct/void."""
    try:
        if hasattr(struct, "dtype") and struct.dtype.names and field_name in struct.dtype.names:
            val = struct[field_name]
            if hasattr(val, "item"):
                val = val.item()
            if val is None or (hasattr(val, "__len__") and len(val) == 0):
                return default
            # Handle NaN
            try:
                import numpy as np
                if np.isnan(val):
                    return default
            except (TypeError, ValueError):
                pass
            return str(val)
    except Exception:
        pass
    return default


def _find_date_in_path(folder_path):
    """Find a YYYY_MM_DD component in the folder path."""
    for part in Path(folder_path).parts:
        if re.match(r"^\d{4}_\d{2}_\d{2}$", part):
            return part
    return None


def _is_time_folder(name):
    """Check if a folder name looks like a time string (HH_MM_SS)."""
    return bool(re.match(r"^\d{2}_\d{2}_\d{2}$", name))


def _is_sex_value(name):
    """Check if a string looks like a valid sex value."""
    return name.upper() in ("F", "M", "NAN")


def _is_date_folder(name):
    """Check if a folder name looks like a date (YYYY_MM_DD)."""
    return bool(re.match(r"^\d{4}_\d{2}_\d{2}$", name))


def _extract_metadata_from_path_fallback(folder_path, scan_root):
    """Best-effort metadata extraction from folder path components.

    Handles partial hierarchical paths, flat structures, and paths with
    extra levels (e.g., sub-strain directories or duplicate date folders).

    For 6+ part paths, parses from the END of the path since the last
    component (time) and second-to-last (sex) have predictable formats.
    This avoids the field-shift bug where extra intermediate directories
    cause dates to be assigned as protocols or protocols as strains.
    """
    rel = os.path.relpath(folder_path, scan_root).replace("\\", "/")
    parts = rel.split("/")

    time_folder = parts[-1] if parts else "unknown"
    date_folder = _find_date_in_path(folder_path) or "unknown"

    if len(parts) >= 6:
        # 6+ parts: likely has extra level (sub-strain, duplicate date, etc.)
        # Parse from the end where the structure is most predictable:
        #   ... / date / protocol / strain / [extra...] / sex / time
        # OR: ... / [extra...] / date / protocol / strain / sex / time
        #
        # Strategy: find time (last), sex (second-to-last if valid),
        # then date (first YYYY_MM_DD), then assign remaining parts.
        time_str = parts[-1]
        sex = "unknown"
        remaining_end = -1  # Index up to which we've consumed from the end

        if _is_sex_value(parts[-2]):
            sex = parts[-2]
            remaining_end = -2
        else:
            remaining_end = -1

        # Find the date among remaining parts
        date_idx = None
        for i in range(len(parts) + remaining_end):
            if _is_date_folder(parts[i]):
                date_idx = i
                break

        if date_idx is not None:
            date_val = parts[date_idx]
            # Everything between date and the consumed end = protocol, strain, [extras]
            middle = parts[date_idx + 1 : len(parts) + remaining_end]
            if len(middle) >= 2:
                return {
                    "date": date_val,
                    "protocol": middle[0],
                    "strain": middle[1],
                    "sex": sex,
                    "time": time_str,
                }
            elif len(middle) == 1:
                return {
                    "date": date_val,
                    "protocol": middle[0],
                    "strain": "unknown",
                    "sex": sex,
                    "time": time_str,
                }
            else:
                return {
                    "date": date_val,
                    "protocol": "unknown",
                    "strain": "unknown",
                    "sex": sex,
                    "time": time_str,
                }

        # No date found in path — fall through to generic handling
        return {
            "date": date_folder,
            "protocol": "unknown",
            "strain": "unknown",
            "sex": "unknown",
            "time": time_folder,
        }

    elif len(parts) == 5:
        # Full hierarchy: date/protocol/strain/sex/time
        return {
            "date": parts[0], "protocol": parts[1], "strain": parts[2],
            "sex": parts[3], "time": parts[4],
        }
    elif len(parts) == 4:
        # Partial hierarchy: date/protocol/strain/time (missing sex)
        return {
            "date": parts[0], "protocol": parts[1], "strain": parts[2],
            "sex": "unknown", "time": parts[3],
        }
    elif len(parts) == 3:
        # date/Protocol_vXX/time or date/protocol_XX/time
        return {
            "date": parts[0], "protocol": parts[1], "strain": "unknown",
            "sex": "unknown", "time": parts[2],
        }
    elif len(parts) == 2:
        # Flat: date/time
        return {
            "date": parts[0], "protocol": "unknown", "strain": "unknown",
            "sex": "unknown", "time": parts[1],
        }
    else:
        return {
            "date": date_folder, "protocol": "unknown", "strain": "unknown",
            "sex": "unknown", "time": time_folder,
        }


# ---------------------------------------------------------------------------
# Results index (for cross-referencing exp_results)
# ---------------------------------------------------------------------------

def _parse_results_filename(fname):
    """Extract metadata from a results filename.

    Pattern: YYYY-MM-DD_HH-MM-SS_strain_protocol_sex_data.mat

    The strain may contain underscores so we locate the protocol name
    (protocol_XX or Protocol_vX) by regex and split around it.

    Returns:
        Dict with strain, protocol, sex — or None if parsing fails.
    """
    match = re.match(
        r"^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2}-\d{2})_(.+)_data\.mat$",
        fname,
    )
    if not match:
        return None

    _, _, rest = match.groups()

    # Find protocol name within rest (e.g. "NorpA_plus_plus_protocol_27_F")
    proto_match = re.search(r"(protocol_\d+|Protocol_v\d+)", rest, re.IGNORECASE)
    if not proto_match:
        return None

    strain = rest[: proto_match.start()].rstrip("_")
    after_proto = rest[proto_match.end() :].lstrip("_")
    protocol = proto_match.group(1)
    sex = after_proto if after_proto else "unknown"

    return {"strain": strain, "protocol": protocol, "sex": sex}


def build_results_index(results_path):
    """Build a lookup index from exp_results *_data.mat files.

    The result filenames follow the pattern:
        YYYY-MM-DD_HH-MM-SS_strain_protocol_sex_data.mat

    We normalize dates from hyphen-separated (2025-02-26) to
    underscore-separated (2025_02_26) and times similarly.

    Args:
        results_path: Path to the exp_results directory.

    Returns:
        Dict mapping (date_underscores, time_underscores) to a dict with
        'path' and optionally 'strain', 'protocol', 'sex' parsed from
        the filename.
    """
    index = {}

    if not results_path or not os.path.isdir(results_path):
        logger.warning(f"Results path not accessible: {results_path}")
        return index

    count = 0
    for dirpath, _, filenames in os.walk(results_path):
        for fname in filenames:
            if fname.endswith("_data.mat"):
                # Parse: YYYY-MM-DD_HH-MM-SS_rest_data.mat
                match = re.match(
                    r"^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2}-\d{2})_(.+)_data\.mat$",
                    fname,
                )
                if match:
                    date_hyphens, time_hyphens, _ = match.groups()
                    date_key = date_hyphens.replace("-", "_")
                    time_key = time_hyphens.replace("-", "_")
                    entry = {"path": os.path.join(dirpath, fname)}
                    # Parse metadata from filename
                    meta = _parse_results_filename(fname)
                    if meta:
                        entry.update(meta)
                    index[(date_key, time_key)] = entry
                    count += 1

    logger.info(f"Built results index: {count} entries from {results_path}")
    return index


# ---------------------------------------------------------------------------
# Stage inference
# ---------------------------------------------------------------------------

def infer_stage(folder_path, metadata, network_results_index, local_results_index=None):
    """Determine the highest completed pipeline stage for an experiment.

    Checks in descending priority order (highest stage first).

    Args:
        folder_path: Path to the experiment time folder.
        metadata: Dict with date, protocol, strain, sex, time.
        network_results_index: Dict from build_results_index() for network exp_results.
        local_results_index: Dict from build_results_index() for local results (optional).

    Returns:
        String stage name from PIPELINE_STAGES.
    """
    date = metadata.get("date", "")
    time_str = metadata.get("time", "")

    # Check: synced_to_network — matching result file in network exp_results
    if (date, time_str) in network_results_index:
        return "synced_to_network"

    # Check: processed — matching result file in local results
    if local_results_index and (date, time_str) in local_results_index:
        return "processed"

    # Check: processed — folder is under a *processed* path
    path_lower = folder_path.lower().replace("\\", "/")
    if "processed" in path_lower:
        return "processed"

    # Check: tracked — trx.mat exists inside recording subfolder
    trx_files = glob.glob(os.path.join(folder_path, "**", "trx.mat"), recursive=True)
    if trx_files:
        return "tracked"

    # Check: copied_to_network — folder is on the network drive
    if path_lower.startswith("\\\\prfs") or path_lower.startswith("//prfs"):
        return "copied_to_network"

    # Check: acquired — folder has basic experiment files
    if is_folder_complete(folder_path):
        return "acquired"

    # Absolute minimum — folder exists with some data
    return "acquired"


# ---------------------------------------------------------------------------
# Missing LOG file check
# ---------------------------------------------------------------------------

def check_missing_log_files(experiments):
    """Check which experiment folders are missing a LOG_*.mat file.

    Args:
        experiments: List of dicts from discover_experiments(),
                     each with 'folder_path' and 'scan_root'.

    Returns:
        List of dicts for experiments missing LOG_*.mat. Each dict contains:
        - folder_path: Full path to the experiment folder
        - scan_root: Which scan root this was found under
        - has_stamp_log: Whether stamp_log* exists
        - has_rec_cam: Whether REC__cam_* exists
        - file_count: Total number of files in the folder
    """
    missing = []
    for exp in experiments:
        folder_path = exp["folder_path"]
        try:
            entries = os.listdir(folder_path)
        except OSError:
            continue

        has_log = any(
            e.startswith("LOG_") and e.endswith(".mat") for e in entries
        )
        if not has_log:
            missing.append({
                "folder_path": folder_path,
                "scan_root": exp["scan_root"],
                "has_stamp_log": any(e.startswith("stamp_log") for e in entries),
                "has_rec_cam": any(e.startswith("REC__cam_") for e in entries),
                "file_count": len(entries),
            })
    return missing


def print_missing_logs_report(missing, total_scanned, scan_paths):
    """Print a console report of experiment folders missing LOG_*.mat.

    Prints the full path of every folder that is missing a LOG file,
    grouped by scan root for readability.
    """
    print(f"\n{'='*70}")
    print("Missing LOG_*.mat Report")
    print(f"{'='*70}")
    print("Scan paths:")
    for sp in scan_paths:
        print(f"  - {sp}")
    print(f"\nTotal experiment folders scanned: {total_scanned}")
    print(f"Folders missing LOG_*.mat:        {len(missing)}")
    print(f"{'='*70}")

    if not missing:
        print("\nAll experiment folders have a LOG_*.mat file.\n")
        return

    # Group by scan_root for readability
    by_root = {}
    for m in missing:
        by_root.setdefault(m["scan_root"], []).append(m)

    for root, items in sorted(by_root.items()):
        print(f"\n--- {root} ({len(items)} missing) ---")
        for item in sorted(items, key=lambda x: x["folder_path"]):
            indicators = []
            if item["has_stamp_log"]:
                indicators.append("stamp_log")
            if item["has_rec_cam"]:
                indicators.append("REC__cam")
            has_str = (
                f"  [has: {', '.join(indicators)}]" if indicators
                else "  [no marker files]"
            )
            print(f"  {item['folder_path']}{has_str}")

    print(f"\n{'='*70}\n")


def write_missing_logs_report(missing, total_scanned, scan_paths, output_path):
    """Write the missing LOG_*.mat report to a text file.

    Args:
        missing: List of dicts from check_missing_log_files().
        total_scanned: Total number of experiment folders scanned.
        scan_paths: List of scan path strings used.
        output_path: Full path to the output text file.
    """
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(f"# Missing LOG_*.mat Report\n")
        f.write(f"# Generated: {datetime.now().isoformat(timespec='seconds')}\n")
        f.write(f"# Total scanned: {total_scanned}\n")
        f.write(f"# Missing: {len(missing)}\n")
        f.write(f"#\n")
        f.write(f"# Scan paths:\n")
        for sp in scan_paths:
            f.write(f"#   {sp}\n")
        f.write(f"#\n")

        if not missing:
            f.write("# All experiment folders have a LOG_*.mat file.\n")
            return

        # Group by scan_root
        by_root = {}
        for m in missing:
            by_root.setdefault(m["scan_root"], []).append(m)

        for root, items in sorted(by_root.items()):
            f.write(f"\n# === {root} ({len(items)} missing) ===\n")
            for item in sorted(items, key=lambda x: x["folder_path"]):
                markers = []
                if item["has_stamp_log"]:
                    markers.append("stamp_log")
                if item["has_rec_cam"]:
                    markers.append("REC__cam")
                marker_str = f"  # has: {', '.join(markers)}" if markers else ""
                f.write(f"{item['folder_path']}{marker_str}\n")

    logger.info(f"Missing LOG report written: {output_path}")
    print(f"Report written: {output_path}")


# ---------------------------------------------------------------------------
# Per-experiment processing
# ---------------------------------------------------------------------------

def process_one_experiment(exp, network_results_index, local_results_index, args):
    """Process a single experiment: extract metadata, infer stage, write status.

    Args:
        exp: Dict with folder_path and scan_root.
        network_results_index: Lookup from build_results_index() for network exp_results.
        local_results_index: Lookup from build_results_index() for local results.
        args: Parsed CLI arguments.

    Returns:
        Dict with experiment status info, or None if skipped.
    """
    folder_path = exp["folder_path"]
    scan_root = exp["scan_root"]

    try:
        # Check for existing status
        if args.skip_existing:
            existing = read_status(folder_path)
            if existing is not None:
                return {"status": "skipped", "folder": folder_path}

        # Extract metadata
        metadata = extract_metadata(folder_path, scan_root)

        # Infer pipeline stage
        stage = infer_stage(folder_path, metadata, network_results_index, local_results_index)

        # Compute cross-reference flags, tagged by machine role
        date = metadata.get("date", "")
        time_str = metadata.get("time", "")
        has_local = (date, time_str) in local_results_index if local_results_index else False
        has_network = (date, time_str) in network_results_index

        machine_role = _get_machine_role()
        has_local_acq = has_local and machine_role == "acquisition"
        has_local_proc = has_local and machine_role == "processing"

        # Experiment DATA folder location (based on which scan path it was found in)
        location = _classify_scan_root(scan_root)
        has_data_network = (location == "network")
        has_data_local_acq = (location == "local" and machine_role == "acquisition")
        has_data_local_proc = (location == "local" and machine_role == "processing")

        if args.dry_run:
            return {
                "status": "dry_run",
                "folder": folder_path,
                "metadata": metadata,
                "inferred_stage": stage,
                "has_data_local_acquisition": has_data_local_acq,
                "has_data_local_processing": has_data_local_proc,
                "has_data_network": has_data_network,
                "has_local_results_acquisition": has_local_acq,
                "has_local_results_processing": has_local_proc,
                "has_network_results": has_network,
            }

        # Write pipeline_status.json
        status_data = init_status(
            folder_path,
            date=metadata["date"],
            protocol=metadata["protocol"],
            strain=metadata["strain"],
            sex=metadata["sex"],
            time_str=metadata["time"],
        )

        # Get folder modification time for timestamps
        try:
            mtime = os.path.getmtime(folder_path)
            timestamp = datetime.fromtimestamp(mtime).isoformat(timespec="seconds")
        except OSError:
            timestamp = datetime.now().isoformat(timespec="seconds")

        # Mark all stages up to and including the inferred stage as complete
        for s in PIPELINE_STAGES:
            update_stage(
                folder_path,
                stage_name=s,
                status="complete",
                backfill=True,
                original_timestamp=timestamp,
            )
            if s == stage:
                break

        return {
            "status": "written",
            "folder": folder_path,
            "metadata": metadata,
            "inferred_stage": stage,
            "has_data_local_acquisition": has_data_local_acq,
            "has_data_local_processing": has_data_local_proc,
            "has_data_network": has_data_network,
            "has_local_results_acquisition": has_local_acq,
            "has_local_results_processing": has_local_proc,
            "has_network_results": has_network,
        }

    except Exception as e:
        logger.error(f"Error processing {folder_path}: {e}")
        return {
            "status": "error",
            "folder": folder_path,
            "error": str(e),
        }


# ---------------------------------------------------------------------------
# Global registry writing
# ---------------------------------------------------------------------------

def _merge_cross_ref(target, source):
    """OR cross-reference boolean flags from source into target."""
    for field in (
        "has_data_local_acquisition",
        "has_data_local_processing",
        "has_data_network",
        "has_local_results_acquisition",
        "has_local_results_processing",
        "has_network_results",
    ):
        target[field] = target.get(field, False) or source.get(field, False)


def _fix_bad_metadata(entry, network_results_index, local_results_index):
    """Detect and fix misaligned metadata using results filenames.

    Common patterns that indicate a problem:
    - protocol field contains a date (YYYY_MM_DD)
    - strain field contains a protocol name (protocol_XX)

    When detected, attempts to correct using parsed metadata from the
    results filename (which is authoritative).
    """
    date_pat = re.compile(r"^\d{4}_\d{2}_\d{2}$")
    proto_pat = re.compile(r"^protocol_\d+$|^Protocol_v\d+$", re.IGNORECASE)

    protocol = entry.get("protocol", "")
    strain = entry.get("strain", "")

    needs_fix = False
    if date_pat.match(protocol):
        needs_fix = True
    if proto_pat.match(strain):
        needs_fix = True

    if not needs_fix:
        return False

    # Try to look up correct metadata from results filename
    key = (entry.get("date", ""), entry.get("time", ""))
    for idx in (network_results_index, local_results_index):
        if idx and key in idx:
            info = idx[key]
            if isinstance(info, dict) and "strain" in info and "protocol" in info:
                old_proto = entry["protocol"]
                old_strain = entry["strain"]
                entry["protocol"] = info["protocol"]
                entry["strain"] = info["strain"]
                if "sex" in info and info["sex"] != "unknown":
                    entry["sex"] = info["sex"]
                # Rebuild experiment_id
                entry["experiment_id"] = (
                    f"{entry['date']}_{entry['time']}_"
                    f"{entry['strain']}_{entry['protocol']}_{entry.get('sex', '')}"
                )
                logger.info(
                    f"Fixed metadata for {key}: "
                    f"protocol {old_proto!r}->{entry['protocol']!r}, "
                    f"strain {old_strain!r}->{entry['strain']!r}"
                )
                return True
    return False


def write_global_registry(results, output_registry,
                          network_results_index=None, local_results_index=None):
    """Write all experiment statuses to the global registry.

    Deduplicates by (date, time) key, keeping the entry with the highest
    pipeline stage. Merges with the existing registry so that running
    backfill on one machine preserves entries written by the other machine.
    Corrects bad metadata using results filenames when available.

    Args:
        results: List of result dicts from process_one_experiment.
        output_registry: Path to the output registry JSON file.
        network_results_index: Results index from network exp_results (optional).
        local_results_index: Results index from local results (optional).
    """
    # Stage priority for deduplication (higher = further along pipeline)
    stage_priority = {s: i for i, s in enumerate(PIPELINE_STAGES)}

    # Deduplicate by (date, time), keeping the highest-stage entry
    best = {}  # (date, time) -> entry dict
    for r in results:
        if r is None or r.get("status") not in ("written",):
            continue

        meta = r.get("metadata", {})
        date = meta.get("date", "")
        time_str = meta.get("time", "")
        dedup_key = (date, time_str)

        entry = {
            "experiment_id": (
                f"{date}_{time_str}_"
                f"{meta.get('strain', '')}_{meta.get('protocol', '')}_{meta.get('sex', '')}"
            ),
            "date": date,
            "time": time_str,
            "protocol": meta.get("protocol", ""),
            "strain": meta.get("strain", ""),
            "sex": meta.get("sex", ""),
            "current_stage": r.get("inferred_stage", ""),
            "last_updated": datetime.now().isoformat(timespec="seconds"),
            "has_errors": False,
            "has_data_local_acquisition": r.get("has_data_local_acquisition", False),
            "has_data_local_processing": r.get("has_data_local_processing", False),
            "has_data_network": r.get("has_data_network", False),
            "has_local_results_acquisition": r.get("has_local_results_acquisition", False),
            "has_local_results_processing": r.get("has_local_results_processing", False),
            "has_network_results": r.get("has_network_results", False),
        }

        if dedup_key in best:
            existing = best[dedup_key]
            existing_prio = stage_priority.get(existing["current_stage"], -1)
            new_prio = stage_priority.get(entry["current_stage"], -1)

            # Keep the higher-stage entry; merge cross-reference flags
            if new_prio > existing_prio:
                _merge_cross_ref(entry, existing)
                best[dedup_key] = entry
            else:
                _merge_cross_ref(existing, entry)
        else:
            best[dedup_key] = entry

    # Merge with existing registry (preserves entries from the other machine)
    if os.path.exists(output_registry):
        try:
            with open(output_registry, "r") as f:
                old_registry = json.load(f)
            old_count = 0
            for exp in old_registry.get("experiments", []):
                key = (exp.get("date", ""), exp.get("time", ""))
                if key == ("", ""):
                    continue  # Skip entries without date/time
                if key not in best:
                    best[key] = exp  # Preserve entry from other machine's run
                    old_count += 1
                else:
                    # Entry exists in both — merge cross-reference flags
                    _merge_cross_ref(best[key], exp)
            if old_count:
                logger.info(
                    f"Merged {old_count} existing entries from previous registry"
                )
        except (json.JSONDecodeError, OSError) as e:
            logger.warning(f"Could not read existing registry for merge: {e}")

    # Fix bad metadata using results filenames
    if network_results_index or local_results_index:
        fixed = 0
        for entry in best.values():
            if _fix_bad_metadata(entry, network_results_index, local_results_index):
                fixed += 1
        if fixed:
            logger.info(f"Corrected metadata for {fixed} experiments using results filenames")
            print(f"  Corrected metadata for {fixed} experiments using results filenames")

    experiments = list(best.values())

    # Log deduplication stats
    total_written = sum(1 for r in results if r and r.get("status") == "written")
    if total_written > len(experiments):
        logger.info(
            f"Deduplicated {total_written} entries to {len(experiments)} "
            f"unique experiments (removed {total_written - len(experiments)} duplicates)"
        )

    registry_data = {
        "last_updated": datetime.now().isoformat(timespec="seconds"),
        "experiments": experiments,
    }

    os.makedirs(os.path.dirname(output_registry) or ".", exist_ok=True)

    # Write atomically
    tmp_path = output_registry + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(registry_data, f, indent=2)
        os.replace(tmp_path, output_registry)
        logger.info(f"Global registry written: {output_registry} ({len(experiments)} experiments)")
    except OSError as e:
        logger.error(f"Error writing registry: {e}")
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

def print_summary(results):
    """Print a summary of the backfill results."""
    stage_counts = {}
    written = 0
    skipped = 0
    errors = 0
    dry_run = 0

    for r in results:
        if r is None:
            continue
        status = r.get("status", "")
        if status == "written":
            written += 1
            stage = r.get("inferred_stage", "unknown")
            stage_counts[stage] = stage_counts.get(stage, 0) + 1
        elif status == "dry_run":
            dry_run += 1
            stage = r.get("inferred_stage", "unknown")
            stage_counts[stage] = stage_counts.get(stage, 0) + 1
        elif status == "skipped":
            skipped += 1
        elif status == "error":
            errors += 1

    total = written + dry_run + skipped + errors
    mode = "(DRY RUN)" if dry_run > 0 else ""

    print(f"\n{'='*60}")
    print(f"Backfill complete. {mode}")
    print(f"{'='*60}")
    print(f"Total experiments scanned: {total}")

    for stage in PIPELINE_STAGES:
        if stage in stage_counts:
            print(f"  - {stage}: {stage_counts[stage]}")

    if "unknown" in stage_counts:
        print(f"  - unknown: {stage_counts['unknown']}")

    if skipped:
        print(f"Skipped (already had status): {skipped}")
    if errors:
        print(f"Errors: {errors}")
    if written:
        print(f"Status files written: {written}")

    print(f"{'='*60}\n")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Backfill pipeline status for existing experiments.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --scan-paths "D:\\FreeWalkOptomotor\\data" --dry-run
  %(prog)s --scan-paths "\\\\prfs.hhmi.org\\reiserlab\\oaky-cokey\\data\\2_processed"
  %(prog)s --all --dry-run
  %(prog)s --all --output-dir "C:\\Users\\labadmin\\Desktop"  # group drive unavailable
        """,
    )

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--scan-paths",
        nargs="+",
        help="Directories to scan for experiments.",
    )
    group.add_argument(
        "--all",
        action="store_true",
        help="Scan all known data locations.",
    )

    parser.add_argument(
        "--results-path",
        default=DEFAULT_RESULTS_PATH,
        help=f"Path to exp_results for cross-referencing (default: {DEFAULT_RESULTS_PATH}).",
    )
    parser.add_argument(
        "--output-registry",
        default=None,
        help="Full path to the global registry JSON file (default: from config, on group drive).",
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help=(
            "Override directory for all output files (registry JSON, HTML, "
            "excluded TXT). Use when the group drive is unavailable. "
            "The standard filenames are used inside this directory."
        ),
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Number of parallel workers (default: 4).",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip folders that already have a pipeline_status.json.",
    )
    parser.add_argument(
        "--local-results-path",
        default=None,
        help="Path to local results folder for cross-referencing (default: from config RESULTS_PATH).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be written without writing anything.",
    )
    parser.add_argument(
        "--check-missing-logs",
        action="store_true",
        help=(
            "Report experiment folders missing a LOG_*.mat file. "
            "Scans all specified paths, prints full folder paths, "
            "and writes a report file. Skips all registry/HTML operations."
        ),
    )

    return parser.parse_args()


def main():
    logger = setup_logging("backfill_registry")

    args = parse_args()

    # Resolve output registry path
    #
    # Priority: --output-registry > --output-dir > config (group drive).
    # The default target is always the network group drive. If that drive
    # is not reachable the user must supply --output-dir (or --output-registry)
    # so that output files are never silently written to a local fallback.
    if args.output_registry is not None:
        # Explicit full path — use as-is
        pass
    elif args.output_dir is not None:
        # Directory override — use standard filename inside that directory
        args.output_registry = os.path.join(args.output_dir, "pipeline_status.json")
    else:
        # Default: group drive via config
        try:
            from config.config import PIPELINE_REGISTRY
            args.output_registry = str(PIPELINE_REGISTRY)
        except Exception:
            print(
                "ERROR: Could not determine the default output path from config.\n"
                "Use --output-dir <path> to specify where output files should be saved.\n"
            )
            sys.exit(1)

    # Verify the output directory is accessible
    output_dir = os.path.dirname(args.output_registry) or "."
    args._output_dir_accessible = os.path.isdir(output_dir)
    if not args._output_dir_accessible:
        if args.check_missing_logs:
            # Non-fatal: console output is the primary deliverable
            logger.warning(f"Output directory not accessible: {output_dir}")
            print(
                f"WARNING: Output directory not accessible ({output_dir}).\n"
                "Report file will not be written; console output only.\n"
            )
        else:
            # Fatal for normal backfill operations
            is_network = output_dir.lower().replace("\\", "/").startswith("//prfs")
            if is_network:
                print(
                    f"ERROR: Group drive is not accessible: {output_dir}\n\n"
                    "Output files are only generated on the group drive by default.\n"
                    "If the group drive is unavailable, use --output-dir to specify\n"
                    "an alternative location:\n\n"
                    f"  python backfill_registry.py --all --output-dir <path>\n"
                )
            else:
                print(
                    f"ERROR: Output directory does not exist: {output_dir}\n"
                    "Please create it first or choose a different location.\n"
                )
            sys.exit(1)

    # Check machine role for local results tagging
    machine_role = _get_machine_role()
    if machine_role not in ("acquisition", "processing"):
        logger.warning(
            f"MACHINE_ROLE is '{machine_role}'; local results cannot be attributed "
            "to a specific machine. Set MACHINE_ROLE environment variable to "
            "'acquisition' or 'processing'."
        )
        print(
            f"WARNING: MACHINE_ROLE='{machine_role}'. "
            "Local results will not be tagged to a specific machine.\n"
            "  Set with: setx MACHINE_ROLE acquisition  (or processing)\n"
        )
    else:
        print(f"Machine role: {machine_role}\n")

    # Resolve local results path
    if args.local_results_path is None:
        try:
            from config.config import RESULTS_PATH
            args.local_results_path = str(RESULTS_PATH)
        except Exception:
            args.local_results_path = None
            logger.warning(
                "Could not import RESULTS_PATH from config; local results checking disabled"
            )

    # Resolve scan paths
    scan_paths = list(args.scan_paths) if args.scan_paths else list(ALL_SCAN_PATHS)

    # Also scan local data directories (only accessible on the current machine)
    if args.all:
        try:
            from config import config as config_module

            for cfg_attr in ("DATA_UNPROCESSED", "DATA_TRACKED", "DATA_PROCESSED"):
                try:
                    path = str(getattr(config_module, cfg_attr))
                    if path not in scan_paths:
                        scan_paths.append(path)
                except AttributeError:
                    pass
        except ImportError:
            logger.debug("Could not import config module for local data paths")

    logger.info(f"Backfill starting — scan paths: {scan_paths}")
    logger.info(f"Output registry: {args.output_registry}")

    # Discover all experiments
    print("Discovering experiments...")
    all_experiments = []
    for sp in scan_paths:
        print(f"  Scanning: {sp}")
        exps = discover_experiments(sp)
        print(f"    Found {len(exps)} experiments")
        all_experiments.extend(exps)

    print(f"\nTotal experiments to process: {len(all_experiments)}\n")

    if not all_experiments:
        print("No experiments found. Nothing to do.")
        return

    # --check-missing-logs mode: report and exit (skip all registry operations)
    if args.check_missing_logs:
        print(f"Checking {len(all_experiments)} experiment folders for missing LOG_*.mat...")
        missing = check_missing_log_files(all_experiments)

        # Enrich with path-based metadata for context
        for m in missing:
            meta = _extract_metadata_from_path_fallback(m["folder_path"], m["scan_root"])
            m["date"] = meta.get("date", "unknown")
            m["protocol"] = meta.get("protocol", "unknown")
            m["strain"] = meta.get("strain", "unknown")

        print_missing_logs_report(missing, len(all_experiments), scan_paths)

        # Write report file if output directory is accessible
        if args._output_dir_accessible:
            report_path = args.output_registry.replace(
                "pipeline_status.json", "missing_log_files.txt"
            )
            try:
                write_missing_logs_report(
                    missing, len(all_experiments), scan_paths, report_path
                )
            except OSError as e:
                logger.warning(f"Could not write report file: {e}")
                print(f"WARNING: Could not write report to {report_path}: {e}")
        else:
            print("(Skipping report file — output directory not accessible)")

        return

    # Build results indexes for cross-referencing (skipped by --check-missing-logs)
    logger.info(f"Results cross-reference: {args.results_path}")
    logger.info(f"Workers: {args.workers}, skip_existing: {args.skip_existing}, dry_run: {args.dry_run}")

    print("Building results index from network exp_results...")
    network_results_index = build_results_index(args.results_path)
    print(f"  Found {len(network_results_index)} result files on network\n")

    local_results_index = {}
    if args.local_results_path:
        print("Building results index from local results...")
        local_results_index = build_results_index(args.local_results_path)
        print(f"  Found {len(local_results_index)} result files locally\n")

    # Process experiments (parallel)
    print(f"Processing experiments ({args.workers} workers)...")
    results = []

    if args.workers == 1:
        # Single-threaded for easier debugging
        for i, exp in enumerate(all_experiments, 1):
            if i % 50 == 0 or i == len(all_experiments):
                print(f"  Progress: {i}/{len(all_experiments)}")
            result = process_one_experiment(exp, network_results_index, local_results_index, args)
            results.append(result)
    else:
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {
                pool.submit(process_one_experiment, exp, network_results_index, local_results_index, args): exp
                for exp in all_experiments
            }
            done = 0
            for future in as_completed(futures):
                done += 1
                if done % 50 == 0 or done == len(all_experiments):
                    print(f"  Progress: {done}/{len(all_experiments)}")
                results.append(future.result())

    # Write global registry
    if not args.dry_run:
        print("\nWriting global registry...")
        write_global_registry(
            results, args.output_registry,
            network_results_index=network_results_index,
            local_results_index=local_results_index,
        )

        print("Generating HTML status page...")
        try:
            generate_status_page(args.output_registry)
        except Exception as e:
            logger.error(f"Error generating status page: {e}")

        out_dir = os.path.dirname(args.output_registry) or "."
        print(f"\nOutput directory: {out_dir}")
        print(f"  Registry:  {args.output_registry}")
        html_path = args.output_registry.replace(".json", ".html")
        print(f"  HTML page: {html_path}")
        txt_path = args.output_registry.replace(".json", "_excluded.txt")
        print(f"  Excluded:  {txt_path}")

    # Print summary
    print_summary(results)

    # In dry-run mode, print a sample of what would be written
    if args.dry_run:
        sample = [r for r in results if r and r.get("status") == "dry_run"][:10]
        if sample:
            print("Sample (first 10 experiments):")
            print("-" * 80)
            for r in sample:
                meta = r.get("metadata", {})
                print(
                    f"  {r['folder']}\n"
                    f"    date={meta.get('date')} protocol={meta.get('protocol')} "
                    f"strain={meta.get('strain')} sex={meta.get('sex')} "
                    f"    -> stage={r.get('inferred_stage')}"
                )
            print("-" * 80)


if __name__ == "__main__":
    main()

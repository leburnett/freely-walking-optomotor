"""Core data processing: load .mat files, segment by condition, combine across cohorts.

Ports the logic from:
  - comb_data_across_cohorts_cond.m (condition segmentation)
  - combine_timeseries_across_exp.m (R1/R2 interleaving, cross-cohort combining)
  - check_and_average_across_reps.m (QC filtering)
"""

from pathlib import Path

import numpy as np
import scipy.io as sio

from dashboard.constants import BASELINE_FRAMES, METRICS, QC_MAX_MIN_DIST, QC_MIN_MEAN_FV


def _squeeze_scalar(val):
    """Extract a scalar from nested MATLAB struct arrays."""
    for _ in range(10):  # guard against infinite nesting
        if isinstance(val, np.ndarray) and val.size == 1:
            val = val.flat[0]
        else:
            break
    if isinstance(val, np.ndarray) and val.dtype.kind in ("U", "S", "O") and val.size == 1:
        return str(val.flat[0])
    return val


def _squeeze_str(val):
    """Extract a string from nested MATLAB struct arrays."""
    result = _squeeze_scalar(val)
    return str(result)


def load_mat_file(filepath: Path) -> tuple[dict, dict, np.ndarray]:
    """Load LOG, comb_data, and n_fly_data from a results .mat file.

    Returns
    -------
    log : dict-like
        The LOG structure with meta, acclim, and log_N entries.
    comb_data : dict
        Behavioral metric arrays, each (n_flies, n_frames).
    n_fly_data : np.ndarray
        [n_flies_arena, n_flies_tracked, n_flies_removed].
    """
    raw = sio.loadmat(str(filepath), variable_names=["LOG", "comb_data", "n_fly_data"])

    log = raw["LOG"][0, 0]
    comb_data_raw = raw["comb_data"][0, 0]
    n_fly_data = raw["n_fly_data"].flatten()

    # Convert comb_data to a plain dict of numpy arrays
    comb_data = {}
    for name in comb_data_raw.dtype.names:
        comb_data[name] = np.asarray(comb_data_raw[name], dtype=np.float64)

    return log, comb_data, n_fly_data


def get_metadata(log, filepath: Path | None = None) -> dict:
    """Extract metadata from LOG.meta.

    Note: LOG.meta.date and LOG.meta.time are MATLAB datetime objects that
    scipy cannot deserialize. The date is extracted from the filename instead.

    Some newer .mat files store fly_strain as a MATLAB `string` instead of
    `char`, which scipy returns as an opaque object. In that case, fall back
    to extracting the strain from the filename.
    """
    meta = log["meta"][0, 0]
    sex = _squeeze_str(meta["fly_sex"])

    # Try extracting strain from meta; fall back to filename if opaque
    try:
        strain = _squeeze_str(meta["fly_strain"]).replace("-", "_")
        # Check if the result looks like a valid strain name
        if "MCOS" in strain or "array" in strain or len(strain) > 100:
            raise ValueError("Opaque MATLAB string object")
    except (ValueError, TypeError):
        strain = ""

    # Extract date and optionally strain from filename
    date_str = ""
    if filepath is not None:
        parts = filepath.stem.split("_")
        if len(parts) >= 2:
            date_str = f"{parts[0]}_{parts[1]}"
        # If strain extraction from meta failed, get it from the folder name
        if not strain:
            strain = filepath.parent.parent.name.replace("-", "_")

    return {
        "strain": strain,
        "sex": sex,
        "date": date_str,
        "cond_array": np.asarray(meta["cond_array"], dtype=np.float64),
    }


def get_log_entries(log) -> list[dict]:
    """Extract all log_N entries from LOG, returning a list of dicts.

    Each dict has: which_condition, start_f (1D), stop_f (1D),
    trial_len, optomotor_pattern, optomotor_speed, interval_pattern, interval_speed.
    """
    entries = []
    idx = 1
    while True:
        key = f"log_{idx}"
        if key not in log.dtype.names:
            break
        entry = log[key][0, 0]
        entries.append({
            "which_condition": int(_squeeze_scalar(entry["which_condition"])),
            "start_f": np.asarray(entry["start_f"]).flatten().astype(int),
            "stop_f": np.asarray(entry["stop_f"]).flatten().astype(int),
            "trial_len": float(_squeeze_scalar(entry["trial_len"])),
            "optomotor_pattern": int(_squeeze_scalar(entry["optomotor_pattern"])),
            "optomotor_speed": int(_squeeze_scalar(entry["optomotor_speed"])),
            "interval_pattern": int(_squeeze_scalar(entry["interval_pattern"])),
            "interval_speed": int(_squeeze_scalar(entry["interval_speed"])),
        })
        idx += 1
    return entries


def segment_condition(
    comb_data: dict,
    log_entry: dict,
    metrics: list[str] | None = None,
    baseline_frames: int = BASELINE_FRAMES,
) -> dict[str, np.ndarray]:
    """Extract per-condition data slices from comb_data using a log entry.

    Mirrors comb_data_across_cohorts_cond.m lines 165-188:
      start_f = Log.start_f(1) - 300   (include pre-stimulus baseline)
      stop_f  = Log.stop_f(end)

    Returns a dict mapping metric name -> (n_flies, n_frames) array.
    """
    if metrics is None:
        metrics = METRICS

    start_f = int(log_entry["start_f"][0]) - baseline_frames
    stop_f = int(log_entry["stop_f"][-1])

    # Clamp start to valid range
    start_f = max(start_f, 0)

    result = {}
    for metric in metrics:
        if metric in comb_data:
            arr = comb_data[metric]
            # Clamp stop_f to array bounds
            actual_stop = min(stop_f, arr.shape[1])
            result[metric] = arr[:, start_f:actual_stop]
    return result


def compute_qc_flags(
    fv_data: np.ndarray,
    dist_data: np.ndarray,
    min_fv: float = QC_MIN_MEAN_FV,
    max_min_dist: float = QC_MAX_MIN_DIST,
) -> np.ndarray:
    """Compute per-fly QC pass/fail flags for one rep.

    Ports check_and_average_across_reps.m lines 41-50.
    A fly fails QC if:
      - mean forward velocity < min_fv (not walking)
      - min distance from center > max_min_dist (stuck at edge)

    Returns boolean array of shape (n_flies,): True = passed QC.
    """
    n_flies = fv_data.shape[0]
    passed = np.ones(n_flies, dtype=bool)

    for i in range(n_flies):
        mean_fv = np.nanmean(fv_data[i])
        min_dist = np.nanmin(dist_data[i])
        if mean_fv < min_fv or min_dist > max_min_dist:
            passed[i] = False

    return passed


def extract_acclimation(
    log,
    comb_data: dict,
    acclim_key: str = "acclim_off1",
    metrics: list[str] | None = None,
) -> dict[str, np.ndarray] | None:
    """Extract acclimation period data from comb_data using LOG frame boundaries.

    Mirrors comb_data_across_cohorts_cond.m lines 95-120:
      Log = LOG.acclim_off1
      start_f = Log.start_f(1);  if start_f==0, start_f=1
      if Log.stop_t(end)<3: stop_f=600  else: stop_f=Log.stop_f(end)

    Returns dict mapping metric name -> (n_flies, n_frames) array, or None
    if the acclim field is not present in LOG.
    """
    if metrics is None:
        metrics = METRICS

    if acclim_key not in log.dtype.names:
        return None

    try:
        acclim = log[acclim_key][0, 0]
    except (IndexError, KeyError):
        return None

    start_f = int(np.asarray(acclim["start_f"]).flat[0])
    if start_f == 0:
        start_f = 1  # MATLAB 1-indexed convention

    # Check for corrupted/short acclim log: fallback to 600 frames
    try:
        stop_t_arr = np.asarray(acclim["stop_t"]).flatten()
        if stop_t_arr[-1] < 3:
            stop_f = 600
        else:
            stop_f = int(np.asarray(acclim["stop_f"]).flatten()[-1])
    except (KeyError, IndexError):
        stop_f = int(np.asarray(acclim["stop_f"]).flatten()[-1])

    # Clamp to valid range
    start_f = max(start_f, 0)

    result = {}
    for metric in metrics:
        if metric in comb_data:
            arr = comb_data[metric]
            actual_stop = min(stop_f, arr.shape[1])
            if actual_stop > start_f:
                result[metric] = arr[:, start_f:actual_stop]

    return result if result else None


def process_one_file(filepath: Path, metrics: list[str] | None = None) -> dict:
    """Process a single .mat file into per-condition, per-fly data.

    Returns a dict with structure:
    {
        "strain": str,
        "sex": str,
        "cohort_id": str (filename stem),
        "cohort_date": str,
        "n_flies": int,
        "conditions": {
            condition_number: {
                "r1": {metric: (n_flies, n_frames) array, ...},
                "r2": {metric: (n_flies, n_frames) array, ...},  # may be None
                "r1_qc": bool array (n_flies,),
                "r2_qc": bool array (n_flies,),  # may be None
                "trial_len": float,
                "optomotor_pattern": int,
                "optomotor_speed": int,
            },
            ...
        }
    }
    """
    if metrics is None:
        metrics = METRICS

    # Ensure fv_data and dist_data are included for QC even if not requested
    qc_metrics = set(metrics) | {"fv_data", "dist_data"}

    log, comb_data, n_fly_data = load_mat_file(filepath)
    meta = get_metadata(log, filepath)
    entries = get_log_entries(log)

    n_entries = len(entries)
    n_conditions = n_entries // 2  # First half = R1, second half = R2

    conditions = {}

    for i, entry in enumerate(entries):
        cond_n = entry["which_condition"]
        is_r1 = i < n_conditions
        rep_key = "r1" if is_r1 else "r2"

        data_slice = segment_condition(comb_data, entry, list(qc_metrics))

        # Compute QC flags
        qc_flags = None
        if "fv_data" in data_slice and "dist_data" in data_slice:
            qc_flags = compute_qc_flags(data_slice["fv_data"], data_slice["dist_data"])

        # Keep only requested metrics in the output
        filtered_slice = {m: data_slice[m] for m in metrics if m in data_slice}

        if cond_n not in conditions:
            conditions[cond_n] = {
                "r1": None,
                "r2": None,
                "r1_qc": None,
                "r2_qc": None,
                "trial_len": entry["trial_len"],
                "optomotor_pattern": entry["optomotor_pattern"],
                "optomotor_speed": entry["optomotor_speed"],
            }

        conditions[cond_n][rep_key] = filtered_slice
        conditions[cond_n][f"{rep_key}_qc"] = qc_flags

    # Extract acclimation data (pre-stimulus dark period)
    acclim_data = extract_acclimation(log, comb_data, "acclim_off1", list(qc_metrics))
    acclim_qc = None
    if acclim_data and "fv_data" in acclim_data and "dist_data" in acclim_data:
        acclim_qc = compute_qc_flags(acclim_data["fv_data"], acclim_data["dist_data"])

    # Filter acclim to requested metrics only
    if acclim_data:
        acclim_filtered = {m: acclim_data[m] for m in metrics if m in acclim_data}
    else:
        acclim_filtered = None

    return {
        "strain": meta["strain"],
        "sex": meta["sex"],
        "cohort_id": filepath.stem,
        "cohort_date": meta["date"],
        "n_flies": int(n_fly_data[1]) if len(n_fly_data) > 1 else int(n_fly_data[0]),
        "conditions": conditions,
        "acclim": acclim_filtered,
        "acclim_qc": acclim_qc,
    }


def _trim_or_pad(arr: np.ndarray, target_cols: int) -> np.ndarray:
    """Trim or NaN-pad array to target_cols columns.

    Mirrors the MATLAB logic in combine_timeseries_across_exp.m lines 81-91.
    """
    n_cols = arr.shape[1]
    if n_cols == target_cols:
        return arr
    elif n_cols > target_cols:
        return arr[:, :target_cols]
    else:
        # Pad with NaN
        pad_width = target_cols - n_cols
        pad = np.full((arr.shape[0], pad_width), np.nan)
        return np.hstack([arr, pad])


def interleave_reps(r1: np.ndarray, r2: np.ndarray) -> np.ndarray:
    """Interleave R1 and R2 rows per fly.

    Matches combine_timeseries_across_exp.m lines 70-75:
    rep_data(1:2:end, :) = rep1_data
    rep_data(2:2:end, :) = rep2_data

    Both reps are trimmed to the shorter length first.
    """
    nf = min(r1.shape[1], r2.shape[1])
    r1 = r1[:, :nf]
    r2 = r2[:, :nf]
    n_flies = r1.shape[0]
    result = np.empty((n_flies * 2, nf), dtype=np.float64)
    result[0::2, :] = r1
    result[1::2, :] = r2
    return result


def average_reps(r1: np.ndarray, r2: np.ndarray) -> np.ndarray:
    """Average R1 and R2 per fly using nanmean.

    Matches combine_timeseries_data_per_cond.m lines 89-91.
    """
    nf = min(r1.shape[1], r2.shape[1])
    r1 = r1[:, :nf]
    r2 = r2[:, :nf]
    return np.nanmean(np.stack([r1, r2], axis=0), axis=0)


def combine_cohorts_for_condition(
    cohort_results: list[dict],
    condition_n: int,
    metric: str,
    rep_mode: str = "interleave",
    apply_qc: bool = False,
) -> np.ndarray:
    """Combine per-fly data across cohorts for one condition and metric.

    Mirrors combine_timeseries_across_exp.m cross-cohort combining with
    NaN padding/trimming.

    Parameters
    ----------
    cohort_results : list of dicts from process_one_file
    condition_n : condition number (1-12)
    metric : e.g. "fv_data"
    rep_mode : "interleave" or "average"
    apply_qc : whether to NaN out flies that fail QC

    Returns
    -------
    cond_data : (n_total_flies_or_rows, n_frames) array
    """
    combined = None

    for cohort in cohort_results:
        cond = cohort["conditions"].get(condition_n)
        if cond is None:
            continue

        r1 = cond["r1"]
        r2 = cond["r2"]
        if r1 is None or metric not in r1:
            continue

        r1_data = r1[metric].copy()
        r2_data = r2[metric].copy() if (r2 is not None and metric in r2) else None

        # Apply QC if requested
        if apply_qc:
            r1_qc = cond.get("r1_qc")
            if r1_qc is not None:
                r1_data[~r1_qc] = np.nan
            if r2_data is not None:
                r2_qc = cond.get("r2_qc")
                if r2_qc is not None:
                    r2_data[~r2_qc] = np.nan

        # Combine reps
        if r2_data is not None:
            if rep_mode == "interleave":
                rep_data = interleave_reps(r1_data, r2_data)
            else:  # average
                rep_data = average_reps(r1_data, r2_data)
        else:
            rep_data = r1_data

        # Combine with existing data (trim/pad to match)
        if combined is None:
            combined = rep_data
        else:
            target_cols = combined.shape[1]
            rep_data = _trim_or_pad(rep_data, target_cols)
            combined = np.vstack([combined, rep_data])

    return combined if combined is not None else np.array([]).reshape(0, 0)

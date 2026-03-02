"""
Process tracked experiment data using MATLAB and sync results to network.

Scans DATA_TRACKED for date folders, runs MATLAB process_freely_walking_data,
copies results and figures to the network, and moves folders to processed.

Usage:
    python daily_processing.py                          # Process new dates only
    python daily_processing.py --reprocess              # Reprocess all dates
    python daily_processing.py 2025_03_01 2025_03_02    # Process specific dates
"""

import argparse
import os
import sys
from pathlib import Path

# Load project-wide config
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
from config.config import (
    DATA_TRACKED, DATA_PROCESSED,
    NETWORK_TRACKED, NETWORK_PROCESSED,
    RESULTS_PATH as _RESULTS_PATH,
    NETWORK_RESULTS, FIGURES_PATH, NETWORK_FIGS,
    REPO_ROOT,
)

# Shared utilities
sys.path.insert(0, str(Path(__file__).parent.parent))
from shared.logging_config import setup_logging
from shared.file_ops import list_date_folders, move_folder, copy_files_by_extension
from shared.matlab import run_matlab
from shared.status import update_stage, read_status, record_error
from shared.registry import update_registry

logger = setup_logging("daily_processing")

# Path aliases
LOCAL_TRACKED        = str(DATA_TRACKED)
LOCAL_PROCESSED      = str(DATA_PROCESSED)
RESULTS_PATH         = str(_RESULTS_PATH)
LOCAL_RESULTS_ROOT   = str(_RESULTS_PATH)
NETWORK_RESULTS_ROOT = NETWORK_RESULTS
LOCAL_FIGS_ROOT      = str(FIGURES_PATH / "overview_figs")
NETWORK_FIGS_ROOT    = NETWORK_FIGS

MATLAB_FUNCTION = "process_freely_walking_data"


def has_results_for_date(date_folder_name):
    """Check if any result files exist for the given date (converted to dash format)."""
    dash_date = date_folder_name.replace("_", "-")
    for root, _, files in os.walk(RESULTS_PATH):
        for file in files:
            if file.startswith(dash_date):
                return True
    return False


def count_results_for_date(date_str):
    """Count how many result files exist for the given date."""
    dash_date = date_str.replace("_", "-")
    count = 0
    for root, _, files in os.walk(RESULTS_PATH):
        count += sum(1 for f in files if f.startswith(dash_date))
    return count


def run_matlab_function(date_str):
    """Run the MATLAB processing function for a given date.

    Returns:
        Tuple of (success: bool, stderr: str).
    """
    setup_path = str(REPO_ROOT / "setup_path.m").replace("\\", "/")
    success, stdout, stderr = run_matlab(
        MATLAB_FUNCTION, date_str, setup_path=setup_path,
    )
    return success, stderr


def copy_mp4s_to_network(local_date_root, network_date_root, date_folder):
    """Copy all .mp4 files from local date folder to network, preserving structure."""
    local_root = os.path.join(local_date_root, date_folder)
    network_root = os.path.join(network_date_root, date_folder)
    return copy_files_by_extension(local_root, network_root, (".mp4",))


def update_experiment_statuses(date_str, stage, status="complete", **extra_fields):
    """Update pipeline_status.json for all experiments under a date folder.

    Walks through the date folder hierarchy to find experiment time folders
    and updates their status files.
    """
    # Check processed first, then tracked
    for base in [LOCAL_PROCESSED, LOCAL_TRACKED]:
        date_path = os.path.join(base, date_str)
        if os.path.isdir(date_path):
            break
    else:
        return

    for root, dirs, files in os.walk(date_path):
        if "pipeline_status.json" in files:
            update_stage(root, stage, status=status, **extra_fields)
            updated = read_status(root)
            if updated:
                update_registry(updated)


def process_date(date_str, reprocess=False):
    """Process a single date folder through the full pipeline.

    Args:
        date_str: Date folder name (YYYY_MM_DD).
        reprocess: If True, skip the has_results check and overwrite on move.

    Returns:
        True if processing succeeded.
    """
    logger.info(f"{'Reprocessing' if reprocess else 'Processing'} date folder: {date_str}")

    success, stderr = run_matlab_function(date_str)

    if not success:
        logger.error(f"MATLAB failed for {date_str}")
        # Record error in experiment status files
        date_path = os.path.join(LOCAL_TRACKED, date_str)
        if os.path.isdir(date_path):
            for root, dirs, files in os.walk(date_path):
                if "pipeline_status.json" in files:
                    record_error(
                        root, "processed",
                        f"MATLAB {MATLAB_FUNCTION} failed",
                        details=stderr,
                    )
                    updated = read_status(root)
                    if updated:
                        update_registry(updated)
        return False

    if not has_results_for_date(date_str):
        logger.warning(f"No results found for {date_str}, skipping move.")
        return False

    result_count = count_results_for_date(date_str)
    logger.info(f"Found {result_count} result files for {date_str}")

    # Copy results to network
    dash_date = date_str.replace("_", "-")
    results_copied = copy_files_by_extension(
        LOCAL_RESULTS_ROOT, NETWORK_RESULTS_ROOT, (".mat",),
        filename_filter=dash_date,
    )
    logger.info(f"Copied {results_copied} .mat files for {dash_date} to exp_results")

    # Copy figures to network
    figs_copied = copy_files_by_extension(
        LOCAL_FIGS_ROOT, NETWORK_FIGS_ROOT, (".pdf", ".png"),
        filename_filter=dash_date,
    )
    logger.info(f"Copied {figs_copied} figure files for {dash_date} to exp_figures")

    # Move local folder: tracked -> processed
    src_local = os.path.join(LOCAL_TRACKED, date_str)
    dst_local = os.path.join(LOCAL_PROCESSED, date_str)
    move_folder(src_local, dst_local, overwrite=reprocess)

    # Move network folder: tracked -> processed
    src_network = os.path.join(NETWORK_TRACKED, date_str)
    dst_network = os.path.join(NETWORK_PROCESSED, date_str)
    move_folder(src_network, dst_network, overwrite=reprocess)

    # Copy MP4 videos to network
    videos_copied = copy_mp4s_to_network(LOCAL_PROCESSED, NETWORK_PROCESSED, date_str)
    logger.info(f"Copied {videos_copied} .mp4 files for {date_str} to network")

    # Update pipeline status for all experiments in this date
    update_experiment_statuses(
        date_str, "processed",
        results_count=result_count, figures_count=figs_copied,
    )
    update_experiment_statuses(
        date_str, "synced_to_network",
        results_copied=results_copied, figures_copied=figs_copied,
        videos_copied=videos_copied,
    )

    return True


def main():
    parser = argparse.ArgumentParser(
        description="Process tracked experiment data and sync to network.",
    )
    parser.add_argument(
        "--reprocess", action="store_true",
        help="Reprocess all dates in tracked, ignoring existing results.",
    )
    parser.add_argument(
        "dates", nargs="*",
        help="Specific date folders to process (default: all in tracked).",
    )
    args = parser.parse_args()

    if args.dates:
        dates_to_process = args.dates
    else:
        dates_to_process = list_date_folders(LOCAL_TRACKED)

    if not args.reprocess:
        # Filter out dates already in the processed folder
        processed_dates = set(list_date_folders(LOCAL_PROCESSED))
        dates_to_process = [d for d in dates_to_process if d not in processed_dates]

    if not dates_to_process:
        logger.info("No dates to process.")
        return

    logger.info(f"Dates to process: {dates_to_process}")

    for date_str in dates_to_process:
        process_date(date_str, reprocess=args.reprocess)


if __name__ == "__main__":
    logger.info("===== Daily Processing Script Started =====")
    main()
    logger.info("===== Daily Processing Script Finished =====")

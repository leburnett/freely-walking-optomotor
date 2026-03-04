"""
Monitor network unprocessed folder, run FlyTracker tracking, and move to tracked.

Scans NETWORK_UNPROCESSED for complete experiment folders, copies them locally,
runs MATLAB batch_track_ufmf, and moves tracked folders through the pipeline.

Usage:
    python monitor_and_track.py                  # Default 75-min timeout
    python monitor_and_track.py --timeout 0      # Run indefinitely
    python monitor_and_track.py --timeout 120    # Exit after 120 min idle
"""

import argparse
import os
import sys
import time
import subprocess
import shutil
from pathlib import Path

# Load project-wide config
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
from config.config import (
    DATA_UNPROCESSED, DATA_TRACKED,
    NETWORK_UNPROCESSED, NETWORK_TRACKED, NETWORK_PROCESSED,
    REPO_ROOT,
)

# Shared utilities
sys.path.insert(0, str(Path(__file__).parent.parent))
from shared.logging_config import setup_logging
from shared.file_ops import is_folder_complete, cleanup_empty_parents
from shared.status import update_stage, read_status, record_error
from shared.registry import update_registry

logger = setup_logging("monitor_and_track")

# Path aliases
GROUP_DRIVE_PATH   = NETWORK_UNPROCESSED
LOCAL_PATH         = str(DATA_UNPROCESSED)
TRACKED_PATH       = NETWORK_TRACKED
TRACKED_LOCAL_PATH = str(DATA_TRACKED)
PROCESSED_PATH     = NETWORK_PROCESSED

# Constants
TRACKING_OUTPUT = "trx.mat"
SCAN_INTERVAL = 300  # seconds (5 minutes)


def has_been_processed(folder_path):
    """Check if the folder already exists in tracked or processed locations."""
    rel_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
    tracked_path = os.path.join(TRACKED_PATH, rel_path)
    processed_path = os.path.join(PROCESSED_PATH, rel_path)
    return os.path.exists(tracked_path) or os.path.exists(processed_path)


def copy_to_local(folder_path):
    """Copy folder from network to local unprocessed directory.

    Returns:
        Local path if successful, None otherwise.
    """
    rel_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
    local_path = os.path.join(LOCAL_PATH, rel_path)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)

    if not os.path.exists(local_path):
        try:
            shutil.copytree(folder_path, local_path)
            logger.info(f"Copied: {folder_path} -> {local_path}")
            return local_path
        except Exception as e:
            logger.error(f"Failed to copy {folder_path}: {e}")
            return None
    else:
        logger.info(f"Local folder already exists: {local_path}")
        return local_path


def run_matlab_tracking(folder_path):
    """Run MATLAB batch_track_ufmf on the given folder.

    Returns:
        Tuple of (success: bool, stderr: str).
    """
    try:
        setup_path = str(REPO_ROOT / "setup_path.m").replace("\\", "/")
        folder_path_matlab = folder_path.replace("\\", "/")
        cmd = (
            f'matlab -batch "run(\'{setup_path}\'); '
            f"cd('{folder_path_matlab}'); "
            f"batch_track_ufmf('{folder_path_matlab}')\""
        )
        logger.info(f"Running MATLAB: {cmd}")
        result = subprocess.run(
            cmd, shell=True, check=True, capture_output=True, text=True
        )
        logger.info("MATLAB batch_track_ufmf completed successfully")
        return True, result.stderr or ""
    except subprocess.CalledProcessError as e:
        logger.error(f"MATLAB tracking failed (exit code {e.returncode})")
        return False, e.stderr or ""
    except FileNotFoundError:
        msg = "MATLAB not found on PATH"
        logger.error(msg)
        return False, msg


def tracking_successful(folder_path):
    """Verify tracking produced trx.mat."""
    for root, _, files in os.walk(folder_path):
        if TRACKING_OUTPUT in files:
            return True
    return False


def move_to_tracked(local_folder):
    """Move tracked folder from local unprocessed to tracked (local + network).

    Steps:
    1. Copy to local archive (DATA_TRACKED)
    2. Move from local unprocessed to network tracked
    3. Clean up empty local parent directories
    4. Delete original from network unprocessed
    5. Clean up empty network parent directories
    """
    rel_path = os.path.relpath(local_folder, LOCAL_PATH)
    final_dest = os.path.join(TRACKED_PATH, rel_path)
    local_archive_dest = os.path.join(TRACKED_LOCAL_PATH, rel_path)
    group_unprocessed_folder = os.path.join(GROUP_DRIVE_PATH, rel_path)

    # Step 1: Copy to local archive
    try:
        os.makedirs(os.path.dirname(local_archive_dest), exist_ok=True)
        shutil.copytree(local_folder, local_archive_dest)
        logger.info(f"Copied to local archive: {local_archive_dest}")
    except Exception as e:
        logger.error(f"Failed to copy to local archive: {e}")

    # Step 2: Move to network tracked folder
    try:
        os.makedirs(os.path.dirname(final_dest), exist_ok=True)
        shutil.move(local_folder, final_dest)
        logger.info(f"Moved to tracked: {final_dest}")

        # Step 3: Clean up empty local parent directories
        cleanup_empty_parents(os.path.dirname(local_folder), LOCAL_PATH)
    except Exception as e:
        logger.error(f"Failed to move to tracked: {e}")

    # Step 4: Delete original from network unprocessed
    try:
        if os.path.exists(group_unprocessed_folder):
            shutil.rmtree(group_unprocessed_folder)
            logger.info(f"Deleted original: {group_unprocessed_folder}")

            # Step 5: Clean up empty network parent directories
            cleanup_empty_parents(
                os.path.dirname(group_unprocessed_folder), GROUP_DRIVE_PATH
            )
    except Exception as e:
        logger.error(f"Failed to delete {group_unprocessed_folder}: {e}")


def process_all_untracked_folders():
    """Scan for and process all untracked folders.

    Returns:
        True if any folder was processed.
    """
    logger.info("Scanning for untracked folders...")
    processed_any = False

    for root, dirs, _ in os.walk(GROUP_DRIVE_PATH):
        for d in dirs:
            full_path = os.path.join(root, d)
            if not has_been_processed(full_path) and is_folder_complete(full_path):
                logger.info(f"Processing folder: {full_path}")
                local_copy = copy_to_local(full_path)
                if local_copy:
                    success, stderr = run_matlab_tracking(local_copy)
                    if success and tracking_successful(local_copy):
                        # Update pipeline status
                        update_stage(
                            local_copy, "tracked",
                            status="complete", trx_mat_found=True,
                        )
                        updated = read_status(local_copy)
                        if updated:
                            update_registry(updated)

                        move_to_tracked(local_copy)
                        processed_any = True
                    else:
                        logger.warning(f"Tracking failed or incomplete: {local_copy}")
                        record_error(
                            local_copy, "tracked",
                            "MATLAB batch_track_ufmf failed or trx.mat not found",
                            details=stderr,
                        )
                        updated = read_status(local_copy)
                        if updated:
                            update_registry(updated)

    return processed_any


def main():
    parser = argparse.ArgumentParser(
        description="Monitor network for untracked experiments and run FlyTracker.",
    )
    parser.add_argument(
        "--timeout", type=int, default=75,
        help="Minutes before exiting with no new data. 0 = run forever. (default: 75)",
    )
    args = parser.parse_args()

    timeout_seconds = args.timeout * 60 if args.timeout > 0 else None
    idle_time = 0

    logger.info(
        f"Starting automated tracker "
        f"(timeout={'infinite' if timeout_seconds is None else f'{args.timeout} min'})..."
    )

    try:
        while True:
            did_process = process_all_untracked_folders()
            if did_process:
                idle_time = 0
            else:
                idle_time += SCAN_INTERVAL

            if timeout_seconds is not None and idle_time >= timeout_seconds:
                logger.info(f"No new data for {args.timeout} minutes. Exiting.")
                break

            logger.info(
                f"Sleeping for {SCAN_INTERVAL}s... "
                f"(idle: {idle_time // 60}m / "
                f"{'inf' if timeout_seconds is None else f'{args.timeout}m'})"
            )
            time.sleep(SCAN_INTERVAL)

    except KeyboardInterrupt:
        logger.info("Script interrupted by user. Exiting.")


if __name__ == "__main__":
    main()

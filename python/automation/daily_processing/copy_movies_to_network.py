"""
Standalone utility to sync .mp4 files from local processed data to network.

This is a backfill tool — during normal operation, daily_processing.py handles
video copying. Use this to catch up on missing videos.

Usage:
    python copy_movies_to_network.py
"""

import os
import sys
from pathlib import Path

# Load project-wide config
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
from config.config import DATA_PROCESSED, NETWORK_PROCESSED

# Shared utilities
sys.path.insert(0, str(Path(__file__).parent.parent))
from shared.logging_config import setup_logging
from shared.file_ops import copy_files_by_extension

logger = setup_logging("copy_movies_to_network")


def sync_videos(local_root, network_root):
    """Sync .mp4 files from local to network, skipping files that already exist.

    Args:
        local_root: Local processed data directory.
        network_root: Network processed data directory.

    Returns:
        Tuple of (copied_count, skipped_count, missing_folders).
    """
    total_copied = 0
    total_skipped = 0
    missing_folders = []

    for date_folder in sorted(os.listdir(local_root)):
        local_date_path = os.path.join(local_root, date_folder)
        if not os.path.isdir(local_date_path):
            continue

        for root, dirs, files in os.walk(local_date_path):
            relative_path = os.path.relpath(root, local_root)
            mp4_files = [f for f in files if f.lower().endswith(".mp4")]

            if not mp4_files:
                missing_folders.append(relative_path)
                continue

            network_folder = os.path.join(network_root, relative_path)
            all_exist = all(
                os.path.exists(os.path.join(network_folder, f)) for f in mp4_files
            )
            if all_exist:
                total_skipped += 1
                continue

            os.makedirs(network_folder, exist_ok=True)
            for mp4 in mp4_files:
                network_mp4 = os.path.join(network_folder, mp4)
                if not os.path.exists(network_mp4):
                    local_mp4 = os.path.join(root, mp4)
                    import shutil
                    shutil.copy2(local_mp4, network_mp4)
                    total_copied += 1
                    logger.info(f"Copied {mp4} to {relative_path}")

    return total_copied, total_skipped, missing_folders


if __name__ == "__main__":
    local_root = str(DATA_PROCESSED)
    network_root = NETWORK_PROCESSED

    logger.info("Starting video sync...")
    copied, skipped, missing = sync_videos(local_root, network_root)

    logger.info(f"Summary: {copied} copied, {skipped} skipped, {len(missing)} folders with no videos")
    if missing:
        logger.info(f"Folders with no videos: {len(missing)}")

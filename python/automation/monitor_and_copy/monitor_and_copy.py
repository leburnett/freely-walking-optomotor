"""
Monitor acquisition source folder for new experiment data and copy to network.

Watches SOURCE_ROOT using a filesystem observer. When a new experiment folder
is detected and contains all required files (stamp_log, .mat, .ufmf), copies
it to the network unprocessed folder and creates a pipeline_status.json inside.

On startup, scans SOURCE_ROOT for any complete experiment folders that were
missed during downtime (e.g., machine reboot, script not running).

Usage:
    python monitor_and_copy.py
"""

import os
import sys
import shutil
import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Load project-wide config
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
from config.config import (
    SOURCE_ROOT, NETWORK_UNPROCESSED, NETWORK_TRACKED, NETWORK_PROCESSED,
)

# Shared utilities
sys.path.insert(0, str(Path(__file__).parent.parent))
from shared.logging_config import setup_logging
from shared.file_ops import is_folder_complete, parse_experiment_path
from shared.status import init_status, update_stage, read_status
from shared.registry import update_registry

logger = setup_logging("monitor_and_copy")

DEST_ROOT = NETWORK_UNPROCESSED
CHECK_INTERVAL = 30  # seconds between checking incomplete folders

pending_folders = set()


def _already_on_network(relative_path):
    """Check if an experiment folder already exists in any network stage."""
    for network_root in (NETWORK_UNPROCESSED, NETWORK_TRACKED, NETWORK_PROCESSED):
        if os.path.exists(os.path.join(network_root, relative_path)):
            return True
    return False


def startup_scan():
    """Scan SOURCE_ROOT for complete experiment folders not yet on the network.

    This catches any experiments created while the script was not running.
    """
    logger.info("Running startup scan for missed experiments...")
    found = 0
    for root, dirs, files in os.walk(str(SOURCE_ROOT)):
        if is_folder_complete(root):
            relative_path = os.path.relpath(root, str(SOURCE_ROOT))
            if not _already_on_network(relative_path):
                pending_folders.add(root)
                found += 1
                logger.info(f"Startup scan found missed folder: {root}")
            # Don't descend into complete folders (leaf experiment directories)
            dirs.clear()
    logger.info(f"Startup scan complete. Found {found} missed folder(s).")


class VideoFolderHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            pending_folders.add(event.src_path)

    def check_pending_folders(self):
        """Check if pending folders now contain all required files and copy them."""
        to_remove = []
        for folder_path in list(pending_folders):
            if is_folder_complete(folder_path):
                logger.info(f"Folder complete: {folder_path}")
                self.copy_folder(folder_path)
                to_remove.append(folder_path)
        for folder in to_remove:
            pending_folders.discard(folder)

    def copy_folder(self, folder_path):
        """Copy the completed folder to the network drive and record status."""
        relative_path = os.path.relpath(folder_path, str(SOURCE_ROOT))
        dest_path = os.path.join(DEST_ROOT, relative_path)

        try:
            shutil.copytree(folder_path, dest_path, dirs_exist_ok=True)
            logger.info(f"Copied: {folder_path} -> {dest_path}")
        except Exception as e:
            logger.error(f"Error copying {folder_path} to {dest_path}: {e}")
            return

        # Create pipeline_status.json in the destination folder
        metadata = parse_experiment_path(folder_path, str(SOURCE_ROOT))
        if metadata:
            init_status(
                dest_path,
                date=metadata["date"],
                protocol=metadata["protocol"],
                strain=metadata["strain"],
                sex=metadata["sex"],
                time_str=metadata["time"],
            )
            update_stage(dest_path, "acquired", status="complete")
            update_stage(dest_path, "copied_to_network", status="complete")
            # Update global registry
            updated = read_status(dest_path)
            if updated:
                update_registry(updated)
        else:
            logger.warning(
                f"Could not parse experiment metadata from path: {folder_path}"
            )


if __name__ == "__main__":
    logger.info("Starting folder monitoring script...")

    # Scan for experiments missed during downtime before starting the watcher
    startup_scan()

    observer = Observer()
    event_handler = VideoFolderHandler()
    observer.schedule(event_handler, path=str(SOURCE_ROOT), recursive=True)
    observer.start()

    try:
        while True:
            event_handler.check_pending_folders()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        logger.info("Script stopped by user.")
        observer.stop()
    observer.join()

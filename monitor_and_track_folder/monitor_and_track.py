import os
import time
import logging
import subprocess
import shutil

# Setup logging
LOG_FILE = "monitor_and_track.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)

# Paths
GROUP_DRIVE_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\0_unprocessed"
LOCAL_PATH = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed"

TRACKED_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\1_tracked"
TRACKED_LOCAL_PATH = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\01_tracked"
PROCESSED_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\2_processed"

MATLAB_FUNCTION = "batch_track_ufmf"


# Config
REQUIRED_EXTENSIONS = {".mat", ".ufmf"}
REQUIRED_PREFIX = "stamp_log"
TRACKING_OUTPUT = "trx.mat"
SCAN_INTERVAL = 300  # seconds (5 minutes)

def is_folder_complete(folder_path):
    try:
        files = os.listdir(folder_path)
        return (
            any(f.startswith(REQUIRED_PREFIX) for f in files)
            and any(f.endswith(".mat") for f in files)
            and any(f.endswith(".ufmf") for f in files)
        )
    except Exception as e:
        logging.warning(f"Error reading {folder_path}: {e}")
        return False

def has_been_processed(folder_path):
    rel_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
    tracked_path = os.path.join(TRACKED_PATH, rel_path)
    processed_path = os.path.join(PROCESSED_PATH, rel_path)
    return os.path.exists(tracked_path) or os.path.exists(processed_path)

def copy_to_local(folder_path):
    rel_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
    local_path = os.path.join(LOCAL_PATH, rel_path)
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    if not os.path.exists(local_path):
        try:
            shutil.copytree(folder_path, local_path)
            logging.info(f"Copied: {folder_path} -> {local_path}")
            return local_path
        except Exception as e:
            logging.error(f"Failed to copy {folder_path}: {e}")
            return None
    else:
        logging.info(f"Local folder already exists: {local_path}")
        return local_path

def run_matlab_tracking(folder_path):
    try:
        folder_path_matlab = folder_path.replace("\\", "/")
        cmd = f'matlab -batch "cd(\'{folder_path_matlab}\'); {MATLAB_FUNCTION}(\'{folder_path_matlab}\')"'
        logging.info(f"Running MATLAB: {cmd}")
        subprocess.run(cmd, shell=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"MATLAB tracking failed: {e}")
        return False

def tracking_successful(folder_path):
    for root, _, files in os.walk(folder_path):
        if TRACKING_OUTPUT in files:
            return True
    return False

def move_to_tracked(local_folder):
    rel_path = os.path.relpath(local_folder, LOCAL_PATH)
    final_dest = os.path.join(TRACKED_PATH, rel_path)
    local_archive_dest = os.path.join(TRACKED_LOCAL_PATH, rel_path)
    group_unprocessed_folder = os.path.join(GROUP_DRIVE_PATH, rel_path)

    # Step 1: Copy to local archive
    try:
        os.makedirs(os.path.dirname(local_archive_dest), exist_ok=True)
        shutil.copytree(local_folder, local_archive_dest)
        logging.info(f"Copied to local archive: {local_archive_dest}")
    except Exception as e:
        logging.error(f"Failed to copy to local archive: {e}")

    # Step 2: Move to network tracked folder
    try:
        os.makedirs(os.path.dirname(final_dest), exist_ok=True)
        shutil.move(local_folder, final_dest)
        logging.info(f"Moved to tracked: {final_dest}")

        # Step 3: Clean up empty intermediate folders in LOCAL_PATH
        cleanup_path = os.path.dirname(local_folder)
        while cleanup_path != LOCAL_PATH and os.path.isdir(cleanup_path):
            try:
                os.rmdir(cleanup_path)
                # logging.info(f"Removed empty folder: {cleanup_path}")
                cleanup_path = os.path.dirname(cleanup_path)
            except OSError:
                break
    except Exception as e:
        logging.error(f"Failed to move to tracked: {e}")

    # Step 4: Delete original folder from group drive
    try:
        if os.path.exists(group_unprocessed_folder):
            shutil.rmtree(group_unprocessed_folder)
            logging.info(f"Deleted original untracked folder: {group_unprocessed_folder}")

            # Step 5: Delete empty parent directories up to GROUP_DRIVE_PATH
            cleanup_path = os.path.dirname(group_unprocessed_folder)
            while cleanup_path != GROUP_DRIVE_PATH and os.path.isdir(cleanup_path):
                try:
                    os.rmdir(cleanup_path)
                    # logging.info(f"Removed empty parent folder: {cleanup_path}")
                    cleanup_path = os.path.dirname(cleanup_path)
                except OSError:
                    # Stop if directory is not empty
                    break

    except Exception as e:
        logging.error(f"Failed to delete group drive folder: {group_unprocessed_folder}: {e}")


def process_all_untracked_folders():
    logging.info("Scanning for untracked folders...")
    processed_folders = False

    for root, dirs, _ in os.walk(GROUP_DRIVE_PATH):
        for d in dirs:
            full_path = os.path.join(root, d)
            if not has_been_processed(full_path) and is_folder_complete(full_path):
                logging.info(f"Processing folder: {full_path}")
                local_copy = copy_to_local(full_path)
                if local_copy:
                    success = run_matlab_tracking(local_copy)
                    if success and tracking_successful(local_copy):
                        move_to_tracked(local_copy)
                        processed_folders = True
                    else:
                        logging.warning(f"Tracking failed or incomplete: {local_copy}")

    return processed_folders

if __name__ == "__main__":
    logging.info("Starting automated tracker with timer loop...")
    scan_count = 0
    try:
        while scan_count < 15:
            did_process = process_all_untracked_folders()
            if did_process:
                scan_count = 0
            else:
                scan_count += 1
            logging.info(f"Sleeping for {SCAN_INTERVAL} seconds... (Scan {scan_count}/15)")
            time.sleep(SCAN_INTERVAL)
        logging.info("Reached maximum scan limit with no new data. Exiting.")
    except KeyboardInterrupt:
        logging.info("Script interrupted by user. Exiting.")

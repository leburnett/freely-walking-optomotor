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
                    logging.info(f"Removed empty parent folder: {cleanup_path}")
                    cleanup_path = os.path.dirname(cleanup_path)
                except OSError:
                    # Stop if directory is not empty
                    break

    except Exception as e:
        logging.error(f"Failed to delete group drive folder: {group_unprocessed_folder}: {e}")


def process_all_untracked_folders():
    logging.info("Scanning for untracked folders...")
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
                    else:
                        logging.warning(f"Tracking failed or incomplete: {local_copy}")

if __name__ == "__main__":
    logging.info("Starting automated tracker with timer loop...")
    scan_count = 0
    try:
        while scan_count < 10:
            process_all_untracked_folders()
            scan_count += 1
            logging.info(f"Sleeping for {SCAN_INTERVAL} seconds... (Scan {scan_count}/10)")
            time.sleep(SCAN_INTERVAL)
        logging.info("Reached maximum scan limit. Exiting.")
    except KeyboardInterrupt:
        logging.info("Script interrupted by user. Exiting.")



#################################################################################################

# import os
# import time
# import logging
# import subprocess
# import shutil
# import sys
# from watchdog.observers import Observer
# from watchdog.events import FileSystemEventHandler

# # Setup logging
# LOG_FILE = "monitor_and_track.log"
# logging.basicConfig(
#     filename=LOG_FILE,
#     level=logging.INFO,
#     format="%(asctime)s - %(levelname)s - %(message)s",
# )

# # Paths
# GROUP_DRIVE_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\0_unprocessed"
# PROCESSED_ROOT = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\1_tracked"
# MATLAB_FUNCTION = "batch_track_ufmf"  # The MATLAB function name
# LOCAL_PATH = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed"

# # Required files in each time folder
# REQUIRED_EXTENSIONS = {".mat", ".ufmf"}
# REQUIRED_PREFIX = "stamp_log"
# TRACKING_OUTPUT = "trx.mat"

# class VideoTrackingHandler(FileSystemEventHandler):
#     def on_created(self, event):
#         """Triggered when a new folder is detected."""
#         if event.is_directory:
#             logging.info(f"New folder detected: {event.src_path}")
#             process_folder(event.src_path)

# def is_folder_complete(folder_path):
#     """Check if a folder contains all required files."""
#     if not os.path.exists(folder_path):
#         return False
#     files = os.listdir(folder_path)
#     complete = (
#         any(f.startswith(REQUIRED_PREFIX) for f in files)
#         and any(f.endswith(".mat") for f in files)
#         and any(f.endswith(".ufmf") for f in files)
#     )
#     if complete:
#         logging.info(f"Folder complete: {folder_path}")
#     return complete

# def process_folder(folder_path):
#     """Check if a folder is complete, copy it, run tracking, and move if successful."""
#     time.sleep(5)  # Allow time for files to settle
    
#     if is_folder_complete(folder_path):
#         # Copy the folder to 00_unprocessed before tracking
#         copied_folder_path = copy_to_destination(folder_path)

#         if copied_folder_path:
#             logging.info(f"Running MATLAB tracking on: {copied_folder_path}")
            
#             # Run the fly tracker from the destination folder
#             success = run_matlab_tracking(copied_folder_path)
            
#             if success and check_tracking_complete(copied_folder_path):
#                 move_processed_folder(copied_folder_path)

# def run_matlab_tracking(folder_path):
#     """Run the MATLAB tracking function on a time folder."""
#     try:
#         folder_path_matlab_escaped = folder_path.replace("\\", "/")  # MATLAB prefers forward slashes
#         cmd = f'matlab -batch "cd(\'{folder_path_matlab_escaped}\'); {MATLAB_FUNCTION}(\'{folder_path_matlab_escaped}\')"'

#         logging.info(f"MATLAB command: {cmd}")
#         subprocess.run(cmd, shell=True, check=True)
#         logging.info(f"MATLAB tracking completed for: {folder_path}")

#         return True
#     except subprocess.CalledProcessError as e:
#         logging.error(f"MATLAB ERROR for {folder_path}: {e}")
#         return False

# def check_tracking_complete(folder_path):
#     """Check if tracking has been completed by looking for trx.mat in subdirectories."""
#     for root, dirs, files in os.walk(folder_path):  
#         if TRACKING_OUTPUT in files:
#             logging.info(f"Tracking confirmed complete in subdirectory: {root}")
#             return True
#     logging.warning(f"Tracking output missing (trx.mat not found): {folder_path}")
#     return False

# def copy_to_destination(folder_path):
#     """Copy the entire path structure of a folder from 0_unprocessed to 00_unprocessed."""
#     relative_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
#     dest_folder = os.path.join(LOCAL_PATH, relative_path)

#     logging.info(f"Copying folder to: {dest_folder}")
    
#     os.makedirs(os.path.dirname(dest_folder), exist_ok=True)

#     if not os.path.exists(dest_folder):
#         try:
#             shutil.copytree(folder_path, dest_folder)
#             logging.info(f"Copied folder: {folder_path} -> {dest_folder}")
#             return dest_folder
#         except Exception as e:
#             logging.error(f"ERROR copying {folder_path}: {e}")
#             return None
#     else:
#         logging.info(f"Folder already exists at: {dest_folder}")
#         return dest_folder

# def move_processed_folder(folder_path):
#     """Move processed folder to the processed directory while maintaining the folder structure."""
#     relative_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
#     dest_folder = os.path.join(PROCESSED_ROOT, relative_path)

#     os.makedirs(os.path.dirname(dest_folder), exist_ok=True)

#     if not os.path.exists(dest_folder):
#         try:
#             shutil.move(folder_path, dest_folder)
#             logging.info(f"Moved folder to processed directory: {folder_path} -> {dest_folder}")
#         except Exception as e:
#             logging.error(f"Error moving {folder_path} to processed directory: {e}")
#     else:
#         logging.info(f"Folder {folder_path} already exists in processed directory.")

# if __name__ == "__main__":
#     logging.info("Starting tracking monitor on Computer 2...")
#     observer = Observer()
#     event_handler = VideoTrackingHandler()
#     observer.schedule(event_handler, path=GROUP_DRIVE_PATH, recursive=True)
#     observer.start()

#     try:
#         while True:
#             time.sleep(10)  # Polling interval
#     except KeyboardInterrupt:
#         logging.info("Script stopped by user.")
#         observer.stop()
#     observer.join()


####################################################################################

# import os
# import time
# import logging
# import subprocess
# import shutil
# import sys
# from watchdog.observers import Observer
# from watchdog.events import FileSystemEventHandler

# # Setup logging
# LOG_FILE = "monitor_and_track.log"
# logging.basicConfig(
#     filename=LOG_FILE,
#     level=logging.INFO,
#     format="%(asctime)s - %(levelname)s - %(message)s",
# )

# # def flush_logs():
# #     for handler in logging.getLogger().handlers:
# #         handler.flush()
# #     sys.stdout.flush()
# #     sys.stderr.flush()

# # Paths
# GROUP_DRIVE_PATH = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\0_unprocessed"
# PROCESSED_ROOT = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\1_tracked"
# MATLAB_FUNCTION = "batch_track_ufmf"  # The MATLAB function name
# LOCAL_PATH = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed"  # New destination path

# # Required files in each time folder
# REQUIRED_EXTENSIONS = {".mat", ".ufmf"}
# REQUIRED_PREFIX = "stamp_log"
# TRACKING_OUTPUT = "trx.mat"  # File that confirms tracking is complete

# class VideoTrackingHandler(FileSystemEventHandler):
#     def on_created(self, event):
#         """Triggered when a new folder is detected."""
#         if event.is_directory:
#             logging.info(f"New folder detected: {event.src_path}")
#             process_folder(event.src_path)

# def is_folder_complete(folder_path):
#     """Check if a folder contains all required files."""
#     if not os.path.exists(folder_path):
#         return False
#     files = os.listdir(folder_path)
#     complete = (
#         any(f.startswith(REQUIRED_PREFIX) for f in files)
#         and any(f.endswith(".mat") for f in files)
#         and any(f.endswith(".ufmf") for f in files)
#     )
#     if complete:
#         logging.info(f"Folder complete: {folder_path}")
#     return complete

# def process_folder(folder_path):
#     """Check if a folder is complete, copy it, run tracking, and move if successful."""
#     time.sleep(5)  # Wait for files to settle
    
#     if is_folder_complete(folder_path):
#         # Copy the folder to 00_unprocessed before tracking
#         copy_to_destination(folder_path)
        
#         # Determine the new path for the copied folder in the destination directory
#         relative_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)  # Get full structure
#         copied_folder_path = os.path.join(LOCAL_PATH, relative_path)  # Preserve hierarchy

#         # Log the copied folder path for debugging
#         logging.info(f"Running MATLAB tracking on: {copied_folder_path}")
#         # flush_logs()
#         logging.info(f"Full copied folder path: {copied_folder_path}")
#         # flush_logs()
        
#         # Run the fly tracker from the destination folder
#         success = run_matlab_tracking(copied_folder_path)
#         if success and check_tracking_complete(copied_folder_path):
#             move_processed_folder(folder_path)

# def run_matlab_tracking(folder_path):
#     """Run the MATLAB tracking function on a time folder."""
#     try:
#         folder_path_matlab_escaped = folder_path.replace("\\", "/")  # MATLAB prefers forward slashes

#         # Log the exact command MATLAB will receive
#         logging.info(f"MATLAB will process: {folder_path_matlab_escaped}")

#         cmd = f'matlab -batch "cd(\'{folder_path_matlab_escaped}\'); {MATLAB_FUNCTION}(\'{folder_path_matlab_escaped}\')"'
#         logging.info(f"MATLAB command: {cmd}")

#         subprocess.run(cmd, shell=True, check=True)
#         logging.info(f"MATLAB tracking completed for: {folder_path}")

#         return True
#     except subprocess.CalledProcessError as e:
#         logging.error(f"MATLAB ERROR for {folder_path}: {e}")
#         return False

    
# def check_tracking_complete(folder_path):
#     """Check if tracking has been completed by looking for trx.mat in subdirectories."""
#     for root, dirs, files in os.walk(folder_path):  # Walk through all subdirectories
#         if TRACKING_OUTPUT in files:
#             logging.info(f"Tracking confirmed complete in subdirectory: {root}")
#             return True
#     logging.warning(f"Tracking output missing (trx.mat not found): {folder_path}")
#     return False

# def copy_to_destination(folder_path):
#     """Copy the entire path structure of a folder from 0_unprocessed to 00_unprocessed."""
#     relative_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)  # Should retain hierarchy
#     dest_folder = os.path.join(LOCAL_PATH, relative_path)  # Recreate full structure

#     logging.info(f"Expected destination path: {dest_folder}")

#     os.makedirs(os.path.dirname(dest_folder), exist_ok=True)  # Ensure parent dirs exist

#     if not os.path.exists(dest_folder):
#         try:
#             shutil.copytree(folder_path, dest_folder)
#             logging.info(f"Copied folder: {folder_path} -> {dest_folder}")
#         except Exception as e:
#             logging.error(f"ERROR copying {folder_path}: {e}")
#     else:
#         logging.info(f"Folder already exists at: {dest_folder}")

#     # NEW: Verify copied folder actually exists
#     if not os.path.exists(dest_folder):
#         logging.error(f"ERROR: Copied folder NOT FOUND at {dest_folder}")
#     else:
#         logging.info(f"Verified folder exists at {dest_folder}")

# def move_processed_folder(folder_path):
#     """Move processed folder to the processed directory while maintaining the folder structure."""
#     # Get the relative path from the root of 0_unprocessed
#     relative_path = os.path.relpath(folder_path, GROUP_DRIVE_PATH)
    
#     # Create the full destination path by appending the relative path to the processed root
#     dest_folder = os.path.join(PROCESSED_ROOT, relative_path)
    
#     # Create the parent directories in the destination if they do not exist
#     os.makedirs(os.path.dirname(dest_folder), exist_ok=True)
    
#     # Only copy if the folder doesn't already exist in the destination
#     if not os.path.exists(dest_folder):
#         try:
#             shutil.copytree(folder_path, dest_folder)
#             logging.info(f"Copied entire folder to processed directory: {folder_path} -> {dest_folder}")
#         except Exception as e:
#             logging.error(f"Error copying {folder_path} to processed directory: {e}")
#     else:
#         logging.info(f"Folder {folder_path} already exists in processed directory.")

# if __name__ == "__main__":
#     logging.info("Starting tracking monitor on Computer 2...")
#     observer = Observer()
#     event_handler = VideoTrackingHandler()
#     observer.schedule(event_handler, path=GROUP_DRIVE_PATH, recursive=True)
#     observer.start()

#     try:
#         while True:
#             time.sleep(10)  # Polling interval
#     except KeyboardInterrupt:
#         logging.info("Script stopped by user.")
#         observer.stop()
#     observer.join()


####################################################################################

# import os
# import shutil
# import subprocess
# import time
# import logging

# # Setup logging
# LOG_FILE = "monitor_and_track.log"
# logging.basicConfig(
#     filename=LOG_FILE,
#     level=logging.INFO,
#     format="%(asctime)s - %(levelname)s - %(message)s",
# )

# # # Set up logging
# # log_file = r"C:\Users\burnettl\Documents\oakey-cokey\tracking_pipeline.log"
# # logging.basicConfig(filename=log_file, level=logging.INFO, 
# #                     format='%(asctime)s - %(levelname)s - %(message)s')

# # Paths
# group_drive_path = r"\\prfs\reiserlab\oaky-cokey\data\0_unprocessed"
# local_path = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed"
# tracked_path = r"\\prfs\reiserlab\oaky-cokey\data\1_tracked"

# # Function to check if required files exist in the time folder
# def check_required_files(folder_path):
#     required_files = ['.mat', '.ufmf', 'stamp_log']
#     for file in required_files:
#         if not any(f.endswith(file) for f in os.listdir(folder_path)):
#             logging.warning(f"Missing required file: {file} in {folder_path}")
#             return False
#     return True

# # Function to run the MATLAB batch tracker
# def run_batch_tracker(time_folder_path):
#     try:
#         # Run MATLAB command
#         logging.info(f"Running batch_track_ufmf on {time_folder_path}")
#         subprocess.run(
#             ["matlab", "-batch", f"batch_track_ufmf('{time_folder_path}')"],
#             check=True
#         )
#         logging.info(f"Batch tracker completed successfully on {time_folder_path}")
#         return True
#     except subprocess.CalledProcessError as e:
#         logging.error(f"Error running batch_track_ufmf on {time_folder_path}: {e}")
#         return False

# # Function to check if trx.mat exists after tracking
# def check_trx_file(time_folder_path):
#     trx_file = os.path.join(time_folder_path, 'trx.mat')
#     if os.path.exists(trx_file):
#         logging.info(f"trx.mat found in {time_folder_path}")
#         return True
#     else:
#         logging.warning(f"trx.mat not found in {time_folder_path}")
#         return False

# # Function to move folder after processing
# def move_folder_to_tracked(local_folder_path):
#     folder_name = os.path.basename(local_folder_path)
#     target_path = os.path.join(tracked_path, folder_name)
#     shutil.move(local_folder_path, target_path)
#     logging.info(f"Moved {folder_name} to tracked.")

# # Main loop to monitor the unprocessed folder and process new folders
# def process_new_folders():

#     logging.info("Starting tracking monitor on Computer 2...")
    
#     while True:
#         # Check for new folders in the unprocessed directory
#         for folder_name in os.listdir(group_drive_path):
#             folder_path = os.path.join(group_drive_path, folder_name)

#             # Check if it's a directory and if required files exist
#             if os.path.isdir(folder_path) and check_required_files(folder_path):
#                 logging.info(f"Found new folder: {folder_name}. Starting processing.")

#                 # Copy folder to local drive
#                 local_folder_path = os.path.join(local_path, folder_name)
#                 shutil.copytree(folder_path, local_folder_path)
#                 logging.info(f"Copied {folder_name} to local drive.")

#                 # Run MATLAB tracking
#                 if run_batch_tracker(local_folder_path):
#                     # Check if trx.mat exists
#                     if check_trx_file(local_folder_path):
#                         # Move folder to tracked
#                         move_folder_to_tracked(local_folder_path)
#                     else:
#                         logging.error(f"trx.mat not found after processing {folder_name}")
#                 else:
#                     logging.error(f"Failed to process {folder_name}")

#         # Wait before checking again
#         time.sleep(60)  # Adjust the interval if needed

# # Start processing
# logging.info("Starting the pipeline.")
# process_new_folders()





# ############## TRY 1 ###################


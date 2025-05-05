import os
import shutil
import subprocess
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    filename="daily_process_runner.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# Paths
LOCAL_TRACKED = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\01_tracked"
LOCAL_PROCESSED = r"C:\Users\burnettl\Documents\oakey-cokey\DATA\02_processed"
NETWORK_TRACKED = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\1_tracked"
NETWORK_PROCESSED = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\2_processed"
RESULTS_PATH = r"C:\Users\burnettl\Documents\oakey-cokey\results\protocol_27"

MATLAB_FUNCTION = "process_freely_walking_data"

def list_date_folders(path):
    return [
        name for name in os.listdir(path)
        if os.path.isdir(os.path.join(path, name)) and name.count('_') == 2
    ]

def has_results_for_date(date_folder_name):
    """Check if any result files exist that start with the given date (converted to dash format)."""
    dash_date = date_folder_name.replace("_", "-")
    for root, _, files in os.walk(RESULTS_PATH):
        for file in files:
            if file.startswith(dash_date):
                return True
    return False

def count_results_for_date(date_str):
    count = 0
    for root, _, files in os.walk(RESULTS_PATH):
        count += sum(1 for f in files if f.startswith(date_str))
    return count

def run_matlab_function(date_str):
    try:
        cmd = f'matlab -batch "{MATLAB_FUNCTION}(\'{date_str}\')"'
        logging.info(f"Running MATLAB command: {cmd}")
        subprocess.run(cmd, shell=True, check=True)
        logging.info(f"Successfully ran MATLAB function for {date_str}")
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"MATLAB ERROR for {date_str}: {e}")
        return False

def move_folder(source_root, dest_root, folder_name):
    src = os.path.join(source_root, folder_name)
    dst = os.path.join(dest_root, folder_name)
    if os.path.exists(src):
        os.makedirs(dest_root, exist_ok=True)
        try:
            shutil.move(src, dst)
            logging.info(f"Moved {src} -> {dst}")
        except Exception as e:
            logging.error(f"Error moving {src} -> {dst}: {e}")
    else:
        logging.warning(f"Source folder not found: {src}")

def main():
    tracked_dates = list_date_folders(LOCAL_TRACKED)
    processed_dates = set(list_date_folders(LOCAL_PROCESSED))

    for date_str in tracked_dates:
        if date_str not in processed_dates:
            logging.info(f"Processing date folder: {date_str}")
            success = run_matlab_function(date_str)

            if success and has_results_for_date(date_str):
                result_count = count_results_for_date(date_str)
                logging.info(f"Found {result_count} result files for {date_str}")

                # Move local folder
                move_folder(LOCAL_TRACKED, LOCAL_PROCESSED, date_str)

                # Move network folder
                move_folder(NETWORK_TRACKED, NETWORK_PROCESSED, date_str)
            else:
                logging.warning(f"No results found for {date_str}, skipping move.")

if __name__ == "__main__":
    logging.info("===== Daily Processing Script Started =====")
    main()
    logging.info("===== Daily Processing Script Finished =====")

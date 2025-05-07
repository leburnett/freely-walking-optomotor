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

LOCAL_RESULTS_ROOT = r"C:\Users\burnettl\Documents\oakey-cokey\results"
NETWORK_RESULTS_ROOT = r"\\prfs\reiserlab\oaky-cokey\exp_results"

LOCAL_FIGS_ROOT = r"C:\Users\burnettl\Documents\oakey-cokey\figures\overview_figs"
NETWORK_FIGS_ROOT = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\exp_figures\overview_figs"

MATLAB_FUNCTION = "process_freely_walking_data"

def list_date_folders(path):
    return [
        name for name in os.listdir(path)
        if os.path.isdir(os.path.join(path, name)) and name.count('_') == 2 and name.startswith("2025_")
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
    dash_date = date_str.replace("_", "-")
    count = 0
    for root, _, files in os.walk(RESULTS_PATH):
        count += sum(1 for f in files if f.startswith(dash_date))
    return count

def copy_results_to_network(local_results_root, network_results_root, date_string_with_dashes):
    """Copy .mat files generated for a given date while preserving folder structure."""
    copied_files = 0
    for dirpath, _, filenames in os.walk(local_results_root):
        for file in filenames:
            if file.endswith(".mat") and date_string_with_dashes in file:
                src_file = os.path.join(dirpath, file)

                # Reconstruct relative path to preserve structure
                rel_path = os.path.relpath(src_file, local_results_root)
                dest_file = os.path.join(network_results_root, rel_path)

                # Ensure destination directory exists
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)

                # Copy file
                shutil.copy2(src_file, dest_file)
                copied_files += 1

    return copied_files

def copy_figs_to_network(local_figs_root, network_figs_root, date_string_with_dashes):
    """Copy figure (pdf or png) files generated for a given date while preserving folder structure."""
    copied_files = 0
    for dirpath, _, filenames in os.walk(local_figs_root):
        for file in filenames:
            if file.endswith((".pdf", ".png")) and date_string_with_dashes in file:
                src_file = os.path.join(dirpath, file)

                # Reconstruct relative path to preserve structure
                rel_path = os.path.relpath(src_file, local_figs_root)
                dest_file = os.path.join(network_figs_root, rel_path)

                # Ensure destination directory exists
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)

                # Copy file
                shutil.copy2(src_file, dest_file)
                copied_files += 1

    return copied_files

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

                # Copy results to exp_results
                dash_date = date_str.replace("_", "-")
                copied_count = copy_results_to_network(LOCAL_RESULTS_ROOT, NETWORK_RESULTS_ROOT, dash_date)
                logging.info(f"Copied {copied_count} .mat files for {dash_date} to exp_results")

                # Copy results to exp_results
                dash_date = date_str.replace("_", "-")
                copied_count = copy_figs_to_network(LOCAL_FIGS_ROOT, NETWORK_FIGS_ROOT, dash_date)
                logging.info(f"Copied {copied_count} .PDF or .PNG files for {dash_date} to exp_figures")

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

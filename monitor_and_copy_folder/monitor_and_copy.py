import os
import shutil
import time
import logging
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Setup logging
LOG_FILE = "monitor_and_copy.log"
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Source and destination paths
SOURCE_ROOT = r"C:\MatlabRoot\FreeWalkOptomotor\data"
DEST_ROOT = r"\\prfs.hhmi.org\reiserlab\oaky-cokey\data\0_unprocessed"
REQUIRED_EXTENSIONS = {'.mat', '.ufmf'}
REQUIRED_PREFIX = 'stamp_log'
CHECK_INTERVAL = 30  # Time (seconds) to wait before checking incomplete folders again

pending_folders = set()

class VideoFolderHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            pending_folders.add(event.src_path)
            # logging.info(f"New folder detected: {event.src_path}")

    def check_pending_folders(self):
        """Checks if pending folders now contain all required files and copies them."""
        to_remove = []
        for folder_path in list(pending_folders):
            if self.is_folder_complete(folder_path):
                self.copy_folder(folder_path)
                to_remove.append(folder_path)
        for folder in to_remove:
            pending_folders.remove(folder)

    def is_folder_complete(self, folder_path):
        """Checks if a folder contains all required files."""
        if not os.path.exists(folder_path):
            return False
        files = os.listdir(folder_path)
        complete = (
            any(f.startswith(REQUIRED_PREFIX) for f in files) and
            any(f.endswith('.mat') for f in files) and
            any(f.endswith('.ufmf') for f in files)
        )
        if complete:
            logging.info(f"Folder complete: {folder_path}")
        return complete

    def copy_folder(self, folder_path):
        """Copies the completed folder to the group drive."""
        relative_path = os.path.relpath(folder_path, SOURCE_ROOT)
        dest_path = os.path.join(DEST_ROOT, relative_path)
        try:
            shutil.copytree(folder_path, dest_path, dirs_exist_ok=True)
            logging.info(f"Copied: {folder_path} -> {dest_path}")
        except Exception as e:
            logging.error(f"Error copying {folder_path} to {dest_path}: {e}")

if __name__ == "__main__":
    logging.info("Starting folder monitoring script...")
    observer = Observer()
    event_handler = VideoFolderHandler()
    observer.schedule(event_handler, path=SOURCE_ROOT, recursive=True)
    observer.start()
    
    try:
        while True:
            event_handler.check_pending_folders()
            time.sleep(CHECK_INTERVAL)
    except KeyboardInterrupt:
        logging.info("Script stopped by user.")
        observer.stop()
    observer.join()

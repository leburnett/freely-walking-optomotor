"""
Shared file operations for the automation pipeline.

Consolidates duplicated file/folder utilities from monitor_and_copy.py,
monitor_and_track.py, daily_processing.py, and reprocessing_script.py.
"""

import logging
import os
import re
import shutil

# Completeness check constants
REQUIRED_EXTENSIONS = {".mat", ".ufmf"}
REQUIRED_PREFIX = "stamp_log"

logger = logging.getLogger(__name__)


def is_folder_complete(folder_path):
    """Check if an experiment folder contains all required files.

    A complete folder has:
    - At least one file starting with 'stamp_log'
    - At least one .mat file
    - At least one .ufmf file

    Args:
        folder_path: Path to the experiment folder.

    Returns:
        True if the folder has all required files.
    """
    try:
        files = os.listdir(folder_path)
        return (
            any(f.startswith(REQUIRED_PREFIX) for f in files)
            and any(f.endswith(".mat") for f in files)
            and any(f.endswith(".ufmf") for f in files)
        )
    except Exception as e:
        logger.warning(f"Error reading {folder_path}: {e}")
        return False


def list_date_folders(path):
    """List all date folders (YYYY_MM_DD format) in the given directory.

    Args:
        path: Directory to scan.

    Returns:
        Sorted list of folder names matching YYYY_MM_DD pattern.
    """
    try:
        return sorted(
            name for name in os.listdir(path)
            if os.path.isdir(os.path.join(path, name))
            and re.match(r"^\d{4}_\d{2}_\d{2}$", name)
        )
    except FileNotFoundError:
        logger.warning(f"Directory not found: {path}")
        return []


def move_folder(src, dst, overwrite=False):
    """Move a folder from src to dst.

    Args:
        src: Source folder path.
        dst: Destination folder path.
        overwrite: If True, delete existing destination before moving.

    Returns:
        True if the move succeeded.
    """
    if not os.path.exists(src):
        logger.warning(f"Source folder not found: {src}")
        return False

    os.makedirs(os.path.dirname(dst), exist_ok=True)

    try:
        if os.path.exists(dst):
            if overwrite:
                shutil.rmtree(dst)
                logger.info(f"Deleted existing destination: {dst}")
            else:
                logger.warning(f"Destination already exists (use overwrite=True): {dst}")
                return False

        shutil.move(src, dst)
        logger.info(f"Moved {src} -> {dst}")
        return True
    except Exception as e:
        logger.error(f"Error moving {src} -> {dst}: {e}")
        return False


def copy_files_by_extension(src_root, dst_root, extensions, filename_filter=None):
    """Copy files matching given extensions from src to dst, preserving structure.

    Args:
        src_root: Source root directory.
        dst_root: Destination root directory.
        extensions: Tuple or set of extensions (e.g., ('.mat',), ('.pdf', '.png')).
        filename_filter: Optional string - only copy files containing this substring.

    Returns:
        Number of files copied.
    """
    if isinstance(extensions, str):
        extensions = (extensions,)
    extensions = tuple(extensions)

    copied = 0
    for dirpath, _, filenames in os.walk(src_root):
        for file in filenames:
            if not file.endswith(extensions):
                continue
            if filename_filter and filename_filter not in file:
                continue

            src_file = os.path.join(dirpath, file)
            rel_path = os.path.relpath(src_file, src_root)
            dst_file = os.path.join(dst_root, rel_path)

            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            shutil.copy2(src_file, dst_file)
            copied += 1

    return copied


def cleanup_empty_parents(path, stop_at):
    """Remove empty parent directories up to (but not including) stop_at.

    Args:
        path: Starting path (will try to remove this and parents).
        stop_at: Stop removing when reaching this directory.
    """
    current = path
    while current != stop_at and os.path.isdir(current):
        try:
            os.rmdir(current)  # Only succeeds if empty
            logger.info(f"Removed empty folder: {current}")
            current = os.path.dirname(current)
        except OSError:
            break


def parse_experiment_path(folder_path, base_path):
    """Parse experiment metadata from the folder path hierarchy.

    Expects: {base}/{date}/{protocol}/{strain}/{sex}/{time}/

    Args:
        folder_path: Full path to the experiment time folder.
        base_path: The base data directory (e.g., DATA_UNPROCESSED).

    Returns:
        Dict with keys: date, protocol, strain, sex, time.
        Returns None if the path doesn't match expected structure.
    """
    try:
        rel = os.path.relpath(folder_path, base_path)
        parts = rel.replace("\\", "/").split("/")
        if len(parts) >= 5:
            return {
                "date": parts[0],
                "protocol": parts[1],
                "strain": parts[2],
                "sex": parts[3],
                "time": parts[4],
            }
    except (ValueError, IndexError):
        pass
    return None

"""
Centralized logging configuration for automation scripts.

Replaces per-script logging.basicConfig() with a shared setup that writes to:
1. A rotating log file in LOG_DIR (max 5MB, 3 backups)
2. Console (stdout) for real-time visibility
"""

import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path


def setup_logging(script_name, log_dir=None, level=logging.INFO):
    """Configure and return a logger for the given script.

    Args:
        script_name: Name used for the log file (e.g., 'monitor_and_copy').
        log_dir: Directory for log files. If None, uses LOG_DIR from config.
        level: Logging level (default: INFO).

    Returns:
        A configured logging.Logger instance.
    """
    if log_dir is None:
        # Import here to avoid circular imports
        try:
            sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
            from config.config import LOG_DIR
            log_dir = str(LOG_DIR)
        except ImportError:
            # Fallback to current directory
            log_dir = "."

    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{script_name}.log")

    # Create logger
    logger = logging.getLogger(script_name)
    logger.setLevel(level)

    # Avoid adding duplicate handlers if called multiple times
    if logger.handlers:
        return logger

    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

    # Rotating file handler: 5MB max, 3 backups
    file_handler = RotatingFileHandler(
        log_file, maxBytes=5 * 1024 * 1024, backupCount=3
    )
    file_handler.setLevel(level)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Console handler for real-time visibility
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    return logger

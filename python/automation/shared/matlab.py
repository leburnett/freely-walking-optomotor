"""
Shared MATLAB subprocess runner for the automation pipeline.

Provides a single function to invoke MATLAB in batch mode, capturing
stdout and stderr for error recording.
"""

import logging
import subprocess
import sys
from pathlib import Path

logger = logging.getLogger(__name__)


def _get_setup_path():
    """Return the path to setup_path.m in the repo root."""
    sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
    from config.config import REPO_ROOT
    return str(REPO_ROOT / "setup_path.m").replace("\\", "/")


def run_matlab(function_name, *args, setup_path=None):
    """Run a MATLAB function via subprocess in batch mode.

    Args:
        function_name: Name of the MATLAB function to call.
        *args: String arguments to pass to the function.
        setup_path: Path to setup_path.m. If None, auto-detected from config.

    Returns:
        Tuple of (success: bool, stdout: str, stderr: str).
    """
    if setup_path is None:
        setup_path = _get_setup_path()

    # Build argument string for MATLAB
    arg_str = ", ".join(f"'{a}'" for a in args)
    matlab_expr = f"restoredefaultpath; run('{setup_path}'); {function_name}({arg_str})"

    cmd = f'matlab -batch "{matlab_expr}"'
    logger.info(f"Running MATLAB: {cmd}")

    try:
        result = subprocess.run(
            cmd,
            shell=True,
            check=True,
            capture_output=True,
            text=True,
        )
        logger.info(f"MATLAB {function_name} completed successfully")
        return True, result.stdout, result.stderr
    except subprocess.CalledProcessError as e:
        logger.error(f"MATLAB {function_name} failed (exit code {e.returncode})")
        if e.stderr:
            logger.error(f"MATLAB stderr: {e.stderr[:500]}")
        return False, e.stdout or "", e.stderr or ""
    except FileNotFoundError:
        msg = "MATLAB not found on PATH. Ensure MATLAB is installed and on the system PATH."
        logger.error(msg)
        return False, "", msg

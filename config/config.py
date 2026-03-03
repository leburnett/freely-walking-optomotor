"""
Project-wide path configuration.

Machine-specific paths are set automatically based on the MACHINE_ROLE
environment variable. Set it once per machine:

    Acquisition machine:  setx MACHINE_ROLE acquisition
    Processing machine:   setx MACHINE_ROLE processing

Then restart your terminal. All other paths are derived automatically.

Usage:
    from config.config import DATA_TRACKED, RESULTS_PATH, NETWORK_TRACKED
"""
import os
from pathlib import Path

# === MACHINE ROLE DETECTION ===
MACHINE_ROLE = os.environ.get("MACHINE_ROLE", "").lower()

if not MACHINE_ROLE:
    raise RuntimeError(
        "MACHINE_ROLE environment variable not set.\n"
        "Run one of the following in an admin terminal, then restart your terminal:\n"
        "  Acquisition machine:  setx MACHINE_ROLE acquisition\n"
        "  Processing machine:   setx MACHINE_ROLE processing"
    )

# === MACHINE-SPECIFIC PATHS ===
if MACHINE_ROLE == "acquisition":
    PROJECT_ROOT = Path(r"C:\Users\labadmin\Documents\freely-walking-optomotor")
    SOURCE_ROOT = Path(r"C:\MatlabRoot\FreeWalkOptomotor\data")
    PYTHON_EXE = Path(r"C:\Users\labadmin\AppData\Local\Programs\Python\Python313\python.exe")

elif MACHINE_ROLE == "processing":
    PROJECT_ROOT = Path(r"C:\Users\labadmin\Documents\freely-walking-optomotor")
    SOURCE_ROOT = None  # Not used on processing machine
    PYTHON_EXE = Path(r"C:\Users\labadmin\AppData\Local\Python\pythoncore-3.14-64\python.exe")

else:
    raise RuntimeError(
        f"Unknown MACHINE_ROLE: '{MACHINE_ROLE}'. "
        "Must be 'acquisition' or 'processing'."
    )

# === DO NOT EDIT BELOW THIS LINE ===

# Repo root (one level up from this file: config/ -> repo root)
REPO_ROOT = Path(__file__).parent.parent

# Local data paths
DATA_UNPROCESSED = PROJECT_ROOT / "DATA" / "00_unprocessed"
DATA_TRACKED     = PROJECT_ROOT / "DATA" / "01_tracked"
DATA_PROCESSED   = PROJECT_ROOT / "DATA" / "02_processed"
RESULTS_PATH     = PROJECT_ROOT / "results"
FIGURES_PATH     = PROJECT_ROOT / "figures"

# Centralized log directory
LOG_DIR = PROJECT_ROOT / "logs"

# Network paths (shared between both machines)
NETWORK_ROOT        = r"\\prfs.hhmi.org\reiserlab\oaky-cokey"
NETWORK_UNPROCESSED = NETWORK_ROOT + r"\data\0_unprocessed"
NETWORK_TRACKED     = NETWORK_ROOT + r"\data\1_tracked"
NETWORK_PROCESSED   = NETWORK_ROOT + r"\data\2_processed"
NETWORK_RESULTS     = NETWORK_ROOT + r"\exp_results"
NETWORK_FIGS        = NETWORK_ROOT + r"\exp_figures\overview_figs"

# Global pipeline status registry (on network drive, shared by both machines)
PIPELINE_REGISTRY = NETWORK_ROOT + r"\pipeline_status.json"

# Repo asset paths
PATTERNS_DIR  = REPO_ROOT / "src" / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = REPO_ROOT / "src" / "protocols"

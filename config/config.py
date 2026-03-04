"""
Project-wide path configuration for the freely-walking-optomotor project.

Machine-specific paths are set automatically based on the MACHINE_ROLE
environment variable. Set it once per machine:

    Acquisition machine:  setx MACHINE_ROLE acquisition
    Processing machine:   setx MACHINE_ROLE processing

Then restart your terminal. All other paths are derived automatically.

Usage:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))  # adjust to repo root
    from config.config import DATA_TRACKED, RESULTS_PATH
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


# ======================================================================
# DERIVED PATHS — DO NOT EDIT BELOW THIS LINE
# ======================================================================

# Repo root (one level up from this file: config/ -> repo root)
REPO_ROOT = Path(__file__).parent.parent


# --- Local data directories (derived from PROJECT_ROOT) ---
#
# PROJECT_ROOT/
#   DATA/
#     00_unprocessed/   <- raw data staged for tracking
#     01_tracked/       <- tracked data awaiting processing
#     02_processed/     <- fully processed data archive
#   results/            <- processing output (.mat result files)
#   figures/            <- generated figures
DATA_UNPROCESSED = PROJECT_ROOT / "DATA" / "00_unprocessed"
DATA_TRACKED     = PROJECT_ROOT / "DATA" / "01_tracked"
DATA_PROCESSED   = PROJECT_ROOT / "DATA" / "02_processed"
RESULTS_PATH     = PROJECT_ROOT / "results"
FIGURES_PATH     = PROJECT_ROOT / "figures"

# Centralized log directory
LOG_DIR = PROJECT_ROOT / "logs"

# Network paths (shared between both machines)
# --- Repo asset paths ---
PATTERNS_DIR  = REPO_ROOT / "src" / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = REPO_ROOT / "src" / "protocols"


# ======================================================================
# NETWORK DRIVE PATHS (processing machine only)
# ======================================================================
# These paths point to the group network drive where data is archived.
# They are only used by the automation scripts on the Windows processing
# machine (monitor_and_track, daily_processing).
#
# Network drive folder structure:
#   \\prfs.hhmi.org\reiserlab\oaky-cokey\
#     data\
#       0_unprocessed/    <- monitor_and_copy deposits here
#       1_tracked/        <- monitor_and_track deposits here
#       2_processed/      <- daily_processing deposits videos here
#     exp_results/        <- daily_processing deposits .mat results
#     exp_figures\
#       overview_figs/    <- daily_processing deposits figures
#
# Note: These use Windows UNC format (\\server\share). The MATLAB
# equivalent (cfg.group_drive) uses SMB format (smb://server/share/data/).
NETWORK_ROOT        = r"\\prfs.hhmi.org\reiserlab\oaky-cokey"
NETWORK_UNPROCESSED = NETWORK_ROOT + r"\data\0_unprocessed"
NETWORK_TRACKED     = NETWORK_ROOT + r"\data\1_tracked"
NETWORK_PROCESSED   = NETWORK_ROOT + r"\data\2_processed"
NETWORK_RESULTS     = NETWORK_ROOT + r"\exp_results"
NETWORK_FIGS        = NETWORK_ROOT + r"\exp_figures\overview_figs"

# Global pipeline status registry (on network drive, shared by both machines)
PIPELINE_REGISTRY = NETWORK_ROOT + r"\pipeline_status.json"

# ======================================================================
# ACQUISITION RIG PATH (rig computer only)
# ======================================================================
# Where BIAS saves raw video on the acquisition rig.
# Only used by monitor_and_copy.py.
# MATLAB equivalent: cfg.rig_data_folder in config/get_config.m
SOURCE_ROOT = r"C:\MatlabRoot\FreeWalkOptomotor\data"

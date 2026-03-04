"""
Project-wide path configuration for the freely-walking-optomotor project.

Machine-specific paths are set automatically based on the MACHINE_ROLE
environment variable. Set it once per machine:

    Acquisition machine:  setx MACHINE_ROLE acquisition
    Processing machine:   setx MACHINE_ROLE processing
    Analysis machine:     setx MACHINE_ROLE analysis
                          setx PROJECT_ROOT C:\\path\\to\\your\\data\\directory  (optional)

Then restart your terminal. All other paths are derived automatically.

The "analysis" role is for any machine (e.g. a personal laptop) where users
run analysis scripts on processed .mat result files, generate plots, or open
the Dash dashboard. Unlike the fixed lab machines, PROJECT_ROOT can vary per
user and is optionally set via the PROJECT_ROOT environment variable.

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
        "  Processing machine:   setx MACHINE_ROLE processing\n"
        "  Analysis machine:     setx MACHINE_ROLE analysis"
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

elif MACHINE_ROLE == "analysis":
    # Analysis machines vary per user. Set PROJECT_ROOT to the directory
    # where local data and results are stored. If not set, defaults to a
    # "freely-walking-optomotor" folder alongside the repo's parent directory.
    _proj = os.environ.get("PROJECT_ROOT", "")
    if _proj:
        PROJECT_ROOT = Path(_proj)
    else:
        # Default: sibling of the repo's parent directory, e.g. if repo is at
        # C:\Users\me\Documents\GitHub\freely-walking-optomotor
        # this becomes C:\Users\me\Documents\freely-walking-optomotor
        PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent / "freely-walking-optomotor"
    SOURCE_ROOT = None  # Not used on analysis machine
    PYTHON_EXE = None   # Use whatever Python is on PATH

else:
    raise RuntimeError(
        f"Unknown MACHINE_ROLE: '{MACHINE_ROLE}'. "
        "Must be 'acquisition', 'processing', or 'analysis'."
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
# NOTE: SOURCE_ROOT is set in the MACHINE_ROLE branch above.
# It is a Path object on the acquisition machine and None elsewhere.

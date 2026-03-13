"""
Project-wide path configuration for the freely-walking-optomotor project.

Machine-specific paths are set automatically based on the MACHINE_ROLE
environment variable. Only the two lab machines need it set explicitly:

    Acquisition machine:  setx MACHINE_ROLE acquisition
    Processing machine:   setx MACHINE_ROLE processing

All other machines (personal laptops, analysis workstations) default to the
"analysis" role automatically — no MACHINE_ROLE setup required.

For analysis machines, edit the PROJECT_ROOT line in this file to point to your
local data directory (same approach as get_config.m). Alternatively, you can
override it with the PROJECT_ROOT environment variable. All other paths are
derived automatically.

Usage:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))  # adjust to repo root
    from config.config import DATA_TRACKED, RESULTS_PATH
"""
import os
import platform as _platform
from pathlib import Path

# === MACHINE ROLE DETECTION ===
# Defaults to "analysis" when MACHINE_ROLE is not explicitly set to
# "acquisition" or "processing". This means personal laptops / analysis
# machines work without any environment variable configuration.
MACHINE_ROLE = os.environ.get("MACHINE_ROLE", "analysis").lower()

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
    # === EDIT THIS LINE FOR YOUR COMPUTER ===
    PROJECT_ROOT = Path('/Users/burnettl/Documents/Projects/oaky_cokey')
    # Windows example:
    # PROJECT_ROOT = Path(r'C:\Users\yourname\Documents\freely-walking-optomotor')

    # Override: the PROJECT_ROOT environment variable takes precedence if set.
    _proj = os.environ.get("PROJECT_ROOT", "")
    if _proj:
        PROJECT_ROOT = Path(_proj)

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
DATA_FAILED      = PROJECT_ROOT / "DATA" / "00_failed"
RESULTS_PATH     = PROJECT_ROOT / "results"
FIGURES_PATH     = PROJECT_ROOT / "figures"

# Centralized log directory
LOG_DIR = PROJECT_ROOT / "logs"

# --- Repo asset paths ---
PATTERNS_DIR  = REPO_ROOT / "src" / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = REPO_ROOT / "src" / "protocols"


# ======================================================================
# NETWORK DRIVE PATHS
# ======================================================================
# These paths point to the group network drive where data is archived.
# Used by automation scripts on the Windows processing machine
# (monitor_and_track, daily_processing) and by the dashboard on any machine.
#
# Network drive folder structure:
#   oaky-cokey/
#     data/
#       0_unprocessed/    <- monitor_and_copy deposits here
#       1_tracked/        <- monitor_and_track deposits here
#       2_processed/      <- daily_processing deposits videos here
#     exp_results/        <- daily_processing deposits .mat results
#     exp_figures/
#       overview_figs/    <- daily_processing deposits figures
#
# On Windows the share is accessed via UNC (\\server\share).
# On macOS/Linux the same share is mounted via Finder/SMB at /Volumes/.
if _platform.system() == "Windows":
    NETWORK_ROOT        = r"\\prfs.hhmi.org\reiserlab\oaky-cokey"
    _sep = "\\"
else:
    # === macOS: EDIT IF YOUR MOUNT POINT DIFFERS ===
    NETWORK_ROOT        = "/Volumes/reiserlab/oaky-cokey"
    _sep = "/"

NETWORK_UNPROCESSED = NETWORK_ROOT + _sep + "data" + _sep + "0_unprocessed"
NETWORK_TRACKED     = NETWORK_ROOT + _sep + "data" + _sep + "1_tracked"
NETWORK_PROCESSED   = NETWORK_ROOT + _sep + "data" + _sep + "2_processed"
NETWORK_RESULTS     = NETWORK_ROOT + _sep + "exp_results"
NETWORK_FIGS        = NETWORK_ROOT + _sep + "exp_figures" + _sep + "overview_figs"

# Global pipeline status registry (on network drive, shared by all machines)
PIPELINE_REGISTRY = NETWORK_ROOT + _sep + "pipeline_status.json"

# ======================================================================
# ACQUISITION RIG PATH (rig computer only)
# ======================================================================
# Where BIAS saves raw video on the acquisition rig.
# Only used by monitor_and_copy.py.
# MATLAB equivalent: cfg.rig_data_folder in config/get_config.m
# NOTE: SOURCE_ROOT is set in the MACHINE_ROLE branch above.
# It is a Path object on the acquisition machine and None elsewhere.

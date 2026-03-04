"""
Project-wide path configuration for the freely-walking-optomotor project.

Edit PROJECT_ROOT for your computer. All other paths are derived from it.

This config is used on three machines:
  1. Acquisition rig (Windows) — uses SOURCE_ROOT only (monitor_and_copy)
  2. Processing machine (Windows) — uses PROJECT_ROOT + local paths + NETWORK_* paths
  3. Analysis computer (Mac/any) — uses PROJECT_ROOT + local paths only

Only PROJECT_ROOT needs to change between machines (2) and (3).
The NETWORK_* paths are only relevant on the processing machine.

See also: config/get_config.m (MATLAB equivalent),
          setup_path.m (adds src/ to MATLAB path)

Usage:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).parent.parent.parent))  # adjust to repo root
    from config.config import DATA_TRACKED, RESULTS_PATH
"""
from pathlib import Path

# ======================================================================
# EDIT THIS FOR YOUR COMPUTER
# ======================================================================
# Set this to the root of your local data folder. The same folder
# structure is used on both the processing machine and analysis
# computers — only the root path differs.
#
# Processing machine (Windows):
#   PROJECT_ROOT = Path(r"C:\Users\burnettl\Documents\oakey-cokey")
#
# Analysis computer (Mac):
PROJECT_ROOT = Path("/Users/burnettl/Documents/Projects/oaky_cokey")


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


# ======================================================================
# ACQUISITION RIG PATH (rig computer only)
# ======================================================================
# Where BIAS saves raw video on the acquisition rig.
# Only used by monitor_and_copy.py.
# MATLAB equivalent: cfg.rig_data_folder in config/get_config.m
SOURCE_ROOT = r"C:\MatlabRoot\FreeWalkOptomotor\data"

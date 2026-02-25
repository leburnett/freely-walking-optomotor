"""
Project-wide path configuration.

Edit PROJECT_ROOT for your computer. All other paths are derived from it.
The network paths (NETWORK_*) are only relevant on the Windows processing machine.

Usage:
    from config.config import DATA_TRACKED, RESULTS_PATH, NETWORK_TRACKED
"""
from pathlib import Path

# === EDIT THIS FOR YOUR COMPUTER ===
PROJECT_ROOT = Path("/Users/burnettl/Documents/Projects/oaky_cokey")
# Windows example:
# PROJECT_ROOT = Path(r"C:\Users\burnettl\Documents\oakey-cokey")

# === DO NOT EDIT BELOW THIS LINE ===

# Repo root (one level up from this file: config/ -> repo root)
REPO_ROOT = Path(__file__).parent.parent

# Local data paths
DATA_UNPROCESSED = PROJECT_ROOT / "DATA" / "00_unprocessed"
DATA_TRACKED     = PROJECT_ROOT / "DATA" / "01_tracked"
DATA_PROCESSED   = PROJECT_ROOT / "DATA" / "02_processed"
RESULTS_PATH     = PROJECT_ROOT / "results"
FIGURES_PATH     = PROJECT_ROOT / "figures"

# Network paths (Windows processing machine only)
NETWORK_ROOT        = r"\\prfs.hhmi.org\reiserlab\oaky-cokey"
NETWORK_UNPROCESSED = NETWORK_ROOT + r"\data\0_unprocessed"
NETWORK_TRACKED     = NETWORK_ROOT + r"\data\1_tracked"
NETWORK_PROCESSED   = NETWORK_ROOT + r"\data\2_processed"
NETWORK_RESULTS     = NETWORK_ROOT + r"\exp_results"
NETWORK_FIGS        = NETWORK_ROOT + r"\exp_figures\overview_figs"

# Acquisition machine source path (used by monitor_and_copy)
SOURCE_ROOT = r"C:\MatlabRoot\FreeWalkOptomotor\data"

# Repo asset paths
PATTERNS_DIR  = REPO_ROOT / "src" / "matlab" / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = REPO_ROOT / "src" / "matlab" / "protocols"

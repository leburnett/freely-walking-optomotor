"""
Configuration for documentation generator paths.
"""
from pathlib import Path

# Base directories
OPTOMOTOR_ROOT = Path(__file__).parent.parent
DOCS_ROOT = Path("/Users/burnettl/Documents/GitHub/reiser-documentation")

# Source directories
PATTERNS_DIR = OPTOMOTOR_ROOT / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = OPTOMOTOR_ROOT / "protocols"

# Output directories in Quarto site
QUARTO_FREELY_WALKING = DOCS_ROOT / "Freely-walking"
QUARTO_ASSETS = DOCS_ROOT / "assets" / "imgs" / "freely" / "patterns"

# Templates
TEMPLATES_DIR = Path(__file__).parent / "templates"

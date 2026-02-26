"""
Configuration for documentation generator paths.
"""
from pathlib import Path

# Repo root: docs_generator/ -> python/ -> src/ -> repo root
OPTOMOTOR_ROOT = Path(__file__).parent.parent.parent.parent
DOCS_ROOT = Path("/Users/burnettl/Documents/GitHub/reiser-documentation")

# Source directories (patterns and protocols are now under src/matlab/)
PATTERNS_DIR = OPTOMOTOR_ROOT / "src" / "matlab" / "patterns" / "Patterns_optomotor"
PROTOCOLS_DIR = OPTOMOTOR_ROOT / "src" / "matlab" / "protocols"

# Output directories in Quarto site
QUARTO_FREELY_WALKING = DOCS_ROOT / "Freely-walking"
QUARTO_ASSETS = DOCS_ROOT / "assets" / "imgs" / "freely" / "patterns"

# Templates
TEMPLATES_DIR = Path(__file__).parent / "templates"

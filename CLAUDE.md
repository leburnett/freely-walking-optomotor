# CLAUDE.md - Context for Claude Code Sessions

This file contains context about the `freely-walking-optomotor` project to help Claude understand the codebase quickly in new sessions.

## Project Overview

This repository contains MATLAB code for running freely-walking optomotor experiments on fruit flies (Drosophila) using a G3 LED arena in the Reiser Lab at HHMI Janelia Research Campus.

### Key Directories

- **`protocols/`** - MATLAB scripts (35 files) that define experimental sessions with timing, stimuli, and data logging
- **`patterns/Patterns_optomotor/`** - MATLAB `.mat` files (63 files) containing LED pattern data for visual stimuli
- **`script_to_make_patterns/`** - MATLAB scripts for generating new pattern files
- **`docs_generator/`** - Python package for generating Quarto documentation pages
- **`python/freely-walking-python/`** - Python environment managed with pixi

### Related Repository

Documentation is published to a separate Quarto website:
- **Location:** `/Users/burnettl/Documents/GitHub/reiser-documentation`
- **Hosted at:** GitHub Pages
- **Structure:** Uses Quarto static site generator with MkDocs Material-like theme

## Pattern File Structure

Pattern files are MATLAB `.mat` files with the following structure:

```matlab
pattern.Pats      % 2D, 3D, or 4D array of LED pixel values
                  % Shapes: (3, 192), (3, 192, x_num), or (3, 192, x_num, y_num)
pattern.x_num     % Number of animation frames (typically 192)
pattern.y_num     % Number of contrast levels (typically 1)
pattern.gs_val    % Greyscale value: 1=binary (2 levels), 2=4-level, 3=8-level, 4=16-level
pattern.num_panels % Number of LED panels (72)
pattern.Panel_map  % Panel arrangement mapping
```

### Arena Geometry

- **Display:** Cylindrical LED arena with 72 panels
- **Resolution:** 3 rows x 192 columns (each panel is 8x8 pixels)
- **Panel arrangement:** `fliplr(flipud(reshape(1:72, 3, 24)))`

### Pattern Types

| Type | Description | Example Patterns |
|------|-------------|------------------|
| Optomotor Grating | Moving vertical stripes | Pattern 04, 06, 09 |
| Flicker | Temporal contrast without motion | Pattern 05, 07, 10 |
| Curtain (ON/OFF) | Progressive edge stimuli | Pattern 19, 20, 51, 52 |
| Reverse Phi | Contrast-reversing motion | Pattern 31-33, 58-62 |
| Bar Fixation | Stationary bars for phototaxis | Pattern 30, 37-46 |
| Background | Uniform patterns for intervals | Pattern 25, 29, 47 |
| Focus of Expansion | Radial expansion patterns | Pattern 34-36 |
| Full Field Flash | Calibration flashes (ON/OFF) | Pattern 48 |

### Special Pattern Notes

- **Pattern 47** (`bkg_0_gsval1_2frames`): Dark background/interval pattern used between stimuli
- **Pattern 48** (`full_flashes_0_1_binary_2frames`): Full field flash for calibration only - NOT an experimental stimulus. The `flash_pattern` variable in protocols references this but it should NOT appear in Pattern Previews.

## Protocol File Structure

Protocol files are MATLAB `.m` scripts with:

```matlab
% Header comments describing the protocol
% Timing parameters
t_acclim_start = 300;  % Acclimation before stimuli (seconds)
t_acclim_end = 30;     % Acclimation after stimuli
t_interval = 20;       % Inter-stimulus interval
t_flash = 5;           % Calibration flash duration
t_pause = 0.01;        % Hardware timing pause

% Pattern assignments
flash_pattern = 48;    % Calibration flash (excluded from docs)
interval_pattern = 47; % Background between stimuli

% Conditions matrix (newer protocols)
all_conditions = [
    pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n;
    9, 47, 127, 1, 15, t_interval, 1;  % 60 deg gratings - 4Hz
    % ... more conditions with inline comments
];
```

### Speed Values

| Speed | Approximate Rate |
|-------|------------------|
| 0 | Static |
| 1 | Minimal (fixation) |
| 8 | ~4 Hz |
| 32 | ~16 Hz |
| 64 | ~32 Hz |
| 127 | Maximum (~63 Hz) |

## Documentation Generator

The `docs_generator/` package converts patterns and protocols into Quarto documentation pages.

### Files

| File | Purpose |
|------|---------|
| `config.py` | Path configuration for both repositories |
| `pattern_visualizer.py` | Converts `.mat` files to PNG frames and animated GIFs |
| `protocol_parser.py` | Extracts metadata from `.m` protocol files |
| `generate_pattern_docs.py` | Main script for generating pattern documentation |
| `generate_protocol_docs.py` | Main script for generating protocol documentation |
| `templates/pattern.qmd.jinja2` | Jinja2 template for pattern pages |
| `templates/protocol.qmd.jinja2` | Jinja2 template for protocol pages |

### Protocol Parser Details

The `protocol_parser.py` extracts:
- **`patterns_used`**: Stimulus patterns only (excludes `flash_pattern`)
- **`interval_pattern`**: The background/interval pattern (separate from stimuli)
- **`conditions`**: Parsed from `all_conditions` matrix with descriptions from inline comments

**Important**: The parser intentionally excludes `flash_pattern` (Pattern 48) because it's only used for calibration flashes at experiment start, not as an experimental stimulus.

### Usage

```bash
cd /Users/burnettl/Documents/GitHub/freely-walking-optomotor

# Generate all pattern documentation (images + .qmd pages)
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_pattern_docs.py

# Generate single pattern
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_pattern_docs.py "Pattern_09_optomotor_16pixel_binary.mat"

# Generate all protocol documentation
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_protocol_docs.py

# Generate single protocol
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_protocol_docs.py "protocol_27.m"
```

### Output Locations

Generated documentation goes to the `reiser-documentation` repository:

- **Pattern images:** `reiser-documentation/assets/imgs/freely/patterns/Pattern_XX_*/`
- **Pattern pages:** `reiser-documentation/Freely-walking/patterns/freely_walking_pattern_XX.qmd`
- **Protocol pages:** `reiser-documentation/Freely-walking/protocols/freely_walking_protocol_XX.qmd`

**Note:** Pattern and protocol `.qmd` files are in subdirectories (`patterns/` and `protocols/`), so relative paths in templates use:
- `../../assets/imgs/...` for images
- `../patterns/freely_walking_pattern_XX.qmd` for pattern links from protocol pages

### Image Generation Details

- Images use **green/black colors** to match the LED arena appearance
- Pattern arrays are scaled 10x vertically and 4x horizontally for visibility
- Animated GIFs sample up to 64 frames at 10fps
- Greyscale values are normalized: max_val = (2^gs_val) - 1

## Python Environment

Managed with pixi (conda-forge based):

```toml
# python/freely-walking-python/pixi.toml
[dependencies]
numpy = ">=2.2.6,<3"
pandas = ">=2.2.3,<3"
scipy = ">=1.15.2,<2"
matplotlib = ">=3.8.0,<4"
pillow = ">=10.0.0,<11"
imageio = ">=2.33.0,<3"
jinja2 = ">=3.1.0,<4"
```

## Quarto Documentation Site

### Directory Structure

```
reiser-documentation/
├── _quarto.yml              # Site configuration
├── Freely-walking/
│   ├── index.qmd
│   ├── freely_walking_protocols_index.qmd   # Protocol overview with links
│   ├── freely_walking_patterns_index.qmd    # Pattern overview with links
│   ├── protocols/                           # Protocol detail pages
│   │   ├── freely_walking_protocol_24.qmd
│   │   ├── freely_walking_protocol_27.qmd
│   │   └── ...
│   └── patterns/                            # Pattern detail pages
│       ├── freely_walking_pattern_01.qmd
│       ├── freely_walking_pattern_09.qmd
│       └── ...
└── assets/imgs/freely/patterns/             # Pattern images
```

### Preview Locally

```bash
cd /Users/burnettl/Documents/GitHub/reiser-documentation
quarto preview --port 4321
```

### Navigation Structure

The sidebar navigation (`_quarto.yml`) shows only index pages:
- **Protocols section**: Links to `freely_walking_protocols_index.qmd`
- **Patterns section**: Links to `freely_walking_patterns_index.qmd`

Individual protocol/pattern pages are accessed by clicking links in the overview tables on index pages, NOT from the sidebar.

### Protocol Page Format

Protocol pages follow this structure (see `freely_walking_protocol_24.qmd` as reference):

```markdown
---
title: "protocol_24"
---

Description text...

## Protocol Parameters

| Parameter | Value |
|:----------|:------|
| Conditions | 10 |
| Patterns Used | 9 |
| t_acclim_start | 300s |
...

## Conditions

| # | Pattern | Speed | Duration | Description |
|--:|:--------|------:|---------:|:------------|
| 1 | [Pattern 9](../patterns/freely_walking_pattern_09.qmd) | 127 | 15s | 60 deg gratings |
| 2 | [Pattern 27](../patterns/freely_walking_pattern_27.qmd) | 127 | 15s | 60 deg gratings |
...
| Interval | [Pattern 47](../patterns/freely_walking_pattern_47.qmd) | N/A | 20s | Dark interval pattern |

## Pattern Previews

#### [Pattern 9](../patterns/freely_walking_pattern_09.qmd)

::: {.content-visible when-format="html"}
![](../../assets/imgs/freely/patterns/Pattern_09.../animation.gif){.ifr}
:::

::: {.content-visible when-format="pdf"}
![](../../assets/imgs/freely/patterns/Pattern_09.../frame_0000.png){.ifr}
:::
```

**Important formatting rules:**
- Conditions table rows must be consecutive with NO blank lines between rows
- Pattern preview headers use `####` (h4) with clickable links
- Images have no alt text: `![]()` not `![Pattern 9]()`
- No separate "View full pattern details" links
- Interval pattern included in Conditions table as last row

### Jinja2 Template Notes

The `protocol.qmd.jinja2` template uses whitespace control (`-`) to avoid blank lines in tables:

```jinja2
{% for cond in protocol.conditions -%}
| {{ cond.condition_n }} | ...
{% endfor -%}
```

Without the `-`, Jinja2 adds newlines that break Markdown table rendering.

## Common Issues & Solutions

### Pattern Array Dimensions

Pattern `.mat` files can have different array shapes:
- **2D (3, 192):** Single frame pattern - handled by adding dimensions
- **3D (3, 192, x_num):** Multi-frame, single contrast level
- **4D (3, 192, x_num, y_num):** Multi-frame, multiple contrast levels

The `pattern_visualizer.py` handles all cases by normalizing to 4D.

### Protocol Parsing

Older protocols use direct variable assignments:
```matlab
optomotor_pattern = 6;
flicker_pattern = 7;
```

Newer protocols use the `all_conditions` matrix format. The parser handles both.

### PDF/HTML Dual Format Rendering

The Quarto site generates both HTML and PDF output. Since LaTeX cannot render `.gif` files, the templates use conditional content blocks:

```markdown
::: {.content-visible when-format="html"}
![](path/to/animation.gif)
:::

::: {.content-visible when-format="pdf"}
![](path/to/frame_0000.png)
:::
```

### Quarto Generated Files

These files are generated during rendering and should be ignored:

1. **LaTeX intermediate files** (`.tex`, `.toc`, `.log`, `.aux`, `.out`, `.fls`, `.fdb_latexmk`, `.synctex.gz`)
2. **Mediabag directories** (`*_files/mediabag/`) - Created during PDF rendering

All are in `.gitignore`. To clean up manually:
```bash
cd reiser-documentation/Freely-walking
rm -rf *_files/
rm -f *.tex *.toc *.log *.aux *.out *.fls *.fdb_latexmk *.synctex.gz
```

### Table Formatting Issues

If Markdown tables don't render properly, check for:
1. **Blank lines between rows** - Tables must have consecutive rows
2. **Missing header separator** - Need `|---|---|` line after header
3. **Inconsistent column counts** - All rows must have same number of `|` separators

## File Naming Conventions

- **Patterns:** `Pattern_XX_descriptive_name.mat` (XX = zero-padded number)
- **Protocols:** `protocol_XX.m` or `Protocol_vX.m`
- **Generated pattern pages:** `freely_walking_pattern_XX.qmd` (in `patterns/` subdirectory)
- **Generated protocol pages:** `freely_walking_protocol_XX.qmd` (in `protocols/` subdirectory)
- **Pattern images:** `Pattern_XX_name/animation.gif`, `Pattern_XX_name/frame_XXXX.png`

## Adding New Content

### New Pattern

1. Create `.mat` file in `patterns/Patterns_optomotor/`
2. Run `generate_pattern_docs.py` with the new file
3. Page auto-appears via link in patterns index table

### New Protocol

1. Create `.m` file in `protocols/`
2. Run `generate_protocol_docs.py` with the new file
3. Add entry to the Protocol Overview table in `freely_walking_protocols_index.qmd`

**Note:** Individual pages are NOT added to `_quarto.yml` sidebar - they're accessed via the index tables.

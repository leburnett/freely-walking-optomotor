# CLAUDE.md - Context for Claude Code Sessions

This file contains context about the `freely-walking-optomotor` project to help Claude understand the codebase quickly in new sessions.

## Project Overview

This repository contains MATLAB code for running freely-walking optomotor experiments on fruit flies (Drosophila) using a G3 LED arena in the Reiser Lab at HHMI Janelia Research Campus.

### Key Directories

```
freely-walking-optomotor/
├── config/                          # Path config — edit paths here
│   ├── get_config.m                 # MATLAB: cfg = get_config()
│   └── config.py                    # Python: from config.config import ...
├── setup_path.m                     # Run once per MATLAB session
├── src/                             # MATLAB source code
│   ├── processing/                  # process_freely_walking_data.m (KEY entry point)
│   │   └── functions/               # 39+ processing helpers
│   ├── plotting/                    # make_overview.m, plot_line_*.m, etc.
│   │   └── functions/               # 76+ plotting helpers
│   ├── analysis/                    # 22 ad-hoc analysis scripts
│   ├── tracking/                    # batch_track_ufmf.m, calibration.mat
│   ├── patterns/
│   │   ├── Patterns_optomotor/      # 63 .mat LED pattern files
│   │   └── make_patterns/           # scripts to generate new patterns
│   ├── protocols/                   # 49 experimental protocol scripts
│   ├── model/                       # 4 behavioral model scripts
│   ├── shared/                      # external_functions/ (viridis, fdr_bh, etc.)
│   └── data_review/                 # Data review notebooks
├── python/
│   ├── freely-walking-python/       # pixi env — DO NOT MOVE
│   │   ├── pixi.toml
│   │   ├── dashboard/              # Dash web dashboard
│   │   └── docs_generator/         # Quarto documentation generator
│   └── automation/
│       ├── daily_processing/        # daily_processing.py, reprocessing_script.py
│       ├── monitor_and_track/       # monitor_and_track.py
│       └── monitor_and_copy/        # monitor_and_copy.py
└── docs/
    └── training_guide/              # example figure generation scripts
```

- **`config/get_config.m`** — single edit point for all MATLAB path configuration
- **`config/config.py`** — single edit point for all Python path configuration
- **`setup_path.m`** — run from MATLAB once per session (or add to `startup.m`)
- **`python/freely-walking-python/`** — Python environment managed with pixi (do not move)

### Related Repository

Documentation is published to a separate Quarto website:
- **Location:** `/Users/burnettl/Documents/GitHub/reiser-documentation`
- **Hosted at:** GitHub Pages
- **Structure:** Uses Quarto static site generator with MkDocs Material-like theme

## Path Configuration

All paths are centralised in two config files (one per language). Each has a single editable field (`project_root` / `PROJECT_ROOT`) that you set per computer.

Three computers are involved:

| Computer | `MACHINE_ROLE` | Role | Editable field |
|----------|---------------|------|----------------|
| Acquisition rig (Windows) | `acquisition` | Runs protocols, records video | N/A (uses fixed rig paths) |
| Processing machine (Windows) | `processing` | Automated tracking & processing | `project_root` / `PROJECT_ROOT` |
| Analysis computer (Mac/any) | `analysis` | Analysis, plotting, dashboard | `project_root` / `PROJECT_ROOT` (env var) |

### MATLAB — `config/get_config.m`

Edit `cfg.project_root`. All other fields are derived or fixed:

```matlab
cfg = get_config();
% --- Editable ---
% cfg.project_root      — local data root (edit per computer)
%
% --- Derived from project_root ---
% cfg.data_unprocessed  — DATA/00_unprocessed/
% cfg.data_tracked      — DATA/01_tracked/
% cfg.data_processed    — DATA/02_processed/
% cfg.results           — results/
% cfg.figures           — figures/
%
% --- Derived from repo_root ---
% cfg.repo_root         — auto-detected git repo root
% cfg.patterns          — Patterns_optomotor/ directory
% cfg.calibration_file  — tracking calibration .mat
%
% --- Rig-only (fixed Windows paths) ---
% cfg.rig_data_folder   — BIAS raw data on the rig
% cfg.bias_config       — BIAS camera config on the rig
%
% --- Network drive ---
% cfg.group_drive       — SMB path to group network drive
```

Run `setup_path.m` once per MATLAB session (or add to `startup.m`) to add all `src/` subdirectories to the MATLAB path.

### Python — `config/config.py`

Only the two lab machines need `MACHINE_ROLE` set explicitly:
```
setx MACHINE_ROLE acquisition   # Acquisition rig
setx MACHINE_ROLE processing    # Processing machine
```

All other machines (personal laptops, analysis workstations) default to `analysis` automatically — no environment variable needed.

For **analysis** machines, edit the `PROJECT_ROOT` line directly in `config/config.py`:
```python
PROJECT_ROOT = Path('/path/to/your/data/root')
```

This can optionally be overridden via the `PROJECT_ROOT` environment variable.

Import in scripts:
```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))  # adjust depth to repo root
from config.config import DATA_TRACKED, RESULTS_PATH, NETWORK_TRACKED, REPO_ROOT
```

Key variable groups:
- **Local paths** (`DATA_UNPROCESSED`, `DATA_TRACKED`, `DATA_PROCESSED`, `RESULTS_PATH`, `FIGURES_PATH`) — derived from `PROJECT_ROOT`
- **Network paths** (`NETWORK_ROOT`, `NETWORK_UNPROCESSED`, `NETWORK_TRACKED`, `NETWORK_PROCESSED`, `NETWORK_RESULTS`, `NETWORK_FIGS`) — OS-aware: Windows UNC on Windows, `/Volumes/` mount on macOS
- **Rig path** (`SOURCE_ROOT`) — acquisition rig only, used by `monitor_and_copy`; `None` on processing and analysis machines
- **Repo paths** (`REPO_ROOT`, `PATTERNS_DIR`, `PROTOCOLS_DIR`) — auto-detected
- **`PYTHON_EXE`** — fixed paths on acquisition/processing; `None` on analysis (uses PATH)

### Dashboard

The interactive Dash dashboard visualises processed experimental data.

**Quick start (from anywhere in the terminal):**
```bash
dash-freely              # start the dashboard (opens http://localhost:8050)
dash-freely preprocess   # preprocess .mat files → Parquet first
```

`dash-freely` is a shell alias for `dashboard.sh` at the repo root. Set it up with:
```bash
# Add to ~/.zshrc or ~/.bashrc:
alias dash-freely='~/Documents/GitHub/freely-walking-optomotor/dashboard.sh'
```

**Or run directly with pixi:**
```bash
cd python/freely-walking-python
pixi run preprocess    # preprocesses .mat → Parquet
pixi run dashboard     # starts Dash app on http://localhost:8050
```

### Pipeline Status Page

The automation scripts on the processing machine generate a standalone HTML status page
(`pipeline_status.html`) alongside the JSON registry on the network drive. This page is
auto-regenerated whenever the automation pipeline updates an experiment's status.

**To view the pipeline status page (macOS):**
```bash
open /Volumes/reiserlab/oaky-cokey/pipeline_status.html
```

The HTML page includes sortable/filterable tables with colour-coded pipeline stages,
split into production experiments (≥ Sep 25, 2024) and testing-phase experiments
(collapsed by default). It is generated by `generate_status_page()` in
`python/automation/shared/registry.py`.

---

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

The `python/freely-walking-python/docs_generator/` package converts patterns and protocols into Quarto documentation pages.

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
cd python/freely-walking-python

# Generate all pattern documentation (images + .qmd pages)
pixi run gen-pattern-docs

# Generate all protocol documentation
pixi run gen-protocol-docs
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

## Historical Data Phases

### Production Cutover: September 25, 2024

On September 25, 2024, the folder naming convention changed to include structured
metadata (date/protocol/strain/sex/time hierarchy). Experiments before this date
are testing-phase (~266 experiments, June–Sep 2024) with flat date/time/ folders
and expected "unknown" metadata. The cutover constant is defined in
`python/automation/shared/registry.py` as `PRODUCTION_CUTOVER_DATE = "2024_09_25"`.

The HTML status page splits experiments into two tables based on this date:
- **Production Experiments** (≥ Sep 25, 2024): Full metadata expected. An orange ⚠
  warning indicator flags experiments with missing metadata or missing LOG .mat files.
- **Testing Phase Experiments** (< Sep 25, 2024): Collapsed by default. "Unknown"
  metadata is expected and normal for these experiments.

Charts (by Protocol, by Strain, Timeline) show production data only.

## Plotting Conventions (MATLAB)

All MATLAB figures should follow these aesthetic defaults unless explicitly told otherwise:

### Axes
- **`box off`** — always. No bounding box around plots.
- **Tick direction:** `set(gca, 'TickDir', 'out')` — ticks face outward.
- **Axis line width:** `set(gca, 'LineWidth', 1.2)` — thicker axis lines for clarity.
- **Font size:** 12 pt for tick labels (`set(gca, 'FontSize', 12)`), 14 pt for axis labels (`xlabel`/`ylabel`), 16 pt for panel titles (`title`), 18 pt for figure super-titles (`sgtitle`).

### Lines
- **Solid lines by default** (`'-'`). Do not use dashed (`'--'`) or dotted (`':'`, `'-.'`) line styles unless explicitly requested.
- **Reference/threshold lines:** Use solid light grey lines (`[0.7 0.7 0.7]`) instead of dashed black. For example:
  ```matlab
  xline(threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
  ```
- Only use dashed or dotted lines when the user specifically asks for them.

### Colors
- Use the default MATLAB colororder for data series.
- Reference/threshold/guide lines should be **light grey** (`[0.7 0.7 0.7]`), not black.

### Standard boilerplate for new figures
After creating axes or subplots, apply:
```matlab
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
```

### Example
```matlab
figure('Position', [50 50 800 600]);
plot(x, y, '-', 'LineWidth', 1.5);
hold on;
xline(threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Time (s)', 'FontSize', 14);
ylabel('Velocity (mm/s)', 'FontSize', 14);
title('Forward Velocity', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
```

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

1. Create `.mat` file in `src/patterns/Patterns_optomotor/`
2. Run `generate_pattern_docs.py` with the new file
3. Page auto-appears via link in patterns index table

### New Protocol

1. Create `.m` file in `src/protocols/`
2. Run `generate_protocol_docs.py` with the new file
3. Add entry to the Protocol Overview table in `freely_walking_protocols_index.qmd`

**Note:** Individual pages are NOT added to `_quarto.yml` sidebar - they're accessed via the index tables.

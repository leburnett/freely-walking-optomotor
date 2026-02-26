# Freely Walking Optomotor

Code to run and analyze freely-walking optomotor behavior experiments in the cylindrical G3 LED arena. Developed for the Reiser Lab at HHMI Janelia Research Campus.

First developed for and with Hannah-Marie Santos, summer 2024 and later used for the freely-walking optomotor "oaky-cokey" screen with Aparna Dev, autumn 2024 - summer 2025. Grace Biondi joined the team in summer 2025 and led the eye painting experiments.

## Repository Structure

```
freely-walking-optomotor/
│
├── config/                          # Centralized path configuration
│   ├── get_config.m                 # MATLAB: cfg = get_config()
│   └── config.py                    # Python: from config.config import ...
│
├── setup_path.m                     # Run once per MATLAB session to add src/matlab/ to path
│
├── src/
│   ├── matlab/
│   │   ├── processing/              # Data processing pipeline
│   │   │   ├── process_freely_walking_data.m   # Main entry point
│   │   │   └── functions/           # Processing helper functions
│   │   │
│   │   ├── plotting/                # Visualization tools
│   │   │   ├── make_overview.m      # Overview/summary plots
│   │   │   ├── plot_line_*.m        # Line plots
│   │   │   └── functions/           # Plotting helper functions
│   │   │
│   │   ├── analysis/                # Ad-hoc analysis scripts
│   │   │
│   │   ├── tracking/                # FlyTracker integration
│   │   │   ├── batch_track_ufmf.m   # Batch tracking script
│   │   │   └── calibration.mat      # Tracking calibration data
│   │   │
│   │   ├── patterns/
│   │   │   ├── Patterns_optomotor/  # LED pattern files (.mat)
│   │   │   └── make_patterns/       # Scripts to generate new patterns
│   │   │
│   │   ├── protocols/               # Experimental protocol scripts (.m)
│   │   │
│   │   ├── model/                   # Behavioral model scripts
│   │   │
│   │   └── shared/                  # External functions (viridis, fdr_bh, etc.)
│   │
│   ├── python/
│   │   ├── dashboard/               # Dash web dashboard
│   │   └── docs_generator/          # Quarto documentation generator
│   │
│   └── automation/
│       ├── daily_processing/        # Automated daily data processing
│       ├── monitor_and_track/       # FlyTracker monitoring service
│       └── monitor_and_copy/        # File transfer monitoring service
│
├── python/
│   └── freely-walking-python/       # pixi environment (DO NOT MOVE)
│       └── pixi.toml
│
├── docs/
│   └── training_guide/              # Example figure generation scripts
│
├── data_review/                     # Data review notebooks
│
└── CLAUDE.md                        # Context for Claude Code sessions
```

## Setup

### MATLAB

1. Edit `config/get_config.m` — set `cfg.project_root` to your data root directory
2. Run `setup_path.m` once per MATLAB session (or add to `startup.m`)

```matlab
% setup_path.m adds all src/matlab/ subdirectories to the MATLAB path
setup_path

% All scripts then use:
cfg = get_config();
% cfg.project_root, cfg.data_tracked, cfg.data_processed, cfg.results, etc.
```

### Python

1. Edit `config/config.py` — set `PROJECT_ROOT` to your data root directory
2. Install the pixi environment:

```bash
cd python/freely-walking-python
pixi install
```

## Workflow

### 1. Pattern Creation
Generate LED pattern files for visual stimuli:
```matlab
% Pattern scripts are in src/matlab/patterns/make_patterns/
% Generated .mat files go to src/matlab/patterns/Patterns_optomotor/
```

### 2. Protocol Design
Define experimental protocols in `src/matlab/protocols/`:
- Timing parameters (acclimation, trial duration, intervals)
- Pattern assignments for each condition
- Condition matrix with stimulus parameters

### 3. Run Experiments
Experiments are run using the G3 arena control system. Raw video is recorded and tracked using FlyTracker.

### 4. Automatic Processing (Janelia setup)
Data is automatically processed via scripts in `src/automation/`:
- `monitor_and_copy/` - transfers files from acquisition machine to network
- `monitor_and_track/` - runs FlyTracker on new data
- `daily_processing/` - runs the processing pipeline on new data

### 5. Data Processing
Process tracked data to extract behavioral metrics:
```matlab
% Process all experiments from a single day
process_freely_walking_data("2024_09_24")
```

**Key processing steps:**
1. Load FlyTracker output (trx, feat)
2. Remove flies with bad tracking
3. Compute behavioral metrics:
   - Forward velocity (fv_data)
   - Angular velocity (av_data)
   - Turning rate/curvature (curv_data)
   - Distance from center (dist_data)
   - Viewing distance (view_dist)
   - Inter-fly distance (IFD_data)
4. Parse data by condition using LOG timing
5. Save processed data as `*_data.mat`

### 6. Combine Data Across Experiments
Create the `DATA` struct combining all experiments:
```matlab
cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');
DATA = comb_data_across_cohorts_cond(protocol_dir);
```

**DATA struct organization:**
```
DATA.(strain).(sex)(cohort_idx).(condition).(data_type)
```

### 7. Analysis
Run analysis scripts from `src/matlab/analysis/`:
```matlab
% Speed tuning analysis (Protocol 31)
p31_different_speeds_analysis

% Contrast tuning analysis (Protocol 30)
p30_different_contrasts_analysis

% Phototaxis analysis
analyse_phototaxis_polar
```

### 8. Generate Documentation
Generate Quarto documentation pages for the companion documentation site:
```bash
cd /path/to/freely-walking-optomotor

# Generate all pattern documentation
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python src/python/docs_generator/generate_pattern_docs.py

# Generate a single pattern
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python src/python/docs_generator/generate_pattern_docs.py "Pattern_09_optomotor_16pixel_binary.mat"

# Generate all protocol documentation
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python src/python/docs_generator/generate_protocol_docs.py

# Generate a single protocol
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python src/python/docs_generator/generate_protocol_docs.py "protocol_27.m"
```

Or using pixi tasks:
```bash
cd python/freely-walking-python
pixi run gen-pattern-docs
pixi run gen-protocol-docs
```

### 9. Dashboard
```bash
cd python/freely-walking-python
pixi run preprocess    # Preprocess .mat files to Parquet
pixi run dashboard     # Start the Dash web dashboard
```

## Key Data Types

| Data Type | Description | Units |
|-----------|-------------|-------|
| `fv_data` | Forward velocity (in heading direction) | mm/s |
| `av_data` | Angular velocity | deg/s |
| `curv_data` | Turning rate (av/fv) | deg/mm |
| `dist_data` | Distance from arena center | mm |
| `dist_data_delta` | Change in distance from stimulus onset | mm |
| `view_dist` | Distance to wall in heading direction | mm |
| `IFD_data` | Inter-fly distance | mm |
| `x_data`, `y_data` | Position coordinates | mm |
| `heading_wrap` | Heading angle (wrapped) | deg |

## Arena Parameters

- **Display:** Cylindrical LED arena with 72 panels
- **Resolution:** 3 rows x 192 columns
- **Arena radius:** ~119 mm
- **Frame rate:** 30 fps
- **Pixels per mm:** 4.1691

## Dependencies

### MATLAB
- Statistics and Machine Learning Toolbox
- Image Processing Toolbox
- Circular Statistics Toolbox (for phototaxis analysis)

### Python (managed with pixi)
- numpy, pandas, scipy
- matplotlib, pillow, imageio
- jinja2, dash, plotly

## Protocol Naming Convention

| Protocol | Description |
|----------|-------------|
| protocol_10 | Basic optomotor (12 conditions) |
| protocol_24-27 | Screen protocols |
| protocol_30 | Different contrasts |
| protocol_31 | Different speeds |
| protocol_33-34 | Eye-painted experiments |
| protocol_35-36 | Shifted center of rotation |

## File Naming Conventions

- **Patterns:** `Pattern_XX_descriptive_name.mat`
- **Protocols:** `protocol_XX.m`
- **Results:** `{date}_{time}_{strain}_{protocol}_{sex}_data.mat`

## Contact

Developed by Laura Burnett and Aparna Dev for the Reiser Lab, HHMI Janelia Research Campus.

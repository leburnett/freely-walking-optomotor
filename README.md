# Freely Walking Optomotor

Code to run and analyze freely-walking optomotor behavior experiments in the cylindrical G3 LED arena. Developed for the Reiser Lab at HHMI Janelia Research Campus.

First developed for HMS, summer 2024 and later used for the oaky-cokey screen with AD, autumn 2024 - summer 2025.

## Repository Structure

```
freely-walking-optomotor/
│
├── protocols/                    # MATLAB scripts defining experimental sessions
│   └── *.m                       # Protocol files (timing, stimuli, data logging)
│
├── patterns/
│   └── Patterns_optomotor/       # LED pattern files (.mat) for visual stimuli
│
├── script_to_make_patterns/      # Scripts for generating new pattern files
│   ├── pattern_tools/            # Utility functions for pattern creation
│   └── *.m                       # Pattern generation scripts
│
├── processing_functions/         # Data processing pipeline
│   ├── process_freely_walking_data.m   # Main entry point for processing
│   ├── process_data_features.m         # Process individual experiments
│   └── functions/                # Helper functions
│       ├── combine_data_one_cohort.m   # Combine metrics for one cohort
│       ├── comb_data_across_cohorts_cond.m  # Combine across experiments
│       ├── calculate_viewing_distance.m
│       ├── calculate_three_point_velocity.m
│       ├── gaussian_conv.m
│       ├── bin_data.m
│       └── ...
│
├── plotting_functions/           # Visualization tools
│   ├── plot_overview_*.m         # Overview/summary plots
│   └── functions/                # Helper functions
│       ├── plot_trajectory.m
│       ├── make_scatter_bar.m
│       ├── plot_boxchart_metrics_xcond.m
│       └── ...
│
├── analysis_scripts/             # Analysis workflows
│   ├── p31_different_speeds_analysis.m
│   ├── p30_different_contrasts_analysis.m
│   ├── analyse_phototaxis_polar.m
│   ├── convex_hull_analysis.m
│   ├── positional_effects_on_behaviour.m
│   └── ...
│
├── docs_generator/               # Documentation generation (Python)
│   ├── config.py
│   ├── pattern_visualizer.py
│   ├── protocol_parser.py
│   ├── generate_pattern_docs.py
│   ├── generate_protocol_docs.py
│   └── templates/
│
├── python/
│   └── freely-walking-python/    # Python environment (pixi-managed)
│
└── CLAUDE.md                     # Context for Claude Code sessions
```

## Workflow

### 1. Pattern Creation
Generate LED pattern files for visual stimuli:
```matlab
cd script_to_make_patterns
% Run pattern generation scripts (e.g., make_reverse_phi_4bit.m)
```

### 2. Protocol Design
Define experimental protocols in `protocols/`:
- Timing parameters (acclimation, trial duration, intervals)
- Pattern assignments for each condition
- Condition matrix with stimulus parameters

### 3. Run Experiments
Experiments are run using the G3 arena control system. Raw video is recorded and tracked using FlyTracker.

### 4. Automatic Processing (Janelia setup)
Data is automatically processed via:
- `monitor_and_copy` - transfers files
- `monitor_and_track` - runs FlyTracker
- `daily_processing` - initial processing

### 5. Data Processing
Process tracked data to extract behavioral metrics:
```matlab
% Process all experiments from a single day
process_freely_walking_data("2024_09_24")

% Or process individually
process_data_features(PROJECT_ROOT, path_to_folder, save_folder, date_str, false)
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
protocol_dir = '/path/to/results/protocol_27';
DATA = comb_data_across_cohorts_cond(protocol_dir);
```

**DATA struct organization:**
```
DATA.(strain).(sex)(cohort_idx).(condition).(data_type)
```

### 7. Analysis
Run analysis scripts from `analysis_scripts/`:
```matlab
% Speed tuning analysis (Protocol 31)
p31_different_speeds_analysis

% Contrast tuning analysis (Protocol 30)
p30_different_contrasts_analysis

% Phototaxis analysis
analyse_phototaxis_polar

% Compare conditions across groups
plot_compare_conditions_per_group
```

### 8. Generate Documentation
Generate Quarto documentation pages:
```bash
cd /path/to/freely-walking-optomotor

# Generate pattern documentation
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_pattern_docs.py

# Generate protocol documentation
pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
    python docs_generator/generate_protocol_docs.py
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
- **Resolution:** 3 rows × 192 columns
- **Arena radius:** ~119 mm
- **Frame rate:** 30 fps
- **Pixels per mm:** 4.1691

## Dependencies

### MATLAB
- Statistics and Machine Learning Toolbox
- Image Processing Toolbox
- Circular Statistics Toolbox (for phototaxis analysis)

### Python (for documentation)
Managed with pixi:
- numpy, pandas, scipy
- matplotlib, pillow, imageio
- jinja2

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

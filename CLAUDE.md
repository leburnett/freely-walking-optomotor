# CLAUDE.md - Freely Walking Optomotor Pipeline Documentation

This document contains comprehensive information about the freely-walking optomotor behavioral data processing pipeline. It serves as a reference for understanding, modifying, and extending the codebase.

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Data Pipeline Architecture](#3-data-pipeline-architecture)
4. [Core Processing Functions](#4-core-processing-functions)
5. [Data Structures](#5-data-structures)
6. [Pattern Metadata System](#6-pattern-metadata-system)
7. [Protocol Configuration](#7-protocol-configuration)
8. [Python Package](#8-python-package)
9. [File Naming Conventions](#9-file-naming-conventions)
10. [Arena & Acquisition Constants](#10-arena--acquisition-constants)
11. [Behavioral Metrics](#11-behavioral-metrics)
12. [LOG Structure](#12-log-structure)
13. [Daily Processing Automation](#13-daily-processing-automation)
14. [Extensibility Guide](#14-extensibility-guide)
15. [Common Workflows](#15-common-workflows)
16. [Troubleshooting](#16-troubleshooting)

---

## 1. Project Overview

**Purpose**: Process and analyze freely-walking optomotor behavioral data from *Drosophila* experiments in the G3 LED arena.

**Timeline**:
- Summer 2024: Original development for HMS
- Autumn 2024 - Summer 2025: Extended for oaky-cokey screen experiments

**Core Technologies**:
- MATLAB: Data processing and analysis
- Python: Analysis utilities and automation
- FlyTracker: Video tracking

**Key Capabilities**:
- Process raw FlyTracker output into structured behavioral data
- Extract 13 behavioral metrics per fly per frame
- Organize data by protocol, strain, sex, and condition
- Auto-extract stimulus properties from pattern filenames
- Support multiple protocols with configurable parameters

---

## 2. Repository Structure

```
freely-walking-optomotor/
├── protocols/                    # Experimental protocol definitions
│   ├── protocol_27.m            # Main screen protocol
│   ├── protocol_31.m            # Speed tuning
│   └── protocol_functions/      # Shared protocol utilities
│
├── processing_functions/         # Data processing pipeline
│   ├── process_freely_walking_data.m    # Main entry point
│   ├── process_screen_data.m            # Batch processing
│   ├── README_DATA_PARSING.md           # Detailed documentation
│   ├── config/
│   │   └── get_protocol_config.m        # Protocol configurations
│   ├── functions/                       # Core processing (21 files)
│   │   ├── process_data_features.m
│   │   ├── combine_data_one_cohort.m
│   │   ├── comb_data_across_cohorts_cond_v2.m
│   │   ├── parse_pattern_metadata.m
│   │   └── ... (velocity, distance calculations)
│   └── fix_data_errors/                 # Data correction utilities
│
├── patterns/                     # Visual stimulus patterns
│   ├── Patterns_optomotor/      # Main pattern files (63 patterns)
│   │   └── PATTERN_LUT.mat      # Generated metadata lookup
│   └── Patterns_optomotor_offset/
│
├── tracking/                     # FlyTracker integration
│   ├── batch_track_ufmf.m
│   └── calibration.mat
│
├── daily_processing/             # Automation scripts
│   └── daily_processing.py
│
├── python/                       # Python analysis package
│   └── optomotor_data/
│       ├── io/mat_loader.py
│       ├── core/experiment.py
│       ├── analysis/slicing.py
│       └── config/protocol_config.py
│
├── monitor_and_copy_folder/      # File monitoring utilities
├── monitor_and_track_folder/     # Tracking automation
│
└── .archive/                     # Legacy/non-essential code
    ├── plotting_functions/       # 83 visualization functions
    ├── analysis_tests/
    ├── model/
    ├── misc/
    └── processing_functions/     # Analysis-only functions
```

---

## 3. Data Pipeline Architecture

### 3.1 Data Flow

```
Raw FlyTracker Output (.mat files: feat, trx)
    │
    ▼
process_data_features.m
    ├── Loads LOG (experiment timing/parameters)
    ├── Loads feat (13 features per fly) and trx (trajectories)
    ├── Calls combine_data_one_cohort()
    │   ├── Validates tracking quality
    │   ├── Interpolates missing data
    │   ├── Smooths position data (Gaussian)
    │   ├── Calculates 13 behavioral metrics
    │   └── Returns comb_data struct
    └── Saves *_data.mat files
    │
    ▼
comb_data_across_cohorts_cond_v2.m
    ├── Discovers all experiment files
    ├── Builds/loads pattern lookup table
    ├── Organizes by strain/sex/condition
    ├── Adds phase markers for trial segmentation
    ├── Links pattern metadata
    └── Returns hierarchical DATA struct
    │
    ▼
Analysis (MATLAB or Python)
```

### 3.2 Processing Stages

| Stage | Input | Output | Function |
|-------|-------|--------|----------|
| 1. Tracking | UFMF video | feat.mat, trx.mat | FlyTracker |
| 2. Feature extraction | feat, trx, LOG | *_data.mat | process_data_features |
| 3. Data combination | *_data.mat files | DATA struct | comb_data_across_cohorts_cond_v2 |
| 4. Analysis | DATA struct | Statistics, plots | Various |

---

## 4. Core Processing Functions

### 4.1 process_data_features.m

**Purpose**: Main processing pipeline for individual experiments.

**Signature**:
```matlab
process_data_features(PROJECT_ROOT, path_to_folder, save_folder, date_str, generate_stim_videos)
```

**Parameters**:
- `PROJECT_ROOT`: Base path for the project
- `path_to_folder`: Path to experiment folder containing LOG, feat, trx
- `save_folder`: Where to save processed data
- `date_str`: Date string for file naming
- `generate_stim_videos`: Boolean for stimulus video generation

**Process**:
1. Load LOG file (experiment metadata and timing)
2. Load feat.mat and trx.mat from FlyTracker
3. Call `combine_data_one_cohort()` to extract behavioral metrics
4. Generate overview plots
5. Save processed data with all metadata

**Output File Contents**:
- `LOG`: Experiment timing and parameters
- `feat`: Raw FlyTracker features
- `trx`: Raw trajectory data
- `comb_data`: Processed behavioral metrics (13 fields)
- `n_fly_data`: [n_arena, n_tracked, n_removed]

### 4.2 combine_data_one_cohort.m

**Purpose**: Extract behavioral metrics from raw tracking data.

**Signature**:
```matlab
[comb_data, n_fly_data] = combine_data_one_cohort(feat, trx)
```

**Process**:
1. Validate flies via `check_tracking_FlyTrk()`
2. Remove flies with bad tracking
3. Interpolate NaN values (spline for position, linear for heading)
4. Smooth position data via `gaussian_conv()`
5. Calculate velocity via `calculate_three_point_velocity()`
6. Estimate angular velocity via `vel_estimate()` (line fit method)
7. Calculate viewing distance via `calculate_viewing_distance()`
8. Calculate inter-fly metrics via `calculate_distance_to_nearest_fly()`

**Output** (`comb_data` struct with 13 fields, each n_flies × n_frames):

| Field | Description | Units |
|-------|-------------|-------|
| `vel_data` | 3-point velocity | mm/s |
| `fv_data` | Forward velocity (in heading direction) | mm/s |
| `av_data` | Angular velocity | deg/s |
| `curv_data` | Curvature (av/fv ratio) | deg/mm |
| `dist_data` | Distance from arena center | mm |
| `dist_trav` | Cumulative distance traveled | mm |
| `heading_data` | Heading angle (unwrapped) | deg |
| `heading_wrap` | Heading angle (wrapped -180 to 180) | deg |
| `x_data` | X position | mm |
| `y_data` | Y position | mm |
| `view_dist` | Viewing distance to wall in heading direction | mm |
| `IFD_data` | Inter-fly distance (to nearest fly) | mm |
| `IFA_data` | Inter-fly angle (to nearest fly) | deg |

### 4.3 comb_data_across_cohorts_cond_v2.m

**Purpose**: Combine data across experiments with enhanced metadata.

**Signature**:
```matlab
DATA = comb_data_across_cohorts_cond_v2(protocol_dir, [pattern_dir], [verbose])
```

**Parameters**:
- `protocol_dir`: Path to protocol results directory
- `pattern_dir`: (Optional) Path to pattern files
- `verbose`: (Optional) Print progress messages

**New Features (v2.0)**:
- Protocol-level `_metadata` field
- Pattern lookup table `_pattern_lut`
- Phase markers for trial segmentation
- Linked pattern metadata per condition

### 4.4 Key Helper Functions

| Function | Purpose |
|----------|---------|
| `check_tracking_FlyTrk` | Identify flies with bad tracking |
| `check_strain_typos` | Correct strain name variations |
| `gaussian_conv` | Smooth position data |
| `vel_estimate` | Calculate angular velocity (line fit) |
| `calculate_three_point_velocity` | Calculate velocity via central differences |
| `calculate_viewing_distance` | Ray-circle intersection for wall distance |
| `calculate_distance_to_nearest_fly` | Inter-fly distance and angle |
| `discover_strains` | Auto-discover strains in protocol directory |

---

## 5. Data Structures

### 5.1 DATA Structure (Hierarchical)

```
DATA
├── _metadata                          % Protocol-level information
│   ├── protocol_name: "protocol_27"
│   ├── protocol_version: "2.0"
│   ├── created_date: datetime
│   ├── n_strains: integer
│   ├── n_total_experiments: integer
│   ├── n_total_flies: integer
│   ├── cond_array: [n_conditions × 7]
│   └── config: struct
│
├── _pattern_lut                       % Pattern metadata lookup
│   ├── P01: {pattern_id, motion_type, spatial_freq_deg, ...}
│   ├── P09: {...}
│   └── P63: {...}
│
├── {strain_name}                      % e.g., "jfrc100_es_shibire_kir"
│   ├── F                              % Females
│   │   ├── (1)                        % Experiment 1
│   │   │   ├── meta                   % Experiment metadata
│   │   │   ├── acclim_off1            % Pre-acclimatization (dark)
│   │   │   ├── acclim_patt            % Pattern acclimatization
│   │   │   ├── acclim_off2            % Post-acclimatization (dark)
│   │   │   ├── R1_condition_1         % Rep 1, Condition 1
│   │   │   │   ├── trial_len
│   │   │   │   ├── interval_dur
│   │   │   │   ├── optomotor_pattern
│   │   │   │   ├── optomotor_speed
│   │   │   │   ├── start_flicker_f
│   │   │   │   ├── phase_markers      % Frame boundaries
│   │   │   │   ├── pattern_meta       % Linked pattern metadata
│   │   │   │   └── [13 behavioral arrays: n_flies × n_frames]
│   │   │   └── R1_condition_2...R2_condition_12
│   │   └── (2)...(n_experiments)
│   └── M                              % Males (same structure)
└── {another_strain}...
```

### 5.2 Phase Markers

Frame boundaries for trial segmentation (1-indexed):

| Phase | Default Frames | Duration | Description |
|-------|---------------|----------|-------------|
| `baseline` | 1-300 | 10s | Pre-stimulus (dark/static) |
| `dir1` | 301-750 | 15s | Stimulus direction 1 |
| `dir2` | 751-1200 | 15s | Stimulus direction 2 (opposite) |
| `interval` | 1201-end | 20s | Inter-trial interval (dark) |

**Structure**:
```matlab
phase_markers.baseline_start = 1;
phase_markers.baseline_end = 300;
phase_markers.dir1_start = 301;
phase_markers.dir1_end = 750;
phase_markers.dir2_start = 751;
phase_markers.dir2_end = 1200;
phase_markers.interval_start = 1201;
phase_markers.interval_end = n_frames;
```

### 5.3 Condition Array Format

```matlab
cond_array = [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n]
```

| Column | Description | Type |
|--------|-------------|------|
| 1 | Pattern ID for stimulus | int |
| 2 | Pattern ID for interval | int |
| 3 | Speed parameter for stimulus | int (0-127) |
| 4 | Speed parameter for interval | int |
| 5 | Trial duration | float (seconds) |
| 6 | Interval duration | float (seconds) |
| 7 | Condition number | int |

---

## 6. Pattern Metadata System

### 6.1 Pattern Naming Convention

Format: `Pattern_{ID}_{motion_type}_{parameters}.mat`

**Examples**:
- `Pattern_09_optomotor_16pixel_binary.mat` - 60° grating
- `Pattern_17_optomotor_skinny_2ON_14OFF_binary.mat` - 2px ON bars
- `Pattern_51_curtain_ON_32pixel_binary.mat` - ON curtain
- `Pattern_60_revphi_16px_8pxstep_binary.mat` - Reverse phi

### 6.2 parse_pattern_metadata.m

**Purpose**: Extract stimulus properties from pattern filenames.

**Signature**:
```matlab
meta = parse_pattern_metadata(pattern_filename)
```

**Output Fields**:

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `pattern_id` | int | Pattern number (1-63) | 9 |
| `pattern_name` | string | Original filename | 'Pattern_09_...' |
| `motion_type` | string | Type of motion | 'optomotor', 'flicker', 'curtain', 'reverse_phi', 'field_of_expansion', 'bar_fixation', 'background' |
| `spatial_freq_deg` | float | Degrees per cycle | 60.0 |
| `bar_width_px` | int | Bar width in pixels | 16 |
| `bar_width_deg` | float | Bar width in degrees | 30.0 |
| `duty_cycle` | float | ON/(ON+OFF) ratio | 0.5 |
| `step_size_px` | int | Pixels per frame | 1 |
| `step_size_deg` | float | Degrees per frame | 1.875 |
| `gs_val` | int | Grayscale bit depth | 1 (binary) |
| `contrast` | float | Michelson contrast | 1.0 |
| `shift_offset` | float | Center of rotation offset | 0.8 |
| `polarity` | string | 'ON', 'OFF', or 'both' | 'both' |
| `n_frames` | int | Total frames in pattern | 32 |

### 6.3 build_pattern_lookup.m

**Purpose**: Generate PATTERN_LUT.mat for all patterns.

**Usage**:
```matlab
PATTERN_LUT = build_pattern_lookup();  % Uses default directory
meta = PATTERN_LUT.P09;                % Access pattern 9
```

---

## 7. Protocol Configuration

### 7.1 get_protocol_config.m

**Location**: `processing_functions/config/get_protocol_config.m`

**Signature**:
```matlab
config = get_protocol_config(protocol_name)
```

**Config Fields**:
```matlab
config.protocol_name          % String identifier
config.description            % Human-readable description
config.fps                    % 30 (constant)
config.n_conditions           % Number of unique conditions
config.n_reps                 % Repetitions per condition (usually 2)
config.trial_duration_s       % Stimulus duration in seconds
config.interval_duration_s    % Inter-trial interval in seconds
config.baseline_duration_s    % Pre-stimulus baseline (default 10s)
config.baseline_frames        % Baseline in frames (default 300)
config.acclim_start_s         % Initial acclimatization (default 300s)
config.acclim_end_s           % Final acclimatization (default 30s)
config.uses_cond_array        % Whether LOG.meta.cond_array is used
config.condition_labels       % Cell array of condition names
config.stimulus_speeds        % Array of speeds (protocol-specific)
```

### 7.2 Supported Protocols

| Protocol | Description | Conditions |
|----------|-------------|------------|
| protocol_10 | Speed and spatial frequency | 12 |
| protocol_15 | Duty cycle comparison | 3 |
| protocol_18 | Gratings vs curtains | 6 |
| protocol_19 | Extended gratings/curtains | 12 |
| protocol_21 | Double-step gratings | 10 |
| protocol_22 | Bar fixation, reverse phi, FoE | 7 |
| protocol_23 | Extended bar fixation (60s) | 2 |
| protocol_24/27 | Standard optomotor screen | 12 |
| protocol_30 | Contrast sensitivity | 8 |
| protocol_31 | Speed tuning | 10 |

### 7.3 protocol_27 Conditions (Main Screen Protocol)

| # | Pattern | Description |
|---|---------|-------------|
| 1 | 9 | 60° gratings 4Hz |
| 2 | 27 | 60° gratings 8Hz |
| 3 | 17 | 2ON_14OFF bars 4Hz |
| 4 | 24 | 2ON_14OFF bars 8Hz |
| 5 | 51 | ON curtains 8Hz |
| 6 | 52 | OFF curtains 8Hz |
| 7 | 60 | Reverse phi slow |
| 8 | 60 | Reverse phi fast |
| 9 | 10 | Flicker 4Hz |
| 10 | 10 | Static grating |
| 11 | 21 | Shifted CoR 0.8 |
| 12 | 57 | Bar fixation |

---

## 8. Python Package

### 8.1 Package Structure

```
python/optomotor_data/
├── __init__.py
├── io/
│   └── mat_loader.py        # MATLoader class
├── core/
│   └── experiment.py        # Data classes
├── analysis/
│   └── slicing.py           # Analysis utilities
└── config/
    └── protocol_config.py   # Protocol configurations
```

### 8.2 Core Classes

**PatternMetadata**: Stimulus properties
**PhaseMarkers**: Frame boundaries for trial phases
**ConditionData**: Single condition with behavioral data
**ExperimentMeta**: Experiment metadata
**Experiment**: Single experiment container
**ProtocolData**: Top-level container (matches MATLAB DATA)

### 8.3 MATLoader

```python
from optomotor_data import MATLoader

loader = MATLoader(pattern_dir='path/to/patterns')
data = loader.load_protocol_data('path/to/results/protocol_27')

# Or load pre-combined DATA.mat
data = loader.load_data_file('path/to/DATA.mat')
```

### 8.4 Analysis Functions

```python
from optomotor_data import (
    get_condition_data_across_experiments,
    compute_mean_sem,
    extract_phase_statistics,
    bin_timeseries
)

# Combine across experiments
av_all = get_condition_data_across_experiments(
    data, 'strain_name', 'F', condition_id=1, data_type='av_data'
)

# Compute statistics
mean, sem = compute_mean_sem(av_all, axis=0)

# Phase statistics
stats = extract_phase_statistics(data, 'strain', 'F', 1, 'av_data')
# Returns: {'baseline': (mean, sem), 'dir1': (mean, sem), ...}
```

### 8.5 Usage Example

```python
from optomotor_data import MATLoader, extract_phase_statistics

# Load
loader = MATLoader(pattern_dir='patterns/Patterns_optomotor')
data = loader.load_protocol_data('results/protocol_27')

# Access
experiments = data.get_strain_sex_data('jfrc100_es_shibire_kir', 'F')
cond = experiments[0].get_condition(1, rep=1)

# Extract phase data
dir1_av = cond.get_phase_data('dir1', 'av_data')

# Pattern info
print(f"Pattern: {cond.pattern_meta.motion_type}, {cond.pattern_meta.spatial_freq_deg}°")
```

---

## 9. File Naming Conventions

### 9.1 Processed Data Files

**Format**: `{date}_{time}_{strain}_{protocol}_{sex}_data.mat`

**Example**: `2025-02-02_12-30_jfrc100_es_shibire_kir_protocol_27_F_data.mat`

### 9.2 Results Directory Structure

```
results/
├── protocol_27/
│   ├── jfrc100_es_shibire_kir/
│   │   ├── F/
│   │   │   ├── 2025-02-01_10-30_*_data.mat
│   │   │   └── 2025-02-01_14-45_*_data.mat
│   │   └── M/
│   └── another_strain/
└── protocol_31/
```

### 9.3 Pattern Files

**Location**: `patterns/Patterns_optomotor/`
**Format**: `Pattern_{ID}_{description}.mat`

---

## 10. Arena & Acquisition Constants

### 10.1 G3 Arena Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Diameter | ~240 mm | |
| Display radius | 119 mm | 496 px ÷ 4.1691 PPM |
| Center (pixels) | [528, 520] | |
| Center (mm) | [126.6, 124.6] | |
| LED panels | 24 | Around arena |
| Pixels per panel | 8 | |
| Total pixels | 192 | 24 × 8 |
| Angular resolution | 1.875 °/px | 360° ÷ 192 |

### 10.2 Acquisition Parameters

| Parameter | Value |
|-----------|-------|
| Frame rate | 30 FPS |
| Video format | UFMF |
| Pixels per mm (PPM) | 4.1691 |
| Calibration file | tracking/calibration.mat |

### 10.3 Processing Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Velocity threshold | 50 mm/s | Higher values = tracking error |
| Angular velocity window | 16 frames | ~533 ms for line fit |
| Baseline duration | 300 frames | 10 seconds |

---

## 11. Behavioral Metrics

### 11.1 Metric Definitions

| Metric | Calculation | Units |
|--------|-------------|-------|
| **vel_data** | 3-point central difference | mm/s |
| **fv_data** | 2-point velocity in heading direction | mm/s |
| **av_data** | Least-squares line fit (16-frame window) | deg/s |
| **curv_data** | av_data / fv_data | deg/mm |
| **dist_data** | 120 - distance_to_wall | mm |
| **view_dist** | Ray-circle intersection | mm |
| **IFD_data** | Distance to nearest fly | mm |
| **IFA_data** | Angle to nearest fly | deg |

### 11.2 Velocity Calculation (3-point)

```matlab
% Central difference for middle points
vx(i) = (x(i+1) - x(i-1)) / (2/fps);
vy(i) = (y(i+1) - y(i-1)) / (2/fps);
v(i) = sqrt(vx(i)^2 + vy(i)^2);

% Forward difference for first point
% Backward difference for last point
```

### 11.3 Angular Velocity (Line Fit)

```matlab
% 16-frame sliding window
% Least-squares fit to heading angle
% Output: deg/s
```

---

## 12. LOG Structure

### 12.1 Overview

```matlab
LOG.meta                       % Experiment metadata
    .fly_strain               % Genotype
    .fly_age                  % Age (e.g., "2-3 days")
    .fly_sex                  % 'F' or 'M'
    .date                     % DD-MMM-YYYY
    .time                     % HH:MM:SS
    .experimenter             % Name
    .start_temp_ring          % Initial temperature
    .end_temp_ring            % Final temperature
    .cond_array               % Condition parameters
    .random_order             % Presentation order

LOG.acclim_off1               % Pre-stimulus (dark)
LOG.acclim_patt               % Pattern flashes
LOG.acclim_off2               % Post-stimulus (dark)

LOG.log_1...LOG.log_N         % Per-condition logs
    .which_condition          % Condition ID
    .trial_len                % Duration (s)
    .optomotor_pattern        % Pattern ID
    .optomotor_speed          % Speed (0-127)
    .start_f                  % Start frames [dir1, dir2, interval]
    .stop_f                   % Stop frames
```

---

## 13. Daily Processing Automation

### 13.1 daily_processing.py

**Location**: `daily_processing/daily_processing.py`

**Process**:
1. Discover new date folders
2. Run `process_freely_walking_data()` via MATLAB CLI
3. Copy results to network drive
4. Copy figures to network
5. Move processed data to 02_processed folder
6. Log all operations

### 13.2 Key Paths (Windows)

```python
LOCAL_TRACKED = "C:\\Users\\burnettl\\Documents\\oakey-cokey\\DATA\\01_tracked"
LOCAL_PROCESSED = "C:\\Users\\burnettl\\Documents\\oakey-cokey\\DATA\\02_processed"
NETWORK_TRACKED = "\\\\prfs.hhmi.org\\reiserlab\\oaky-cokey\\data\\1_tracked"
NETWORK_PROCESSED = "\\\\prfs.hhmi.org\\reiserlab\\oaky-cokey\\data\\2_processed"
```

---

## 14. Extensibility Guide

### 14.1 Adding a New Protocol

1. **Add configuration** to `get_protocol_config.m`:
```matlab
case 'protocol_35'
    config.description = 'New protocol';
    config.n_conditions = 8;
    config.n_reps = 2;
    config.trial_duration_s = 20;
    config.uses_cond_array = true;
    config.condition_labels = {'Cond 1', 'Cond 2', ...};
```

2. **Create protocol script** in `protocols/protocol_35.m`

3. **Add Python config** (optional) in `protocol_config.py`

### 14.2 Adding a New Behavioral Metric

1. Calculate in `combine_data_one_cohort.m`
2. Add to `comb_data` struct
3. Add to `data_fields` in `comb_data_across_cohorts_cond_v2.m`
4. Add to `BEHAVIORAL_FIELDS` in Python `mat_loader.py`
5. Add as attribute in `ConditionData` class

### 14.3 Adding New Pattern Types

1. Create pattern files following naming convention
2. Update regex in `parse_pattern_metadata.m` if needed
3. Regenerate PATTERN_LUT:
```matlab
PATTERN_LUT = build_pattern_lookup();
```

---

## 15. Common Workflows

### 15.1 Process New Experiments

```matlab
% Process single date
process_freely_walking_data('2025_02_02');

% Or via daily_processing.py for automation
```

### 15.2 Combine Protocol Data

```matlab
DATA = comb_data_across_cohorts_cond_v2('/path/to/results/protocol_27');

% Access data
av = DATA.strain_name.F(1).R1_condition_1.av_data;
markers = DATA.strain_name.F(1).R1_condition_1.phase_markers;

% Extract direction 1 only
dir1_av = av(:, markers.dir1_start:markers.dir1_end);
```

### 15.3 Python Analysis

```python
from optomotor_data import MATLoader, extract_phase_statistics

loader = MATLoader(pattern_dir='patterns/Patterns_optomotor')
data = loader.load_protocol_data('results/protocol_27')

stats = extract_phase_statistics(data, 'strain', 'F', 1, 'av_data')
print(f"Dir1: {stats['dir1'][0]:.2f} ± {stats['dir1'][1]:.2f} deg/s")
```

### 15.4 Discover Available Data

```matlab
info = discover_strains('/path/to/results/protocol_27');
% Prints strain/sex/experiment summary
```

---

## 16. Troubleshooting

### 16.1 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Strain name mismatch | Typos/variations | `check_strain_typos()` handles common cases |
| Missing pattern metadata | New pattern type | Update `parse_pattern_metadata.m` regex |
| High velocity values | Tracking errors | Filtered at 50 mm/s threshold |
| NaN in data | Tracking gaps | Interpolated (spline for position) |

### 16.2 Strain Name Handling

- Hyphens converted to underscores: `jfrc100-es` → `jfrc100_es`
- Leading numbers get 'ss' prefix: `1209_DCH` → `ss1209_DCH`

### 16.3 Data Correction

```matlab
% Fix LOG errors
edit_LOGs.m

% Resave comb_data
resave_comb_data_only.m
```

### 16.4 Regenerate Pattern Lookup

```matlab
PATTERN_LUT = build_pattern_lookup('/path/to/patterns', true);
```

---

## Quick Reference

### MATLAB Commands

```matlab
% Process daily data
process_freely_walking_data('2025_02_02')

% Combine protocol data
DATA = comb_data_across_cohorts_cond_v2('/path/to/protocol_27');

% Discover strains
info = discover_strains('/path/to/protocol_27');

% Get protocol config
config = get_protocol_config('protocol_27');

% Build pattern lookup
PATTERN_LUT = build_pattern_lookup();

% Parse single pattern
meta = parse_pattern_metadata('Pattern_09_optomotor_16pixel_binary.mat');
```

### Python Commands

```python
from optomotor_data import MATLoader, extract_phase_statistics

loader = MATLoader(pattern_dir='patterns/Patterns_optomotor')
data = loader.load_protocol_data('results/protocol_27')
exps = data.get_strain_sex_data('strain_name', 'F')
cond = exps[0].get_condition(1, rep=1)
dir1_av = cond.get_phase_data('dir1', 'av_data')
```

---

*Last updated: February 2025*
*Pipeline version: 2.0*

# Data Parsing Pipeline for Freely-Walking Optomotor Experiments

This document describes the enhanced data parsing pipeline for processing behavioral data from freely-walking *Drosophila* optomotor experiments.

## Table of Contents

1. [Overview](#overview)
2. [Data Flow](#data-flow)
3. [Data Structures](#data-structures)
4. [MATLAB Functions](#matlab-functions)
5. [Python Package](#python-package)
6. [Usage Examples](#usage-examples)
7. [Extensibility](#extensibility)
8. [File Reference](#file-reference)

---

## Overview

This pipeline processes raw experimental data from the G3 LED arena into organized, hierarchical data structures. Key features include:

- **Automatic pattern metadata extraction** from pattern filenames
- **Protocol-agnostic processing** via configuration system
- **Phase markers** for trial segmentation (baseline, dir1, dir2, interval)
- **Dual language support**: MATLAB (core) and Python (analysis)
- **Backward compatibility** with existing analysis functions

### Why This Structure?

| Design Choice | Rationale |
|--------------|-----------|
| Protocol > Strain > Sex hierarchy | Facilitates cross-strain comparisons under identical conditions |
| Auto-extracted pattern metadata | Eliminates manual lookup table maintenance |
| Continuous data with phase markers | Preserves temporal structure while enabling flexible slicing |
| Both MATLAB and Python | Leverages existing MATLAB plotting + modern Python ML ecosystem |

---

## Data Flow

```
Raw Tracking Data (FlyTracker .mat files)
    │
    ▼
process_data_features.m
    │
    ▼
Individual Experiment Files (*_data.mat)
    │ Contains: comb_data, LOG, n_fly_data, feat, trx
    │
    ▼
comb_data_across_cohorts_cond_v2.m  ◄── build_pattern_lookup.m
    │                                    (Pattern metadata)
    │
    ▼
DATA struct (hierarchical)
    │
    ├──► MATLAB analysis (existing plotting functions)
    │
    └──► Python analysis (optomotor_data package)
```

---

## Data Structures

### DATA Struct (MATLAB / Python ProtocolData)

```
DATA
├── _metadata                          % Protocol-level information
│   ├── protocol_name: "protocol_27"
│   ├── protocol_version: "2.0"
│   ├── created_date: datetime
│   ├── n_strains: 5
│   ├── n_total_experiments: 150
│   ├── n_total_flies: 2250
│   ├── cond_array: [12 × 7 matrix]
│   └── config: struct (from get_protocol_config)
│
├── _pattern_lut                       % Pattern metadata lookup table
│   ├── P04: {pattern_id, motion_type, spatial_freq_deg, ...}
│   ├── P09: {pattern_id: 9, motion_type: 'optomotor', ...}
│   └── P17: {pattern_id: 17, bar_width_px: 2, duty_cycle: 0.125, ...}
│
├── jfrc100_es_shibire_kir             % Strain name
│   ├── F                              % Sex (Female)
│   │   ├── (1)                        % Experiment 1
│   │   │   ├── meta                   % Experiment metadata
│   │   │   │   ├── date, time, fly_strain, fly_age, fly_sex
│   │   │   │   ├── experimenter, n_flies, n_flies_rm
│   │   │   │   ├── start_temp_ring, end_temp_ring
│   │   │   │   ├── random_order, source_file
│   │   │   │   └── cond_array
│   │   │   │
│   │   │   ├── acclim_off1            % Pre-acclimatization (dark)
│   │   │   ├── acclim_patt            % Pattern acclimatization
│   │   │   ├── acclim_off2            % Post-acclimatization (dark)
│   │   │   │
│   │   │   ├── R1_condition_1         % Repetition 1, Condition 1
│   │   │   │   ├── trial_len: 15
│   │   │   │   ├── interval_dur: 20
│   │   │   │   ├── optomotor_pattern: 9
│   │   │   │   ├── optomotor_speed: 127
│   │   │   │   ├── start_flicker_f: 750
│   │   │   │   │
│   │   │   │   ├── phase_markers      % NEW: Frame boundaries
│   │   │   │   │   ├── baseline_start: 1
│   │   │   │   │   ├── baseline_end: 300
│   │   │   │   │   ├── dir1_start: 301
│   │   │   │   │   ├── dir1_end: 750
│   │   │   │   │   ├── dir2_start: 751
│   │   │   │   │   ├── dir2_end: 1200
│   │   │   │   │   └── interval_start: 1201
│   │   │   │   │
│   │   │   │   ├── pattern_meta       % NEW: Linked from _pattern_lut
│   │   │   │   │   ├── pattern_id: 9
│   │   │   │   │   ├── motion_type: 'optomotor'
│   │   │   │   │   ├── spatial_freq_deg: 60
│   │   │   │   │   ├── bar_width_px: 16
│   │   │   │   │   └── duty_cycle: 0.5
│   │   │   │   │
│   │   │   │   └── [Behavioral data arrays: n_flies × n_frames]
│   │   │   │       ├── vel_data       % 3-point velocity (mm/s)
│   │   │   │       ├── fv_data        % Forward velocity (mm/s)
│   │   │   │       ├── av_data        % Angular velocity (deg/s)
│   │   │   │       ├── curv_data      % Curvature (deg/mm)
│   │   │   │       ├── dist_data      % Distance from center (mm)
│   │   │   │       ├── heading_data   % Heading unwrapped (deg)
│   │   │   │       ├── heading_wrap   % Heading wrapped (deg)
│   │   │   │       ├── x_data, y_data % Position (mm)
│   │   │   │       ├── view_dist      % Viewing distance to wall (mm)
│   │   │   │       └── IFD_data, IFA_data % Inter-fly metrics
│   │   │   │
│   │   │   └── R2_condition_1...R2_condition_12
│   │   │
│   │   └── (2)...(n_experiments)
│   │
│   └── M                              % Males (same structure)
│
└── another_strain...
```

### Pattern Metadata Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `pattern_id` | int | Pattern number (1-63) | 9 |
| `pattern_name` | string | Original filename | 'Pattern_09_optomotor_16pixel_binary.mat' |
| `motion_type` | string | Type of motion | 'optomotor', 'flicker', 'curtain', 'reverse_phi' |
| `spatial_freq_deg` | float | Degrees per cycle | 60.0 |
| `bar_width_px` | int | ON bar width in pixels | 16 |
| `bar_width_deg` | float | ON bar width in degrees | 30.0 |
| `duty_cycle` | float | ON/(ON+OFF) ratio | 0.5 |
| `step_size_px` | int | Pixels per frame update | 1 |
| `step_size_deg` | float | Degrees per frame update | 1.875 |
| `gs_val` | int | Grayscale bit depth | 1 (binary) |
| `contrast` | float | Estimated Michelson contrast | 1.0 |
| `polarity` | string | 'ON', 'OFF', or 'both' | 'both' |

### Phase Markers

Phase markers enable easy extraction of trial phases:

| Phase | Typical Frames | Duration | Description |
|-------|---------------|----------|-------------|
| `baseline` | 1-300 | 10s | Pre-stimulus period (dark or static) |
| `dir1` | 301-750 | 15s | Stimulus moving in direction 1 |
| `dir2` | 751-1200 | 15s | Stimulus moving in direction 2 (opposite) |
| `interval` | 1201-end | 20s | Inter-trial interval (dark) |

---

## MATLAB Functions

### Core Functions

#### `comb_data_across_cohorts_cond_v2(protocol_dir, pattern_dir, verbose)`

Enhanced data combiner that creates the hierarchical DATA struct.

```matlab
% Basic usage
DATA = comb_data_across_cohorts_cond_v2('/path/to/results/protocol_27');

% With custom pattern directory
DATA = comb_data_across_cohorts_cond_v2(protocol_dir, '/path/to/patterns', true);
```

**New features over v1:**
- Adds `_metadata` field with protocol info
- Adds `_pattern_lut` with pattern metadata
- Adds `phase_markers` to each condition
- Links `pattern_meta` from lookup table

#### `parse_pattern_metadata(pattern_filename)`

Extracts stimulus properties from pattern filenames.

```matlab
meta = parse_pattern_metadata('Pattern_09_optomotor_16pixel_binary.mat');
% Returns: spatial_freq_deg=60, bar_width_px=16, motion_type='optomotor'

meta = parse_pattern_metadata('Pattern_17_optomotor_skinny_2ON_14OFF_binary.mat');
% Returns: bar_width_px=2, duty_cycle=0.125, spatial_freq_deg=30
```

#### `build_pattern_lookup(pattern_dir, save_lut)`

Generates `PATTERN_LUT.mat` containing metadata for all patterns.

```matlab
% Build and save lookup table
PATTERN_LUT = build_pattern_lookup('/path/to/patterns');

% Access pattern metadata
meta = PATTERN_LUT.P09;  % Pattern 9
disp(meta.spatial_freq_deg);  % 60.0
```

#### `get_protocol_config(protocol_name)`

Returns protocol-specific configuration.

```matlab
config = get_protocol_config('protocol_27');
fprintf('Protocol has %d conditions\n', config.n_conditions);
fprintf('Condition 1: %s\n', config.condition_labels{1});
```

#### `discover_strains(protocol_dir, verbose)`

Automatically discovers strains in a protocol directory.

```matlab
info = discover_strains('/path/to/results/protocol_27');
% Prints summary and returns struct with strain/sex/experiment counts
```

---

## Python Package

### Installation

The Python package is located at `python/optomotor_data/`. Add to your Python path or install:

```bash
cd /path/to/freely-walking-optomotor/python
pip install -e .
```

### Quick Start

```python
from optomotor_data import MATLoader, get_condition_data_across_experiments

# Load data
loader = MATLoader(pattern_dir='/path/to/patterns')
data = loader.load_protocol_data('/path/to/results/protocol_27')

# Access experiments
experiments = data.get_strain_sex_data('jfrc100_es_shibire_kir', 'F')
print(f"Found {len(experiments)} experiments")

# Get condition data
cond = experiments[0].get_condition(1, rep=1)
print(f"Angular velocity shape: {cond.av_data.shape}")

# Extract phase data
dir1_av = cond.get_phase_data('dir1', 'av_data')
print(f"Direction 1 mean: {dir1_av.mean():.2f} deg/s")
```

### Key Classes

| Class | Description |
|-------|-------------|
| `MATLoader` | Loads MATLAB .mat files into Python |
| `ProtocolData` | Top-level container (matches DATA struct) |
| `Experiment` | Single experiment with conditions |
| `ConditionData` | Behavioral data + metadata for one condition |
| `PatternMetadata` | Stimulus properties |
| `PhaseMarkers` | Frame boundaries for trial phases |

### Analysis Functions

```python
from optomotor_data import (
    get_condition_data_across_experiments,
    compute_mean_sem,
    extract_phase_statistics,
    bin_timeseries
)

# Combine data across experiments
av_all = get_condition_data_across_experiments(
    data, 'strain_name', 'F', condition_id=1, data_type='av_data'
)

# Compute statistics
mean, sem = compute_mean_sem(av_all, axis=0)

# Get phase statistics
stats = extract_phase_statistics(data, 'strain_name', 'F', 1, 'av_data')
print(f"Dir1: {stats['dir1'][0]:.2f} ± {stats['dir1'][1]:.2f} deg/s")

# Bin time series
binned = bin_timeseries(av_all, window_size=15, step_size=5)
```

---

## Usage Examples

### MATLAB: Basic Analysis

```matlab
% Load data
DATA = comb_data_across_cohorts_cond_v2('/path/to/results/protocol_27');

% Access strain/sex data
strain = 'jfrc100_es_shibire_kir';
experiments = DATA.(strain).F;

% Get condition 1, repetition 1 from first experiment
cond = experiments(1).R1_condition_1;

% Extract direction 1 angular velocity using phase markers
markers = cond.phase_markers;
dir1_av = cond.av_data(:, markers.dir1_start:markers.dir1_end);

% Compute mean across flies
mean_av = mean(dir1_av, 1, 'omitnan');

% Access pattern metadata
fprintf('Pattern %d: %s, spatial freq = %.1f deg\n', ...
    cond.pattern_meta.pattern_id, ...
    cond.pattern_meta.motion_type, ...
    cond.pattern_meta.spatial_freq_deg);
```

### MATLAB: Backward Compatible

```matlab
% The new DATA struct works with existing plotting functions
DATA = comb_data_across_cohorts_cond_v2(protocol_dir);

% Existing code still works:
av_data = DATA.strain_name.F(1).R1_condition_1.av_data;
fv_data = DATA.strain_name.F(1).R1_condition_1.fv_data;

% New features are additive:
phase_markers = DATA.strain_name.F(1).R1_condition_1.phase_markers;
pattern_info = DATA.strain_name.F(1).R1_condition_1.pattern_meta;
```

### Python: Cross-Strain Comparison

```python
from optomotor_data import MATLoader, extract_phase_statistics
import matplotlib.pyplot as plt

# Load data
loader = MATLoader(pattern_dir='path/to/patterns')
data = loader.load_protocol_data('path/to/results/protocol_27')

# Compare strains
strains = ['control_strain', 'experimental_strain']
condition = 1

results = {}
for strain in strains:
    stats = extract_phase_statistics(data, strain, 'F', condition, 'av_data')
    results[strain] = stats

# Plot comparison
fig, ax = plt.subplots()
x = range(len(strains))
dir1_means = [results[s]['dir1'][0] for s in strains]
dir1_sems = [results[s]['dir1'][1] for s in strains]
ax.bar(x, dir1_means, yerr=dir1_sems)
ax.set_xticks(x)
ax.set_xticklabels(strains, rotation=45)
ax.set_ylabel('Angular velocity (deg/s)')
plt.tight_layout()
plt.show()
```

---

## Extensibility

### Adding a New Protocol

1. **Add configuration** to `processing_functions/config/get_protocol_config.m`:

```matlab
case 'protocol_35'
    config.description = 'New protocol description';
    config.n_conditions = 8;
    config.n_reps = 2;
    config.trial_duration_s = 20;
    config.uses_cond_array = true;
    config.condition_labels = {
        'Condition 1 label'
        'Condition 2 label'
        % ...
    };
```

2. **Add to Python config** in `python/optomotor_data/config/protocol_config.py`:

```python
'protocol_35': ProtocolConfig(
    protocol_name='protocol_35',
    description='New protocol description',
    n_conditions=8,
    condition_labels=['Condition 1 label', 'Condition 2 label', ...]
),
```

3. **Run the pipeline** — no other changes needed:

```matlab
DATA = comb_data_across_cohorts_cond_v2('/path/to/results/protocol_35');
```

### Adding a New Strain

No code changes required. Place data in the expected folder structure:

```
protocol_27/
├── existing_strain/
└── new_strain_name/      % Automatically discovered
    ├── F/
    │   └── *_data.mat
    └── M/
        └── *_data.mat
```

### Adding New Pattern Types

1. Create pattern files following the naming convention
2. Update regex patterns in `parse_pattern_metadata.m` if needed
3. Regenerate the lookup table:

```matlab
build_pattern_lookup('/path/to/patterns');
```

### Adding New Behavioral Metrics

1. Add the field to `data_fields` in `comb_data_across_cohorts_cond_v2.m`
2. Add to `BEHAVIORAL_FIELDS` in `python/optomotor_data/io/mat_loader.py`
3. Add as attribute in `ConditionData` class

---

## File Reference

### MATLAB Files

| File | Location | Purpose |
|------|----------|---------|
| `comb_data_across_cohorts_cond_v2.m` | `processing_functions/functions/` | Main data combining function |
| `parse_pattern_metadata.m` | `processing_functions/functions/` | Extract pattern properties from filename |
| `build_pattern_lookup.m` | `processing_functions/functions/` | Generate PATTERN_LUT.mat |
| `discover_strains.m` | `processing_functions/functions/` | Auto-discover strains in protocol |
| `get_protocol_config.m` | `processing_functions/config/` | Protocol configuration registry |

### Python Files

| File | Location | Purpose |
|------|----------|---------|
| `__init__.py` | `python/optomotor_data/` | Package initialization |
| `mat_loader.py` | `python/optomotor_data/io/` | MATLAB file loader |
| `experiment.py` | `python/optomotor_data/core/` | Data classes |
| `slicing.py` | `python/optomotor_data/analysis/` | Data extraction utilities |
| `protocol_config.py` | `python/optomotor_data/config/` | Protocol configurations |

### Generated Files

| File | Location | Purpose |
|------|----------|---------|
| `PATTERN_LUT.mat` | `patterns/Patterns_optomotor/` | Pattern metadata lookup table |

---

## Version History

- **v2.0** (2025): Enhanced pipeline with pattern metadata, phase markers, Python package
- **v1.0** (2024): Original `comb_data_across_cohorts_cond.m` implementation

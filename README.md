# Freely Walking Optomotor

Code to run and process freely walking optomotor behaviour protocols in the cylindrical G3 arena.

First developed for HMS, summer 2024 and later used for the oaky-cokey screen with AD, autumn 2024 - summer 2025.

## Repository Structure

```
freely-walking-optomotor/
├── protocols/              # Experimental protocol definitions
├── processing_functions/   # Data processing and parsing pipeline
│   ├── functions/          # Core processing functions
│   ├── config/             # Protocol configurations
│   └── README_DATA_PARSING.md  # Detailed documentation
├── patterns/               # Visual stimulus pattern files
├── tracking/               # FlyTracker integration
├── daily_processing/       # Automated daily processing scripts
├── python/                 # Python analysis package
│   └── optomotor_data/     # Data loading and analysis utilities
├── monitor_and_copy_folder/    # File monitoring utilities
├── monitor_and_track_folder/   # Tracking automation
└── .archive/               # Legacy code (plotting, analysis, model)
```

## Quick Start

### Running Experiments
Protocol files are in `protocols/`. Each protocol defines the stimulus conditions, timing, and parameters.

### Processing Data
```matlab
% Process all data for a protocol
DATA = comb_data_across_cohorts_cond_v2('/path/to/results/protocol_27');

% Discover strains in a protocol directory
strain_info = discover_strains('/path/to/results/protocol_27');
```

### Python Analysis
```python
from optomotor_data import MATLoader

loader = MATLoader(pattern_dir='patterns/Patterns_optomotor')
data = loader.load_protocol_data('/path/to/results/protocol_27')

# Access experiments
experiments = data.get_strain_sex_data('strain_name', 'F')
```

## Documentation

See `processing_functions/README_DATA_PARSING.md` for detailed documentation on:
- Data structures and organization
- Pattern metadata extraction
- Phase markers for trial segmentation
- Adding new protocols and strains

## Archived Code

Legacy plotting, analysis, and model code is available in `.archive/`:
- `plotting_functions/` - Visualization and figure generation
- `analysis_tests/` - Experimental analysis scripts
- `model/` - Optomotor response modeling
- `misc/` - Miscellaneous utilities

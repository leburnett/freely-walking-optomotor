"""
Optomotor Data Analysis Package

A Python package for loading, processing, and analyzing freely-walking
optomotor behavioral data from Drosophila experiments.

This package provides:
- MATLAB .mat file loading with automatic structure parsing
- Data classes for experiments, conditions, and pattern metadata
- Utilities for time-series analysis and statistics
- Compatibility with the MATLAB DATA structure from comb_data_across_cohorts_cond_v2

Example usage:
    from optomotor_data import MATLoader, ProtocolData

    # Load data from a protocol directory
    loader = MATLoader(pattern_dir='/path/to/patterns')
    data = loader.load_protocol_data('/path/to/results/protocol_27')

    # Access experiments
    experiments = data.get_strain_sex_data('jfrc100_es_shibire_kir', 'F')

    # Get condition data
    cond = experiments[0].get_condition(1, rep=1)
    av = cond.av_data  # Angular velocity

See the README for detailed documentation.
"""

__version__ = '2.0.0'
__author__ = 'Laura Burnett'

# Import main classes for convenient access
from .io.mat_loader import MATLoader
from .core.experiment import (
    PatternMetadata,
    PhaseMarkers,
    ConditionData,
    ExperimentMeta,
    Experiment,
    ProtocolData
)
from .analysis.slicing import (
    get_condition_data_across_experiments,
    compute_mean_sem,
    bin_timeseries,
    extract_phase_statistics
)

__all__ = [
    'MATLoader',
    'PatternMetadata',
    'PhaseMarkers',
    'ConditionData',
    'ExperimentMeta',
    'Experiment',
    'ProtocolData',
    'get_condition_data_across_experiments',
    'compute_mean_sem',
    'bin_timeseries',
    'extract_phase_statistics',
]

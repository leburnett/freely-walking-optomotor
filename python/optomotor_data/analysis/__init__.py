"""
Analysis utilities for optomotor data.

Provides:
- Data slicing and extraction functions
- Statistical utilities (mean, SEM, binning)
- Phase-based analysis
"""

from .slicing import (
    get_condition_data_across_experiments,
    compute_mean_sem,
    bin_timeseries,
    extract_phase_statistics
)

__all__ = [
    'get_condition_data_across_experiments',
    'compute_mean_sem',
    'bin_timeseries',
    'extract_phase_statistics'
]

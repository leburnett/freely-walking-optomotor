"""
Core data structures for optomotor experiments.

Provides dataclasses for:
- PatternMetadata: Stimulus pattern properties
- PhaseMarkers: Trial phase boundaries
- ConditionData: Single condition behavioral data
- ExperimentMeta: Experiment metadata
- Experiment: Complete experiment container
- ProtocolData: Protocol-level data container
"""

from .experiment import (
    PatternMetadata,
    PhaseMarkers,
    ConditionData,
    ExperimentMeta,
    Experiment,
    ProtocolData
)

__all__ = [
    'PatternMetadata',
    'PhaseMarkers',
    'ConditionData',
    'ExperimentMeta',
    'Experiment',
    'ProtocolData'
]

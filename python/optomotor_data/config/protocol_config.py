"""
Protocol configuration for optomotor experiments.

This module provides protocol-specific parameters that mirror the
MATLAB get_protocol_config.m function.
"""

from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field


@dataclass
class ProtocolConfig:
    """Configuration for a single protocol."""
    protocol_name: str
    description: str = ''
    fps: int = 30
    n_conditions: int = 12
    n_reps: int = 2
    trial_duration_s: float = 15.0
    interval_duration_s: float = 20.0
    baseline_duration_s: float = 10.0
    acclim_start_s: float = 300.0
    acclim_end_s: float = 30.0
    flash_duration_s: float = 5.0
    uses_cond_array: bool = True
    condition_labels: List[str] = field(default_factory=list)
    stimulus_speeds: List[float] = field(default_factory=list)

    @property
    def baseline_frames(self) -> int:
        """Baseline duration in frames."""
        return int(self.baseline_duration_s * self.fps)


# Protocol configuration registry
PROTOCOL_CONFIGS: Dict[str, ProtocolConfig] = {
    'protocol_10': ProtocolConfig(
        protocol_name='protocol_10',
        description='Speed and spatial frequency testing',
        n_conditions=12,
        uses_cond_array=False,
        condition_labels=[
            '60deg slow 2s', '60deg fast 15s', '60deg slow 15s', '60deg fast 2s',
            '30deg slow 2s', '30deg fast 15s', '30deg slow 15s', '30deg fast 2s',
            '15deg slow 2s', '15deg fast 15s', '15deg slow 15s', '15deg fast 2s'
        ]
    ),

    'protocol_15': ProtocolConfig(
        protocol_name='protocol_15',
        description='Duty cycle comparison (ON/OFF ratios)',
        n_conditions=3,
        uses_cond_array=False,
        condition_labels=[
            '4ON_4OFF (50% duty)',
            '4ON_12OFF (25% duty)',
            '12ON_4OFF (75% duty)'
        ]
    ),

    'protocol_18': ProtocolConfig(
        protocol_name='protocol_18',
        description='Gratings vs curtains comparison',
        n_conditions=6,
        uses_cond_array=False,
        condition_labels=[
            'Gratings 60deg fast', 'Gratings 60deg slow',
            'ON curtain slow', 'ON curtain fast',
            'OFF curtain slow', 'OFF curtain fast'
        ]
    ),

    'protocol_19': ProtocolConfig(
        protocol_name='protocol_19',
        description='Extended gratings and curtains with thin bars',
        n_conditions=12,
        uses_cond_array=False,
        condition_labels=[
            '60deg grating slow', '60deg grating fast',
            'ON curtain slow', 'ON curtain fast',
            'OFF curtain slow', 'OFF curtain fast',
            '2ON_14OFF grating slow', '2ON_14OFF grating fast',
            '2OFF_14ON grating slow', '2OFF_14ON grating fast',
            '15deg grating slow', '15deg grating fast'
        ]
    ),

    'protocol_21': ProtocolConfig(
        protocol_name='protocol_21',
        description='Double-step gratings with curtains and flicker',
        n_conditions=10,
        uses_cond_array=False,
        condition_labels=[
            '60deg 2px-step slow', '60deg 2px-step fast',
            '30deg 2px-step slow', '30deg 2px-step fast',
            'ON curtain slow', 'ON curtain fast',
            'OFF curtain slow', 'OFF curtain fast',
            'Flicker 60deg slow', 'Flicker 60deg fast'
        ]
    ),

    'protocol_22': ProtocolConfig(
        protocol_name='protocol_22',
        description='Bar fixation, reverse phi, and field of expansion',
        n_conditions=7,
        uses_cond_array=False,
        condition_labels=[
            'Bar fixation',
            'Reverse phi 1px step', 'Reverse phi 4px step', 'Reverse phi 8px step',
            'FoE 30deg', 'FoE 15deg', 'FoE 60deg'
        ]
    ),

    'protocol_23': ProtocolConfig(
        protocol_name='protocol_23',
        description='Extended bar fixation (60s trials)',
        n_conditions=2,
        trial_duration_s=60.0,
        interval_duration_s=7.0,
        uses_cond_array=False,
        condition_labels=[
            'ON bar fixation 60s',
            'OFF bar fixation 60s'
        ]
    ),

    'protocol_24': ProtocolConfig(
        protocol_name='protocol_24',
        description='Standard optomotor screen with multiple stimulus types',
        n_conditions=12,
        uses_cond_array=True,
        condition_labels=[
            '60deg gratings 4Hz', '60deg gratings 8Hz',
            '2ON_14OFF bars 4Hz', '2ON_14OFF bars 8Hz',
            'ON curtains 4Hz', 'ON curtains 8Hz',
            'OFF curtains 4Hz', 'OFF curtains 8Hz',
            'Reverse phi slow', 'Reverse phi fast',
            'Flicker 60deg', 'Static pattern'
        ]
    ),

    'protocol_27': ProtocolConfig(
        protocol_name='protocol_27',
        description='Standard optomotor screen with multiple stimulus types',
        n_conditions=12,
        uses_cond_array=True,
        condition_labels=[
            '60deg gratings 4Hz', '60deg gratings 8Hz',
            '2ON_14OFF bars 4Hz', '2ON_14OFF bars 8Hz',
            'ON curtains 4Hz', 'ON curtains 8Hz',
            'OFF curtains 4Hz', 'OFF curtains 8Hz',
            'Reverse phi slow', 'Reverse phi fast',
            'Flicker 60deg', 'Static pattern'
        ]
    ),

    'protocol_30': ProtocolConfig(
        protocol_name='protocol_30',
        description='Contrast sensitivity testing',
        n_conditions=8,
        uses_cond_array=True,
        condition_labels=[
            'High contrast fast', 'High contrast slow',
            'Medium contrast fast', 'Medium contrast slow',
            'Low contrast fast', 'Low contrast slow',
            'Very low contrast fast', 'Very low contrast slow'
        ]
    ),

    'protocol_31': ProtocolConfig(
        protocol_name='protocol_31',
        description='Speed tuning with multiple velocities',
        n_conditions=10,
        trial_duration_s=20.0,
        uses_cond_array=True,
        condition_labels=[
            '60deg 60dps', '60deg 120dps', '60deg 240dps', '60deg 480dps', '60deg flicker',
            '15deg 60dps', '15deg 120dps', '15deg 240dps', '15deg 480dps', '15deg flicker'
        ],
        stimulus_speeds=[60, 120, 240, 480, 0, 60, 120, 240, 480, 0]
    ),
}


def get_protocol_config(protocol_name: str) -> ProtocolConfig:
    """
    Get configuration for a specific protocol.

    Args:
        protocol_name: Protocol identifier (e.g., 'protocol_27')

    Returns:
        ProtocolConfig object with protocol-specific parameters

    Raises:
        KeyError: If protocol is not in the registry (returns default config)
    """
    if protocol_name in PROTOCOL_CONFIGS:
        return PROTOCOL_CONFIGS[protocol_name]

    # Return default configuration for unknown protocols
    return ProtocolConfig(
        protocol_name=protocol_name,
        description=f'Unknown protocol (default configuration)',
        n_conditions=12,
        uses_cond_array=True
    )


def get_condition_label(protocol_name: str, condition_id: int) -> str:
    """
    Get human-readable label for a condition.

    Args:
        protocol_name: Protocol identifier
        condition_id: Condition number (1-indexed)

    Returns:
        Condition label string, or generic label if not found
    """
    config = get_protocol_config(protocol_name)

    if config.condition_labels and 0 < condition_id <= len(config.condition_labels):
        return config.condition_labels[condition_id - 1]

    return f'Condition {condition_id}'

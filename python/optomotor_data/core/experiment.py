"""
Core data classes for optomotor experiments.

This module defines the primary data structures used to represent
experimental data loaded from MATLAB .mat files.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import numpy as np


@dataclass
class PatternMetadata:
    """
    Stimulus pattern metadata extracted from pattern filenames.

    Attributes:
        pattern_id: Integer pattern number (1-63)
        pattern_name: Original filename
        motion_type: Type of motion ('optomotor', 'flicker', 'curtain', etc.)
        spatial_freq_deg: Degrees per cycle
        bar_width_px: Bar width in pixels (ON portion)
        bar_width_deg: Bar width in degrees
        duty_cycle: ON/(ON+OFF) ratio
        step_size_px: Pixels per frame update
        step_size_deg: Degrees per frame update
        gs_val: Grayscale bit depth (1=binary)
        contrast: Estimated Michelson contrast
        shift_offset: Center of rotation offset (for shifted patterns)
        polarity: 'ON', 'OFF', or 'both'
        n_frames: Total frames in pattern
    """
    pattern_id: int
    pattern_name: str
    motion_type: str = 'unknown'
    spatial_freq_deg: Optional[float] = None
    bar_width_px: Optional[int] = None
    bar_width_deg: Optional[float] = None
    duty_cycle: Optional[float] = None
    step_size_px: int = 1
    step_size_deg: float = 1.875
    gs_val: int = 1
    contrast: float = 1.0
    shift_offset: Optional[float] = None
    polarity: str = 'both'
    n_frames: Optional[int] = None

    @classmethod
    def from_matlab(cls, mat_struct: Dict) -> 'PatternMetadata':
        """Create PatternMetadata from MATLAB struct."""
        return cls(
            pattern_id=int(mat_struct.get('pattern_id', 0)),
            pattern_name=str(mat_struct.get('pattern_name', '')),
            motion_type=str(mat_struct.get('motion_type', 'unknown')),
            spatial_freq_deg=_safe_float(mat_struct.get('spatial_freq_deg')),
            bar_width_px=_safe_int(mat_struct.get('bar_width_px')),
            bar_width_deg=_safe_float(mat_struct.get('bar_width_deg')),
            duty_cycle=_safe_float(mat_struct.get('duty_cycle')),
            step_size_px=int(mat_struct.get('step_size_px', 1)),
            step_size_deg=float(mat_struct.get('step_size_deg', 1.875)),
            gs_val=int(mat_struct.get('gs_val', 1)),
            contrast=float(mat_struct.get('contrast', 1.0)),
            shift_offset=_safe_float(mat_struct.get('shift_offset')),
            polarity=str(mat_struct.get('polarity', 'both')),
            n_frames=_safe_int(mat_struct.get('n_frames'))
        )


@dataclass
class PhaseMarkers:
    """
    Frame boundaries for trial phases.

    All values are 1-indexed frame numbers relative to condition start.

    Attributes:
        baseline_start: First frame of pre-stimulus baseline
        baseline_end: Last frame of baseline
        dir1_start: First frame of stimulus direction 1
        dir1_end: Last frame of direction 1
        dir2_start: First frame of stimulus direction 2
        dir2_end: Last frame of direction 2
        interval_start: First frame of inter-trial interval
        interval_end: Last frame of condition
    """
    baseline_start: int = 1
    baseline_end: int = 300
    dir1_start: int = 301
    dir1_end: int = 750
    dir2_start: int = 751
    dir2_end: int = 1200
    interval_start: int = 1201
    interval_end: int = 1500

    @classmethod
    def from_matlab(cls, mat_struct: Dict) -> 'PhaseMarkers':
        """Create PhaseMarkers from MATLAB struct."""
        return cls(
            baseline_start=int(mat_struct.get('baseline_start', 1)),
            baseline_end=int(mat_struct.get('baseline_end', 300)),
            dir1_start=int(mat_struct.get('dir1_start', 301)),
            dir1_end=int(mat_struct.get('dir1_end', 750)),
            dir2_start=int(mat_struct.get('dir2_start', 751)),
            dir2_end=int(mat_struct.get('dir2_end', 1200)),
            interval_start=int(mat_struct.get('interval_start', 1201)),
            interval_end=int(mat_struct.get('interval_end', 1500))
        )

    def get_slice(self, phase: str) -> slice:
        """
        Get a slice object for extracting a specific phase.

        Args:
            phase: 'baseline', 'dir1', 'dir2', or 'interval'

        Returns:
            slice object for array indexing (0-indexed)
        """
        if phase == 'baseline':
            return slice(self.baseline_start - 1, self.baseline_end)
        elif phase == 'dir1':
            return slice(self.dir1_start - 1, self.dir1_end)
        elif phase == 'dir2':
            return slice(self.dir2_start - 1, self.dir2_end)
        elif phase == 'interval':
            return slice(self.interval_start - 1, self.interval_end)
        else:
            raise ValueError(f"Unknown phase: {phase}")


@dataclass
class ConditionData:
    """
    Data for a single experimental condition.

    Contains behavioral time-series data and metadata for one condition
    (e.g., R1_condition_1 = Repetition 1 of condition 1).

    Attributes:
        condition_id: Condition number (1-12 typically)
        repetition: Repetition number (1 or 2)
        trial_len: Trial duration in seconds
        interval_dur: Inter-trial interval in seconds
        optomotor_pattern: Pattern ID used
        optomotor_speed: Stimulus speed parameter
        interval_pattern: Pattern during interval
        interval_speed: Speed during interval
        start_flicker_f: Frame where inter-trial begins (relative to start)
        phase_markers: Frame boundaries for phases
        pattern_meta: Linked pattern metadata

        # Behavioral data arrays (n_flies x n_frames):
        vel_data: Velocity (mm/s)
        fv_data: Forward velocity (mm/s)
        av_data: Angular velocity (deg/s)
        curv_data: Curvature (deg/mm)
        dist_data: Distance from center (mm)
        dist_trav: Cumulative distance traveled (mm)
        heading_data: Heading unwrapped (deg)
        heading_wrap: Heading wrapped (deg)
        x_data: X position (mm)
        y_data: Y position (mm)
        view_dist: Viewing distance to wall (mm)
        IFD_data: Inter-fly distance (mm)
        IFA_data: Inter-fly angle (deg)
    """
    condition_id: int
    repetition: int
    trial_len: float = 15.0
    interval_dur: float = 20.0
    optomotor_pattern: int = 0
    optomotor_speed: int = 0
    interval_pattern: int = 0
    interval_speed: int = 0
    start_flicker_f: int = 0
    phase_markers: Optional[PhaseMarkers] = None
    pattern_meta: Optional[PatternMetadata] = None

    # Behavioral data arrays
    vel_data: Optional[np.ndarray] = None
    fv_data: Optional[np.ndarray] = None
    av_data: Optional[np.ndarray] = None
    curv_data: Optional[np.ndarray] = None
    dist_data: Optional[np.ndarray] = None
    dist_trav: Optional[np.ndarray] = None
    heading_data: Optional[np.ndarray] = None
    heading_wrap: Optional[np.ndarray] = None
    x_data: Optional[np.ndarray] = None
    y_data: Optional[np.ndarray] = None
    view_dist: Optional[np.ndarray] = None
    IFD_data: Optional[np.ndarray] = None
    IFA_data: Optional[np.ndarray] = None

    @property
    def n_flies(self) -> int:
        """Number of flies in this condition."""
        if self.vel_data is not None:
            return self.vel_data.shape[0]
        return 0

    @property
    def n_frames(self) -> int:
        """Number of frames in this condition."""
        if self.vel_data is not None:
            return self.vel_data.shape[1]
        return 0

    @property
    def fps(self) -> int:
        """Frames per second (constant)."""
        return 30

    @property
    def duration_s(self) -> float:
        """Duration in seconds."""
        return self.n_frames / self.fps

    def get_phase_data(self, phase: str, data_type: str = 'av_data') -> np.ndarray:
        """
        Extract data for a specific trial phase.

        Args:
            phase: 'baseline', 'dir1', 'dir2', or 'interval'
            data_type: Name of the data field to extract

        Returns:
            numpy array of shape (n_flies, n_phase_frames)
        """
        data = getattr(self, data_type, None)
        if data is None:
            raise ValueError(f"Data type '{data_type}' not available")

        if self.phase_markers is None:
            raise ValueError("Phase markers not available for this condition")

        phase_slice = self.phase_markers.get_slice(phase)
        return data[:, phase_slice]


@dataclass
class ExperimentMeta:
    """
    Metadata for a single experiment.

    Attributes:
        date: Experiment date
        time: Experiment time
        fly_strain: Genotype/strain name
        fly_age: Age of flies
        fly_sex: Sex ('F' or 'M')
        experimenter: Name of experimenter
        n_flies_arena: Number of flies in arena
        n_flies: Number of flies tracked
        n_flies_rm: Number of flies removed from analysis
        start_temp_ring: Initial ring temperature (C)
        end_temp_ring: Final ring temperature (C)
        start_temp_outside: Initial external temperature (C)
        end_temp_outside: Final external temperature (C)
        random_order: Order conditions were presented
        source_file: Original data filename
    """
    date: Optional[datetime] = None
    time: str = ''
    fly_strain: str = ''
    fly_age: str = ''
    fly_sex: str = ''
    experimenter: str = ''
    n_flies_arena: int = 0
    n_flies: int = 0
    n_flies_rm: int = 0
    start_temp_ring: float = 0.0
    end_temp_ring: float = 0.0
    start_temp_outside: float = 0.0
    end_temp_outside: float = 0.0
    random_order: List[int] = field(default_factory=list)
    source_file: str = ''


@dataclass
class Experiment:
    """
    Container for a single experiment's data.

    Attributes:
        meta: Experiment metadata
        acclim_off1: Pre-acclimatization data
        acclim_patt: Pattern acclimatization data
        acclim_off2: Post-acclimatization data
        conditions: Dict of condition data keyed by 'R{rep}_condition_{n}'
    """
    meta: ExperimentMeta
    acclim_off1: Dict[str, np.ndarray] = field(default_factory=dict)
    acclim_patt: Dict[str, np.ndarray] = field(default_factory=dict)
    acclim_off2: Dict[str, np.ndarray] = field(default_factory=dict)
    conditions: Dict[str, ConditionData] = field(default_factory=dict)

    @property
    def strain(self) -> str:
        """Strain name."""
        return self.meta.fly_strain

    @property
    def sex(self) -> str:
        """Sex ('F' or 'M')."""
        return self.meta.fly_sex

    def get_condition(self, condition_id: int, rep: int = 1) -> Optional[ConditionData]:
        """
        Get condition data by ID and repetition.

        Args:
            condition_id: Condition number (1-12)
            rep: Repetition (1 or 2)

        Returns:
            ConditionData or None if not found
        """
        key = f"R{rep}_condition_{condition_id}"
        return self.conditions.get(key)

    def list_conditions(self) -> List[str]:
        """List all available condition keys."""
        return list(self.conditions.keys())

    def get_all_conditions_for_id(self, condition_id: int) -> List[ConditionData]:
        """Get both repetitions of a condition."""
        conditions = []
        for rep in [1, 2]:
            cond = self.get_condition(condition_id, rep)
            if cond is not None:
                conditions.append(cond)
        return conditions


@dataclass
class ProtocolData:
    """
    Container for all data from a protocol.

    This is the top-level data structure matching the MATLAB DATA struct.

    Attributes:
        protocol_name: Protocol identifier (e.g., 'protocol_27')
        protocol_version: Data format version
        created_date: When the data was processed
        n_strains: Number of unique strains
        n_total_experiments: Total number of experiments
        n_total_flies: Total number of flies
        cond_array: Condition parameters matrix
        pattern_lut: Pattern metadata lookup table
        data: Nested dict of experiments by strain and sex
    """
    protocol_name: str
    protocol_version: str = '2.0'
    created_date: Optional[datetime] = None
    n_strains: int = 0
    n_total_experiments: int = 0
    n_total_flies: int = 0
    cond_array: Optional[np.ndarray] = None
    pattern_lut: Dict[str, PatternMetadata] = field(default_factory=dict)
    data: Dict[str, Dict[str, List[Experiment]]] = field(default_factory=dict)

    def get_strain_sex_data(self, strain: str, sex: str) -> List[Experiment]:
        """
        Get all experiments for a strain/sex combination.

        Args:
            strain: Strain name (hyphens will be converted to underscores)
            sex: 'F' or 'M'

        Returns:
            List of Experiment objects
        """
        strain = strain.replace('-', '_')
        if strain in self.data and sex in self.data[strain]:
            return self.data[strain][sex]
        return []

    def list_strains(self) -> List[str]:
        """List all strain names in the dataset."""
        return [k for k in self.data.keys() if not k.startswith('_')]

    def list_sexes(self, strain: str) -> List[str]:
        """List available sexes for a strain."""
        strain = strain.replace('-', '_')
        if strain in self.data:
            return list(self.data[strain].keys())
        return []

    def get_n_flies(self, strain: str, sex: str) -> int:
        """Get total number of flies for a strain/sex combination."""
        experiments = self.get_strain_sex_data(strain, sex)
        return sum(exp.meta.n_flies for exp in experiments)

    def get_n_experiments(self, strain: str, sex: str) -> int:
        """Get number of experiments for a strain/sex combination."""
        return len(self.get_strain_sex_data(strain, sex))

    def get_pattern_metadata(self, pattern_id: int) -> Optional[PatternMetadata]:
        """Get pattern metadata by ID."""
        key = f"P{pattern_id:02d}"
        return self.pattern_lut.get(key)


# Helper functions
def _safe_float(val: Any) -> Optional[float]:
    """Safely convert value to float, returning None for NaN/invalid."""
    if val is None:
        return None
    try:
        f = float(val)
        if np.isnan(f):
            return None
        return f
    except (TypeError, ValueError):
        return None


def _safe_int(val: Any) -> Optional[int]:
    """Safely convert value to int, returning None for NaN/invalid."""
    if val is None:
        return None
    try:
        f = float(val)
        if np.isnan(f):
            return None
        return int(f)
    except (TypeError, ValueError):
        return None

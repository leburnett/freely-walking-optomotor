"""
MATLAB .mat file loader for optomotor data.

This module provides the MATLoader class for loading MATLAB DATA structs
into Python data structures.
"""

import numpy as np
from scipy.io import loadmat
from pathlib import Path
from typing import Dict, Any, Optional, Union, List
from datetime import datetime
import warnings

from ..core.experiment import (
    PatternMetadata,
    PhaseMarkers,
    ConditionData,
    ExperimentMeta,
    Experiment,
    ProtocolData
)


class MATLoader:
    """
    Load optomotor experiment data from MATLAB .mat files.

    This loader handles the DATA struct format produced by
    comb_data_across_cohorts_cond_v2.m, converting it to Python
    data structures.

    Attributes:
        pattern_dir: Path to pattern files directory
        _pattern_lut: Loaded pattern lookup table

    Example:
        loader = MATLoader(pattern_dir='/path/to/patterns')
        data = loader.load_protocol_data('/path/to/results/protocol_27')

        # Or load a pre-combined DATA.mat file
        data = loader.load_data_file('/path/to/DATA.mat')
    """

    # Behavioral data fields to extract
    BEHAVIORAL_FIELDS = [
        'vel_data', 'fv_data', 'av_data', 'curv_data', 'dist_data',
        'dist_trav', 'heading_data', 'heading_wrap', 'x_data', 'y_data',
        'view_dist', 'IFD_data', 'IFA_data'
    ]

    def __init__(self, pattern_dir: Optional[str] = None):
        """
        Initialize loader with optional pattern directory.

        Args:
            pattern_dir: Path to directory containing pattern .mat files.
                        If provided, pattern metadata will be loaded.
        """
        self.pattern_dir = pattern_dir
        self._pattern_lut: Dict[str, PatternMetadata] = {}

        if pattern_dir:
            self._load_pattern_lut(pattern_dir)

    def _load_pattern_lut(self, pattern_dir: str) -> None:
        """Load pattern lookup table from MATLAB file."""
        lut_file = Path(pattern_dir) / 'PATTERN_LUT.mat'
        if lut_file.exists():
            try:
                mat_data = loadmat(str(lut_file), simplify_cells=True)
                lut = mat_data.get('PATTERN_LUT', {})

                for key, meta in lut.items():
                    if key.startswith('P') and isinstance(meta, dict):
                        self._pattern_lut[key] = PatternMetadata.from_matlab(meta)

            except Exception as e:
                warnings.warn(f"Failed to load pattern LUT: {e}")

    def load_protocol_data(self, protocol_dir: str,
                          verbose: bool = True) -> ProtocolData:
        """
        Load all data for a protocol from individual experiment files.

        This method scans a protocol directory for *_data.mat files and
        combines them into a single ProtocolData object.

        Args:
            protocol_dir: Path to protocol results directory
            verbose: Print progress messages

        Returns:
            ProtocolData object containing all experiments
        """
        protocol_path = Path(protocol_dir)
        protocol_name = protocol_path.name

        # Find all data files
        data_files = list(protocol_path.rglob('*_data.mat'))
        data_files = [f for f in data_files if 'DATA' not in f.name]

        if verbose:
            print(f"Loading {len(data_files)} experiment files from {protocol_name}")

        # Initialize protocol data
        protocol_data = ProtocolData(
            protocol_name=protocol_name,
            protocol_version='2.0',
            created_date=datetime.now(),
            n_strains=0,
            n_total_experiments=len(data_files),
            n_total_flies=0,
            cond_array=None,
            pattern_lut=self._pattern_lut.copy(),
            data={}
        )

        # Load each experiment
        for i, data_file in enumerate(data_files):
            if verbose:
                print(f"  [{i+1}/{len(data_files)}] {data_file.name}")

            experiment = self.load_single_experiment(data_file)
            if experiment is None:
                continue

            strain = experiment.strain.replace('-', '_')
            sex = experiment.sex

            if strain not in protocol_data.data:
                protocol_data.data[strain] = {}
            if sex not in protocol_data.data[strain]:
                protocol_data.data[strain][sex] = []

            protocol_data.data[strain][sex].append(experiment)
            protocol_data.n_total_flies += experiment.meta.n_flies

        protocol_data.n_strains = len([k for k in protocol_data.data.keys()
                                       if not k.startswith('_')])

        if verbose:
            print(f"Loaded {protocol_data.n_strains} strains, "
                  f"{protocol_data.n_total_flies} total flies")

        return protocol_data

    def load_data_file(self, file_path: Union[str, Path]) -> ProtocolData:
        """
        Load a pre-combined DATA.mat file.

        This loads a DATA struct that was previously saved by
        comb_data_across_cohorts_cond_v2.m.

        Args:
            file_path: Path to the DATA.mat file

        Returns:
            ProtocolData object
        """
        file_path = Path(file_path)

        try:
            mat_data = loadmat(str(file_path), simplify_cells=True)
        except Exception as e:
            raise ValueError(f"Failed to load {file_path}: {e}")

        if 'DATA' not in mat_data:
            raise ValueError(f"No 'DATA' variable found in {file_path}")

        return self._parse_data_struct(mat_data['DATA'])

    def _parse_data_struct(self, data_struct: Dict) -> ProtocolData:
        """Parse a MATLAB DATA struct into ProtocolData."""
        # Extract metadata
        metadata = data_struct.get('_metadata', {})
        pattern_lut_raw = data_struct.get('_pattern_lut', {})

        # Parse pattern LUT
        pattern_lut = {}
        if isinstance(pattern_lut_raw, dict):
            for key, meta in pattern_lut_raw.items():
                if key.startswith('P') and isinstance(meta, dict):
                    pattern_lut[key] = PatternMetadata.from_matlab(meta)

        # Merge with loaded pattern LUT
        pattern_lut.update(self._pattern_lut)

        # Initialize ProtocolData
        protocol_data = ProtocolData(
            protocol_name=str(metadata.get('protocol_name', 'unknown')),
            protocol_version=str(metadata.get('protocol_version', '2.0')),
            created_date=_parse_datetime(metadata.get('created_date')),
            n_strains=int(metadata.get('n_strains', 0)),
            n_total_experiments=int(metadata.get('n_total_experiments', 0)),
            n_total_flies=int(metadata.get('n_total_flies', 0)),
            cond_array=np.array(metadata.get('cond_array', [])),
            pattern_lut=pattern_lut,
            data={}
        )

        # Parse strain/sex/experiment data
        for key, value in data_struct.items():
            if key.startswith('_'):
                continue  # Skip metadata fields

            strain = key
            if not isinstance(value, dict):
                continue

            protocol_data.data[strain] = {}

            for sex, experiments in value.items():
                if not isinstance(experiments, (dict, list, np.ndarray)):
                    continue

                protocol_data.data[strain][sex] = []

                # Handle both single experiment and array of experiments
                if isinstance(experiments, dict):
                    experiments = [experiments]
                elif isinstance(experiments, np.ndarray):
                    if experiments.ndim == 0:
                        experiments = [experiments.item()]
                    else:
                        experiments = list(experiments)

                for exp_data in experiments:
                    experiment = self._parse_experiment(exp_data, pattern_lut)
                    if experiment is not None:
                        protocol_data.data[strain][sex].append(experiment)

        return protocol_data

    def load_single_experiment(self, file_path: Union[str, Path]) -> Optional[Experiment]:
        """
        Load a single experiment from a *_data.mat file.

        Args:
            file_path: Path to the experiment data file

        Returns:
            Experiment object or None if loading fails
        """
        try:
            mat_data = loadmat(str(file_path), simplify_cells=True)
        except Exception as e:
            warnings.warn(f"Failed to load {file_path}: {e}")
            return None

        # Extract required variables
        LOG = mat_data.get('LOG', {})
        comb_data = mat_data.get('comb_data', {})
        n_fly_data = mat_data.get('n_fly_data', [0, 0, 0])

        if not LOG or not comb_data:
            warnings.warn(f"Missing LOG or comb_data in {file_path}")
            return None

        # Parse metadata
        meta = self._parse_experiment_meta(LOG, n_fly_data, file_path)

        # Create experiment
        experiment = Experiment(meta=meta)

        # Load acclimatization periods
        for period in ['acclim_off1', 'acclim_patt', 'acclim_off2']:
            experiment.__dict__[period] = self._extract_period_data(
                LOG, comb_data, period
            )

        # Load condition data
        log_fields = sorted([k for k in LOG.keys() if k.startswith('log_')])
        n_cond = len(log_fields)

        for log_n, log_field in enumerate(log_fields, 1):
            log_entry = LOG[log_field]
            if not isinstance(log_entry, dict):
                continue

            condition = self._extract_condition_data(
                log_entry, comb_data, LOG, log_n, n_cond
            )
            if condition:
                rep = 1 if log_n <= n_cond // 2 else 2
                key = f"R{rep}_condition_{condition.condition_id}"
                experiment.conditions[key] = condition

        return experiment

    def _parse_experiment_meta(self, LOG: Dict, n_fly_data: List,
                               file_path: Path) -> ExperimentMeta:
        """Parse experiment metadata from LOG structure."""
        meta = LOG.get('meta', {})

        # Parse date
        date_val = meta.get('date')
        exp_date = _parse_datetime(date_val)

        return ExperimentMeta(
            date=exp_date,
            time=str(meta.get('time', '')),
            fly_strain=str(meta.get('fly_strain', 'unknown')),
            fly_age=str(meta.get('fly_age', 'unknown')),
            fly_sex=str(meta.get('fly_sex', 'unknown')),
            experimenter=str(meta.get('experimenter', 'unknown')),
            n_flies_arena=int(n_fly_data[0]) if len(n_fly_data) > 0 else 0,
            n_flies=int(n_fly_data[1]) if len(n_fly_data) > 1 else 0,
            n_flies_rm=int(n_fly_data[2]) if len(n_fly_data) > 2 else 0,
            start_temp_ring=float(meta.get('start_temp_ring', 0)),
            end_temp_ring=float(meta.get('end_temp_ring', 0)),
            start_temp_outside=float(meta.get('start_temp_outside', 0)),
            end_temp_outside=float(meta.get('end_temp_outside', 0)),
            random_order=list(meta.get('random_order', [])),
            source_file=str(file_path.name) if hasattr(file_path, 'name') else str(file_path)
        )

    def _extract_period_data(self, LOG: Dict, comb_data: Dict,
                             period: str) -> Dict[str, np.ndarray]:
        """Extract behavioral data for an acclimatization period."""
        period_log = LOG.get(period, {})
        result = {}

        # Get frame boundaries
        start_f = _get_frame_value(period_log, 'start_f', 0)
        start_f = max(start_f, 1) - 1  # Convert to 0-indexed

        if period == 'acclim_off1':
            stop_t = _get_frame_value(period_log, 'stop_t', 30, use_last=True)
            if stop_t < 3:
                stop_f = 600
            else:
                stop_f = _get_frame_value(period_log, 'stop_f', 600, use_last=True)
        elif period == 'acclim_off2':
            stop_f = None  # Use end of data
        else:
            stop_f = _get_frame_value(period_log, 'stop_f', None, use_last=True)

        # Extract each data field
        for field in self.BEHAVIORAL_FIELDS:
            if field in comb_data:
                data = np.atleast_2d(comb_data[field])
                if stop_f is None:
                    result[field] = data[:, start_f:]
                else:
                    result[field] = data[:, start_f:stop_f]

        return result

    def _extract_condition_data(self, log_entry: Dict, comb_data: Dict,
                                LOG: Dict, log_n: int, n_cond: int) -> Optional[ConditionData]:
        """Extract data for a single condition."""
        condition_id = int(log_entry.get('which_condition', 0))

        # Calculate frame boundaries with 10s baseline
        acclim_off1 = LOG.get('acclim_off1', {})
        stop_t = _get_frame_value(acclim_off1, 'stop_t', 30, use_last=True)

        framesb4 = 0 if (stop_t < 3 and log_n == 1) else 300

        start_f_arr = _ensure_array(log_entry.get('start_f', [1]))
        start_f = int(start_f_arr[0]) - framesb4 - 1  # Convert to 0-indexed

        stop_f_arr = _ensure_array(log_entry.get('stop_f', []))
        stop_f = int(stop_f_arr[-1]) if len(stop_f_arr) > 0 else None

        rep = 1 if log_n <= n_cond // 2 else 2

        # Create condition data
        condition = ConditionData(
            condition_id=condition_id,
            repetition=rep,
            trial_len=float(log_entry.get('trial_len', 15)),
            interval_dur=float(log_entry.get('interval_dur', 20)),
            optomotor_pattern=int(log_entry.get('optomotor_pattern', 0)),
            optomotor_speed=int(log_entry.get('optomotor_speed', 0)),
            interval_pattern=int(log_entry.get('interval_pattern', 0)),
            interval_speed=int(log_entry.get('interval_speed', 0)),
            start_flicker_f=int(start_f_arr[-1]) - (start_f + 1) if len(start_f_arr) > 0 else 0
        )

        # Create phase markers
        if len(start_f_arr) >= 2:
            condition.phase_markers = PhaseMarkers(
                baseline_start=1,
                baseline_end=framesb4,
                dir1_start=framesb4 + 1,
                dir1_end=int(start_f_arr[1]) - (start_f + 1),
                dir2_start=int(start_f_arr[1]) - (start_f + 1) + 1,
                dir2_end=int(start_f_arr[-1]) - (start_f + 1) if len(start_f_arr) >= 3 else (stop_f - start_f if stop_f else 0),
                interval_start=int(start_f_arr[-1]) - (start_f + 1) + 1 if len(start_f_arr) >= 3 else (stop_f - start_f + 1 if stop_f else 0),
                interval_end=(stop_f - start_f) if stop_f else 0
            )

        # Link pattern metadata
        patt_field = f"P{condition.optomotor_pattern:02d}"
        if patt_field in self._pattern_lut:
            condition.pattern_meta = self._pattern_lut[patt_field]

        # Extract behavioral data
        for field in self.BEHAVIORAL_FIELDS:
            if field in comb_data:
                data = np.atleast_2d(comb_data[field])
                if stop_f is None:
                    setattr(condition, field, data[:, start_f:])
                else:
                    setattr(condition, field, data[:, start_f:stop_f])

        return condition

    def _parse_experiment(self, exp_data: Dict,
                         pattern_lut: Dict[str, PatternMetadata]) -> Optional[Experiment]:
        """Parse a single experiment from DATA struct format."""
        if not isinstance(exp_data, dict):
            return None

        # Parse metadata
        meta_data = exp_data.get('meta', {})
        meta = ExperimentMeta(
            date=_parse_datetime(meta_data.get('date')),
            time=str(meta_data.get('time', '')),
            fly_strain=str(meta_data.get('fly_strain', '')),
            fly_age=str(meta_data.get('fly_age', '')),
            fly_sex=str(meta_data.get('fly_sex', '')),
            experimenter=str(meta_data.get('experimenter', '')),
            n_flies_arena=int(meta_data.get('n_flies_arena', 0)),
            n_flies=int(meta_data.get('n_flies', 0)),
            n_flies_rm=int(meta_data.get('n_flies_rm', 0)),
            start_temp_ring=float(meta_data.get('start_temp_ring', 0)),
            end_temp_ring=float(meta_data.get('end_temp_ring', 0)),
            start_temp_outside=float(meta_data.get('start_temp_outside', 0)),
            end_temp_outside=float(meta_data.get('end_temp_outside', 0)),
            random_order=list(meta_data.get('random_order', [])),
            source_file=str(meta_data.get('source_file', ''))
        )

        experiment = Experiment(meta=meta)

        # Load acclimatization periods
        for period in ['acclim_off1', 'acclim_patt', 'acclim_off2']:
            period_data = exp_data.get(period, {})
            if isinstance(period_data, dict):
                experiment.__dict__[period] = {
                    k: np.atleast_2d(v) for k, v in period_data.items()
                    if k in self.BEHAVIORAL_FIELDS
                }

        # Load conditions
        for key, value in exp_data.items():
            if key.startswith('R') and '_condition_' in key:
                condition = self._parse_condition(key, value, pattern_lut)
                if condition:
                    experiment.conditions[key] = condition

        return experiment

    def _parse_condition(self, key: str, cond_data: Dict,
                        pattern_lut: Dict[str, PatternMetadata]) -> Optional[ConditionData]:
        """Parse condition data from DATA struct format."""
        if not isinstance(cond_data, dict):
            return None

        # Parse key to get condition_id and rep
        parts = key.split('_')
        rep = int(parts[0][1])  # R1 -> 1
        condition_id = int(parts[-1])

        condition = ConditionData(
            condition_id=condition_id,
            repetition=rep,
            trial_len=float(cond_data.get('trial_len', 15)),
            interval_dur=float(cond_data.get('interval_dur', 20)),
            optomotor_pattern=int(cond_data.get('optomotor_pattern', 0)),
            optomotor_speed=int(cond_data.get('optomotor_speed', 0)),
            interval_pattern=int(cond_data.get('interval_pattern', 0)),
            interval_speed=int(cond_data.get('interval_speed', 0)),
            start_flicker_f=int(cond_data.get('start_flicker_f', 0))
        )

        # Parse phase markers if present
        markers_data = cond_data.get('phase_markers')
        if isinstance(markers_data, dict):
            condition.phase_markers = PhaseMarkers.from_matlab(markers_data)

        # Parse pattern metadata if present
        pattern_meta_data = cond_data.get('pattern_meta')
        if isinstance(pattern_meta_data, dict):
            condition.pattern_meta = PatternMetadata.from_matlab(pattern_meta_data)
        else:
            # Try to get from lookup
            patt_field = f"P{condition.optomotor_pattern:02d}"
            condition.pattern_meta = pattern_lut.get(patt_field)

        # Extract behavioral data
        for field in self.BEHAVIORAL_FIELDS:
            if field in cond_data:
                setattr(condition, field, np.atleast_2d(cond_data[field]))

        return condition


# Helper functions
def _parse_datetime(val: Any) -> Optional[datetime]:
    """Parse various date formats to datetime."""
    if val is None:
        return None
    if isinstance(val, datetime):
        return val
    if isinstance(val, str):
        for fmt in ['%d-%b-%Y', '%Y-%m-%d', '%d/%m/%Y']:
            try:
                return datetime.strptime(val, fmt)
            except ValueError:
                continue
    return None


def _get_frame_value(log: Dict, key: str, default: Any = 0,
                    use_last: bool = False) -> Any:
    """Get frame value from log entry, handling arrays."""
    val = log.get(key, default)
    if val is None:
        return default
    if isinstance(val, (list, np.ndarray)):
        if len(val) == 0:
            return default
        return val[-1] if use_last else val[0]
    return val


def _ensure_array(val: Any) -> np.ndarray:
    """Ensure value is a numpy array."""
    if val is None:
        return np.array([])
    if isinstance(val, np.ndarray):
        return val.flatten()
    if isinstance(val, (list, tuple)):
        return np.array(val)
    return np.array([val])

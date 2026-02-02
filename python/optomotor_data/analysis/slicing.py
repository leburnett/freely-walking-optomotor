"""
Data slicing and extraction utilities for optomotor data.

This module provides functions for extracting and combining data
across experiments, computing statistics, and binning time series.
"""

import numpy as np
from typing import Dict, List, Optional, Tuple, Union

from ..core.experiment import ProtocolData, Experiment, ConditionData


def get_condition_data_across_experiments(
    protocol_data: ProtocolData,
    strain: str,
    sex: str,
    condition_id: int,
    data_type: str = 'av_data',
    average_reps: bool = True
) -> np.ndarray:
    """
    Combine data for a specific condition across all experiments.

    This function extracts behavioral data from all experiments for a
    given strain/sex combination and concatenates flies across experiments.

    Args:
        protocol_data: ProtocolData object containing all experiments
        strain: Strain name (hyphens will be converted to underscores)
        sex: 'F' or 'M'
        condition_id: Condition number (1-12 typically)
        data_type: Name of behavioral metric to extract
                  Options: 'vel_data', 'fv_data', 'av_data', 'curv_data',
                          'dist_data', 'heading_data', 'x_data', 'y_data', etc.
        average_reps: If True, average R1 and R2 repetitions for each fly.
                     If False, only return R1 data.

    Returns:
        numpy array of shape (n_total_flies, n_frames)
        Returns empty array if no data found.

    Example:
        # Get angular velocity for condition 1 across all experiments
        av = get_condition_data_across_experiments(
            data, 'jfrc100_es_shibire_kir', 'F', 1, 'av_data'
        )

        # Compute mean across flies
        mean_av = np.nanmean(av, axis=0)
    """
    experiments = protocol_data.get_strain_sex_data(strain, sex)
    all_data = []

    for exp in experiments:
        cond1 = exp.get_condition(condition_id, rep=1)
        cond2 = exp.get_condition(condition_id, rep=2)

        if cond1 is None:
            continue

        data1 = getattr(cond1, data_type, None)
        if data1 is None:
            continue

        if average_reps and cond2 is not None:
            data2 = getattr(cond2, data_type, None)
            if data2 is not None:
                # Trim to same length and average
                min_len = min(data1.shape[1], data2.shape[1])
                data = (data1[:, :min_len] + data2[:, :min_len]) / 2
                all_data.append(data)
            else:
                all_data.append(data1)
        else:
            all_data.append(data1)

    if not all_data:
        return np.array([])

    # Combine across experiments, handling different frame lengths
    max_frames = max(d.shape[1] for d in all_data)
    combined = []

    for data in all_data:
        if data.shape[1] < max_frames:
            # Pad with NaN for shorter recordings
            padded = np.full((data.shape[0], max_frames), np.nan)
            padded[:, :data.shape[1]] = data
            combined.append(padded)
        else:
            combined.append(data)

    return np.vstack(combined)


def compute_mean_sem(data: np.ndarray, axis: int = 0) -> Tuple[np.ndarray, np.ndarray]:
    """
    Compute mean and standard error of the mean, ignoring NaN values.

    Args:
        data: Input array
        axis: Axis along which to compute statistics
              axis=0: across flies (returns time series)
              axis=1: across time (returns per-fly values)

    Returns:
        Tuple of (mean, sem) arrays

    Example:
        # Compute mean and SEM across flies
        mean, sem = compute_mean_sem(av_data, axis=0)

        # Plot with shaded error
        plt.plot(mean)
        plt.fill_between(range(len(mean)), mean-sem, mean+sem, alpha=0.3)
    """
    mean = np.nanmean(data, axis=axis)
    n = np.sum(~np.isnan(data), axis=axis)
    std = np.nanstd(data, axis=axis, ddof=1)  # Sample std
    sem = std / np.sqrt(n)
    return mean, sem


def bin_timeseries(data: np.ndarray,
                   window_size: int = 15,
                   step_size: int = 5,
                   method: str = 'mean') -> np.ndarray:
    """
    Bin time series data using a sliding window.

    Args:
        data: Input array of shape (n_samples,) or (n_flies, n_frames)
        window_size: Number of frames per bin
        step_size: Step between bin centers
        method: Aggregation method ('mean', 'median', 'std', 'max', 'min')

    Returns:
        Binned data array with shape (n_flies, n_bins) or (n_bins,)

    Example:
        # Bin angular velocity with 0.5s window (15 frames) and 5-frame step
        binned_av = bin_timeseries(av_data, window_size=15, step_size=5)
    """
    if data.ndim == 1:
        data = data.reshape(1, -1)
        squeeze_output = True
    else:
        squeeze_output = False

    n_flies, n_frames = data.shape
    n_bins = (n_frames - window_size) // step_size + 1

    # Select aggregation function
    agg_funcs = {
        'mean': np.nanmean,
        'median': np.nanmedian,
        'std': np.nanstd,
        'max': np.nanmax,
        'min': np.nanmin
    }
    agg_func = agg_funcs.get(method, np.nanmean)

    binned = np.zeros((n_flies, n_bins))
    for i in range(n_bins):
        start = i * step_size
        end = start + window_size
        binned[:, i] = agg_func(data[:, start:end], axis=1)

    if squeeze_output:
        return binned.squeeze()
    return binned


def extract_phase_statistics(
    protocol_data: ProtocolData,
    strain: str,
    sex: str,
    condition_id: int,
    data_type: str = 'av_data',
    average_reps: bool = True
) -> Dict[str, Tuple[float, float]]:
    """
    Extract mean and SEM for each trial phase.

    This function computes statistics for baseline, dir1, dir2, and
    interval phases. For angular velocity, dir2 is automatically sign-flipped
    to align with dir1 (since the stimulus moves in opposite directions).

    Args:
        protocol_data: ProtocolData object
        strain: Strain name
        sex: 'F' or 'M'
        condition_id: Condition number
        data_type: Behavioral metric ('av_data', 'fv_data', etc.)
        average_reps: Whether to average R1 and R2 repetitions

    Returns:
        Dict mapping phase names to (mean, sem) tuples.
        Phases: 'baseline', 'dir1', 'dir2', 'dir2_flipped', 'interval'

    Example:
        stats = extract_phase_statistics(data, strain, 'F', 1, 'av_data')
        print(f"Direction 1: {stats['dir1'][0]:.2f} +/- {stats['dir1'][1]:.2f} deg/s")
    """
    # Get all data for this condition
    full_data = get_condition_data_across_experiments(
        protocol_data, strain, sex, condition_id, data_type, average_reps
    )

    if full_data.size == 0:
        return {}

    # Get phase markers from first experiment with this condition
    experiments = protocol_data.get_strain_sex_data(strain, sex)
    markers = None
    for exp in experiments:
        cond = exp.get_condition(condition_id, rep=1)
        if cond and cond.phase_markers:
            markers = cond.phase_markers
            break

    if markers is None:
        # Use default phase boundaries (at 30 fps)
        # baseline: 10s, dir1: ~15s, dir2: ~15s
        phases = {
            'baseline': full_data[:, :300],
            'dir1': full_data[:, 300:750],
            'dir2': full_data[:, 750:1200],
        }
        if full_data.shape[1] > 1200:
            phases['interval'] = full_data[:, 1200:]
    else:
        phases = {
            'baseline': full_data[:, markers.baseline_start-1:markers.baseline_end],
            'dir1': full_data[:, markers.dir1_start-1:markers.dir1_end],
            'dir2': full_data[:, markers.dir2_start-1:markers.dir2_end],
        }
        if markers.interval_end > markers.interval_start:
            phases['interval'] = full_data[:, markers.interval_start-1:markers.interval_end]

    results = {}

    for phase_name, phase_data in phases.items():
        if phase_data is not None and phase_data.size > 0:
            # Compute mean for each fly across time, then stats across flies
            fly_means = np.nanmean(phase_data, axis=1)
            mean = np.nanmean(fly_means)
            n = np.sum(~np.isnan(fly_means))
            std = np.nanstd(fly_means, ddof=1)
            sem = std / np.sqrt(n) if n > 0 else np.nan
            results[phase_name] = (mean, sem)

            # For dir2, also compute flipped version (for angular velocity alignment)
            if phase_name == 'dir2':
                flipped_means = -fly_means
                mean_flipped = np.nanmean(flipped_means)
                sem_flipped = std / np.sqrt(n) if n > 0 else np.nan
                results['dir2_flipped'] = (mean_flipped, sem_flipped)

    return results


def get_response_index(
    protocol_data: ProtocolData,
    strain: str,
    sex: str,
    condition_id: int,
    data_type: str = 'av_data'
) -> Tuple[float, float]:
    """
    Compute optomotor response index for a condition.

    The response index is defined as the difference between dir1 and dir2
    responses, normalized by their sum. For angular velocity, this gives
    a measure between -1 and 1, where 1 indicates perfect following of
    the stimulus.

    Response Index = (dir1 - dir2) / (|dir1| + |dir2|)

    For angular velocity specifically, since dir2 has opposite sign
    (stimulus moves opposite direction), this becomes:
    Response Index = (dir1 + dir2_raw) / (|dir1| + |dir2_raw|)

    Args:
        protocol_data: ProtocolData object
        strain: Strain name
        sex: 'F' or 'M'
        condition_id: Condition number
        data_type: Behavioral metric

    Returns:
        Tuple of (response_index, sem)
    """
    stats = extract_phase_statistics(
        protocol_data, strain, sex, condition_id, data_type
    )

    if 'dir1' not in stats or 'dir2' not in stats:
        return (np.nan, np.nan)

    dir1_mean = stats['dir1'][0]
    dir2_mean = stats['dir2'][0]

    # For av_data, the fly should turn in opposite directions for dir1/dir2
    # So we expect dir1 > 0 and dir2 < 0 (or vice versa)
    # Response index = (dir1 - dir2) / (|dir1| + |dir2|)
    denominator = abs(dir1_mean) + abs(dir2_mean)
    if denominator < 1e-10:
        return (0.0, np.nan)

    ri = (dir1_mean - dir2_mean) / denominator

    # Propagate error (simplified)
    dir1_sem = stats['dir1'][1]
    dir2_sem = stats['dir2'][1]
    # Approximate SEM for ratio using first-order Taylor expansion
    ri_sem = np.sqrt(dir1_sem**2 + dir2_sem**2) / denominator

    return (ri, ri_sem)


def compare_strains(
    protocol_data: ProtocolData,
    strains: List[str],
    sex: str,
    condition_id: int,
    data_type: str = 'av_data'
) -> Dict[str, Dict[str, Tuple[float, float]]]:
    """
    Compare phase statistics across multiple strains.

    Args:
        protocol_data: ProtocolData object
        strains: List of strain names to compare
        sex: 'F' or 'M'
        condition_id: Condition number
        data_type: Behavioral metric

    Returns:
        Dict mapping strain names to phase statistics dicts

    Example:
        comparison = compare_strains(
            data,
            ['control_strain', 'experimental_strain'],
            'F', 1, 'av_data'
        )
        for strain, stats in comparison.items():
            print(f"{strain} dir1: {stats['dir1'][0]:.2f}")
    """
    results = {}
    for strain in strains:
        stats = extract_phase_statistics(
            protocol_data, strain, sex, condition_id, data_type
        )
        if stats:
            results[strain] = stats
    return results

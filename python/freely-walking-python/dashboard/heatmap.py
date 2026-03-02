"""Statistical heatmap computation for the summary tab.

Replicates the MATLAB make_summary_heat_maps_p27 / plot_pval_heatmap
workflow: Welch's t-tests comparing each strain to a control, with
Benjamini-Yekutieli FDR correction.
"""

import numpy as np
import pandas as pd
from scipy import stats

from dashboard.constants import (
    CONTROL_STRAIN,
    DOWNSAMPLE_FACTOR,
    FDR_Q,
    HEATMAP_METRICS,
)

# Frame indices used for metric computation (raw, pre-downsample values).
# Parquet stores every DOWNSAMPLE_FACTOR-th frame starting at 0.
_STIM_START = 300
_STIM_END = 1200
_ONSET_POST_START = 300
_ONSET_POST_END = 390
_ONSET_PRE_START = 210
_ONSET_PRE_END = 300
_DIRECTION_CHANGE = 750
_EARLY_TURN_START = 315
_EARLY_TURN_END = 450
_DIST_10S_START = 570
_DIST_10S_END = 600
_DIST_END_START = 1170
_DIST_END_END = 1200
_SMOOTH_WINDOW = 15  # moving-average window for turning metrics
_FLIP_START = 762  # start of sign-flip region (second half of stimulus)
_FLIP_END = 1210


def _frame_mask(frames: np.ndarray, start: int, end: int) -> np.ndarray:
    """Boolean mask for frames in [start, end] (inclusive)."""
    return (frames >= start) & (frames <= end)


def _smooth(arr: np.ndarray, window: int = _SMOOTH_WINDOW) -> np.ndarray:
    """Simple moving average (same length, edge-padded)."""
    if len(arr) < window:
        return arr
    kernel = np.ones(window) / window
    return np.convolve(arr, kernel, mode="same")


def compute_fly_metrics(
    frames: np.ndarray,
    fv: np.ndarray,
    curv: np.ndarray,
    dist: np.ndarray,
) -> np.ndarray:
    """Compute 6 scalar metrics for a single fly/condition.

    Parameters
    ----------
    frames : raw frame numbers (multiples of DOWNSAMPLE_FACTOR)
    fv, curv, dist : metric arrays aligned with *frames*

    Returns
    -------
    np.ndarray of shape (6,) — one value per HEATMAP_METRICS entry.
    NaN for any metric that cannot be computed.
    """
    result = np.full(6, np.nan)

    # 1. Avg FV (stimulus): mean fv for frames 300-1200
    m = _frame_mask(frames, _STIM_START, _STIM_END)
    if m.any():
        result[0] = np.nanmean(fv[m])

    # 2. ΔFV at onset: normalized change
    pre = _frame_mask(frames, _ONSET_PRE_START, _ONSET_PRE_END - 1)  # 210:299
    post = _frame_mask(frames, _ONSET_POST_START, _ONSET_POST_END - 1)  # 300:389
    if pre.any() and post.any():
        mean_pre = np.nanmean(fv[pre])
        mean_post = np.nanmean(fv[post])
        denom = mean_post + mean_pre
        if abs(denom) > 1e-10:
            result[1] = (mean_post - mean_pre) / denom

    # 3 & 4. Turning metrics: smooth curv, flip sign for second half
    smoothed = _smooth(curv.copy())
    flip_mask = _frame_mask(frames, _FLIP_START, _FLIP_END)
    smoothed[flip_mask] = -smoothed[flip_mask]

    # 3. Avg Turning (stimulus): mean of smoothed+flipped, frames 300-1200
    stim_mask = _frame_mask(frames, _STIM_START, _STIM_END)
    if stim_mask.any():
        result[2] = np.nanmean(smoothed[stim_mask])

    # 4. Early Turning (CW): mean of smoothed+flipped, frames 315-450
    early_mask = _frame_mask(frames, _EARLY_TURN_START, _EARLY_TURN_END)
    if early_mask.any():
        result[3] = np.nanmean(smoothed[early_mask])

    # 5 & 6. Movement towards centre: inverted baseline-subtract
    # (positive = movement toward centre)
    baseline_mask = frames == _STIM_START  # frame 300
    if baseline_mask.any():
        baseline_val = dist[baseline_mask][0]
        movement = baseline_val - dist  # flip sign: toward centre is positive

        # 5. Movement towards centre (10s): max in frames 570-600
        m10 = _frame_mask(frames, _DIST_10S_START, _DIST_10S_END)
        if m10.any():
            result[4] = np.nanmax(movement[m10])

        # 6. Movement towards centre (end): max in frames 1170-1200
        mend = _frame_mask(frames, _DIST_END_START, _DIST_END_END)
        if mend.any():
            result[5] = np.nanmax(movement[mend])

    return result


def _collect_strain_metrics(
    store,
    strain: str,
    condition_id: int,
    apply_qc: bool = True,
    rep_mode: str = "average",
) -> np.ndarray:
    """Compute per-fly metric array for one strain/condition.

    Returns shape (n_flies, 6). If rep_mode == "average", R1 and R2 are
    averaged per fly before metric computation.
    """
    df = store.load_per_fly(strain)
    if df.empty:
        return np.empty((0, 6))

    mask = df["condition"] == condition_id
    if apply_qc:
        mask &= df["qc_passed"]
    subset = df[mask]

    if subset.empty:
        return np.empty((0, 6))

    if rep_mode == "average":
        # Average R1 & R2 per fly per frame
        grouped = (
            subset.groupby(["fly_idx", "frame"])[["fv_data", "curv_data", "dist_data"]]
            .mean()
            .reset_index()
        )
        fly_ids = sorted(grouped["fly_idx"].unique())
        metrics = []
        for fly_idx in fly_ids:
            fly_df = grouped[grouped["fly_idx"] == fly_idx].sort_values("frame")
            metrics.append(compute_fly_metrics(
                fly_df["frame"].values,
                fly_df["fv_data"].values,
                fly_df["curv_data"].values,
                fly_df["dist_data"].values,
            ))
    else:
        # Treat each rep as independent
        fly_reps = sorted(subset.groupby(["fly_idx", "rep"]).groups.keys())
        metrics = []
        for fly_idx, rep in fly_reps:
            fly_df = subset[(subset["fly_idx"] == fly_idx) & (subset["rep"] == rep)].sort_values("frame")
            metrics.append(compute_fly_metrics(
                fly_df["frame"].values,
                fly_df["fv_data"].values,
                fly_df["curv_data"].values,
                fly_df["dist_data"].values,
            ))

    return np.array(metrics) if metrics else np.empty((0, 6))


def benjamini_yekutieli_fdr(pvalues: np.ndarray, q: float = FDR_Q) -> np.ndarray:
    """Benjamini-Yekutieli FDR correction ('dep' method).

    Returns boolean array: True where null hypothesis is rejected.
    Handles NaN p-values (treated as non-rejected).
    """
    p = np.asarray(pvalues, dtype=float).ravel()
    m = len(p)
    if m == 0:
        return np.array([], dtype=bool)

    # Track valid (non-NaN) positions
    valid = ~np.isnan(p)
    rejected = np.zeros(m, dtype=bool)
    p_valid = p[valid]
    m_valid = len(p_valid)
    if m_valid == 0:
        return rejected

    # Harmonic number c(m) for 'dep' method
    c_m = np.sum(1.0 / np.arange(1, m_valid + 1))

    # Sort p-values
    sort_idx = np.argsort(p_valid)
    sorted_p = p_valid[sort_idx]

    # BH-Y thresholds: (k / (m * c_m)) * q
    thresholds = np.arange(1, m_valid + 1) / (m_valid * c_m) * q

    # Find largest k where p_(k) <= threshold_(k)
    below = sorted_p <= thresholds
    if below.any():
        k_max = np.max(np.where(below)[0])
        rej_sorted = np.zeros(m_valid, dtype=bool)
        rej_sorted[:k_max + 1] = True
        rej_valid = np.zeros(m_valid, dtype=bool)
        rej_valid[sort_idx] = rej_sorted
        rejected[valid] = rej_valid

    return rejected


def _pvalue_to_intensity(p: float) -> float:
    """Map a p-value to a 0–1 intensity using continuous -log10 scaling.

    Mapping: p >= 0.05 → 0 (white), p = 1e-8 or smaller → 1 (fully saturated).
    Intermediate values scale linearly on -log10: -log10(0.05) ≈ 1.3 to -log10(1e-8) = 8.
    """
    if np.isnan(p) or p >= 0.05:
        return 0.0
    # Clamp to avoid log(0)
    p_clamped = max(p, 1e-12)
    neg_log = -np.log10(p_clamped)
    # Linear scale: -log10(0.05)≈1.3 maps to 0, -log10(1e-8)=8 maps to 1
    lo, hi = 1.3, 8.0
    intensity = (neg_log - lo) / (hi - lo)
    return float(np.clip(intensity, 0.0, 1.0))


def compute_heatmap_data(
    store,
    condition_id: int,
    apply_qc: bool = True,
    rep_mode: str = "average",
) -> dict:
    """Compute full heatmap data for one condition.

    Returns dict with keys:
        z_matrix     : np.ndarray (n_strains, 6) — signed intensity values [-1, 1]
        p_matrix     : np.ndarray (n_strains, 6) — raw p-values
        strain_list  : list[str] — strain names (rows)
        metric_names : list[str] — metric labels (columns)
        per_fly_data : dict[str, np.ndarray] — strain → (n_flies, 6) metric arrays
        control_data : np.ndarray — (n_control_flies, 6)
        direction    : np.ndarray (n_strains, 6) — +1 or -1 (target vs control)
    """
    strains = store.get_strains()
    # Exclude control strain from rows
    test_strains = [s for s in strains if s != CONTROL_STRAIN]

    # Compute control metrics
    control_metrics = _collect_strain_metrics(store, CONTROL_STRAIN, condition_id, apply_qc, rep_mode)

    # Compute per-strain metrics and t-tests
    per_fly_data = {CONTROL_STRAIN: control_metrics}
    n_metrics = len(HEATMAP_METRICS)
    n_strains = len(test_strains)
    p_matrix = np.full((n_strains, n_metrics), np.nan)
    direction = np.zeros((n_strains, n_metrics))

    for i, strain in enumerate(test_strains):
        strain_metrics = _collect_strain_metrics(store, strain, condition_id, apply_qc, rep_mode)
        per_fly_data[strain] = strain_metrics

        for j in range(n_metrics):
            ctrl_vals = control_metrics[:, j]
            test_vals = strain_metrics[:, j]
            # Remove NaNs
            ctrl_valid = ctrl_vals[~np.isnan(ctrl_vals)]
            test_valid = test_vals[~np.isnan(test_vals)]

            if len(ctrl_valid) >= 2 and len(test_valid) >= 2:
                t_stat, p_val = stats.ttest_ind(test_valid, ctrl_valid, equal_var=False)
                p_matrix[i, j] = p_val
                direction[i, j] = 1.0 if np.mean(test_valid) > np.mean(ctrl_valid) else -1.0

    # FDR correction across all tests
    all_p = p_matrix.ravel()
    rejected = benjamini_yekutieli_fdr(all_p, q=FDR_Q)
    rejected = rejected.reshape(p_matrix.shape)

    # Build z_matrix: direction * continuous intensity from -log10(p)
    z_matrix = np.zeros_like(p_matrix)
    for i in range(n_strains):
        for j in range(n_metrics):
            intensity = _pvalue_to_intensity(p_matrix[i, j])
            z_matrix[i, j] = direction[i, j] * intensity

    return {
        "z_matrix": z_matrix,
        "p_matrix": p_matrix,
        "rejected": rejected,
        "strain_list": test_strains,
        "metric_names": HEATMAP_METRICS,
        "per_fly_data": per_fly_data,
        "control_data": control_metrics,
        "direction": direction,
    }

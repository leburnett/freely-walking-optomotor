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


def _compute_fv_curv_metrics(
    frames: np.ndarray,
    fv: np.ndarray,
    curv: np.ndarray,
) -> np.ndarray:
    """Compute FV and turning metrics (indices 0-3) for one fly.

    These metrics use mean(), so averaging reps before computing is
    equivalent to the MATLAB approach (compute per rep, then average).

    Returns np.ndarray of shape (4,).
    """
    result = np.full(4, np.nan)

    # 1. Avg FV (stimulus): mean fv for frames 300-1200
    # MATLAB: welch_ttest_for_rng(cond_data, ..., 300:1200)
    m = _frame_mask(frames, _STIM_START, _STIM_END)
    if m.any():
        result[0] = np.nanmean(fv[m])

    # 2. ΔFV at onset: normalized change (post-pre)/(post+pre)
    # MATLAB: welch_ttest_for_change(..., 210:300, 300:390, "norm")
    pre = _frame_mask(frames, _ONSET_PRE_START, _ONSET_PRE_END - 1)  # 210:299
    post = _frame_mask(frames, _ONSET_POST_START, _ONSET_POST_END - 1)  # 300:389
    if pre.any() and post.any():
        mean_pre = np.nanmean(fv[pre])
        mean_post = np.nanmean(fv[post])
        denom = mean_post + mean_pre
        if abs(denom) > 1e-10:
            result[1] = (mean_post - mean_pre) / denom

    # 3 & 4. Turning metrics: smooth curv, flip sign for second half
    # MATLAB: movmean per row, then flip 762:1210, then welch_ttest_for_rng
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

    return result


def _compute_dist_metric_per_rep(
    frames: np.ndarray,
    dist: np.ndarray,
) -> np.ndarray:
    """Compute distance metrics for a single rep.

    MATLAB approach (welch_ttest_for_rng_min): find min() per rep in
    the frame range, THEN average across reps. So this function returns
    the per-rep min values that will be averaged later.

    Returns np.ndarray of shape (2,) — [min_delta_10s, min_delta_end].
    """
    result = np.full(2, np.nan)

    # Baseline-subtract: dist_data_delta = dist_data - dist_data(:, 300)
    # MATLAB: cond_data = cond_data - cond_data(:, 300)
    baseline_mask = frames == _STIM_START  # frame 300
    if not baseline_mask.any():
        return result

    baseline_val = dist[baseline_mask][0]
    dist_delta = dist - baseline_val  # negative = toward centre

    # 5. Movement towards centre (10s): min of delta in frames 570-600
    # MATLAB: welch_ttest_for_rng_min(cond_data_delta, ..., 570:600)
    m10 = _frame_mask(frames, _DIST_10S_START, _DIST_10S_END)
    if m10.any():
        result[0] = np.nanmin(dist_delta[m10])

    # 6. Movement towards centre (end): min of delta in frames 1170-1200
    # MATLAB: welch_ttest_for_rng_min(cond_data_delta, ..., 1170:1200)
    mend = _frame_mask(frames, _DIST_END_START, _DIST_END_END)
    if mend.any():
        result[1] = np.nanmin(dist_delta[mend])

    return result


def _collect_strain_metrics(
    store,
    strain: str,
    condition_id: int,
    apply_qc: bool = True,
    rep_mode: str = "average",
) -> np.ndarray:
    """Compute per-fly metric array for one strain/condition.

    Returns shape (n_flies, 6).

    Matches the MATLAB pipeline:
    - Metrics 0-3 (FV, turning): mean_every_two_rows then mean per fly
      (equivalent to averaging reps first, then computing mean).
    - Metrics 4-5 (distance): min per rep first, then average across reps
      per fly (welch_ttest_for_rng_min.m).
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

    # --- FV & curv metrics (0-3): average reps first, then compute ---
    # For mean-based metrics, averaging reps before computing is equivalent
    # to the MATLAB approach (compute per rep, then average).
    avg_reps = (
        subset.groupby(["cohort_id", "fly_idx", "frame"])[["fv_data", "curv_data"]]
        .mean()
        .reset_index()
    )

    # --- Distance metrics (4-5): min per rep, then average across reps ---
    # MATLAB: min(d') per rep, then mean_every_two_rows
    # Must compute per-rep first.

    # Build per-fly results using efficient groupby iteration
    fly_keys = sorted(
        avg_reps.groupby(["cohort_id", "fly_idx"]).groups.keys()
    )

    metrics = np.full((len(fly_keys), 6), np.nan)

    for i, (cohort_id, fly_idx) in enumerate(fly_keys):
        # FV + curv metrics from rep-averaged data
        fly_avg = avg_reps[
            (avg_reps["cohort_id"] == cohort_id) & (avg_reps["fly_idx"] == fly_idx)
        ].sort_values("frame")

        fv_curv = _compute_fv_curv_metrics(
            fly_avg["frame"].values,
            fly_avg["fv_data"].values,
            fly_avg["curv_data"].values,
        )
        metrics[i, :4] = fv_curv

        # Distance metrics: compute per rep, then average
        fly_reps = subset[
            (subset["cohort_id"] == cohort_id) & (subset["fly_idx"] == fly_idx)
        ]
        rep_ids = sorted(fly_reps["rep"].unique())
        rep_dist_vals = []
        for rep_id in rep_ids:
            rep_df = fly_reps[fly_reps["rep"] == rep_id].sort_values("frame")
            rep_dist = _compute_dist_metric_per_rep(
                rep_df["frame"].values,
                rep_df["dist_data"].values,
            )
            rep_dist_vals.append(rep_dist)

        if rep_dist_vals:
            # Average min values across reps (MATLAB: mean_every_two_rows)
            metrics[i, 4:6] = np.nanmean(rep_dist_vals, axis=0)

    return metrics


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
    from dashboard.constants import HEATMAP_STRAIN_ORDER
    available = set(store.get_strains())
    # Use custom order, filtering to available strains only
    test_strains = [s for s in HEATMAP_STRAIN_ORDER if s in available]

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


def compute_drilldown_stats(
    control_vals: np.ndarray,
    test_vals: np.ndarray,
) -> dict:
    """Run comprehensive statistical tests comparing test vs control.

    Parameters
    ----------
    control_vals, test_vals : 1-D arrays of per-fly scalar metric values
        (NaN-free).

    Returns
    -------
    dict with keys:
        n_control, n_test : sample sizes
        tests : list of dicts, each with name, stat, pvalue, note
        chosen_test : dict (the primary location test)
        effect_size : dict with name, value, interpretation
    """
    result = {
        "n_control": len(control_vals),
        "n_test": len(test_vals),
        "tests": [],
        "chosen_test": None,
        "effect_size": None,
    }

    # 1. Normality: Shapiro-Wilk on each group (requires n >= 3)
    ctrl_normal = True
    test_normal = True

    if len(control_vals) >= 3:
        sw_ctrl = stats.shapiro(control_vals)
        ctrl_normal = sw_ctrl.pvalue > 0.05
        result["tests"].append({
            "name": "Shapiro-Wilk (control)",
            "stat": float(sw_ctrl.statistic),
            "pvalue": float(sw_ctrl.pvalue),
            "note": "normal" if ctrl_normal else "non-normal",
        })

    if len(test_vals) >= 3:
        sw_test = stats.shapiro(test_vals)
        test_normal = sw_test.pvalue > 0.05
        result["tests"].append({
            "name": "Shapiro-Wilk (test strain)",
            "stat": float(sw_test.statistic),
            "pvalue": float(sw_test.pvalue),
            "note": "normal" if test_normal else "non-normal",
        })

    # 2. Equal variances: Levene's test
    lev = stats.levene(control_vals, test_vals)
    equal_var = lev.pvalue > 0.05
    result["tests"].append({
        "name": "Levene's test",
        "stat": float(lev.statistic),
        "pvalue": float(lev.pvalue),
        "note": "equal variance" if equal_var else "unequal variance",
    })

    # 3. Primary comparison: parametric or non-parametric
    both_normal = ctrl_normal and test_normal

    if both_normal:
        # Welch's t-test (robust to unequal variance)
        tt = stats.ttest_ind(test_vals, control_vals, equal_var=False)
        chosen = {
            "name": "Welch's t-test",
            "stat": float(tt.statistic),
            "pvalue": float(tt.pvalue),
            "note": "parametric (both groups normal)",
        }
    else:
        # Mann-Whitney U
        mw = stats.mannwhitneyu(test_vals, control_vals, alternative="two-sided")
        chosen = {
            "name": "Mann-Whitney U",
            "stat": float(mw.statistic),
            "pvalue": float(mw.pvalue),
            "note": "non-parametric (normality violated)",
        }

    result["tests"].append(chosen)
    result["chosen_test"] = chosen

    # 4. Distribution equality: Kolmogorov-Smirnov 2-sample
    ks = stats.ks_2samp(test_vals, control_vals)
    result["tests"].append({
        "name": "Kolmogorov-Smirnov",
        "stat": float(ks.statistic),
        "pvalue": float(ks.pvalue),
        "note": "distribution equality",
    })

    # 5. Effect size
    n1, n2 = len(control_vals), len(test_vals)
    if both_normal:
        # Cohen's d (pooled SD)
        pooled_std = np.sqrt(
            ((n1 - 1) * np.var(control_vals, ddof=1)
             + (n2 - 1) * np.var(test_vals, ddof=1)) / (n1 + n2 - 2)
        )
        d = (np.mean(test_vals) - np.mean(control_vals)) / pooled_std if pooled_std > 0 else 0.0
        interp = (
            "negligible" if abs(d) < 0.2 else
            "small" if abs(d) < 0.5 else
            "medium" if abs(d) < 0.8 else
            "large"
        )
        result["effect_size"] = {"name": "Cohen's d", "value": float(d), "interpretation": interp}
    else:
        # Rank-biserial correlation: r = 1 - 2U/(n1*n2)
        mw = stats.mannwhitneyu(test_vals, control_vals, alternative="two-sided")
        r_rb = 1 - (2 * mw.statistic) / (n1 * n2)
        interp = (
            "negligible" if abs(r_rb) < 0.1 else
            "small" if abs(r_rb) < 0.3 else
            "medium" if abs(r_rb) < 0.5 else
            "large"
        )
        result["effect_size"] = {"name": "Rank-biserial r", "value": float(r_rb), "interpretation": interp}

    return result

"""Cohort consistency statistics for the Strain View one-condition mode.

Computes Kruskal-Wallis H test, eta-squared, and MAD-based outlier
detection to identify cohorts with atypical mean or spread.
"""

import numpy as np
from scipy import stats


def compute_cohort_consistency_stats(
    cohort_values: dict[str, np.ndarray],
    outlier_threshold: float = 2.5,
) -> dict:
    """Compute cohort consistency metrics and flag outlier cohorts.

    Parameters
    ----------
    cohort_values : dict mapping cohort label (str) -> 1-D array of per-fly
        scalar values (e.g., mean forward velocity during stimulus).
        Cohorts with fewer than 2 valid (non-NaN) values are excluded from
        the overall test but still reported in per_cohort with flagged=False.
    outlier_threshold : float
        Modified Z-score threshold for flagging a cohort as an outlier.
        Default 2.5.

    Returns
    -------
    dict with keys:
        n_cohorts       : int — number of cohorts with >= 2 valid values
        n_total_flies   : int — total fly count across valid cohorts
        per_cohort      : list[dict] — one dict per cohort (all cohorts, including
                          those with < 2 values), each containing:
            cohort_id, n_flies, mean, median, iqr,
            mean_zscore, spread_zscore,
            flagged_mean, flagged_spread, flagged
        kruskal_wallis  : dict with stat, pvalue, note (or None if < 2 valid cohorts)
        eta_squared     : float | None
        overall_median  : float | None — median of cohort medians
        overall_mad     : float | None — MAD of cohort medians
        any_flagged     : bool
    """
    # Clean NaNs and partition into valid (>= 2 flies) and small cohorts
    cleaned = {}
    for k, v in cohort_values.items():
        arr = np.asarray(v, dtype=float)
        arr = arr[~np.isnan(arr)]
        cleaned[k] = arr

    valid = {k: v for k, v in cleaned.items() if len(v) >= 2}
    n_valid = len(valid)
    n_total = sum(len(v) for v in valid.values())

    # Compute per-cohort summaries for ALL cohorts (including small ones)
    cohort_medians = {}
    cohort_means = {}
    cohort_iqrs = {}
    for k, v in cleaned.items():
        if len(v) >= 1:
            cohort_medians[k] = float(np.median(v))
            cohort_means[k] = float(np.mean(v))
            cohort_iqrs[k] = float(
                np.percentile(v, 75) - np.percentile(v, 25)
            ) if len(v) >= 2 else 0.0
        else:
            cohort_medians[k] = np.nan
            cohort_means[k] = np.nan
            cohort_iqrs[k] = np.nan

    # ---- Modified Z-scores (only from valid cohorts) ----
    mean_zscores = {k: 0.0 for k in cleaned}
    spread_zscores = {k: 0.0 for k in cleaned}
    overall_median_val = None
    overall_mad_val = None

    if n_valid >= 2:
        # Z-scores for cohort medians
        med_array = np.array([cohort_medians[k] for k in valid])
        overall_median_val = float(np.median(med_array))
        overall_mad_val = float(np.median(np.abs(med_array - overall_median_val)))

        if overall_mad_val > 0:
            scale = 1.4826 * overall_mad_val
            for k in valid:
                mean_zscores[k] = abs(cohort_medians[k] - overall_median_val) / scale

        # Z-scores for cohort IQRs
        iqr_array = np.array([cohort_iqrs[k] for k in valid])
        iqr_median = float(np.median(iqr_array))
        iqr_mad = float(np.median(np.abs(iqr_array - iqr_median)))

        if iqr_mad > 0:
            scale_iqr = 1.4826 * iqr_mad
            for k in valid:
                spread_zscores[k] = abs(cohort_iqrs[k] - iqr_median) / scale_iqr

    # ---- Kruskal-Wallis test ----
    kruskal_wallis = None
    eta_squared = None

    if n_valid >= 2:
        groups = [valid[k] for k in valid]
        try:
            kw_stat, kw_p = stats.kruskal(*groups)
            k_groups = len(groups)
            eta_sq = (kw_stat - k_groups + 1) / (n_total - k_groups) if n_total > k_groups else None
            kruskal_wallis = {
                "stat": float(kw_stat),
                "pvalue": float(kw_p),
                "note": "significant *" if kw_p < 0.05 else "not significant",
            }
            if eta_sq is not None:
                eta_squared = max(0.0, float(eta_sq))  # clamp to non-negative
        except ValueError:
            # All groups identical or other degenerate case
            pass

    # ---- Build per-cohort results ----
    per_cohort = []
    for k in cohort_values:
        v = cleaned[k]
        n_flies = len(v)
        is_valid = k in valid
        flagged_mean = is_valid and mean_zscores[k] > outlier_threshold
        flagged_spread = is_valid and spread_zscores[k] > outlier_threshold
        per_cohort.append({
            "cohort_id": k,
            "n_flies": n_flies,
            "mean": cohort_means.get(k, np.nan),
            "median": cohort_medians.get(k, np.nan),
            "iqr": cohort_iqrs.get(k, np.nan),
            "mean_zscore": mean_zscores.get(k, 0.0),
            "spread_zscore": spread_zscores.get(k, 0.0),
            "flagged_mean": flagged_mean,
            "flagged_spread": flagged_spread,
            "flagged": flagged_mean or flagged_spread,
        })

    return {
        "n_cohorts": n_valid,
        "n_total_flies": n_total,
        "per_cohort": per_cohort,
        "kruskal_wallis": kruskal_wallis,
        "eta_squared": eta_squared,
        "overall_median": overall_median_val,
        "overall_mad": overall_mad_val,
        "any_flagged": any(pc["flagged"] for pc in per_cohort),
    }

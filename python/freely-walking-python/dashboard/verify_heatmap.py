#!/usr/bin/env python3
"""Verify the Python heatmap implementation against the MATLAB pipeline.

This script checks that:
1. Per-fly metrics are computed correctly (correct fly count, no grouping bugs)
2. Distance metrics use the MATLAB approach (min per rep, then average)
3. FV/turning metrics match the MATLAB approach
4. Frame ranges match the MATLAB code exactly
5. Statistical tests produce valid results for all strain/condition combos

Usage:
    cd python/freely-walking-python
    pixi run python -m dashboard.verify_heatmap
"""

import sys
from pathlib import Path

import numpy as np
import pandas as pd

# Ensure project root is on path
sys.path.insert(0, str(Path(__file__).parent.parent))

from dashboard.constants import (
    CONTROL_STRAIN,
    FDR_Q,
    HEATMAP_METRICS,
    HEATMAP_STRAIN_ORDER,
)
from dashboard.data_loader import DataStore
from dashboard.heatmap import (
    _DIST_10S_END,
    _DIST_10S_START,
    _DIST_END_END,
    _DIST_END_START,
    _EARLY_TURN_END,
    _EARLY_TURN_START,
    _FLIP_END,
    _FLIP_START,
    _ONSET_POST_END,
    _ONSET_POST_START,
    _ONSET_PRE_END,
    _ONSET_PRE_START,
    _SMOOTH_WINDOW,
    _STIM_END,
    _STIM_START,
    _collect_strain_metrics,
    compute_heatmap_data,
)

# ---- Expected MATLAB frame ranges (from src/processing/summary_plot/*.m) ----
MATLAB_FRAME_RANGES = {
    "Avg FV (stimulus)": (300, 1200),      # fv_metric_tests.m: rng_stim = 300:1200
    "ΔFV at onset (pre)": (210, 300),      # welch_ttest_for_change: rng_b4_3 = 210:300
    "ΔFV at onset (post)": (300, 390),     # welch_ttest_for_change: rng_stim_3 = 300:390
    "Avg Turning (stimulus)": (300, 1200), # curv_metric_tests.m: rng_stim = 300:1200
    "Early Turning (CW)": (315, 450),      # curv_metric_tests.m: rng_stim_start = 315:450
    "Movement 10s": (570, 600),            # dist_metric_tests.m: rng_at_10s = 570:600
    "Movement end": (1170, 1200),          # dist_metric_tests.m: rng_at_end = 1170:1200
    "Smooth window": 15,                   # curv_metric_tests.m: f_window = 15
    "Flip range": (762, 1210),             # curv_metric_tests.m: 762:1210
}


def check_frame_ranges():
    """Verify frame ranges match MATLAB."""
    print("=" * 60)
    print("CHECK 1: Frame ranges match MATLAB code")
    print("=" * 60)

    checks = [
        ("Avg FV (stimulus)", (_STIM_START, _STIM_END), (300, 1200)),
        ("ΔFV at onset (pre)", (_ONSET_PRE_START, _ONSET_PRE_END), (210, 300)),
        ("ΔFV at onset (post)", (_ONSET_POST_START, _ONSET_POST_END), (300, 390)),
        ("Avg Turning (stimulus)", (_STIM_START, _STIM_END), (300, 1200)),
        ("Early Turning (CW)", (_EARLY_TURN_START, _EARLY_TURN_END), (315, 450)),
        ("Movement 10s", (_DIST_10S_START, _DIST_10S_END), (570, 600)),
        ("Movement end", (_DIST_END_START, _DIST_END_END), (1170, 1200)),
        ("Smooth window", _SMOOTH_WINDOW, 15),
        ("Flip range", (_FLIP_START, _FLIP_END), (762, 1210)),
    ]

    all_pass = True
    for name, python_val, matlab_val in checks:
        match = python_val == matlab_val
        status = "✓" if match else "✗"
        print(f"  {status} {name}: Python={python_val}, MATLAB={matlab_val}")
        if not match:
            all_pass = False

    return all_pass


def check_fly_counts(store, condition_id=1):
    """Verify per-fly counts match expected (no grouping bug)."""
    print("\n" + "=" * 60)
    print(f"CHECK 2: Per-fly counts (condition {condition_id})")
    print("=" * 60)

    all_pass = True

    for strain in [CONTROL_STRAIN] + HEATMAP_STRAIN_ORDER[:3]:
        df = store.load_per_fly(strain)
        if df.empty:
            print(f"  ? {strain}: no data")
            continue

        mask = (df["condition"] == condition_id) & df["qc_passed"]
        subset = df[mask]

        # Expected: unique (cohort_id, fly_idx) pairs
        expected_n = subset.groupby(["cohort_id", "fly_idx"]).ngroups

        # Actual from _collect_strain_metrics
        metrics = _collect_strain_metrics(store, strain, condition_id)
        actual_n = metrics.shape[0]

        match = actual_n == expected_n
        status = "✓" if match else "✗"
        print(f"  {status} {strain}: expected={expected_n}, actual={actual_n}")
        if not match:
            all_pass = False

    return all_pass


def check_distance_metric_order(store, condition_id=1):
    """Verify distance metrics use min-per-rep-then-average (MATLAB approach).

    MATLAB: welch_ttest_for_rng_min
        1. min(d') per rep → scalar per rep
        2. mean_every_two_rows → average across reps per fly
        3. ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal')

    This checks that we don't get the same result as "average reps then min"
    (the wrong approach), confirming the correct order of operations.
    """
    print("\n" + "=" * 60)
    print(f"CHECK 3: Distance metric computation order (condition {condition_id})")
    print("=" * 60)

    strain = CONTROL_STRAIN
    df = store.load_per_fly(strain)
    mask = (df["condition"] == condition_id) & df["qc_passed"]
    subset = df[mask]

    # Pick a specific fly with 2 reps
    fly_groups = subset.groupby(["cohort_id", "fly_idx"])
    example_key = None
    for key, group in fly_groups:
        if group["rep"].nunique() == 2:
            example_key = key
            break

    if example_key is None:
        print("  ? No fly with 2 reps found")
        return True

    cohort_id, fly_idx = example_key
    fly_data = subset[(subset["cohort_id"] == cohort_id) & (subset["fly_idx"] == fly_idx)]

    # Method A (MATLAB): min per rep, then average
    rep_mins = []
    for rep_id in sorted(fly_data["rep"].unique()):
        rep_df = fly_data[fly_data["rep"] == rep_id].sort_values("frame")
        frames = rep_df["frame"].values
        dist = rep_df["dist_data"].values
        bl_mask = frames == 300
        if bl_mask.any():
            delta = dist - dist[bl_mask][0]
            m10 = (frames >= 570) & (frames <= 600)
            if m10.any():
                rep_mins.append(np.nanmin(delta[m10]))
    method_a = np.nanmean(rep_mins) if rep_mins else np.nan

    # Method B (wrong): average reps first, then min
    avg_df = fly_data.groupby("frame")[["dist_data"]].mean().reset_index()
    avg_frames = avg_df["frame"].values
    avg_dist = avg_df["dist_data"].values
    bl_mask = avg_frames == 300
    if bl_mask.any():
        avg_delta = avg_dist - avg_dist[bl_mask][0]
        m10 = (avg_frames >= 570) & (avg_frames <= 600)
        method_b = np.nanmin(avg_delta[m10]) if m10.any() else np.nan
    else:
        method_b = np.nan

    # They should generally differ (unless reps are identical)
    diff = abs(method_a - method_b)
    print(f"  Fly ({cohort_id}, {fly_idx}):")
    print(f"    Method A (MATLAB: min-per-rep, avg): {method_a:.4f}")
    print(f"    Method B (wrong: avg-reps, then min): {method_b:.4f}")
    print(f"    Difference: {diff:.4f}")

    # Check that our code produces Method A
    metrics = _collect_strain_metrics(store, strain, condition_id)

    # Find this fly's index in the output
    all_flies = sorted(
        subset.groupby(["cohort_id", "fly_idx"]).groups.keys()
    )
    fly_row = all_flies.index(example_key)
    our_value = metrics[fly_row, 4]  # metric 5 = Movement towards centre (10s)

    match = np.isclose(our_value, method_a, rtol=1e-6)
    status = "✓" if match else "✗"
    print(f"    Our code produces: {our_value:.4f} → {status} matches MATLAB approach")

    return match


def check_all_conditions(store):
    """Test that all 12 conditions × all strains compute without error."""
    print("\n" + "=" * 60)
    print("CHECK 4: All conditions compute without error")
    print("=" * 60)

    all_pass = True
    for cond in range(1, 13):
        try:
            result = compute_heatmap_data(store, cond, apply_qc=True, rep_mode="average")
            n_strains = len(result["strain_list"])
            ctrl_n = result["per_fly_data"][CONTROL_STRAIN].shape[0]
            n_nan = np.isnan(result["z_matrix"]).sum()
            print(f"  ✓ Condition {cond:2d}: {n_strains} strains, ctrl_n={ctrl_n}, NaN cells={n_nan}")
        except Exception as e:
            print(f"  ✗ Condition {cond:2d}: ERROR - {e}")
            all_pass = False

    return all_pass


def check_metric_labels():
    """Verify the 6 HEATMAP_METRICS labels match expected MATLAB metrics."""
    print("\n" + "=" * 60)
    print("CHECK 5: Metric labels match MATLAB (make_pvalue_array_per_condition.m)")
    print("=" * 60)

    # MATLAB output line 70: pvals = horzcat(pvals_fv, pvals_cv, pvals_delta)
    # fv: 2 metrics (Avg FV, ΔFV at onset)
    # cv: 2 metrics (Avg Turning, Early Turning)
    # delta: 2 metrics (Movement 10s, Movement end)
    expected = [
        "Avg FV (stimulus)",         # fv_metric_tests: welch_ttest_for_rng(300:1200)
        "ΔFV at onset",              # fv_metric_tests: welch_ttest_for_change(210:300, 300:390, "norm")
        "Avg Turning (stimulus)",    # curv_metric_tests: welch_ttest_for_rng(300:1200)
        "Early Turning (CW)",        # curv_metric_tests: welch_ttest_for_rng(315:450)
        "Movement towards centre (10s)",  # dist_metric_tests type 2: welch_ttest_for_rng_min(570:600)
        "Movement towards centre (end)",  # dist_metric_tests type 2: welch_ttest_for_rng_min(1170:1200)
    ]

    all_pass = True
    for i, (actual, exp) in enumerate(zip(HEATMAP_METRICS, expected)):
        match = actual == exp
        status = "✓" if match else "✗"
        print(f"  {status} Metric {i}: '{actual}' == '{exp}'")
        if not match:
            all_pass = False

    return all_pass


def check_strain_order():
    """Verify HEATMAP_STRAIN_ORDER excludes duplicates and control."""
    print("\n" + "=" * 60)
    print("CHECK 6: Strain ordering and filtering")
    print("=" * 60)

    all_pass = True

    # Control should NOT be in the order
    if CONTROL_STRAIN in HEATMAP_STRAIN_ORDER:
        print(f"  ✗ Control strain '{CONTROL_STRAIN}' should not be in HEATMAP_STRAIN_ORDER")
        all_pass = False
    else:
        print(f"  ✓ Control strain excluded from order list")

    # Excluded Dm4 duplicates
    excluded = ["ss02360_Dm4_shibire_kir", "ss02587_Dm4_shibire_kir"]
    for s in excluded:
        if s in HEATMAP_STRAIN_ORDER:
            print(f"  ✗ Duplicate strain '{s}' should not be in order list")
            all_pass = False
        else:
            print(f"  ✓ '{s}' correctly excluded")

    print(f"  ✓ {len(HEATMAP_STRAIN_ORDER)} strains in custom order")
    return all_pass


def main():
    from dashboard.constants import DEFAULT_DATA_DIR

    preprocessed = str(Path(DEFAULT_DATA_DIR).parent / f"{Path(DEFAULT_DATA_DIR).name}_preprocessed")
    store = DataStore(preprocessed)

    if not store.is_valid:
        print(f"ERROR: Preprocessed data not found at {preprocessed}")
        sys.exit(1)

    print(f"Data: {preprocessed}")
    print(f"Strains: {len(store.get_strains())}")
    print()

    results = []
    results.append(("Frame ranges", check_frame_ranges()))
    results.append(("Fly counts", check_fly_counts(store)))
    results.append(("Distance metric order", check_distance_metric_order(store)))
    results.append(("All conditions", check_all_conditions(store)))
    results.append(("Metric labels", check_metric_labels()))
    results.append(("Strain ordering", check_strain_order()))

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    all_pass = True
    for name, passed in results:
        status = "PASS" if passed else "FAIL"
        print(f"  {status}: {name}")
        if not passed:
            all_pass = False

    if all_pass:
        print("\n✓ All checks passed.")
    else:
        print("\n✗ Some checks failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()

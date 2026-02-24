"""Preprocess .mat result files into Parquet format for the dashboard.

Usage:
    pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
        python -m dashboard.preprocess \
        --data-dir /path/to/results/protocol_27 \
        --output-dir /path/to/results/protocol_27_preprocessed

If --output-dir is omitted, defaults to {data-dir}_preprocessed/.
"""

import argparse
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd

from dashboard.constants import (
    CONDITION_NAMES,
    DOWNSAMPLE_FACTOR,
    FPS,
    METRICS,
)
from dashboard.processing import (
    combine_cohorts_for_condition,
    process_one_file,
)


def discover_mat_files(data_dir: Path) -> list[Path]:
    """Find all .mat files under data_dir, excluding DATA*.mat."""
    files = sorted(data_dir.rglob("*.mat"))
    return [f for f in files if not f.name.startswith("DATA")]


def build_per_fly_dataframe(
    cohort_results: list[dict],
    strain: str,
    downsample: int = DOWNSAMPLE_FACTOR,
) -> pd.DataFrame:
    """Build a per-fly DataFrame for one strain across all its cohorts.

    Stores both R1 and R2 data with QC flags. Downsampled by `downsample`.

    Columns: cohort_id, fly_idx, rep (1 or 2), condition, qc_passed, frame, time_s,
             fv_data, av_data, ...
    """
    rows = []

    for cohort in cohort_results:
        cohort_id = cohort["cohort_id"]

        for cond_n, cond in cohort["conditions"].items():
            for rep_key, rep_num in [("r1", 1), ("r2", 2)]:
                rep_data = cond[rep_key]
                if rep_data is None:
                    continue

                qc_flags = cond.get(f"{rep_key}_qc")
                first_metric = next(iter(rep_data.values()))
                n_flies, n_frames = first_metric.shape

                # Downsample frame indices
                frame_indices = np.arange(0, n_frames, downsample)

                for fly_idx in range(n_flies):
                    qc = bool(qc_flags[fly_idx]) if qc_flags is not None else True

                    for fi in frame_indices:
                        row = {
                            "cohort_id": cohort_id,
                            "fly_idx": fly_idx,
                            "rep": rep_num,
                            "condition": cond_n,
                            "qc_passed": qc,
                            "frame": fi,
                            "time_s": round(fi / FPS, 3),
                        }
                        for metric in METRICS:
                            if metric in rep_data:
                                row[metric] = float(rep_data[metric][fly_idx, fi])
                        rows.append(row)

    if not rows:
        return pd.DataFrame()

    df = pd.DataFrame(rows)
    df["strain"] = strain
    return df


def build_summary_dataframe(
    all_strain_cohorts: dict[str, list[dict]],
    downsample: int = DOWNSAMPLE_FACTOR,
) -> pd.DataFrame:
    """Build strain-level summary (mean + SEM) for all strains and conditions.

    Uses the "interleave" rep mode (matching current MATLAB behavior).
    No QC filtering applied (matching current MATLAB behavior).
    """
    rows = []

    for strain, cohort_results in all_strain_cohorts.items():
        for cond_n in sorted(CONDITION_NAMES.keys()):
            for metric in METRICS:
                cond_data = combine_cohorts_for_condition(
                    cohort_results, cond_n, metric,
                    rep_mode="interleave", apply_qc=False,
                )
                if cond_data.size == 0:
                    continue

                n_total = cond_data.shape[0]
                n_frames = cond_data.shape[1]
                frame_indices = np.arange(0, n_frames, downsample)

                mean_vals = np.nanmean(cond_data, axis=0)
                n_valid = np.sum(~np.isnan(cond_data), axis=0)
                sem_vals = np.nanstd(cond_data, axis=0) / np.sqrt(
                    np.maximum(n_valid, 1)
                )

                for fi in frame_indices:
                    rows.append({
                        "strain": strain,
                        "condition": cond_n,
                        "condition_name": CONDITION_NAMES.get(cond_n, f"condition_{cond_n}"),
                        "metric": metric,
                        "frame": int(fi),
                        "time_s": round(fi / FPS, 3),
                        "mean": float(mean_vals[fi]),
                        "sem": float(sem_vals[fi]),
                        "n_flies": int(n_valid[fi]),
                        "n_cohorts": len(cohort_results),
                    })

    return pd.DataFrame(rows)


def main():
    parser = argparse.ArgumentParser(
        description="Preprocess .mat result files to Parquet for the dashboard."
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        required=True,
        help="Path to protocol results folder (e.g., .../results/protocol_27)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Output directory for Parquet files (default: {data-dir}_preprocessed)",
    )
    args = parser.parse_args()

    data_dir = args.data_dir
    output_dir = args.output_dir or data_dir.parent / f"{data_dir.name}_preprocessed"
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Data directory:   {data_dir}")
    print(f"Output directory: {output_dir}")

    # Discover files
    mat_files = discover_mat_files(data_dir)
    print(f"Found {len(mat_files)} .mat files")

    if not mat_files:
        print("No .mat files found. Exiting.")
        sys.exit(1)

    # Process all files, grouping by strain
    all_strain_cohorts: dict[str, list[dict]] = {}
    n_processed = 0
    n_failed = 0
    t_start = time.time()

    for filepath in mat_files:
        try:
            result = process_one_file(filepath, metrics=METRICS)
            strain = result["strain"]
            if strain not in all_strain_cohorts:
                all_strain_cohorts[strain] = []
            all_strain_cohorts[strain].append(result)
            n_processed += 1
            print(f"  [{n_processed}/{len(mat_files)}] {filepath.name} -> {strain} ({result['n_flies']} flies)")
        except Exception as e:
            n_failed += 1
            print(f"  FAILED: {filepath.name}: {e}")

    elapsed = time.time() - t_start
    print(f"\nProcessed {n_processed} files in {elapsed:.1f}s ({n_failed} failed)")
    print(f"Strains found: {sorted(all_strain_cohorts.keys())}")

    # Save per-strain Parquet files
    print("\nSaving per-strain Parquet files...")
    per_fly_dir = output_dir / "per_fly"
    per_fly_dir.mkdir(exist_ok=True)

    for strain, cohort_results in all_strain_cohorts.items():
        df = build_per_fly_dataframe(cohort_results, strain)
        if df.empty:
            print(f"  WARNING: No data for {strain}, skipping")
            continue
        out_path = per_fly_dir / f"{strain}.parquet"
        df.to_parquet(out_path, index=False)
        n_rows = len(df)
        size_mb = out_path.stat().st_size / 1e6
        print(f"  {strain}: {n_rows:,} rows, {size_mb:.1f} MB")

    # Build and save summary
    print("\nBuilding strain summary...")
    summary_df = build_summary_dataframe(all_strain_cohorts)
    summary_path = output_dir / "strain_summary.parquet"
    summary_df.to_parquet(summary_path, index=False)
    size_mb = summary_path.stat().st_size / 1e6
    print(f"Summary: {len(summary_df):,} rows, {size_mb:.1f} MB")

    # Save metadata
    meta = {
        "strain": list(all_strain_cohorts.keys()),
        "n_cohorts": [len(v) for v in all_strain_cohorts.values()],
        "n_conditions": [len(CONDITION_NAMES)],
    }
    meta_df = pd.DataFrame(
        [(s, len(cohorts)) for s, cohorts in all_strain_cohorts.items()],
        columns=["strain", "n_cohorts"],
    )
    meta_df.to_parquet(output_dir / "metadata.parquet", index=False)

    print(f"\nDone. Output saved to: {output_dir}")


if __name__ == "__main__":
    main()

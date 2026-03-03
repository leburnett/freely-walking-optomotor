"""Load preprocessed Parquet data for the dashboard."""

from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd

from dashboard.constants import ACCLIM_CONDITION_ID, CONDITION_NAMES, FPS, METRICS, STIM_ONSET_FRAME


class DataStore:
    """Manages loading and caching of preprocessed Parquet data."""

    def __init__(self, preprocessed_dir: Path | str):
        self.preprocessed_dir = Path(preprocessed_dir)
        self._summary_df: pd.DataFrame | None = None
        self._metadata_df: pd.DataFrame | None = None
        self._per_fly_cache: dict[str, pd.DataFrame] = {}
        self._metadata_summary_cache: pd.DataFrame | None = None
        self._temperatures_df: pd.DataFrame | None = None
        self._summary_variants: dict[str, pd.DataFrame] = {}  # keyed by "qc{0|1}_rep{mode}"

    def warm_cache(self):
        """Pre-load all per-fly Parquets into memory for fast interactive use.

        Call at startup to eliminate first-access latency (~0.3-0.4s per strain).
        Total memory usage is ~1.5 GB for all strains.
        """
        import time
        meta = self.load_metadata()
        strains = meta["strain"].tolist()
        t0 = time.time()
        for i, strain in enumerate(strains, 1):
            self.load_per_fly(strain)
            print(f"  [{i}/{len(strains)}] {strain}")
        elapsed = time.time() - t0
        print(f"  All {len(strains)} strains loaded in {elapsed:.1f}s")

    @property
    def is_valid(self) -> bool:
        """Check if the preprocessed directory contains expected files."""
        return (
            self.preprocessed_dir.exists()
            and (self.preprocessed_dir / "strain_summary.parquet").exists()
        )

    def load_summary(self) -> pd.DataFrame:
        """Load the strain summary Parquet (all strains, conditions, metrics)."""
        if self._summary_df is None:
            path = self.preprocessed_dir / "strain_summary.parquet"
            self._summary_df = pd.read_parquet(path)
        return self._summary_df

    def load_metadata(self) -> pd.DataFrame:
        """Load the metadata Parquet."""
        if self._metadata_df is None:
            path = self.preprocessed_dir / "metadata.parquet"
            self._metadata_df = pd.read_parquet(path)
        return self._metadata_df

    def load_per_fly(self, strain: str) -> pd.DataFrame:
        """Load per-fly Parquet for a specific strain (lazy, cached)."""
        if strain not in self._per_fly_cache:
            path = self.preprocessed_dir / "per_fly" / f"{strain}.parquet"
            if not path.exists():
                return pd.DataFrame()
            self._per_fly_cache[strain] = pd.read_parquet(path)
        return self._per_fly_cache[strain]

    def get_strains(self) -> list[str]:
        """List available strains."""
        meta = self.load_metadata()
        return sorted(meta["strain"].tolist())

    def get_cohorts_for_strain(self, strain: str) -> list[str]:
        """List cohort IDs for a strain."""
        df = self.load_per_fly(strain)
        if df.empty:
            return []
        return sorted(df["cohort_id"].unique().tolist())

    def get_strain_summary(
        self,
        strain: str,
        condition: int,
        metric: str,
    ) -> pd.DataFrame:
        """Get summary (mean, SEM, n_flies) for one strain/condition/metric."""
        df = self.load_summary()
        mask = (df["strain"] == strain) & (df["condition"] == condition) & (df["metric"] == metric)
        return df[mask].sort_values("frame").reset_index(drop=True)

    def get_summary_for_settings(
        self,
        strain: str,
        condition: int,
        metric: str,
        apply_qc: bool = False,
        rep_mode: str = "interleave",
        central_tendency: str = "mean",
        dispersion: str = "sem",
    ) -> pd.DataFrame | None:
        """Look up pre-computed summary for any QC/rep/stat combination.

        Returns DataFrame with columns: frame, time_s, mean, sem, n_flies
        (column names kept as 'mean'/'sem' for backward compatibility).
        Returns None if the pre-computed file doesn't exist (caller should
        fall back to compute_summary_on_the_fly).
        """
        key = f"qc{int(apply_qc)}_rep{rep_mode}"
        if key not in self._summary_variants:
            path = self.preprocessed_dir / f"strain_summary_{key}.parquet"
            if path.exists():
                self._summary_variants[key] = pd.read_parquet(path)
            else:
                return None
        df = self._summary_variants[key]
        mask = (df["strain"] == strain) & (df["condition"] == condition) & (df["metric"] == metric)
        subset = df[mask]
        if subset.empty:
            return pd.DataFrame(columns=["frame", "time_s", "mean", "sem", "n_flies"])
        # Select the requested central tendency and dispersion columns
        col_center = central_tendency  # "mean" or "median"
        col_disp = dispersion if dispersion != "none" else "sem"  # fallback
        result = subset[["frame", "time_s", col_center, col_disp, "n_flies"]].copy()
        result.columns = ["frame", "time_s", "mean", "sem", "n_flies"]
        if dispersion == "none":
            result["sem"] = 0.0
        return result.sort_values("frame").reset_index(drop=True)

    def get_cohort_data(
        self,
        strain: str,
        cohort_id: str,
        condition: int,
        metric: str,
        rep: int | None = None,
        qc_only: bool = False,
    ) -> pd.DataFrame:
        """Get per-fly data for one cohort/condition/metric.

        Parameters
        ----------
        rep : filter to specific rep (1 or 2), or None for both
        qc_only : if True, only include flies that passed QC
        """
        df = self.load_per_fly(strain)
        if df.empty:
            return df

        mask = (
            (df["cohort_id"] == cohort_id)
            & (df["condition"] == condition)
        )
        if rep is not None:
            mask &= df["rep"] == rep
        if qc_only:
            mask &= df["qc_passed"]

        result = df[mask]

        # Handle derived metric: move_to_centre = dist_at_onset minus dist_data (positive = towards centre)
        if metric == "move_to_centre":
            if "dist_data" not in result.columns or result.empty:
                return pd.DataFrame()
            result = result.copy()
            onset_vals = (
                result[result["frame"] == STIM_ONSET_FRAME]
                .groupby(["fly_idx", "rep"])["dist_data"]
                .first()
            )
            result["move_to_centre"] = result.apply(
                lambda row: onset_vals.get((row["fly_idx"], row["rep"]), np.nan) - row["dist_data"],
                axis=1,
            )

        if metric in result.columns:
            return result[["fly_idx", "rep", "frame", "time_s", "qc_passed", metric]].sort_values(
                ["fly_idx", "rep", "frame"]
            ).reset_index(drop=True)
        return pd.DataFrame()

    def get_acclim_data(
        self,
        strain: str,
        cohort_id: str,
        metric: str,
        qc_only: bool = False,
    ) -> pd.DataFrame:
        """Get acclimation period data for one cohort.

        Returns DataFrame with columns: fly_idx, frame, time_s, qc_passed, {metric}.
        """
        df = self.load_per_fly(strain)
        if df.empty:
            return df

        mask = (
            (df["cohort_id"] == cohort_id)
            & (df["condition"] == ACCLIM_CONDITION_ID)
        )
        if qc_only:
            mask &= df["qc_passed"]

        result = df[mask]
        if metric in result.columns:
            return result[["fly_idx", "frame", "time_s", "qc_passed", metric]].sort_values(
                ["fly_idx", "frame"]
            ).reset_index(drop=True)
        return pd.DataFrame()

    def get_acclim_summary(
        self,
        strain: str,
        cohort_id: str,
        metric: str,
        qc_only: bool = False,
    ) -> dict:
        """Compute summary statistics for the acclimation period.

        Returns dict with: n_flies, overall_mean, overall_std, overall_sem.
        Empty dict if no acclim data is available.
        """
        df = self.get_acclim_data(strain, cohort_id, metric, qc_only)
        if df.empty:
            return {}

        per_fly = df.groupby("fly_idx")[metric].mean()
        n = len(per_fly)
        return {
            "n_flies": n,
            "overall_mean": float(per_fly.mean()),
            "overall_std": float(per_fly.std()) if n > 1 else 0.0,
            "overall_sem": float(per_fly.std() / np.sqrt(n)) if n > 1 else 0.0,
        }

    def get_dataset_summary(self) -> dict:
        """Compute overall dataset summary: path, cohort count, date range, preprocessing time.

        Returns dict with keys:
            preprocessed_dir   : str  — absolute path to preprocessed directory
            n_strains          : int  — number of strains
            n_cohorts_total    : int  — total cohort/experiment count
            date_min           : str | None  — earliest acquisition date (YYYY-MM-DD)
            date_max           : str | None  — latest acquisition date (YYYY-MM-DD)
            preprocessed_on    : str | None  — when data was last preprocessed (YYYY-MM-DD HH:MM)
        """
        import datetime

        meta = self.load_metadata()
        n_strains = len(meta)
        n_cohorts_total = int(meta["n_cohorts"].sum()) if "n_cohorts" in meta.columns else 0

        # Gather unique acquisition dates from cohort_id values.
        # cohort_id format: YYYY-MM-DD_HH-MM-SS_strain_protocol_...
        # We read only the cohort_id column from each per-fly Parquet (fast with columnar format).
        all_dates: list[str] = []
        for strain in meta["strain"].tolist():
            path = self.preprocessed_dir / "per_fly" / f"{strain}.parquet"
            if path.exists():
                try:
                    cid_df = pd.read_parquet(path, columns=["cohort_id"])
                    for cid in cid_df["cohort_id"].unique():
                        date_part = str(cid)[:10]
                        if len(date_part) == 10 and date_part[4] == "-" and date_part[7] == "-":
                            all_dates.append(date_part)
                except Exception:
                    pass

        date_min = min(all_dates) if all_dates else None
        date_max = max(all_dates) if all_dates else None

        # Preprocessing timestamp — use mtime of metadata.parquet
        meta_path = self.preprocessed_dir / "metadata.parquet"
        preprocessed_on: str | None = None
        if meta_path.exists():
            ts = meta_path.stat().st_mtime
            preprocessed_on = datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M")

        return {
            "preprocessed_dir": str(self.preprocessed_dir.resolve()),
            "n_strains": n_strains,
            "n_cohorts_total": n_cohorts_total,
            "date_min": date_min,
            "date_max": date_max,
            "preprocessed_on": preprocessed_on,
        }

    def get_metadata_summary(self) -> pd.DataFrame:
        """Return per-cohort acquisition summary for all strains.

        Columns: strain, cohort_id, date (YYYY-MM-DD), n_flies

        Reads only the minimal columns needed from each per-fly Parquet
        (columnar format makes this efficient). Result is cached.
        """
        if self._metadata_summary_cache is not None:
            return self._metadata_summary_cache

        meta = self.load_metadata()
        rows = []

        for strain in meta["strain"].tolist():
            path = self.preprocessed_dir / "per_fly" / f"{strain}.parquet"
            if not path.exists():
                continue
            try:
                # Read only the columns needed to count flies per cohort
                df = pd.read_parquet(path, columns=["cohort_id", "fly_idx", "condition", "rep"])
                # Filter to one condition+rep so each fly is counted exactly once
                single = df[(df["condition"] == 1) & (df["rep"] == 1)]
                for cohort_id, group in single.groupby("cohort_id"):
                    date_part = str(cohort_id)[:10]
                    rows.append({
                        "strain": strain,
                        "cohort_id": cohort_id,
                        "date": date_part,
                        "n_flies": group["fly_idx"].nunique(),
                    })
            except Exception:
                pass

        result = pd.DataFrame(rows) if rows else pd.DataFrame(
            columns=["strain", "cohort_id", "date", "n_flies"]
        )
        self._metadata_summary_cache = result
        return result

    def load_temperatures(self) -> pd.DataFrame:
        """Load the temperature data Parquet (one row per cohort).

        Columns: cohort_id, strain, datetime, start_temp_outside,
                 end_temp_outside, start_temp_ring, end_temp_ring

        Returns an empty DataFrame if the file does not yet exist
        (i.e., data was preprocessed before temperature support was added).
        """
        if self._temperatures_df is None:
            path = self.preprocessed_dir / "temperatures.parquet"
            self._temperatures_df = pd.read_parquet(path) if path.exists() else pd.DataFrame()
        return self._temperatures_df

    def compute_summary_on_the_fly(
        self,
        strain: str,
        condition: int,
        metric: str,
        rep_mode: str = "interleave",
        apply_qc: bool = False,
        central_tendency: str = "mean",
        dispersion: str = "sem",
    ) -> pd.DataFrame:
        """Compute central tendency / dispersion from per-fly data.

        Used when the user changes the rep mode, QC toggle, or switches
        to median/MAD, since the pre-computed summary uses defaults
        (mean, SEM, interleave, no QC).

        Returns DataFrame with columns: frame, time_s, mean, sem, n_flies.
        (Column names kept as 'mean'/'sem' for backward compatibility, but
        they represent the selected central tendency and dispersion.)
        """
        df = self.load_per_fly(strain)
        if df.empty:
            return pd.DataFrame()

        mask = df["condition"] == condition
        if apply_qc:
            mask &= df["qc_passed"]
        subset = df[mask]

        # Resolve the source column: move_to_centre = dist_at_onset minus dist_data (positive = towards centre)
        if metric == "move_to_centre":
            if "dist_data" not in subset.columns or subset.empty:
                return pd.DataFrame()
            subset = subset.copy()
            onset_vals = (
                subset[subset["frame"] == STIM_ONSET_FRAME]
                .groupby(["cohort_id", "fly_idx", "rep"])["dist_data"]
                .first()
                .rename("_onset_val")
                .reset_index()
            )
            subset = subset.merge(onset_vals, on=["cohort_id", "fly_idx", "rep"], how="left")
            subset["move_to_centre"] = subset["_onset_val"] - subset["dist_data"]
            subset = subset.drop(columns=["_onset_val"])
            col = "move_to_centre"
        else:
            col = metric

        if subset.empty or col not in subset.columns:
            return pd.DataFrame()

        if rep_mode == "average":
            # Average R1 and R2 per fly per frame, then compute group stats
            source = subset.groupby(
                ["cohort_id", "fly_idx", "frame", "time_s"]
            )[col].mean().reset_index()
        else:
            source = subset

        # Group by frame and compute central tendency + dispersion
        frame_groups = source.groupby("frame")
        time_s = frame_groups["time_s"].first()

        if central_tendency == "median":
            center = frame_groups[col].median()
        else:
            center = frame_groups[col].mean()

        if dispersion == "none":
            disp = pd.Series(np.zeros(len(center)), index=center.index)
        elif dispersion == "mad":
            # Median Absolute Deviation: median(|x - median(x)|) per frame
            med_per_frame = frame_groups[col].median()
            source_with_med = source.merge(
                med_per_frame.rename("_frame_median").reset_index(),
                on="frame",
            )
            source_with_med["_abs_dev"] = np.abs(
                source_with_med[col] - source_with_med["_frame_median"]
            )
            disp = source_with_med.groupby("frame")["_abs_dev"].median()
        else:
            # SEM: std / sqrt(n)
            std = frame_groups[col].std()
            count = frame_groups[col].count()
            disp = std / np.sqrt(count.clip(lower=1))

        n_flies = frame_groups[col].count()

        grouped = pd.DataFrame({
            "frame": time_s.index,
            "time_s": time_s.values,
            "mean": center.values,
            "sem": disp.values,
            "n_flies": n_flies.values,
        }).sort_values("frame").reset_index(drop=True)

        return grouped

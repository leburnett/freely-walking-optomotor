"""Load preprocessed Parquet data for the dashboard."""

from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd

from dashboard.constants import ACCLIM_CONDITION_ID, CONDITION_NAMES, FPS, METRICS


class DataStore:
    """Manages loading and caching of preprocessed Parquet data."""

    def __init__(self, preprocessed_dir: Path | str):
        self.preprocessed_dir = Path(preprocessed_dir)
        self._summary_df: pd.DataFrame | None = None
        self._metadata_df: pd.DataFrame | None = None
        self._per_fly_cache: dict[str, pd.DataFrame] = {}

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

        if subset.empty or metric not in subset.columns:
            return pd.DataFrame()

        if rep_mode == "average":
            # Average R1 and R2 per fly per frame, then compute group stats
            source = subset.groupby(
                ["cohort_id", "fly_idx", "frame", "time_s"]
            )[metric].mean().reset_index()
        else:
            source = subset

        # Group by frame and compute central tendency + dispersion
        frame_groups = source.groupby("frame")
        time_s = frame_groups["time_s"].first()

        if central_tendency == "median":
            center = frame_groups[metric].median()
        else:
            center = frame_groups[metric].mean()

        if dispersion == "mad":
            # Median Absolute Deviation: median(|x - median(x)|) per frame
            med_per_frame = frame_groups[metric].median()
            source_with_med = source.merge(
                med_per_frame.rename("_frame_median").reset_index(),
                on="frame",
            )
            source_with_med["_abs_dev"] = np.abs(
                source_with_med[metric] - source_with_med["_frame_median"]
            )
            disp = source_with_med.groupby("frame")["_abs_dev"].median()
        else:
            # SEM: std / sqrt(n)
            std = frame_groups[metric].std()
            count = frame_groups[metric].count()
            disp = std / np.sqrt(count.clip(lower=1))

        n_flies = frame_groups[metric].count()

        grouped = pd.DataFrame({
            "frame": time_s.index,
            "time_s": time_s.values,
            "mean": center.values,
            "sem": disp.values,
            "n_flies": n_flies.values,
        }).sort_values("frame").reset_index(drop=True)

        return grouped

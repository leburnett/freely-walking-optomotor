"""Load preprocessed Parquet data for the dashboard."""

from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd

from dashboard.constants import CONDITION_NAMES, FPS, METRICS


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

    def compute_summary_on_the_fly(
        self,
        strain: str,
        condition: int,
        metric: str,
        rep_mode: str = "interleave",
        apply_qc: bool = False,
    ) -> pd.DataFrame:
        """Compute mean/SEM from per-fly data with custom rep_mode and QC settings.

        Used when the user changes the rep mode or QC toggle, since the
        pre-computed summary uses the defaults (interleave, no QC).

        Returns DataFrame with columns: frame, time_s, mean, sem, n_flies.
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
            avg = subset.groupby(["cohort_id", "fly_idx", "frame", "time_s"])[metric].mean().reset_index()
            grouped = avg.groupby("frame").agg(
                time_s=("time_s", "first"),
                mean=(metric, "mean"),
                sem=(metric, lambda x: x.std() / np.sqrt(len(x)) if len(x) > 1 else 0.0),
                n_flies=(metric, "count"),
            ).reset_index()
        else:
            # Interleave: each rep is a separate row
            grouped = subset.groupby("frame").agg(
                time_s=("time_s", "first"),
                mean=(metric, "mean"),
                sem=(metric, lambda x: x.std() / np.sqrt(len(x)) if len(x) > 1 else 0.0),
                n_flies=(metric, "count"),
            ).reset_index()

        return grouped.sort_values("frame").reset_index(drop=True)

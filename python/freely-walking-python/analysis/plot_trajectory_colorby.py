"""plot_trajectory_colorby.py

Creates a 1x3 figure showing a single fly trajectory from the es_shibire_kir
dataset, with the trajectory line coloured three different ways:

  Subplot 1 — Time bin index   : each non-overlapping time-bin segment gets
                                  a distinct categorical colour.
  Subplot 2 — Tortuosity       : colour = path_length / displacement for
                                  each time-bin segment.
  Subplot 3 — Distance from edge: colour = mean(ARENA_RADIUS - dist_from_centre)
                                  for each time-bin segment.

The trajectory shown is the stimulus period only (same as the HTML explorer).

Usage (CLI):
    cd python/freely-walking-python
    pixi run python -m analysis.plot_trajectory_colorby --fly_id 5 --time_bin 2.0

Usage (Python):
    from analysis.plot_trajectory_colorby import plot_trajectory_colorby
    fig = plot_trajectory_colorby(fly_id=5, time_bin_s=2.0)
    fig.savefig("traj_fly5_2s.png", dpi=150, bbox_inches="tight")
"""

import argparse
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.cm as cm
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.collections import LineCollection
from scipy.optimize import minimize

sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from config.config import FIGURES_PATH, RESULTS_PATH
from dashboard.constants import BASELINE_FRAMES, FPS, STIM_OFFSET_FRAME
from analysis.tortuosity_explorer import (
    ARENA_RADIUS_MM,
    DEFAULT_STRAIN,
    MIN_DISPLACEMENT,
    load_condition_data,
)

# ---------------------------------------------------------------------------
# Module-level cache so repeated calls within one session don't reload data
# ---------------------------------------------------------------------------
_FLY_TRACES_CACHE: dict[str, list[dict]] = {}


def load_traces(strain: str = DEFAULT_STRAIN) -> list[dict]:
    """Load (and cache) QC-passed fly traces for *strain*.

    Parameters
    ----------
    strain:
        Strain folder name, e.g. ``"jfrc100_es_shibire_kir"``.

    Returns
    -------
    list of dicts with keys ``x``, ``y``, ``heading``, ``dist``, ``fv``.
    """
    if strain in _FLY_TRACES_CACHE:
        return _FLY_TRACES_CACHE[strain]

    data_dir = RESULTS_PATH / "protocol_27" / strain / "F"
    if not data_dir.exists():
        raise FileNotFoundError(f"Data directory not found: {data_dir}")

    print(f"Loading data from {data_dir} ...")
    fly_traces, n_files, n_excluded = load_condition_data(data_dir)
    print(f"  {len(fly_traces)} flies loaded from {n_files} files "
          f"({n_excluded} excluded by QC)")

    _FLY_TRACES_CACHE[strain] = fly_traces
    return fly_traces


# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

def _estimate_arena_centre(x: np.ndarray, y: np.ndarray,
                            dist: np.ndarray) -> tuple[float, float]:
    """Estimate the arena centre by minimising residuals of dist = |pos - centre|."""
    valid = ~np.isnan(x) & ~np.isnan(y) & ~np.isnan(dist)
    if valid.sum() < 10:
        return float(np.nanmean(x)), float(np.nanmean(y))

    xv, yv, dv = x[valid][::10], y[valid][::10], dist[valid][::10]

    def obj(p):
        return np.sum((np.sqrt((xv - p[0]) ** 2 + (yv - p[1]) ** 2) - dv) ** 2)

    res = minimize(obj, [float(np.mean(xv)), float(np.mean(yv))],
                   method="Nelder-Mead")
    return float(res.x[0]), float(res.x[1])


def _compute_bin_metrics(
    x: np.ndarray,
    y: np.ndarray,
    dist: np.ndarray,
    bin_frames: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Split trajectory into non-overlapping bins and compute per-bin metrics.

    Parameters
    ----------
    x, y : position arrays (stimulus period).
    dist : distance-from-centre array (stimulus period).
    bin_frames : number of frames per bin.

    Returns
    -------
    bin_idx : (N,) int — which bin each frame belongs to (-1 = remainder).
    bin_tortuosity : (n_bins,) float — path_length / displacement per bin.
    bin_dist_from_edge : (n_bins,) float — mean distance from arena edge per bin.
    """
    n = len(x)
    n_bins = n // bin_frames

    bin_idx = np.full(n, -1, dtype=int)
    bin_tortuosity = np.full(n_bins, np.nan)
    bin_dist_from_edge = np.full(n_bins, np.nan)

    for b in range(n_bins):
        start = b * bin_frames
        end = start + bin_frames
        bin_idx[start:end] = b

        xb = x[start:end]
        yb = y[start:end]
        db = dist[start:end]

        # Tortuosity = path_length / displacement
        valid = ~np.isnan(xb) & ~np.isnan(yb)
        if valid.sum() > 1:
            xv, yv = xb[valid], yb[valid]
            dx = np.diff(xv)
            dy = np.diff(yv)
            path_length = float(np.sum(np.sqrt(dx ** 2 + dy ** 2)))
            displacement = float(np.sqrt((xv[-1] - xv[0]) ** 2 +
                                         (yv[-1] - yv[0]) ** 2))
            if displacement >= MIN_DISPLACEMENT:
                bin_tortuosity[b] = path_length / displacement

        # Distance from edge
        valid_d = ~np.isnan(db)
        if valid_d.sum() > 0:
            bin_dist_from_edge[b] = ARENA_RADIUS_MM - float(np.nanmean(db[valid_d]))

    return bin_idx, bin_tortuosity, bin_dist_from_edge


def _make_line_collection(
    x: np.ndarray,
    y: np.ndarray,
    per_frame_values: np.ndarray,
    cmap,
    vmin: float,
    vmax: float,
    linewidth: float = 1.5,
) -> LineCollection:
    """Build a LineCollection coloured by *per_frame_values*.

    Each segment connects frame i to frame i+1 and is coloured by the
    mean of the two endpoint values.
    """
    points = np.column_stack([x, y]).reshape(-1, 1, 2)
    segments = np.concatenate([points[:-1], points[1:]], axis=1)

    seg_values = 0.5 * (per_frame_values[:-1] + per_frame_values[1:])

    valid_mask = (
        ~np.isnan(x[:-1]) & ~np.isnan(x[1:])
        & ~np.isnan(y[:-1]) & ~np.isnan(y[1:])
        & ~np.isnan(seg_values)
    )

    norm = plt.Normalize(vmin=vmin, vmax=vmax)
    lc = LineCollection(
        segments[valid_mask],
        cmap=cmap,
        norm=norm,
        linewidth=linewidth,
    )
    lc.set_array(seg_values[valid_mask])
    return lc


# ---------------------------------------------------------------------------
# Main public function
# ---------------------------------------------------------------------------

def plot_trajectory_colorby(
    fly_id: int,
    time_bin_s: float,
    fly_traces: list[dict] | None = None,
    strain: str = DEFAULT_STRAIN,
) -> plt.Figure:
    """Create a 1x3 trajectory figure with three different colourings.

    Parameters
    ----------
    fly_id : int
        1-indexed fly number in the QC-passed dataset for *strain*.
        Use ``load_traces()`` to see how many flies are available.
    time_bin_s : float
        Duration of each time bin in seconds.  The stimulus trajectory
        (~30 s) is split into non-overlapping chunks of this length.
    fly_traces : list of dicts, optional
        Pre-loaded data (output of ``load_traces()``).  Loaded from disk
        automatically if *None*.
    strain : str
        Strain folder name.  Only used when *fly_traces* is *None*.

    Returns
    -------
    matplotlib.figure.Figure
    """
    if fly_traces is None:
        fly_traces = load_traces(strain)

    n_flies = len(fly_traces)
    if fly_id < 1 or fly_id > n_flies:
        raise ValueError(
            f"fly_id must be between 1 and {n_flies} (got {fly_id}). "
            f"Dataset has {n_flies} QC-passed flies."
        )

    trace = fly_traces[fly_id - 1]   # convert to 0-indexed
    x_full = trace["x"]
    y_full = trace["y"]
    dist_full = trace["dist"]

    # Stimulus period only
    stim_end = min(STIM_OFFSET_FRAME, len(x_full))
    x = x_full[BASELINE_FRAMES:stim_end].copy()
    y = y_full[BASELINE_FRAMES:stim_end].copy()
    dist = dist_full[BASELINE_FRAMES:stim_end].copy()

    n_frames = len(x)
    bin_frames = max(1, int(round(time_bin_s * FPS)))
    n_bins = n_frames // bin_frames

    if n_bins < 2:
        raise ValueError(
            f"time_bin_s={time_bin_s}s produces only {n_bins} bin(s) for a "
            f"{n_frames / FPS:.1f}s stimulus trajectory.  Use a smaller value."
        )

    bin_idx, bin_tortuosity, bin_dist_from_edge = _compute_bin_metrics(
        x, y, dist, bin_frames
    )

    # Expand bin metrics to per-frame arrays (used for segment colouring)
    frame_bin = bin_idx.astype(float)
    frame_bin[bin_idx < 0] = np.nan

    frame_tortuosity = np.full(n_frames, np.nan)
    frame_dist_from_edge = np.full(n_frames, np.nan)
    for b in range(n_bins):
        mask = bin_idx == b
        if not np.isnan(bin_tortuosity[b]):
            frame_tortuosity[mask] = bin_tortuosity[b]
        if not np.isnan(bin_dist_from_edge[b]):
            frame_dist_from_edge[mask] = bin_dist_from_edge[b]

    # Arena boundary circle
    cx, cy = _estimate_arena_centre(x, y, dist)
    theta = np.linspace(0, 2 * np.pi, 300)
    arena_x = cx + ARENA_RADIUS_MM * np.cos(theta)
    arena_y = cy + ARENA_RADIUS_MM * np.sin(theta)

    # Shared axis limits
    valid_x = x[~np.isnan(x)]
    valid_y = y[~np.isnan(y)]
    pad = 10.0
    if len(valid_x) > 0:
        xlim = (float(valid_x.min()) - pad, float(valid_x.max()) + pad)
        ylim = (float(valid_y.min()) - pad, float(valid_y.max()) + pad)
    else:
        xlim = ylim = (-ARENA_RADIUS_MM - pad, ARENA_RADIUS_MM + pad)

    # Colour scale bounds
    valid_tort = bin_tortuosity[~np.isnan(bin_tortuosity)]
    t_vmin = 1.0
    t_vmax = float(np.percentile(valid_tort, 95)) if len(valid_tort) > 0 else 5.0
    t_vmax = max(t_vmax, 2.0)

    valid_dfe = bin_dist_from_edge[~np.isnan(bin_dist_from_edge)]
    d_vmin = 0.0
    d_vmax = float(np.nanmax(valid_dfe)) if len(valid_dfe) > 0 else ARENA_RADIUS_MM

    # ---------------------------------------------------------------------------
    # Figure
    # ---------------------------------------------------------------------------
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    fig.suptitle(
        f"Fly {fly_id} of {n_flies}  |  strain: {strain}\n"
        f"Time bin: {time_bin_s:.1f} s  ({n_bins} bins × {bin_frames} frames  "
        f"= {bin_frames / FPS:.1f} s each)",
        fontsize=11, y=1.03,
    )

    # --- Subplot 1: time bin index (categorical) ---
    ax = axes[0]
    ax.plot(arena_x, arena_y, color="lightgrey", lw=0.8, zorder=0)
    cmap1 = cm.get_cmap("tab20" if n_bins <= 20 else "hsv", n_bins)
    lc1 = _make_line_collection(x, y, frame_bin, cmap1, 0, n_bins - 1, linewidth=1.5)
    ax.add_collection(lc1)
    sm1 = cm.ScalarMappable(cmap=cmap1, norm=plt.Normalize(0, n_bins - 1))
    sm1.set_array([])
    cbar1 = fig.colorbar(sm1, ax=ax, shrink=0.75, pad=0.02)
    cbar1.set_label("Time bin", fontsize=9)
    cbar1.set_ticks([0, n_bins - 1])
    cbar1.set_ticklabels(["1", str(n_bins)])
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_aspect("equal")
    ax.set_title("Time bin index", fontsize=11)
    ax.set_xlabel("x (mm)")
    ax.set_ylabel("y (mm)")
    ax.tick_params(direction="out")

    # --- Subplot 2: tortuosity ---
    ax = axes[1]
    ax.plot(arena_x, arena_y, color="lightgrey", lw=0.8, zorder=0)
    lc2 = _make_line_collection(x, y, frame_tortuosity, "inferno",
                                 t_vmin, t_vmax, linewidth=1.5)
    ax.add_collection(lc2)
    sm2 = cm.ScalarMappable(cmap="inferno", norm=plt.Normalize(t_vmin, t_vmax))
    sm2.set_array([])
    cbar2 = fig.colorbar(sm2, ax=ax, shrink=0.75, pad=0.02)
    cbar2.set_label("Tortuosity", fontsize=9)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_aspect("equal")
    ax.set_title("Tortuosity", fontsize=11)
    ax.set_xlabel("x (mm)")
    ax.set_yticklabels([])
    ax.tick_params(direction="out")

    # --- Subplot 3: distance from edge ---
    ax = axes[2]
    ax.plot(arena_x, arena_y, color="lightgrey", lw=0.8, zorder=0)
    lc3 = _make_line_collection(x, y, frame_dist_from_edge, "plasma",
                                 d_vmin, d_vmax, linewidth=1.5)
    ax.add_collection(lc3)
    sm3 = cm.ScalarMappable(cmap="plasma", norm=plt.Normalize(d_vmin, d_vmax))
    sm3.set_array([])
    cbar3 = fig.colorbar(sm3, ax=ax, shrink=0.75, pad=0.02)
    cbar3.set_label("Distance from edge (mm)", fontsize=9)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_aspect("equal")
    ax.set_title("Distance from edge", fontsize=11)
    ax.set_xlabel("x (mm)")
    ax.set_yticklabels([])
    ax.tick_params(direction="out")

    plt.tight_layout()
    return fig


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Plot a single fly trajectory coloured three ways."
    )
    parser.add_argument(
        "--fly_id", type=int, required=True,
        help="1-indexed fly number in the QC-passed dataset.",
    )
    parser.add_argument(
        "--time_bin", type=float, default=2.0,
        help="Time bin duration in seconds (default: 2.0).",
    )
    parser.add_argument(
        "--strain", type=str, default=DEFAULT_STRAIN,
        help=f"Strain folder name (default: {DEFAULT_STRAIN}).",
    )
    parser.add_argument(
        "--output", type=str, default=None,
        help="Output file path (default: figures dir / traj_flyN_Xs.png).",
    )
    parser.add_argument(
        "--show", action="store_true",
        help="Display the figure interactively instead of saving.",
    )
    return parser.parse_args()


def main() -> None:
    args = _parse_args()

    fly_traces = load_traces(args.strain)
    fig = plot_trajectory_colorby(
        fly_id=args.fly_id,
        time_bin_s=args.time_bin,
        fly_traces=fly_traces,
        strain=args.strain,
    )

    if args.show:
        matplotlib.use("TkAgg")
        plt.show()
    else:
        if args.output:
            out_path = Path(args.output)
        else:
            out_path = (
                FIGURES_PATH
                / f"traj_fly{args.fly_id}_{args.time_bin:.1f}s_{args.strain}.png"
            )
        out_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(out_path, dpi=150, bbox_inches="tight")
        print(f"Saved: {out_path}")


if __name__ == "__main__":
    main()

"""Interactive tortuosity analysis for freely-walking optomotor experiments.

Generates a standalone HTML page with interactive Plotly plots showing
the relationship between trajectory tortuosity and distance from the
arena edge during condition 1 (60° gratings, 4Hz).

Usage:
    python -m analysis.tortuosity_explorer                     # control strain
    python -m analysis.tortuosity_explorer --strain ss2571_T5_shibire_kir
    python -m analysis.tortuosity_explorer --output /tmp/out.html
"""

import argparse
import sys
import warnings
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# Ensure repo root is importable
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from config.config import FIGURES_PATH, REPO_ROOT, RESULTS_PATH
from dashboard.constants import BASELINE_FRAMES, FPS, STIM_OFFSET_FRAME
from dashboard.processing import (
    get_log_entries,
    load_mat_file,
    segment_condition,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
ARENA_RADIUS_MM = 119.0  # 496 pixels / 4.1691 PPM
CONDITION_N = 1
TORTUOSITY_METRICS = ["x_data", "y_data", "heading_data", "dist_data", "fv_data"]
DEFAULT_STRAIN = "jfrc100_es_shibire_kir"

# Window sizes in seconds → frames
WINDOW_SIZES_S = [0.5, 1.0, 2.0, 3.0, 5.0, 7.0]
WINDOW_SIZES_F = [int(ws * FPS) for ws in WINDOW_SIZES_S]

# Trajectory subplot windows (1s, 3s, 7s)
TRAJ_WINDOWS_S = [1.0, 3.0, 7.0]
TRAJ_WINDOWS_F = [int(ws * FPS) for ws in TRAJ_WINDOWS_S]

# Displacement threshold below which tortuosity is undefined (mm)
MIN_DISPLACEMENT = 0.5

# Tortuosity display cap (values above this are clipped for visualisation)
MAX_TORTUOSITY = 30.0

# Distance bins for radial profiles
N_DIST_BINS = 12
DIST_BIN_EDGES = np.linspace(0, ARENA_RADIUS_MM, N_DIST_BINS + 1)
DIST_BIN_CENTRES = 0.5 * (DIST_BIN_EDGES[:-1] + DIST_BIN_EDGES[1:])

# Zone boundaries for time-course plot (distance from center)
ZONE_EDGES = [(0, 30), (30, 60), (60, 90), (90, ARENA_RADIUS_MM)]
ZONE_LABELS = ["Inner (0–30 mm)", "Inner-mid (30–60 mm)", "Outer-mid (60–90 mm)", "Outer (90–119 mm)"]
ZONE_COLORS = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728"]

# 2D histogram bins
N_HIST_BINS = 50


# ---------------------------------------------------------------------------
# Computation
# ---------------------------------------------------------------------------
def compute_windowed_tortuosity(
    x: np.ndarray, y: np.ndarray, window_frames: int
) -> np.ndarray:
    """Compute windowed tortuosity for a single fly trace.

    tortuosity = path_length / displacement over the window.
    Returns array of same length as x, with NaN at edges and where
    displacement is below threshold.
    """
    n = len(x)
    half_w = window_frames // 2
    tortuosity = np.full(n, np.nan)

    dx = np.diff(x)
    dy = np.diff(y)
    step_dist = np.sqrt(dx**2 + dy**2)
    # NaN-safe cumulative sum
    step_dist_safe = np.where(np.isnan(step_dist), 0.0, step_dist)
    cum_path = np.concatenate([[0.0], np.cumsum(step_dist_safe)])

    for t in range(half_w, n - half_w):
        t_start = t - half_w
        t_end = t + half_w

        if np.isnan(x[t_start]) or np.isnan(x[t_end]):
            continue

        path_length = cum_path[t_end] - cum_path[t_start]
        displacement = np.sqrt(
            (x[t_end] - x[t_start]) ** 2 + (y[t_end] - y[t_start]) ** 2
        )

        if displacement < MIN_DISPLACEMENT:
            continue

        tortuosity[t] = path_length / displacement

    return tortuosity


def compute_full_rotations(
    x: np.ndarray,
    y: np.ndarray,
    heading_unwrapped: np.ndarray,
    dist_data: np.ndarray,
) -> list[dict]:
    """Detect full 360° heading rotations and characterise each.

    Returns list of dicts with rotation event properties.
    """
    heading_diff = np.diff(heading_unwrapped)
    dx = np.diff(x)
    dy = np.diff(y)
    step_dist = np.sqrt(dx**2 + dy**2)

    rotations = []
    cumulative_heading = 0.0
    cumulative_path = 0.0
    segment_start = 0

    for i in range(len(heading_diff)):
        dh = heading_diff[i]
        if np.isnan(dh):
            cumulative_heading = 0.0
            cumulative_path = 0.0
            segment_start = i + 1
            continue

        cumulative_heading += dh
        sd = step_dist[i]
        if not np.isnan(sd):
            cumulative_path += sd

        if abs(cumulative_heading) >= 360.0:
            seg = slice(segment_start, i + 2)
            mean_dist_center = np.nanmean(dist_data[seg])
            duration = i + 1 - segment_start

            rotations.append(
                {
                    "direction": "ccw" if cumulative_heading > 0 else "cw",
                    "path_length": cumulative_path,
                    "effective_radius": cumulative_path / (2 * np.pi),
                    "mean_dist_center": mean_dist_center,
                    "dist_from_edge": ARENA_RADIUS_MM - mean_dist_center,
                    "duration_frames": duration,
                    "duration_s": duration / FPS,
                    "period": _frame_period((segment_start + i + 1) // 2),
                    "frame_start": segment_start,
                    "frame_end": i + 1,
                }
            )

            cumulative_heading = 0.0
            cumulative_path = 0.0
            segment_start = i + 1

    return rotations


def _frame_period(frame_idx: int) -> str:
    """Classify a frame index as 'baseline', 'stimulus', or 'interval'."""
    if frame_idx < BASELINE_FRAMES:
        return "baseline"
    elif frame_idx < STIM_OFFSET_FRAME:
        return "stimulus"
    return "interval"


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------
def load_condition_data(data_dir: Path) -> tuple[list[dict], int, int]:
    """Load condition 1 data from all .mat files in data_dir.

    Returns:
        fly_traces: list of dicts with per-fly arrays for one rep
        n_files: number of files loaded
        n_excluded: number of flies excluded by QC
    """
    mat_files = sorted(data_dir.glob("*.mat"))
    if not mat_files:
        print(f"No .mat files found in {data_dir}")
        sys.exit(1)

    fly_traces = []
    n_files = 0
    n_excluded = 0

    for filepath in mat_files:
        try:
            log, comb_data, _n_fly = load_mat_file(filepath)
        except Exception as e:
            print(f"  Skipping {filepath.name}: {e}")
            continue

        entries = get_log_entries(log)
        cond1_entries = [e for e in entries if e["which_condition"] == CONDITION_N]

        if not cond1_entries:
            continue

        n_files += 1

        for entry in cond1_entries:
            segment = segment_condition(comb_data, entry, TORTUOSITY_METRICS)
            if "x_data" not in segment or "fv_data" not in segment:
                continue

            # QC: mean fv > 3 mm/s AND mean dist < 110 mm during stimulus
            n_flies = segment["fv_data"].shape[0]
            n_seg_frames = segment["fv_data"].shape[1]
            stim_end = min(STIM_OFFSET_FRAME, n_seg_frames)
            stim_slice = slice(BASELINE_FRAMES, stim_end)

            for fly_idx in range(n_flies):
                fv_stim = segment["fv_data"][fly_idx, stim_slice]
                dist_stim = segment["dist_data"][fly_idx, stim_slice]

                mean_fv = np.nanmean(fv_stim)
                mean_dist = np.nanmean(dist_stim)

                if mean_fv < 3.0 or mean_dist > 110.0:
                    n_excluded += 1
                    continue

                fly_traces.append(
                    {
                        "x": segment["x_data"][fly_idx].copy(),
                        "y": segment["y_data"][fly_idx].copy(),
                        "heading": segment["heading_data"][fly_idx].copy(),
                        "dist": segment["dist_data"][fly_idx].copy(),
                        "fv": segment["fv_data"][fly_idx].copy(),
                    }
                )

    return fly_traces, n_files, n_excluded


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------
def aggregate_all(
    fly_traces: list[dict],
) -> dict:
    """Compute all metrics and aggregate for plotting."""
    n_flies = len(fly_traces)
    raw_n_frames = fly_traces[0]["x"].shape[0] if fly_traces else 0
    # Limit to baseline + stimulus (exclude interval)
    n_frames = min(raw_n_frames, STIM_OFFSET_FRAME)

    # Per-window tortuosity + distance arrays (for histograms and profiles)
    hist2d_data = {}  # (ws_idx, period) -> (dist_from_edge[], tortuosity[])
    profile_data = {}  # (ws_idx, period) -> per-bin lists
    timecourse_data = {}  # (ws_idx, zone_idx) -> list of tortuosity timeseries

    # Initialise containers
    for ws_idx in range(len(WINDOW_SIZES_F)):
        for period in ("baseline", "stimulus"):
            hist2d_data[(ws_idx, period)] = ([], [])
            profile_data[(ws_idx, period)] = {
                b: [] for b in range(N_DIST_BINS)
            }
        for z_idx in range(len(ZONE_EDGES)):
            timecourse_data[(ws_idx, z_idx)] = []

    # Full rotation events
    all_rotations = []

    # 1D histogram data by zone and by period
    zone_tort_data = {}   # (ws_idx, zone_idx) -> list of tort values (stimulus)
    period_tort_data = {}  # (ws_idx, period) -> list of tort values

    for ws_idx in range(len(WINDOW_SIZES_F)):
        for z_idx in range(len(ZONE_EDGES)):
            zone_tort_data[(ws_idx, z_idx)] = []
        for period in ("baseline", "stimulus"):
            period_tort_data[(ws_idx, period)] = []

    # Example trajectories: pick flies from different distance zones
    zone_examples = {z: [] for z in range(len(ZONE_EDGES))}

    print(f"  Computing metrics for {n_flies} flies...")

    for fly_i, trace in enumerate(fly_traces):
        x, y = trace["x"], trace["y"]
        heading = trace["heading"]
        dist = trace["dist"]
        dist_from_edge = ARENA_RADIUS_MM - dist

        # Mean distance from center during stimulus (for zone assignment)
        stim_end_fly = min(STIM_OFFSET_FRAME, len(dist))
        mean_dist_center = np.nanmean(dist[BASELINE_FRAMES:stim_end_fly])
        zone_idx = _assign_zone(mean_dist_center)

        # Collect example trajectories (up to 5 per zone)
        if len(zone_examples[zone_idx]) < 5:
            zone_examples[zone_idx].append(fly_i)

        # Full rotations
        rots = compute_full_rotations(x, y, heading, dist)
        all_rotations.extend(rots)

        # Windowed tortuosity at each scale
        for ws_idx, wf in enumerate(WINDOW_SIZES_F):
            tort = compute_windowed_tortuosity(x, y, wf)
            tort_clipped = np.clip(tort, 1.0, MAX_TORTUOSITY)

            # Split baseline / stimulus (exclude post-stimulus interval)
            n_seg = len(tort_clipped)
            stim_end = min(STIM_OFFSET_FRAME, n_seg)
            for period, sl in [
                ("baseline", slice(0, BASELINE_FRAMES)),
                ("stimulus", slice(BASELINE_FRAMES, stim_end)),
            ]:
                valid = ~np.isnan(tort_clipped[sl])
                t_vals = tort_clipped[sl][valid]
                d_vals = dist_from_edge[sl][valid]

                hist2d_data[(ws_idx, period)][0].extend(d_vals.tolist())
                hist2d_data[(ws_idx, period)][1].extend(t_vals.tolist())

                # Collect for 1D period histogram
                period_tort_data[(ws_idx, period)].extend(t_vals.tolist())

                # Collect for 1D zone histogram (stimulus only)
                if period == "stimulus":
                    dist_center_vals = dist[sl][valid]
                    for z_idx_h, (z_lo, z_hi) in enumerate(ZONE_EDGES):
                        z_mask = (dist_center_vals >= z_lo) & (
                            dist_center_vals < z_hi
                        )
                        if z_mask.any():
                            zone_tort_data[(ws_idx, z_idx_h)].extend(
                                t_vals[z_mask].tolist()
                            )

                # Bin into distance zones for profile
                for b_idx in range(N_DIST_BINS):
                    mask = (d_vals >= DIST_BIN_EDGES[b_idx]) & (
                        d_vals < DIST_BIN_EDGES[b_idx + 1]
                    )
                    if mask.any():
                        profile_data[(ws_idx, period)][b_idx].extend(
                            t_vals[mask].tolist()
                        )

            # Time course: tortuosity per frame (baseline + stimulus only)
            tc_end = min(stim_end, len(tort_clipped))
            timecourse_data[(ws_idx, zone_idx)].append(tort_clipped[:tc_end])

    # Build aggregated structures
    histograms = _build_histograms(hist2d_data)
    profiles = _build_profiles(profile_data)
    timecourses = _build_timecourses(timecourse_data, n_frames)

    # Select example fly indices (all collected, up to 5 per zone)
    example_indices = []
    for z in range(len(ZONE_EDGES)):
        example_indices.extend(zone_examples[z])

    # Find real high/low tortuosity trajectory snippets (5s window) for explanation
    tort_examples = _find_tort_examples(fly_traces)

    return {
        "histograms": histograms,
        "profiles": profiles,
        "timecourses": timecourses,
        "rotations": all_rotations,
        "example_indices": example_indices,
        "zone_tort_data": zone_tort_data,
        "period_tort_data": period_tort_data,
        "n_frames": n_frames,
        "tort_examples": tort_examples,
    }


def _assign_zone(mean_dist_center: float) -> int:
    """Assign a fly to a radial zone based on mean distance from center."""
    for z_idx, (lo, hi) in enumerate(ZONE_EDGES):
        if lo <= mean_dist_center < hi:
            return z_idx
    return len(ZONE_EDGES) - 1


def _find_tort_examples(fly_traces: list[dict]) -> dict:
    """Find real trajectory snippets with high and low tortuosity (5s window).

    Returns dict with 'low' and 'high' keys, each containing
    path_length, displacement, tortuosity, duration_s, and x/y arrays
    for rendering example images.
    """
    ws = int(5.0 * FPS)  # 5s window = 150 frames
    best_low = {"tortuosity": 999.0}
    best_high = {"tortuosity": 0.0}

    for trace in fly_traces[:100]:  # sample first 100 for speed
        x, y = trace["x"], trace["y"]
        stim_end = min(STIM_OFFSET_FRAME, len(x))
        sx = x[BASELINE_FRAMES:stim_end]
        sy = y[BASELINE_FRAMES:stim_end]
        if len(sx) < ws:
            continue

        dx = np.diff(sx)
        dy = np.diff(sy)
        step_dist = np.sqrt(dx**2 + dy**2)
        step_safe = np.where(np.isnan(step_dist), 0.0, step_dist)
        cum_path = np.concatenate([[0.0], np.cumsum(step_safe)])

        for t in range(0, len(sx) - ws, ws // 2):
            t_end = t + ws
            if np.isnan(sx[t]) or np.isnan(sx[t_end]):
                continue
            path_length = cum_path[t_end] - cum_path[t]
            disp = np.sqrt((sx[t_end] - sx[t])**2 + (sy[t_end] - sy[t])**2)
            if disp < MIN_DISPLACEMENT:
                continue
            tort = path_length / disp

            if tort < best_low["tortuosity"]:
                best_low = {"tortuosity": round(tort, 2),
                            "path_length": round(path_length, 1),
                            "displacement": round(disp, 1),
                            "duration_s": 5.0,
                            "x": sx[t:t_end + 1].copy(),
                            "y": sy[t:t_end + 1].copy()}
            if tort > best_high["tortuosity"] and tort < MAX_TORTUOSITY:
                best_high = {"tortuosity": round(tort, 2),
                             "path_length": round(path_length, 1),
                             "displacement": round(disp, 1),
                             "duration_s": 5.0,
                             "x": sx[t:t_end + 1].copy(),
                             "y": sy[t:t_end + 1].copy()}

    return {"low": best_low, "high": best_high}


def _build_histograms(
    hist2d_data: dict,
) -> dict:
    """Build 2D histograms for each (window_size, period)."""
    tort_bins = np.linspace(1.0, MAX_TORTUOSITY, N_HIST_BINS + 1)
    dist_bins = np.linspace(0, ARENA_RADIUS_MM, N_HIST_BINS + 1)

    histograms = {}
    for (ws_idx, period), (d_vals, t_vals) in hist2d_data.items():
        if len(d_vals) == 0:
            histograms[(ws_idx, period)] = np.zeros((N_HIST_BINS, N_HIST_BINS))
            continue
        h, _, _ = np.histogram2d(
            d_vals, t_vals, bins=[dist_bins, tort_bins]
        )
        histograms[(ws_idx, period)] = h

    histograms["dist_bins"] = dist_bins
    histograms["tort_bins"] = tort_bins
    return histograms


def _build_profiles(profile_data: dict) -> dict:
    """Compute mean ± SEM tortuosity per distance bin."""
    profiles = {}
    for (ws_idx, period), bin_dict in profile_data.items():
        means = np.full(N_DIST_BINS, np.nan)
        sems = np.full(N_DIST_BINS, np.nan)
        counts = np.zeros(N_DIST_BINS, dtype=int)
        for b in range(N_DIST_BINS):
            vals = bin_dict[b]
            if len(vals) > 1:
                means[b] = np.mean(vals)
                sems[b] = np.std(vals) / np.sqrt(len(vals))
                counts[b] = len(vals)
        profiles[(ws_idx, period)] = {
            "mean": means,
            "sem": sems,
            "count": counts,
        }
    return profiles


def _build_timecourses(timecourse_data: dict, n_frames: int) -> dict:
    """Compute mean tortuosity time course per zone."""
    timecourses = {}
    for (ws_idx, z_idx), traces_list in timecourse_data.items():
        if not traces_list or n_frames == 0:
            timecourses[(ws_idx, z_idx)] = {
                "mean": np.array([]),
                "sem": np.array([]),
            }
            continue
        # Stack all fly timeseries for this zone
        stacked = np.array(
            [t[:n_frames] for t in traces_list if len(t) >= n_frames]
        )
        if stacked.ndim < 2 or stacked.shape[0] == 0:
            timecourses[(ws_idx, z_idx)] = {
                "mean": np.full(n_frames, np.nan),
                "sem": np.full(n_frames, np.nan),
            }
            continue
        with np.errstate(all="ignore"):
            mean_tc = np.nanmean(stacked, axis=0)
            n_valid = np.sum(~np.isnan(stacked), axis=0)
            sem_tc = np.nanstd(stacked, axis=0) / np.sqrt(
                np.maximum(n_valid, 1)
            )
        timecourses[(ws_idx, z_idx)] = {"mean": mean_tc, "sem": sem_tc}
    return timecourses


# ---------------------------------------------------------------------------
# Plotly figure builders
# ---------------------------------------------------------------------------
def _hex_to_rgba(hex_color: str, opacity: float) -> str:
    """Convert hex colour to rgba string."""
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f"rgba({r},{g},{b},{opacity})"


def _hist_stats(vals: list) -> dict:
    """Compute summary stats for a distribution."""
    if not vals:
        return {"mean": np.nan, "median": np.nan, "std": np.nan, "n": 0}
    a = np.array(vals)
    return {
        "mean": float(np.nanmean(a)),
        "median": float(np.nanmedian(a)),
        "std": float(np.nanstd(a)),
        "n": len(a),
    }


def make_tortuosity_histograms(
    zone_tort_data: dict, period_tort_data: dict
) -> tuple[go.Figure, dict]:
    """Plot A: Tortuosity distributions — single plot with zone + baseline lines.

    Returns (figure, all_stats) where all_stats[ws_idx] has stats for each
    window size (used for dynamic JS table).
    """
    import json as _json

    hist_bins = np.linspace(1.0, MAX_TORTUOSITY, 80)
    bin_centres = 0.5 * (hist_bins[:-1] + hist_bins[1:])

    fig = go.Figure()

    # Trace order: 3 zone lines + 3 zone vlines + 1 baseline line + 1 baseline vline = 8
    # Compute global max for vertical line heights
    def _global_max(ws_idx):
        ymax = 0
        for z_idx in range(len(ZONE_EDGES)):
            vals = zone_tort_data.get((ws_idx, z_idx), [])
            if vals:
                c, _ = np.histogram(vals, bins=hist_bins)
                ymax = max(ymax, int(c.max()))
        vals = period_tort_data.get((ws_idx, "baseline"), [])
        if vals:
            c, _ = np.histogram(vals, bins=hist_bins)
            ymax = max(ymax, int(c.max()))
        return ymax

    gmax = _global_max(0)

    # --- Zone distributions (stimulus) ---
    for z_idx in range(len(ZONE_EDGES)):
        vals = zone_tort_data.get((0, z_idx), [])
        stats = _hist_stats(vals)
        counts, _ = np.histogram(vals, bins=hist_bins) if vals else (
            np.zeros(len(hist_bins) - 1), None)
        fig.add_trace(go.Scatter(
            x=bin_centres.tolist(), y=counts.tolist(),
            mode="lines", name=ZONE_LABELS[z_idx],
            line=dict(color=ZONE_COLORS[z_idx], width=2),
            fill="tozeroy", fillcolor=_hex_to_rgba(ZONE_COLORS[z_idx], 0.15),
            showlegend=True,
        ))
        fig.add_trace(go.Scatter(
            x=[stats["mean"], stats["mean"]], y=[0, gmax],
            mode="lines", line=dict(color=ZONE_COLORS[z_idx], width=2, dash="dash"),
            showlegend=False, hoverinfo="skip",
        ))

    # --- Baseline (all zones combined) ---
    bvals = period_tort_data.get((0, "baseline"), [])
    bstats = _hist_stats(bvals)
    bcounts, _ = np.histogram(bvals, bins=hist_bins) if bvals else (
        np.zeros(len(hist_bins) - 1), None)
    fig.add_trace(go.Scatter(
        x=bin_centres.tolist(), y=bcounts.tolist(),
        mode="lines", name="Baseline (all zones)",
        line=dict(color="grey", width=2),
        fill="tozeroy", fillcolor="rgba(150,150,150,0.1)",
        showlegend=True,
    ))
    fig.add_trace(go.Scatter(
        x=[bstats["mean"], bstats["mean"]], y=[0, gmax],
        mode="lines", line=dict(color="grey", width=2, dash="dash"),
        showlegend=False, hoverinfo="skip",
    ))

    # Frames for slider
    frames = []
    all_stats = {}
    for ws_idx, ws_s in enumerate(WINDOW_SIZES_S):
        frame_data = []
        ws_gmax = _global_max(ws_idx)
        ws_zone_stats = {}

        for z_idx in range(len(ZONE_EDGES)):
            vals = zone_tort_data.get((ws_idx, z_idx), [])
            stats = _hist_stats(vals)
            ws_zone_stats[z_idx] = stats
            counts, _ = np.histogram(vals, bins=hist_bins) if vals else (
                np.zeros(len(hist_bins) - 1), None)
            frame_data.append(go.Scatter(
                x=bin_centres.tolist(), y=counts.tolist(),
                mode="lines", name=ZONE_LABELS[z_idx],
                line=dict(color=ZONE_COLORS[z_idx], width=2),
                fill="tozeroy", fillcolor=_hex_to_rgba(ZONE_COLORS[z_idx], 0.15),
            ))
            frame_data.append(go.Scatter(
                x=[stats["mean"], stats["mean"]], y=[0, ws_gmax],
                mode="lines", line=dict(color=ZONE_COLORS[z_idx], width=2, dash="dash"),
                showlegend=False, hoverinfo="skip",
            ))

        bvals_ws = period_tort_data.get((ws_idx, "baseline"), [])
        bstats_ws = _hist_stats(bvals_ws)
        bcounts_ws, _ = np.histogram(bvals_ws, bins=hist_bins) if bvals_ws else (
            np.zeros(len(hist_bins) - 1), None)
        frame_data.append(go.Scatter(
            x=bin_centres.tolist(), y=bcounts_ws.tolist(),
            mode="lines", name="Baseline (all zones)",
            line=dict(color="grey", width=2),
            fill="tozeroy", fillcolor="rgba(150,150,150,0.1)",
        ))
        frame_data.append(go.Scatter(
            x=[bstats_ws["mean"], bstats_ws["mean"]], y=[0, ws_gmax],
            mode="lines", line=dict(color="grey", width=2, dash="dash"),
            showlegend=False, hoverinfo="skip",
        ))

        frames.append(go.Frame(data=frame_data, name=f"{ws_s}s"))
        all_stats[ws_idx] = {"zones": ws_zone_stats, "baseline": bstats_ws}

    fig.frames = frames

    sliders = [dict(
        active=0, currentvalue=dict(prefix="Window: "), pad=dict(t=60),
        steps=[dict(
            label=f"{ws}s", method="animate",
            args=[[f"{ws}s"], dict(mode="immediate", frame=dict(duration=0, redraw=True))],
        ) for ws in WINDOW_SIZES_S],
    )]

    fig.update_layout(
        sliders=sliders, height=450,
        title_text="Tortuosity Distributions by Distance Zone",
        xaxis_title="Tortuosity",
        yaxis_title="Count",
    )

    return fig, all_stats


def _arena_zone_svg() -> str:
    """Generate an inline SVG showing the arena with coloured distance zones.

    Draws from outer to inner with solid pastel fills so each ring is distinct.
    Labels: zone title above, distance range below.
    """
    scale = 90.0 / ARENA_RADIUS_MM
    cx, cy = 110, 110
    svg_w, svg_h = 220, 240

    # Pastel fill colours matching ZONE_COLORS order (blue, orange, green, red)
    pastel_fills = ["#c4daf4", "#fce4b8", "#c8e6c9", "#f4c7c3"]
    # Short zone names (without distance)
    zone_names = ["Inner", "Inner-mid", "Outer-mid", "Outer"]

    # Draw circles from outer to inner
    circles = ""
    labels = ""
    for z_idx in range(len(ZONE_EDGES) - 1, -1, -1):
        _, z_hi = ZONE_EDGES[z_idx]
        z_lo, _ = ZONE_EDGES[z_idx]
        r = z_hi * scale
        stroke = ' stroke="#999" stroke-width="1"' if z_idx == len(ZONE_EDGES) - 1 else ' stroke="none"'
        circles += f'  <circle cx="{cx}" cy="{cy}" r="{r:.1f}" fill="{pastel_fills[z_idx]}"{stroke}/>\n'

        # Label position: midpoint of the ring
        r_mid = 0.5 * (z_lo + z_hi) * scale
        label_y = cy - r_mid
        labels += (
            f'  <text x="{cx}" y="{label_y:.0f}" text-anchor="middle" '
            f'font-size="9" font-weight="600" fill="{ZONE_COLORS[z_idx]}">{zone_names[z_idx]}</text>\n'
            f'  <text x="{cx}" y="{label_y + 11:.0f}" text-anchor="middle" '
            f'font-size="7" fill="#666">{int(z_lo)}–{int(z_hi)} mm</text>\n'
        )

    # Centre dot + caption
    centre = (
        f'  <circle cx="{cx}" cy="{cy}" r="2" fill="#333"/>\n'
        f'  <text x="{cx}" y="{cy + 6}" text-anchor="middle" font-size="8" fill="#333">centre</text>\n'
    )
    footer = f'  <text x="{cx}" y="{svg_h - 5}" text-anchor="middle" font-size="9" fill="#888">Distance from centre</text>\n'

    return (
        f'<svg width="{svg_w}" height="{svg_h}" viewBox="0 0 {svg_w} {svg_h}" '
        f'style="display:block; margin:0 auto;">\n'
        + circles + centre + labels + footer
        + '</svg>'
    )


def _build_stats_json(all_stats: dict) -> str:
    """Serialize all_stats to JSON for embedding in JS.

    Keys match the Plotly slider step labels (e.g. "0.5s", "1.0s").
    """
    import json as _json
    # Convert to serializable format
    out = {}
    for ws_idx, ws_data in all_stats.items():
        ws_key = f"{WINDOW_SIZES_S[ws_idx]}s"  # matches slider labels exactly
        zones = {}
        for z_idx, s in ws_data["zones"].items():
            zones[str(z_idx)] = {
                k: (round(v, 3) if isinstance(v, float) and not np.isnan(v) else None)
                for k, v in s.items()
            }
        bl = ws_data.get("baseline", {})
        baseline = {
            k: (round(v, 3) if isinstance(v, float) and not np.isnan(v) else None)
            for k, v in bl.items()
        }
        out[ws_key] = {"zones": zones, "baseline": baseline}
    return _json.dumps(out)


def make_profile_plot(profiles: dict) -> go.Figure:
    """Plot B: Mean tortuosity profile by distance zone."""
    fig = go.Figure()

    # Initial traces (first window size)
    for period, color, dash in [
        ("baseline", "grey", "solid"),
        ("stimulus", "#1f77b4", "solid"),
    ]:
        p = profiles[(0, period)]
        fig.add_trace(
            go.Scatter(
                x=DIST_BIN_CENTRES,
                y=p["mean"],
                error_y=dict(type="data", array=p["sem"], visible=True),
                mode="lines+markers",
                name=period.capitalize(),
                line=dict(color=color, dash=dash),
            )
        )

    # Frames
    frames = []
    for ws_idx, ws_s in enumerate(WINDOW_SIZES_S):
        frame_data = []
        for period, color, dash in [
            ("baseline", "grey", "solid"),
            ("stimulus", "#1f77b4", "solid"),
        ]:
            p = profiles[(ws_idx, period)]
            frame_data.append(
                go.Scatter(
                    x=DIST_BIN_CENTRES,
                    y=p["mean"],
                    error_y=dict(type="data", array=p["sem"], visible=True),
                    mode="lines+markers",
                    name=period.capitalize(),
                    line=dict(color=color, dash=dash),
                )
            )
        frames.append(go.Frame(
            data=frame_data, name=f"{ws_s}s",
            layout=dict(yaxis=dict(autorange=True)),
        ))

    fig.frames = frames

    sliders = [
        dict(
            active=0,
            currentvalue=dict(prefix="Window: "),
            pad=dict(t=60),
            steps=[
                dict(
                    label=f"{ws}s",
                    method="animate",
                    args=[
                        [f"{ws}s"],
                        dict(mode="immediate", frame=dict(duration=0, redraw=True)),
                    ],
                )
                for ws in WINDOW_SIZES_S
            ],
        )
    ]

    fig.update_layout(
        sliders=sliders,
        height=450,
        title_text="Mean Tortuosity by Distance from Edge",
        xaxis_title="Distance from edge (mm)",
        yaxis_title="Mean tortuosity &plusmn; SEM",
        yaxis=dict(autorange=True),
    )
    return fig


def make_rotation_histograms(rotations: list[dict]) -> tuple[go.Figure, dict]:
    """Plot C: Histograms of effective turning radius by zone + baseline.

    Similar format to Plot A: zone lines (stimulus) + 1 baseline (grey).
    Excludes rotations overlapping the direction-change window.

    Returns (figure, rotation_stats) where rotation_stats contains per-zone
    and baseline summary statistics for the stats table.
    """
    # Direction change at frame 750; exclude ±2.5s = frames 675-825
    dir_change_frame = 750
    exclude_lo = dir_change_frame - int(2.5 * FPS)
    exclude_hi = dir_change_frame + int(2.5 * FPS)

    if not rotations:
        fig = go.Figure()
        fig.add_annotation(text="No full rotations detected", showarrow=False)
        return fig, {}

    # Filter rotations: exclude direction-change window and interval period
    n_excluded_dirchange = 0
    zone_radii = {z: [] for z in range(len(ZONE_EDGES))}  # stimulus, by zone
    baseline_radii = []

    for r in rotations:
        if r["period"] == "interval":
            continue
        if r["period"] == "stimulus":
            f_start = r.get("frame_start", 0)
            f_end = r.get("frame_end", 0)
            if f_start < exclude_hi and f_end > exclude_lo:
                n_excluded_dirchange += 1
                continue
            # Classify into zone by mean_dist_center
            z_idx = _assign_zone(r["mean_dist_center"])
            zone_radii[z_idx].append(r["effective_radius"])
        elif r["period"] == "baseline":
            baseline_radii.append(r["effective_radius"])

    print(f"  Rotation histogram: {n_excluded_dirchange} rotations excluded "
          f"(direction-change window)")

    # Use log-spaced bins for effective radius
    radius_bins = np.logspace(np.log10(0.3), np.log10(200), 60)
    bin_centres = np.sqrt(radius_bins[:-1] * radius_bins[1:])  # geometric mean

    fig = go.Figure()

    # Compute global max for vline heights
    gmax = 0
    for z_idx in range(len(ZONE_EDGES)):
        if zone_radii[z_idx]:
            c, _ = np.histogram(zone_radii[z_idx], bins=radius_bins)
            gmax = max(gmax, int(c.max()))
    if baseline_radii:
        c, _ = np.histogram(baseline_radii, bins=radius_bins)
        gmax = max(gmax, int(c.max()))

    # Zone distributions (stimulus)
    rotation_stats = {"zones": {}, "baseline": {}}
    for z_idx in range(len(ZONE_EDGES)):
        vals = zone_radii[z_idx]
        stats = _hist_stats(vals)
        rotation_stats["zones"][z_idx] = stats
        if not vals:
            counts = np.zeros(len(radius_bins) - 1)
        else:
            counts, _ = np.histogram(vals, bins=radius_bins)
        median_val = stats["median"]

        fig.add_trace(go.Scatter(
            x=bin_centres.tolist(), y=counts.tolist(),
            mode="lines", name=f"{ZONE_LABELS[z_idx]} (n={len(vals)})",
            line=dict(color=ZONE_COLORS[z_idx], width=2),
            fill="tozeroy", fillcolor=_hex_to_rgba(ZONE_COLORS[z_idx], 0.15),
        ))
        if not np.isnan(median_val):
            fig.add_trace(go.Scatter(
                x=[median_val, median_val], y=[0, gmax],
                mode="lines",
                line=dict(color=ZONE_COLORS[z_idx], width=2, dash="dash"),
                showlegend=False, hoverinfo="skip",
            ))

    # Baseline distribution
    bstats = _hist_stats(baseline_radii)
    rotation_stats["baseline"] = bstats
    if baseline_radii:
        bcounts, _ = np.histogram(baseline_radii, bins=radius_bins)
    else:
        bcounts = np.zeros(len(radius_bins) - 1)
    bmedian = bstats["median"]

    fig.add_trace(go.Scatter(
        x=bin_centres.tolist(), y=bcounts.tolist(),
        mode="lines", name=f"Baseline (n={len(baseline_radii)})",
        line=dict(color="grey", width=2),
        fill="tozeroy", fillcolor="rgba(150,150,150,0.1)",
    ))
    if not np.isnan(bmedian):
        fig.add_trace(go.Scatter(
            x=[bmedian, bmedian], y=[0, gmax],
            mode="lines", line=dict(color="grey", width=2, dash="dash"),
            showlegend=False, hoverinfo="skip",
        ))

    fig.update_layout(
        height=450,
        title_text="Effective Turning Radius by Distance Zone",
        xaxis_title="Effective turning radius (mm)",
        yaxis_title="Count",
        xaxis=dict(type="log"),
    )

    return fig, rotation_stats


def _build_rotation_stats_html(rotation_stats: dict | None) -> str:
    """Build a static HTML table for effective turning radius stats (Plot C)."""
    if not rotation_stats or "zones" not in rotation_stats:
        return ""
    rows = []
    for z_idx in range(len(ZONE_EDGES)):
        zs = rotation_stats["zones"].get(z_idx, {})
        if not zs or zs.get("n", 0) == 0:
            continue
        rows.append(
            f'<tr style="color:{ZONE_COLORS[z_idx]};">'
            f'<td>{ZONE_LABELS[z_idx]}</td>'
            f'<td>{zs["mean"]:.1f}</td>'
            f'<td>{zs["median"]:.1f}</td>'
            f'<td>{zs["std"]:.1f}</td>'
            f'<td>{zs["n"]:,}</td></tr>'
        )
    bl = rotation_stats.get("baseline", {})
    if bl and bl.get("mean") is not None and not np.isnan(bl["mean"]):
        rows.append(
            f'<tr style="color:#888;">'
            f'<td>Baseline (all zones)</td>'
            f'<td>{bl["mean"]:.1f}</td>'
            f'<td>{bl["median"]:.1f}</td>'
            f'<td>{bl["std"]:.1f}</td>'
            f'<td>{bl["n"]:,}</td></tr>'
        )
    if not rows:
        return ""
    return (
        '<table class="stats-table">'
        '<tr><th>Distribution</th><th>Mean (mm)</th><th>Median (mm)</th>'
        '<th>Std (mm)</th><th>N</th></tr>'
        + ''.join(rows)
        + '</table>'
    )


def make_radius_profile(rotations: list[dict]) -> go.Figure:
    """Plot D: Mean effective turning radius profile by distance from edge.

    Similar to Plot B but for effective_radius instead of tortuosity.
    Two traces: baseline (grey) and stimulus (blue) with error bars.
    No slider needed (no window-size parameter for rotations).
    """
    # Direction change at frame 750; exclude ±2.5s = frames 675-825
    dir_change_frame = 750
    exclude_lo = dir_change_frame - int(2.5 * FPS)
    exclude_hi = dir_change_frame + int(2.5 * FPS)

    # Bin rotations by dist_from_edge
    baseline_bins = {b: [] for b in range(N_DIST_BINS)}
    stimulus_bins = {b: [] for b in range(N_DIST_BINS)}

    for r in rotations:
        if r["period"] == "interval":
            continue
        if r["period"] == "stimulus":
            f_start = r.get("frame_start", 0)
            f_end = r.get("frame_end", 0)
            if f_start < exclude_hi and f_end > exclude_lo:
                continue
            target = stimulus_bins
        elif r["period"] == "baseline":
            target = baseline_bins
        else:
            continue

        d_edge = r["dist_from_edge"]
        for b_idx in range(N_DIST_BINS):
            if d_edge >= DIST_BIN_EDGES[b_idx] and d_edge < DIST_BIN_EDGES[b_idx + 1]:
                target[b_idx].append(r["effective_radius"])
                break

    fig = go.Figure()

    for period_name, bins, color in [
        ("Baseline", baseline_bins, "grey"),
        ("Stimulus", stimulus_bins, "#1f77b4"),
    ]:
        means = np.full(N_DIST_BINS, np.nan)
        sems = np.full(N_DIST_BINS, np.nan)
        for b in range(N_DIST_BINS):
            vals = bins[b]
            if len(vals) > 1:
                means[b] = np.mean(vals)
                sems[b] = np.std(vals) / np.sqrt(len(vals))

        fig.add_trace(go.Scatter(
            x=DIST_BIN_CENTRES,
            y=means,
            error_y=dict(type="data", array=sems, visible=True),
            mode="lines+markers",
            name=period_name,
            line=dict(color=color),
        ))

    fig.update_layout(
        height=450,
        title_text="Mean Effective Turning Radius by Distance from Edge",
        xaxis_title="Distance from edge (mm)",
        yaxis_title="Mean effective radius (mm) ± SEM",
    )
    return fig


def _subsample_trajectory(
    x: np.ndarray,
    y: np.ndarray,
    tort: np.ndarray,
    step: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Subsample trajectory at regular intervals for cleaner visualisation.

    At each subsampled point, take the mean position and tortuosity over
    the surrounding `step` frames.
    """
    n = len(x)
    half = step // 2
    indices = np.arange(half, n - half, step)
    if len(indices) == 0:
        return x, y, tort

    sx = np.array([np.nanmean(x[max(0, i - half):i + half]) for i in indices])
    sy = np.array([np.nanmean(y[max(0, i - half):i + half]) for i in indices])
    st = np.array([np.nanmean(tort[max(0, i - half):i + half]) for i in indices])
    return sx, sy, st


def _get_color_bins(n: int = 12, cmin: float = 1.0, cmax: float = 10.0) -> list[tuple[float, float, str]]:
    """Return n colour bins spanning [cmin, cmax] using the Inferno colorscale.

    Each bin is (low, high, hex_colour).
    """
    import matplotlib
    matplotlib.use("Agg")


    edges = np.linspace(cmin, cmax, n + 1)
    cmap = matplotlib.colormaps["inferno"]
    bins = []
    for i in range(n):
        mid = 0.5 * (edges[i] + edges[i + 1])
        norm_val = (mid - cmin) / (cmax - cmin)
        r, g, b, _ = cmap(np.clip(norm_val, 0, 1))
        hex_c = f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"
        bins.append((float(edges[i]), float(edges[i + 1]), hex_c))
    return bins


def make_trajectory_plot(
    fly_traces: list[dict], example_indices: list[int]
) -> go.Figure:
    """Example Trajectory: 3 subplots showing the SAME fly at 1s/3s/7s windows.

    Uses colour-bin approach: N colour bins per subplot, each a separate trace
    with NaN-separated segments for continuous coloured lines.
    Trace layout per subplot: 1 arena + N bins = N+1 traces.
    Total: 3*(N+1) + 1 colorbar = 3*N + 4 traces.
    Dropdown switches all traces at once.
    """
    N_COLOR_BINS = 8
    TORT_CMIN = 1.0

    n_examples = len(example_indices)
    if n_examples == 0:
        fig = go.Figure()
        fig.add_annotation(text="No example trajectories", showarrow=False)
        return fig

    # First pass: compute tortuosity at all 3 windows for adaptive colour range
    all_tort_vals = []
    raw_trajectories = []
    for fly_idx in example_indices:
        trace = fly_traces[fly_idx]
        x, y = trace["x"], trace["y"]
        dist = trace["dist"]
        stim_end = min(STIM_OFFSET_FRAME, len(x))
        stim_x = x[BASELINE_FRAMES:stim_end]
        stim_y = y[BASELINE_FRAMES:stim_end]

        per_window = {}
        for wi, wf in enumerate(TRAJ_WINDOWS_F):
            tort = compute_windowed_tortuosity(x, y, wf)
            tort_clipped = np.clip(tort, TORT_CMIN, MAX_TORTUOSITY)
            stim_tort = tort_clipped[BASELINE_FRAMES:stim_end]
            per_window[wi] = stim_tort
            valid = stim_tort[~np.isnan(stim_tort)]
            if len(valid) > 0:
                all_tort_vals.extend(valid.tolist())

        raw_trajectories.append({
            "x": x, "y": y, "dist": dist,
            "stim_x": stim_x, "stim_y": stim_y,
            "per_window": per_window,
        })

    # Adaptive colour ceiling: 75th percentile
    TORT_CMAX = float(np.percentile(all_tort_vals, 75)) if all_tort_vals else 3.0
    TORT_CMAX = max(TORT_CMAX, 2.0)
    print(f"  Trajectory colour range: {TORT_CMIN:.1f} – {TORT_CMAX:.1f} (75th percentile)")

    color_bins = _get_color_bins(N_COLOR_BINS, TORT_CMIN, TORT_CMAX)

    # Helper: build per-bin x/y arrays for a given stim_tort array
    def _build_bin_xy(stim_x, stim_y, stim_tort):
        seg_tort = 0.5 * (stim_tort[:-1] + stim_tort[1:])
        bin_xy = []
        for b_lo, b_hi, _ in color_bins:
            bx, by = [], []
            in_seg = False
            for j in range(len(seg_tort)):
                t_val = seg_tort[j]
                if np.isnan(t_val) or np.isnan(stim_x[j]) or np.isnan(stim_x[j + 1]):
                    if in_seg:
                        bx.append(np.nan)
                        by.append(np.nan)
                        in_seg = False
                    continue
                in_bin = (t_val >= b_lo and t_val < b_hi) or (
                    b_hi == TORT_CMAX and t_val >= b_lo
                )
                if in_bin:
                    if not in_seg:
                        bx.append(float(stim_x[j]))
                        by.append(float(stim_y[j]))
                        in_seg = True
                    bx.append(float(stim_x[j + 1]))
                    by.append(float(stim_y[j + 1]))
                else:
                    if in_seg:
                        bx.append(np.nan)
                        by.append(np.nan)
                        in_seg = False
            bin_xy.append((bx, by))
        return bin_xy

    # Second pass: build per-fly, per-window bin segments
    trajectories = []
    for i, fly_idx in enumerate(example_indices):
        raw = raw_trajectories[i]
        stim_x, stim_y = raw["stim_x"], raw["stim_y"]
        dist = raw["dist"]
        x, y = raw["x"], raw["y"]
        stim_end = min(STIM_OFFSET_FRAME, len(x))
        mean_dist = np.nanmean(dist[BASELINE_FRAMES:stim_end])
        zone_name = ZONE_LABELS[_assign_zone(mean_dist)]

        # Mean tortuosity using the middle window (3s)
        mid_tort = raw["per_window"][1]
        valid_tort = mid_tort[~np.isnan(mid_tort)]
        mean_tort = float(np.nanmean(valid_tort)) if len(valid_tort) > 0 else np.nan

        window_bins = {}
        for wi in range(len(TRAJ_WINDOWS_S)):
            window_bins[wi] = _build_bin_xy(stim_x, stim_y, raw["per_window"][wi])

        trajectories.append({
            "window_bins": window_bins,
            "cx": float(np.nanmean(x)), "cy": float(np.nanmean(y)),
            "zone": zone_name, "mean_dist": mean_dist, "mean_tort": mean_tort,
        })

    # Create 1×3 subplots
    n_windows = len(TRAJ_WINDOWS_S)
    fig = make_subplots(
        rows=1, cols=n_windows,
        subplot_titles=[f"{ws:.0f}s window" for ws in TRAJ_WINDOWS_S],
        horizontal_spacing=0.04,
    )

    theta = np.linspace(0, 2 * np.pi, 100)
    t0 = trajectories[0]

    # Add traces for first fly: for each subplot: 1 arena + N_COLOR_BINS bins
    for wi in range(n_windows):
        col = wi + 1
        # Arena circle
        fig.add_trace(go.Scatter(
            x=(t0["cx"] + ARENA_RADIUS_MM * np.cos(theta)).tolist(),
            y=(t0["cy"] + ARENA_RADIUS_MM * np.sin(theta)).tolist(),
            mode="lines", line=dict(color="lightgrey", width=1),
            showlegend=False, hoverinfo="skip",
        ), row=1, col=col)

        # Colour-bin traces
        for b_idx, (_, _, hex_c) in enumerate(color_bins):
            bx, by = t0["window_bins"][wi][b_idx]
            fig.add_trace(go.Scatter(
                x=bx, y=by,
                mode="lines", line=dict(color=hex_c, width=2.5),
                showlegend=False, hoverinfo="skip",
            ), row=1, col=col)

    # Colorbar trace (invisible, on last subplot)
    import matplotlib
    matplotlib.use("Agg")
    cmap = matplotlib.colormaps["inferno"]
    n_steps = 20
    colorscale = []
    for i_step in range(n_steps):
        frac = i_step / (n_steps - 1)
        r, g, b, _ = cmap(frac)
        colorscale.append([frac, f"rgb({int(r*255)},{int(g*255)},{int(b*255)})"])

    fig.add_trace(go.Scatter(
        x=[None], y=[None],
        mode="markers",
        marker=dict(
            color=[TORT_CMIN], colorscale=colorscale,
            cmin=TORT_CMIN, cmax=TORT_CMAX, size=0.001,
            colorbar=dict(title="Tortuosity", len=0.6),
            showscale=True,
        ),
        showlegend=False, hoverinfo="skip",
    ), row=1, col=n_windows)

    # Total traces: n_windows * (1 + N_COLOR_BINS) + 1 colorbar
    n_traces = n_windows * (1 + N_COLOR_BINS) + 1

    # Dropdown buttons — update all traces per fly
    buttons = []
    for i, traj in enumerate(trajectories):
        new_x = []
        new_y = []
        for wi in range(n_windows):
            # Arena circle
            new_x.append((traj["cx"] + ARENA_RADIUS_MM * np.cos(theta)).tolist())
            new_y.append((traj["cy"] + ARENA_RADIUS_MM * np.sin(theta)).tolist())
            # Bin traces
            for bx, by in traj["window_bins"][wi]:
                new_x.append(bx)
                new_y.append(by)
        # Colorbar trace
        new_x.append([None])
        new_y.append([None])

        buttons.append(dict(
            label=f"Fly {i + 1} — {traj['zone']} (d={traj['mean_dist']:.0f} mm, T={traj['mean_tort']:.1f})",
            method="update",
            args=[{"x": new_x, "y": new_y}],
        ))

    # Equal-scale axes for all subplots
    # scaleanchor expects "y", "y2", "y3" (not "yaxis", "yaxis2")
    axis_updates = {}
    for wi in range(n_windows):
        xax = f"xaxis{wi + 1}" if wi > 0 else "xaxis"
        yref = f"y{wi + 1}" if wi > 0 else "y"
        axis_updates[xax] = dict(scaleanchor=yref, title="x (mm)" if wi == 0 else "")
        yax = f"yaxis{wi + 1}" if wi > 0 else "yaxis"
        axis_updates[yax] = dict(title="y (mm)" if wi == 0 else "")

    fig.update_layout(
        updatemenus=[dict(
            active=0, buttons=buttons,
            x=0.0, xanchor="left", y=1.18, yanchor="top",
            type="dropdown",
        )],
        height=550,
        title_text="Example Trajectory (stimulus period, coloured by tortuosity)",
        **axis_updates,
    )

    return fig


def make_time_course(timecourses: dict, n_frames: int) -> go.Figure:
    """Plot E: Tortuosity time course by distance zone."""
    fig = go.Figure()

    if n_frames == 0:
        fig.add_annotation(text="No data", showarrow=False)
        return fig

    time_s = (np.arange(n_frames) - BASELINE_FRAMES) / FPS

    # Initial traces (first window)
    for z_idx in range(len(ZONE_EDGES)):
        tc = timecourses[(0, z_idx)]
        mean_tc = tc["mean"]
        if len(mean_tc) == 0:
            mean_tc = np.full(n_frames, np.nan)

        fig.add_trace(
            go.Scatter(
                x=time_s,
                y=mean_tc[:n_frames],
                mode="lines",
                name=ZONE_LABELS[z_idx],
                line=dict(color=ZONE_COLORS[z_idx], width=2),
            )
        )

    # Frames
    frames = []
    for ws_idx, ws_s in enumerate(WINDOW_SIZES_S):
        frame_data = []
        for z_idx in range(len(ZONE_EDGES)):
            tc = timecourses[(ws_idx, z_idx)]
            mean_tc = tc["mean"]
            if len(mean_tc) == 0:
                mean_tc = np.full(n_frames, np.nan)
            frame_data.append(
                go.Scatter(
                    x=time_s,
                    y=mean_tc[:n_frames],
                    mode="lines",
                    name=ZONE_LABELS[z_idx],
                    line=dict(color=ZONE_COLORS[z_idx], width=2),
                )
            )
        frames.append(go.Frame(
            data=frame_data, name=f"{ws_s}s",
            layout=dict(yaxis=dict(autorange=True)),
        ))

    fig.frames = frames

    sliders = [
        dict(
            active=0,
            currentvalue=dict(prefix="Window: "),
            pad=dict(t=60),
            steps=[
                dict(
                    label=f"{ws}s",
                    method="animate",
                    args=[
                        [f"{ws}s"],
                        dict(mode="immediate", frame=dict(duration=0, redraw=True)),
                    ],
                )
                for ws in WINDOW_SIZES_S
            ],
        )
    ]

    # Stimulus onset line
    fig.add_vline(x=0, line_dash="dash", line_color="black", annotation_text="Stimulus ON")

    fig.update_layout(
        sliders=sliders,
        height=450,
        title_text="Tortuosity Time Course by Distance Zone",
        xaxis_title="Time (s, 0 = stimulus onset)",
        yaxis_title="Mean tortuosity",
        yaxis=dict(autorange=True),
    )
    return fig


# ---------------------------------------------------------------------------
# HTML assembly
# ---------------------------------------------------------------------------
def _build_initial_stats_html(all_stats: dict | None) -> str:
    """Build the initial stats table HTML for the first window size."""
    if not all_stats or 0 not in all_stats:
        return ""
    s = all_stats[0]
    rows = []
    for z_idx in range(len(ZONE_EDGES)):
        zs = s["zones"].get(z_idx, {})
        if not zs:
            continue
        rows.append(
            f'<tr style="color:{ZONE_COLORS[z_idx]};">'
            f'<td>{ZONE_LABELS[z_idx]}</td>'
            f'<td>{zs["mean"]:.2f}</td>'
            f'<td>{zs["median"]:.2f}</td>'
            f'<td>{zs["std"]:.2f}</td>'
            f'<td>{zs["n"]:,}</td></tr>'
        )
    bl = s.get("baseline", {})
    if bl and bl.get("mean") is not None:
        rows.append(
            f'<tr style="color:#888;">'
            f'<td>Baseline (all zones)</td>'
            f'<td>{bl["mean"]:.2f}</td>'
            f'<td>{bl["median"]:.2f}</td>'
            f'<td>{bl["std"]:.2f}</td>'
            f'<td>{bl["n"]:,}</td></tr>'
        )
    return (
        '<table class="stats-table">'
        '<tr><th>Distribution</th><th>Mean</th><th>Median</th><th>Std</th><th>N</th></tr>'
        + ''.join(rows)
        + '</table>'
    )


def _render_figure(fig: go.Figure, div_id: str, include_js: bool) -> str:
    """Render a single Plotly figure to an HTML div."""
    return fig.to_html(
        full_html=False,
        include_plotlyjs="cdn" if include_js else False,
        div_id=div_id,
    )


def _render_example_image(x: np.ndarray, y: np.ndarray, tort_val: float, label: str) -> str:
    """Render a small trajectory image as a base64-encoded PNG.

    Uses matplotlib to draw the path coloured by local tortuosity.
    Returns base64 string suitable for embedding in <img src="data:...">.
    """
    import base64
    import io

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.collections import LineCollection

    fig_mpl, ax = plt.subplots(figsize=(3, 3), dpi=100)

    # Compute local tortuosity for colouring (1s window for short snippet)
    ws = int(1.0 * FPS)
    tort = compute_windowed_tortuosity(x, y, ws)
    tort_clipped = np.clip(tort, 1.0, 10.0)

    # Build line segments
    valid = ~np.isnan(x) & ~np.isnan(y)
    xv, yv = x[valid], y[valid]
    tv = tort_clipped[valid]

    if len(xv) > 1:
        points = np.column_stack([xv, yv]).reshape(-1, 1, 2)
        segments = np.concatenate([points[:-1], points[1:]], axis=1)
        seg_colors = 0.5 * (tv[:-1] + tv[1:])
        # Replace NaN colours with 1.0
        seg_colors = np.where(np.isnan(seg_colors), 1.0, seg_colors)

        lc = LineCollection(segments, cmap="inferno", linewidths=2.5)
        lc.set_array(seg_colors)
        lc.set_clim(1.0, 10.0)
        ax.add_collection(lc)

    ax.set_xlim(xv.min() - 2, xv.max() + 2)
    ax.set_ylim(yv.min() - 2, yv.max() + 2)
    ax.set_aspect("equal")
    ax.set_title(f"{label}\nTortuosity = {tort_val:.1f}", fontsize=10)
    ax.set_xlabel("mm", fontsize=8)
    ax.set_ylabel("mm", fontsize=8)
    ax.tick_params(labelsize=7)
    fig_mpl.tight_layout()

    buf = io.BytesIO()
    fig_mpl.savefig(buf, format="png", bbox_inches="tight", facecolor="white")
    plt.close(fig_mpl)
    buf.seek(0)
    return base64.b64encode(buf.read()).decode("ascii")


def _tort_examples_html(tort_examples: dict | None) -> str:
    """Generate HTML showing real tortuosity examples with trajectory images."""
    if not tort_examples:
        return ""
    low = tort_examples.get("low", {})
    high = tort_examples.get("high", {})
    if "path_length" not in low or "path_length" not in high:
        return ""

    # Generate trajectory images if x/y data available
    images_html = ""
    if "x" in low and "x" in high:
        low_img = _render_example_image(low["x"], low["y"], low["tortuosity"], "Straight path")
        high_img = _render_example_image(high["x"], high["y"], high["tortuosity"], "Winding path")
        images_html = (
            '<div style="display:flex; gap:20px; justify-content:center; margin:12px 0;">'
            f'<img src="data:image/png;base64,{low_img}" style="border:1px solid #ddd; border-radius:4px;" />'
            f'<img src="data:image/png;base64,{high_img}" style="border:1px solid #ddd; border-radius:4px;" />'
            '</div>'
        )

    return (
        f'<p><strong>Examples from this dataset (5s window):</strong></p>'
        f'{images_html}'
        f'<table style="border-collapse:collapse; margin:8px 0; font-size:13px;">'
        f'<tr style="border-bottom:1px solid #ddd;">'
        f'<th style="text-align:left; padding:4px 12px;"></th>'
        f'<th style="padding:4px 12px;">Path length</th>'
        f'<th style="padding:4px 12px;">Displacement</th>'
        f'<th style="padding:4px 12px;">Tortuosity</th></tr>'
        f'<tr><td style="padding:4px 12px;">Straightest 5s segment</td>'
        f'<td style="text-align:center; padding:4px 12px;">{low["path_length"]} mm</td>'
        f'<td style="text-align:center; padding:4px 12px;">{low["displacement"]} mm</td>'
        f'<td style="text-align:center; padding:4px 12px;"><strong>{low["tortuosity"]}</strong></td></tr>'
        f'<tr><td style="padding:4px 12px;">Most winding 5s segment</td>'
        f'<td style="text-align:center; padding:4px 12px;">{high["path_length"]} mm</td>'
        f'<td style="text-align:center; padding:4px 12px;">{high["displacement"]} mm</td>'
        f'<td style="text-align:center; padding:4px 12px;"><strong>{high["tortuosity"]}</strong></td></tr>'
        f'</table>'
    )


def build_html(
    figures: dict[str, go.Figure],
    strain: str,
    n_files: int,
    n_flies: int,
    n_excluded: int,
    tort_examples: dict | None = None,
    all_stats: dict | None = None,
    rotation_stats: dict | None = None,
) -> str:
    """Assemble multiple Plotly figures into a standalone HTML page.

    Plot order: Trajectory (top), A (with arena SVG + stats), B, C (+ stats table),
    D (radius profile), E (time course).
    """
    # Render figures in desired order
    ordered = [
        ("trajectory", figures["Example Trajectory"]),
        ("histograms", figures["A. Tortuosity Distributions"]),
        ("profile", figures["B. Mean Tortuosity by Radial Zone"]),
        ("rotation", figures["C. Full Rotation Analysis"]),
        ("radius_profile", figures["D. Turning Radius Profile"]),
        ("timecourse", figures["E. Tortuosity Time Course"]),
    ]

    rendered = {}
    first = True
    for div_id, fig in ordered:
        rendered[div_id] = _render_figure(fig, div_id, first)
        first = False

    # Arena zone SVG
    arena_svg = _arena_zone_svg()

    # Stats JSON for dynamic table
    stats_json = _build_stats_json(all_stats) if all_stats else "{}"

    # Build initial stats table (first window size)
    initial_stats_html = _build_initial_stats_html(all_stats)

    # Build rotation stats table (Plot C)
    rotation_stats_html = _build_rotation_stats_html(rotation_stats)

    return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Tortuosity Explorer &mdash; {strain}</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif;
               max-width: 1300px; margin: 0 auto; padding: 20px;
               background: #fafafa; color: #333; }}
        h1 {{ border-bottom: 2px solid #ddd; padding-bottom: 10px; }}
        h2 {{ color: #555; margin-top: 40px; }}
        .metadata {{ background: #f0f0f0; padding: 15px; border-radius: 5px;
                     margin: 20px 0; font-size: 14px; }}
        .metadata span {{ margin-right: 25px; }}
        hr {{ border: none; border-top: 1px solid #ddd; margin: 30px 0; }}
        .explainer {{ background: #fff; border: 1px solid #e0e0e0;
                      border-radius: 8px; padding: 20px; margin: 20px 0;
                      font-size: 14px; line-height: 1.6; }}
        .explainer h3 {{ margin-top: 0; color: #444; }}
        .diagram {{ font-family: monospace; font-size: 13px; line-height: 1.4;
                    background: #f8f8f8; padding: 15px; border-radius: 5px;
                    margin: 10px 0; white-space: pre; overflow-x: auto; }}
        .formula {{ font-style: italic; background: #f0f4ff; padding: 4px 8px;
                    border-radius: 3px; display: inline-block; margin: 4px 0; }}
        .stats-table {{ border-collapse: collapse; margin: 10px 0; font-size: 13px; width: 100%; }}
        .stats-table th, .stats-table td {{ padding: 6px 12px; text-align: center;
                                            border-bottom: 1px solid #eee; }}
        .stats-table th {{ background: #f8f8f8; font-weight: 600; }}
        .stats-table td:first-child {{ text-align: left; }}
    </style>
</head>
<body>
    <h1>Tortuosity Explorer &mdash; Condition 1 (60&deg; gratings 4Hz)</h1>
    <div class="metadata">
        <span><strong>Strain:</strong> {strain}</span>
        <span><strong>Files:</strong> {n_files}</span>
        <span><strong>Flies (passed QC):</strong> {n_flies}</span>
        <span><strong>Excluded (QC):</strong> {n_excluded}</span>
        <span><strong>Window sizes:</strong> {', '.join(f'{w}s' for w in WINDOW_SIZES_S)}</span>
        <span><strong>Arena radius:</strong> {ARENA_RADIUS_MM} mm</span>
    </div>
    <p style="font-size:13px; color:#888;">
        QC: excluded flies with mean forward velocity &lt; 3 mm/s or
        mean distance from centre &gt; 110 mm during stimulus.
    </p>

    <!-- Tortuosity explanation + trajectory plot -->
    <div class="explainer">
        <h3>What is tortuosity?</h3>
        <p>Tortuosity measures how winding a trajectory is over a given time
        window. It is computed as:</p>
        <p class="formula">tortuosity = path length / displacement</p>
        <p>where <strong>path length</strong> is the total distance walked along
        the trajectory within the window, and <strong>displacement</strong> is
        the straight-line distance between the start and end positions of that
        window.</p>
        <p>A perfectly straight path has a tortuosity of <strong>1.0</strong>.
        Higher values indicate more winding trajectories &mdash; a fly walking
        in a tight circle would have very high tortuosity, while one walking in
        a gentle arc would be closer to 1.</p>
        <div class="diagram">  Straight path (tortuosity &asymp; 1.0):       Winding path (tortuosity &gt;&gt; 1):

  A &mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&mdash;&gt; B              A ~~&gt; &middot;
  path &asymp; displacement                        &middot; &lt;~~&middot;
                                              &middot; ~~&gt; B
                                           path &gt;&gt; displacement</div>
        {_tort_examples_html(tort_examples)}
        <p>The <strong>window size</strong> controls the timescale over which
        tortuosity is evaluated. Short windows (0.5&ndash;1s) capture individual
        turns. Longer windows (3&ndash;7s) capture extended looping behaviour.
        Use the slider on each plot to explore different timescales.</p>
        <p>The three trajectory subplots below show the <strong>same fly</strong>
        with tortuosity computed at three different window sizes (1s, 3s, 7s).
        Dark colours (low tortuosity) indicate straight segments; bright colours
        (high tortuosity) indicate winding or looping segments. Use the dropdown
        to switch between example flies.</p>
    </div>

    <h2>Example Trajectory</h2>
    {rendered["trajectory"]}

    <hr>
    <h2>A. Tortuosity Distributions</h2>
    <div style="display:flex; align-items:flex-start; gap:20px; margin-bottom:10px;">
        <div style="flex-shrink:0;">{arena_svg}</div>
        <p style="font-size:13px; color:#666; margin:0;">
            Tortuosity distributions during the <strong>stimulus</strong> period,
            split by arena zone (distance from centre). The grey line shows the
            baseline (pre-stimulus) distribution across all zones for comparison.
            Dashed vertical lines indicate the mean for each distribution.
            Use the slider to change the analysis window size.
        </p>
    </div>
    {rendered["histograms"]}
    <div id="hist-stats">{initial_stats_html}</div>

    <hr>
    <h2>B. Mean Tortuosity by Radial Zone</h2>
    {rendered["profile"]}

    <hr>
    <!-- Turning radius explanation -->
    <div class="explainer">
        <h3>What is the effective turning radius?</h3>
        <p>The effective turning radius measures the spatial scale of a
        fly&rsquo;s turns. It is derived from <strong>full rotation
        events</strong> &mdash; segments of the trajectory where the fly&rsquo;s
        heading has accumulated 360&deg; of change in one direction.</p>
        <p class="formula">effective radius = path length per 360&deg; / (2&pi;)</p>
        <p>This is the radius of a circle that would produce the same path
        length for one full revolution:</p>
        <div class="diagram">  Large sweeping loop                 Tight pivot
  (high effective radius)            (low effective radius)

       .  - .                              .
     /        \\                           / \\
    |    r     |  &larr; path is long        | r| &larr; path is short
     \\        /     for 360&deg;              \\ /     for 360&deg;
       ' - '                               '

  eff. radius = large               eff. radius = small
  (e.g. 20&ndash;50 mm)                   (e.g. 1&ndash;5 mm)</div>
        <p><strong>Hypothesis:</strong> If flies adjust their turning behaviour
        based on proximity to the arena wall, we would expect to see smaller
        effective turning radii near the edge (tight turns to avoid the wall) and
        larger radii in the centre (more space for sweeping loops). This would
        appear as a leftward shift in the outer-zone distribution relative to the
        inner zone.</p>
        <p>In the histogram below, effective turning radii are grouped by the
        same distance zones as Plot A (coloured lines = stimulus, grey = baseline).
        Rotations are classified by their <strong>midpoint frame</strong>.
        CW and CCW rotations are combined. Dashed vertical lines show the
        median for each distribution. Rotations overlapping with the middle 5s
        around the stimulus direction change are excluded.
        The x-axis uses a logarithmic scale.</p>
    </div>

    <h2>C. Full Rotation Analysis</h2>
    {rendered["rotation"]}
    {rotation_stats_html}

    <hr>
    <h2>D. Turning Radius Profile</h2>
    {rendered["radius_profile"]}

    <hr>
    <h2>E. Tortuosity Time Course</h2>
    {rendered["timecourse"]}

    <!-- Dynamic stats table JavaScript -->
    <script>
    var histStats = {stats_json};
    var zoneLabels = {repr([l for l in ZONE_LABELS])};
    var zoneColors = {repr(ZONE_COLORS)};

    function updateStatsTable(windowKey) {{
        var el = document.getElementById('hist-stats');
        if (!el || !histStats[windowKey]) return;
        var s = histStats[windowKey];
        var html = '<table class="stats-table">';
        html += '<tr><th>Distribution</th><th>Mean</th><th>Median</th><th>Std</th><th>N</th></tr>';
        for (var z = 0; z < zoneLabels.length; z++) {{
            var zs = s.zones[String(z)];
            if (!zs) continue;
            html += '<tr style="color:' + zoneColors[z] + ';">';
            html += '<td>' + zoneLabels[z] + '</td>';
            html += '<td>' + (zs.mean !== null ? zs.mean.toFixed(2) : '—') + '</td>';
            html += '<td>' + (zs.median !== null ? zs.median.toFixed(2) : '—') + '</td>';
            html += '<td>' + (zs["std"] !== null ? zs["std"].toFixed(2) : '—') + '</td>';
            html += '<td>' + (zs.n !== null ? zs.n.toLocaleString() : '—') + '</td>';
            html += '</tr>';
        }}
        var bl = s.baseline;
        if (bl) {{
            html += '<tr style="color:#888;">';
            html += '<td>Baseline (all zones)</td>';
            html += '<td>' + (bl.mean !== null ? bl.mean.toFixed(2) : '—') + '</td>';
            html += '<td>' + (bl.median !== null ? bl.median.toFixed(2) : '—') + '</td>';
            html += '<td>' + (bl["std"] !== null ? bl["std"].toFixed(2) : '—') + '</td>';
            html += '<td>' + (bl.n !== null ? bl.n.toLocaleString() : '—') + '</td>';
            html += '</tr>';
        }}
        html += '</table>';
        el.innerHTML = html;
    }}

    // Listen for slider changes on the histogram plot
    var histEl = document.getElementById('histograms');
    if (histEl) {{
        histEl.on('plotly_sliderchange', function(e) {{
            if (e && e.step && e.step.label) {{
                updateStatsTable(e.step.label);
            }}
        }});
    }}
    </script>

</body>
</html>"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Generate tortuosity explorer HTML")
    parser.add_argument(
        "--strain",
        default=DEFAULT_STRAIN,
        help=f"Strain folder name (default: {DEFAULT_STRAIN})",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output HTML path (default: figures/analysis/tortuosity_explorer_<strain>.html)",
    )
    args = parser.parse_args()

    data_dir = RESULTS_PATH / "protocol_27" / args.strain / "F"
    if not data_dir.exists():
        print(f"Data directory not found: {data_dir}")
        sys.exit(1)

    print(f"Loading data from {data_dir}...")
    fly_traces, n_files, n_excluded = load_condition_data(data_dir)
    n_flies = len(fly_traces)
    print(f"  Loaded {n_files} files, {n_flies} flies passed QC, {n_excluded} excluded")

    if n_flies == 0:
        print("No flies passed QC. Exiting.")
        sys.exit(1)

    print("Aggregating metrics...")
    warnings.filterwarnings("ignore", category=RuntimeWarning)
    agg = aggregate_all(fly_traces)

    print("Building plots...")
    hist_fig, all_stats = make_tortuosity_histograms(
        agg["zone_tort_data"], agg["period_tort_data"]
    )
    rotation_fig, rotation_stats = make_rotation_histograms(agg["rotations"])
    figures = {
        "A. Tortuosity Distributions": hist_fig,
        "B. Mean Tortuosity by Radial Zone": make_profile_plot(agg["profiles"]),
        "C. Full Rotation Analysis": rotation_fig,
        "D. Turning Radius Profile": make_radius_profile(agg["rotations"]),
        "Example Trajectory": make_trajectory_plot(
            fly_traces, agg["example_indices"]
        ),
        "E. Tortuosity Time Course": make_time_course(
            agg["timecourses"], agg["n_frames"]
        ),
    }

    html = build_html(
        figures, args.strain, n_files, n_flies, n_excluded,
        agg["tort_examples"], all_stats, rotation_stats,
    )

    if args.output:
        output_path = Path(args.output)
    else:
        output_path = (
            REPO_ROOT / "src" / "analysis" / f"tortuosity_explorer_{args.strain}.html"
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html)
    print(f"Saved to {output_path}")


if __name__ == "__main__":
    main()

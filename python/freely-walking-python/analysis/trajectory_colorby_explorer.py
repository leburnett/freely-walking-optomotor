"""trajectory_colorby_explorer.py

Interactive HTML trajectory viewer: 2×2 subplots showing a single fly's
trajectory coloured four different ways, plus a 1×4 time series row below.

  Top-left  (SP1) — Time bin index        : categorical tab20 colours per bin
  Top-right (SP2) — Distance from edge    : plasma colormap, fixed [0, 119 mm]
  Bot-left  (SP3) — Tortuosity            : inferno colormap, adaptive per-fly range
  Bot-right (SP4) — Heading rate of change: viridis colormap, adaptive per-fly range
  Bottom row (TS) — Step-plot time series : fwd velocity, dist from edge,
                                            tortuosity, heading rate

Tortuosity and heading-rate colour limits are computed per-fly per-time-bin
so the colour scale reflects the actual data range for the displayed trajectory.
The colorbar labels update dynamically when the slider or dropdown changes.

Heading rate = mean(|wrap(Δheading_wrap)|) × FPS per bin, using wrapped
degrees so 0°/360° discontinuities are handled correctly.

Time series show only the stimulus period (0–30 s from onset) using flat
horizontal lines per time bin (step plot with shape='hv').

Usage:
    cd python/freely-walking-python
    pixi run python -m analysis.trajectory_colorby_explorer
    pixi run python -m analysis.trajectory_colorby_explorer \\
        --strain jfrc100_es_shibire_kir --n_flies 20 --output /tmp/out.html
"""

import argparse
import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from scipy.optimize import minimize

sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from config.config import REPO_ROOT, RESULTS_PATH
from dashboard.constants import BASELINE_FRAMES, FPS, STIM_OFFSET_FRAME
from dashboard.processing import get_log_entries, load_mat_file, segment_condition
from analysis.tortuosity_explorer import (
    ARENA_RADIUS_MM,
    CONDITION_N,
    DEFAULT_STRAIN,
    MIN_DISPLACEMENT,
    WINDOW_SIZES_S,
    ZONE_EDGES,
    ZONE_LABELS,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
N_PER_ZONE = 5              # max example flies per radial zone
N_ZONES = len(ZONE_EDGES)   # 4
N_TS_BOOTSTRAP = 10         # number of offset segmentations averaged for TS robustness

N_TAB20_TRACES = 20         # SP1: categorical colour traces (tab20 cycling)
N_DFE_BINS = 8              # SP2: dist-from-edge colour bins
N_TORT_BINS = 8             # SP3: tortuosity colour bins
N_HDG_BINS  = 8             # SP4: heading-rate colour bins

DFE_CMIN  = 0.0
DFE_CMAX  = ARENA_RADIUS_MM  # 119 mm — fixed (arena geometry)
TORT_CMIN = 1.0              # theoretical minimum for tortuosity
HDG_CMIN  = 0.0             # heading rate always ≥ 0

STIM_DURATION_S = (STIM_OFFSET_FRAME - BASELINE_FRAMES) / FPS  # 30.0 s

# Fixed trace index layout (55 traces total)
#   SP1 (r1c1-2): traces  0–19  tab20 categorical  + trace 20 arena
#   SP2 (r1c3-4): traces 21–28  dist-from-edge     + trace 29 arena + trace 30 cbar
#   SP3 (r2c1-2): traces 31–38  tortuosity         + trace 39 arena + trace 40 cbar
#   SP4 (r2c3-4): traces 41–48  heading rate       + trace 49 arena + trace 50 cbar
#   TS1 (r3c1):   trace  51  fwd velocity step plot
#   TS2 (r3c2):   trace  52  dist from edge step plot
#   TS3 (r3c3):   trace  53  tortuosity step plot
#   TS4 (r3c4):   trace  54  heading rate step plot
_SP1_START = 0
_SP1_ARENA = _SP1_START + N_TAB20_TRACES        # 20
_SP2_START = _SP1_ARENA + 1                     # 21
_SP2_ARENA = _SP2_START + N_DFE_BINS            # 29
_SP2_CBAR  = _SP2_ARENA + 1                     # 30
_SP3_START = _SP2_CBAR + 1                      # 31
_SP3_ARENA = _SP3_START + N_TORT_BINS           # 39
_SP3_CBAR  = _SP3_ARENA + 1                     # 40
_SP4_START = _SP3_CBAR + 1                      # 41
_SP4_ARENA = _SP4_START + N_HDG_BINS            # 49
_SP4_CBAR  = _SP4_ARENA + 1                     # 50
_TS1_IDX   = _SP4_CBAR + 1                      # 51
_TS2_IDX   = _TS1_IDX + 1                       # 52
_TS3_IDX   = _TS2_IDX + 1                       # 53
_TS4_IDX   = _TS3_IDX + 1                       # 54
_N_TRACES  = _TS4_IDX + 1                       # 55

_DEFAULT_TB_IDX = WINDOW_SIZES_S.index(2.0)

# Metrics to load — extends the standard set with heading_wrap
_METRICS = ["x_data", "y_data", "heading_data", "heading_wrap", "dist_data", "fv_data"]


# ---------------------------------------------------------------------------
# Data loading (local version that includes heading_wrap)
# ---------------------------------------------------------------------------

def load_colorby_data(data_dir: Path) -> tuple[list[dict], int, int]:
    """Load condition 1 data including heading_wrap for heading-rate metric."""
    mat_files = sorted(data_dir.glob("*.mat"))
    if not mat_files:
        print(f"No .mat files found in {data_dir}")
        sys.exit(1)

    fly_traces = []
    n_files = 0
    n_excluded = 0

    for filepath in mat_files:
        try:
            log, comb_data, _ = load_mat_file(filepath)
        except Exception as e:
            print(f"  Skipping {filepath.name}: {e}")
            continue

        entries = get_log_entries(log)
        cond1_entries = [e for e in entries if e["which_condition"] == CONDITION_N]
        if not cond1_entries:
            continue

        n_files += 1

        for entry in cond1_entries:
            segment = segment_condition(comb_data, entry, _METRICS)
            if "x_data" not in segment or "fv_data" not in segment:
                continue

            n_flies_seg = segment["fv_data"].shape[0]
            n_seg_frames = segment["fv_data"].shape[1]
            stim_end = min(STIM_OFFSET_FRAME, n_seg_frames)
            stim_sl = slice(BASELINE_FRAMES, stim_end)

            for fly_idx in range(n_flies_seg):
                fv_stim   = segment["fv_data"][fly_idx, stim_sl]
                dist_stim = segment["dist_data"][fly_idx, stim_sl]

                if np.nanmean(fv_stim) < 3.0 or np.nanmean(dist_stim) > 110.0:
                    n_excluded += 1
                    continue

                fly_dict = {
                    "x":    segment["x_data"][fly_idx].copy(),
                    "y":    segment["y_data"][fly_idx].copy(),
                    "dist": segment["dist_data"][fly_idx].copy(),
                    "fv":   segment["fv_data"][fly_idx].copy(),
                }
                if "heading_wrap" in segment:
                    fly_dict["heading_wrap"] = segment["heading_wrap"][fly_idx].copy()

                fly_traces.append(fly_dict)

    return fly_traces, n_files, n_excluded


# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

def _tab20_hex() -> list[str]:
    cmap = matplotlib.colormaps["tab20"]
    return [
        "#{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255))
        for r, g, b, _ in [cmap(i / 20) for i in range(20)]
    ]


def _bin_hex(cmap_name: str, n: int, vmin: float, vmax: float) -> list[str]:
    cmap = matplotlib.colormaps[cmap_name]
    edges = np.linspace(vmin, vmax, n + 1)
    colors = []
    for i in range(n):
        mid = 0.5 * (edges[i] + edges[i + 1])
        norm = np.clip((mid - vmin) / (vmax - vmin), 0.0, 1.0)
        r, g, b, _ = cmap(norm)
        colors.append("#{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255)))
    return colors


def _plotly_colorscale(cmap_name: str, n_steps: int = 20) -> list:
    cmap = matplotlib.colormaps[cmap_name]
    scale = []
    for i in range(n_steps):
        frac = i / (n_steps - 1)
        r, g, b, _ = cmap(frac)
        scale.append([frac, "rgb({},{},{})".format(int(r * 255), int(g * 255), int(b * 255))])
    return scale


# ---------------------------------------------------------------------------
# Arena centre estimation
# ---------------------------------------------------------------------------

def _estimate_arena_centre(fly_traces: list[dict]) -> tuple[float, float]:
    xs, ys, ds = [], [], []
    for trace in fly_traces:
        x, y, dist = trace["x"], trace["y"], trace["dist"]
        valid = ~np.isnan(x) & ~np.isnan(y) & ~np.isnan(dist)
        xs.extend(x[valid][::30].tolist())
        ys.extend(y[valid][::30].tolist())
        ds.extend(dist[valid][::30].tolist())

    if len(xs) < 3:
        return 0.0, 0.0

    xa, ya, da = np.array(xs), np.array(ys), np.array(ds)

    def _obj(p):
        return np.sum((np.sqrt((xa - p[0]) ** 2 + (ya - p[1]) ** 2) - da) ** 2)

    res = minimize(_obj, [float(np.mean(xa)), float(np.mean(ya))], method="Nelder-Mead")
    return float(res.x[0]), float(res.x[1])


# ---------------------------------------------------------------------------
# Trajectory trace builders
# ---------------------------------------------------------------------------

def _categorical_traces(
    x: np.ndarray, y: np.ndarray, frame_color: np.ndarray, n_colors: int
) -> list[tuple[list, list]]:
    """Build n_colors NaN-separated (x, y) lists, one per colour index."""
    traces_x = [[] for _ in range(n_colors)]
    traces_y = [[] for _ in range(n_colors)]
    in_seg = [False] * n_colors

    for i in range(len(x) - 1):
        fc = int(frame_color[i])
        xi, yi, xi1, yi1 = float(x[i]), float(y[i]), float(x[i + 1]), float(y[i + 1])
        has_nan = (
            fc < 0
            or xi != xi or yi != yi
            or xi1 != xi1 or yi1 != yi1
        )
        for c in range(n_colors):
            if not has_nan and fc == c:
                if not in_seg[c]:
                    traces_x[c].append(xi)
                    traces_y[c].append(yi)
                    in_seg[c] = True
                traces_x[c].append(xi1)
                traces_y[c].append(yi1)
            else:
                if in_seg[c]:
                    traces_x[c].append(None)
                    traces_y[c].append(None)
                    in_seg[c] = False

    return [(traces_x[c], traces_y[c]) for c in range(n_colors)]


def _value_traces(
    x: np.ndarray,
    y: np.ndarray,
    frame_values: np.ndarray,
    vmin: float,
    vmax: float,
    n_bins: int,
) -> list[tuple[list, list]]:
    """Build n_bins NaN-separated (x, y) lists based on per-frame values."""
    edges = np.linspace(vmin, vmax, n_bins + 1)
    traces_x = [[] for _ in range(n_bins)]
    traces_y = [[] for _ in range(n_bins)]
    in_seg = [False] * n_bins

    for i in range(len(x) - 1):
        v = float(frame_values[i])
        xi, yi, xi1, yi1 = float(x[i]), float(y[i]), float(x[i + 1]), float(y[i + 1])
        has_nan = v != v or xi != xi or yi != yi or xi1 != xi1 or yi1 != yi1
        for b in range(n_bins):
            in_bin = (
                not has_nan
                and v >= edges[b]
                and (v < edges[b + 1] or b == n_bins - 1)
            )
            if in_bin:
                if not in_seg[b]:
                    traces_x[b].append(xi)
                    traces_y[b].append(yi)
                    in_seg[b] = True
                traces_x[b].append(xi1)
                traces_y[b].append(yi1)
            else:
                if in_seg[b]:
                    traces_x[b].append(None)
                    traces_y[b].append(None)
                    in_seg[b] = False

    return [(traces_x[b], traces_y[b]) for b in range(n_bins)]


# ---------------------------------------------------------------------------
# Time series step-plot builder
# ---------------------------------------------------------------------------

def _build_ts_step(bin_vals: np.ndarray, bin_frames: int) -> tuple[list, list]:
    """Build step-plot arrays for a per-bin scalar time series (stimulus period).

    Uses n_bins+1 points with the last value repeated so that shape='hv'
    draws a complete flat segment for every bin across the full 30 s.
    """
    n_bins = len(bin_vals)
    ts_t = [b * bin_frames / FPS for b in range(n_bins + 1)]
    ts_v = [None if np.isnan(v) else float(v) for v in bin_vals]
    ts_v.append(ts_v[-1] if ts_v else None)  # terminal point to close last bin
    return ts_t, ts_v


# ---------------------------------------------------------------------------
# Zone assignment
# ---------------------------------------------------------------------------

def _assign_zone(mean_dist_center: float) -> int:
    for z, (lo, hi) in enumerate(ZONE_EDGES):
        if lo <= mean_dist_center < hi:
            return z
    return N_ZONES - 1


# ---------------------------------------------------------------------------
# Bootstrapped time-series computation
# ---------------------------------------------------------------------------

def _compute_ts_bootstrap(
    x: np.ndarray,
    y: np.ndarray,
    dist: np.ndarray,
    fv: np.ndarray,
    hdg,          # ndarray or None
    bin_frames: int,
    n_bins: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Average per-bin metrics over N_TS_BOOTSTRAP different starting offsets.

    For each offset o_k = k * bin_frames // N_TS_BOOTSTRAP, compute per-bin
    values for all shifted bins and accumulate them into the reference bin
    whose centre they are nearest to.  The resulting averages are far less
    sensitive to individual turns happening to straddle a bin boundary.
    """
    n = len(x)

    acc_fv   = [[] for _ in range(n_bins)]
    acc_dfe  = [[] for _ in range(n_bins)]
    acc_tort = [[] for _ in range(n_bins)]
    acc_hdg  = [[] for _ in range(n_bins)]

    for k in range(N_TS_BOOTSTRAP):
        offset = k * bin_frames // N_TS_BOOTSTRAP
        n_shifted = n - offset
        n_bins_k = n_shifted // bin_frames

        for b in range(n_bins_k):
            s = offset + b * bin_frames
            e = min(offset + (b + 1) * bin_frames, n)

            # Which reference bin does this shifted bin belong to?
            mid_frame = (s + e - 1) / 2.0
            ref_b = int(mid_frame // bin_frames)
            if ref_b < 0 or ref_b >= n_bins:
                continue

            xb, yb   = x[s:e],    y[s:e]
            db, fvb  = dist[s:e], fv[s:e]

            # Forward velocity
            if not np.all(np.isnan(fvb)):
                acc_fv[ref_b].append(float(np.nanmean(fvb)))

            # Distance from edge
            if not np.all(np.isnan(db)):
                acc_dfe[ref_b].append(ARENA_RADIUS_MM - float(np.nanmean(db)))

            # Tortuosity
            valid_xy = ~np.isnan(xb) & ~np.isnan(yb)
            if valid_xy.sum() > 1:
                xv, yv = xb[valid_xy], yb[valid_xy]
                dx, dy = np.diff(xv), np.diff(yv)
                path_len = float(np.sum(np.sqrt(dx ** 2 + dy ** 2)))
                disp = float(np.sqrt((xv[-1] - xv[0]) ** 2 + (yv[-1] - yv[0]) ** 2))
                if disp >= MIN_DISPLACEMENT:
                    acc_tort[ref_b].append(path_len / disp)

            # Heading rate
            if hdg is not None:
                hb = hdg[s:e]
                dh = np.diff(hb)
                dh_w = ((dh + 180.0) % 360.0) - 180.0
                valid_h = ~np.isnan(dh_w)
                if valid_h.sum() > 0:
                    acc_hdg[ref_b].append(
                        float(np.mean(np.abs(dh_w[valid_h]))) * FPS
                    )

    def _mean_or_nan(lst):
        return float(np.mean(lst)) if lst else np.nan

    bin_fv_r   = np.array([_mean_or_nan(acc_fv[b])   for b in range(n_bins)])
    bin_dfe_r  = np.array([_mean_or_nan(acc_dfe[b])  for b in range(n_bins)])
    bin_tort_r = np.array([_mean_or_nan(acc_tort[b]) for b in range(n_bins)])
    bin_hdg_r  = np.array([_mean_or_nan(acc_hdg[b])  for b in range(n_bins)])

    return bin_fv_r, bin_dfe_r, bin_tort_r, bin_hdg_r


# ---------------------------------------------------------------------------
# Per-fly, per-time-bin data computation (single stage)
# ---------------------------------------------------------------------------

def _compute_tb_data(trace: dict, bin_frames: int) -> dict:
    """Compute all data for one fly at one time-bin width.

    Returns per-fly per-tb adaptive limits, trajectory traces, bin colours,
    and step-plot time series for forward velocity, dist-from-edge,
    tortuosity, and heading rate.
    """
    x_full    = trace["x"]
    y_full    = trace["y"]
    dist_full = trace["dist"]
    fv_full   = trace["fv"]
    hdg_full  = trace.get("heading_wrap")

    stim_end = min(STIM_OFFSET_FRAME, len(x_full))
    x    = x_full[BASELINE_FRAMES:stim_end].copy()
    y    = y_full[BASELINE_FRAMES:stim_end].copy()
    dist = dist_full[BASELINE_FRAMES:stim_end].copy()
    fv   = fv_full[BASELINE_FRAMES:stim_end].copy()
    hdg  = hdg_full[BASELINE_FRAMES:stim_end].copy() if hdg_full is not None else None

    n = len(x)
    n_bins = max(1, n // bin_frames)

    bin_idx  = np.full(n, -1, dtype=int)
    bin_fv   = np.full(n_bins, np.nan)
    bin_dfe  = np.full(n_bins, np.nan)
    bin_tort = np.full(n_bins, np.nan)
    bin_hdg  = np.full(n_bins, np.nan)

    for b in range(n_bins):
        s = b * bin_frames
        e = min((b + 1) * bin_frames, n)
        if s >= n:
            break
        bin_idx[s:e] = b

        xb, yb   = x[s:e], y[s:e]
        db, fvb  = dist[s:e], fv[s:e]

        # Forward velocity
        valid_fv = ~np.isnan(fvb)
        if valid_fv.sum() > 0:
            bin_fv[b] = float(np.nanmean(fvb))

        # Distance from edge
        valid_d = ~np.isnan(db)
        if valid_d.sum() > 0:
            bin_dfe[b] = ARENA_RADIUS_MM - float(np.nanmean(db))

        # Tortuosity
        valid_xy = ~np.isnan(xb) & ~np.isnan(yb)
        if valid_xy.sum() > 1:
            xv, yv = xb[valid_xy], yb[valid_xy]
            dx, dy = np.diff(xv), np.diff(yv)
            path_len = float(np.sum(np.sqrt(dx ** 2 + dy ** 2)))
            disp = float(np.sqrt((xv[-1] - xv[0]) ** 2 + (yv[-1] - yv[0]) ** 2))
            if disp >= MIN_DISPLACEMENT:
                bin_tort[b] = path_len / disp

        # Heading rate (deg/s) — wrap-corrected
        if hdg is not None:
            hb = hdg[s:e]
            dh = np.diff(hb)
            dh_wrapped = ((dh + 180.0) % 360.0) - 180.0
            valid_h = ~np.isnan(dh_wrapped)
            if valid_h.sum() > 0:
                bin_hdg[b] = float(np.mean(np.abs(dh_wrapped[valid_h]))) * FPS

    # --- Adaptive limits from this fly's bins ---
    valid_tort = bin_tort[~np.isnan(bin_tort)]
    tort_cmin = TORT_CMIN
    tort_cmax = (
        max(float(np.max(valid_tort)), tort_cmin + 0.5)
        if len(valid_tort) > 0 else 5.0
    )

    valid_hdg = bin_hdg[~np.isnan(bin_hdg)]
    hdg_cmin = HDG_CMIN
    hdg_cmax = (
        max(float(np.max(valid_hdg)), 10.0)
        if len(valid_hdg) > 0 else 180.0
    )

    # Adaptive bin colours
    sp3_colors = _bin_hex("inferno", N_TORT_BINS, tort_cmin, tort_cmax)
    sp4_colors = _bin_hex("viridis", N_HDG_BINS,  hdg_cmin,  hdg_cmax)

    # --- Frame-level values for trajectory colouring ---
    frame_color = np.where(bin_idx >= 0, bin_idx % N_TAB20_TRACES, -1)
    frame_dfe   = np.full(n, np.nan)
    frame_tort  = np.full(n, np.nan)
    frame_hdg   = np.full(n, np.nan)

    for b in range(n_bins):
        mask = bin_idx == b
        if not np.isnan(bin_dfe[b]):
            frame_dfe[mask]  = np.clip(bin_dfe[b],  DFE_CMIN,  DFE_CMAX)
        if not np.isnan(bin_tort[b]):
            frame_tort[mask] = np.clip(bin_tort[b], tort_cmin, tort_cmax)
        if not np.isnan(bin_hdg[b]):
            frame_hdg[mask]  = np.clip(bin_hdg[b],  hdg_cmin,  hdg_cmax)

    sp1 = _categorical_traces(x, y, frame_color, N_TAB20_TRACES)
    sp2 = _value_traces(x, y, frame_dfe,  DFE_CMIN,  DFE_CMAX,  N_DFE_BINS)
    sp3 = _value_traces(x, y, frame_tort, tort_cmin, tort_cmax, N_TORT_BINS)
    sp4 = _value_traces(x, y, frame_hdg,  hdg_cmin,  hdg_cmax,  N_HDG_BINS)

    # --- Step-plot time series: bootstrapped over N_TS_BOOTSTRAP offsets ---
    bs_fv, bs_dfe, bs_tort, bs_hdg = _compute_ts_bootstrap(
        x, y, dist, fv, hdg, bin_frames, n_bins
    )
    ts_t, ts_fv   = _build_ts_step(bs_fv,   bin_frames)
    _,    ts_dfe  = _build_ts_step(bs_dfe,  bin_frames)
    _,    ts_tort = _build_ts_step(bs_tort, bin_frames)
    _,    ts_hdg  = _build_ts_step(bs_hdg,  bin_frames)

    return {
        "n_bins":     n_bins,
        "sp1_x": [t[0] for t in sp1], "sp1_y": [t[1] for t in sp1],
        "sp2_x": [t[0] for t in sp2], "sp2_y": [t[1] for t in sp2],
        "sp3_x": [t[0] for t in sp3], "sp3_y": [t[1] for t in sp3],
        "sp4_x": [t[0] for t in sp4], "sp4_y": [t[1] for t in sp4],
        "tort_cmin":  tort_cmin,  "tort_cmax":  tort_cmax,
        "hdg_cmin":   hdg_cmin,   "hdg_cmax":   hdg_cmax,
        "sp3_colors": sp3_colors,
        "sp4_colors": sp4_colors,
        "ts_t":    ts_t,
        "ts_fv":   ts_fv,
        "ts_dfe":  ts_dfe,
        "ts_tort": ts_tort,
        "ts_hdg":  ts_hdg,
    }


# ---------------------------------------------------------------------------
# HTML builder
# ---------------------------------------------------------------------------

def build_explorer(
    fly_traces: list[dict],
    strain: str,
    n_files: int,
    n_flies_total: int,
    n_excluded: int,
    n_per_zone: int = N_PER_ZONE,
) -> str:
    """Build the standalone HTML string for the trajectory colorby explorer."""

    # --- Select example flies (up to n_per_zone per radial zone) ---
    zone_examples: dict[int, list[int]] = {z: [] for z in range(N_ZONES)}
    for fly_i, trace in enumerate(fly_traces):
        dist = trace["dist"]
        stim_end = min(STIM_OFFSET_FRAME, len(dist))
        mean_dist = float(np.nanmean(dist[BASELINE_FRAMES:stim_end]))
        z = _assign_zone(mean_dist)
        if len(zone_examples[z]) < n_per_zone:
            zone_examples[z].append(fly_i)

    example_indices = [idx for z in range(N_ZONES) for idx in zone_examples[z]]
    n_examples = len(example_indices)
    print(f"  Selected {n_examples} example flies "
          f"({[len(zone_examples[z]) for z in range(N_ZONES)]} per zone)")

    # --- Arena geometry ---
    example_traces = [fly_traces[i] for i in example_indices]
    arena_cx, arena_cy = _estimate_arena_centre(example_traces)
    print(f"  Arena centre: ({arena_cx:.1f}, {arena_cy:.1f}) mm")

    theta = np.linspace(0, 2 * np.pi, 180)
    arena_x = (arena_cx + ARENA_RADIUS_MM * np.cos(theta)).tolist()
    arena_y = (arena_cy + ARENA_RADIUS_MM * np.sin(theta)).tolist()

    pad = 15.0
    x_range = [arena_cx - ARENA_RADIUS_MM - pad, arena_cx + ARENA_RADIUS_MM + pad]
    y_range = [arena_cy - ARENA_RADIUS_MM - pad, arena_cy + ARENA_RADIUS_MM + pad]

    # --- Compute all (fly × time-bin) data ---
    window_frames = [int(round(s * FPS)) for s in WINDOW_SIZES_S]
    print("  Building per-fly per-tb data ...")

    fly_json_list = []
    for list_i, fly_i in enumerate(example_indices):
        trace = fly_traces[fly_i]
        dist  = trace["dist"]
        stim_end  = min(STIM_OFFSET_FRAME, len(dist))
        mean_dist = float(np.nanmean(dist[BASELINE_FRAMES:stim_end]))
        zone_label = ZONE_LABELS[_assign_zone(mean_dist)]
        label = f"Fly {list_i + 1} \u2014 {zone_label} (d={mean_dist:.0f}\u202fmm)"

        time_bins_data = []
        for tb_idx, (tb_s, tb_f) in enumerate(zip(WINDOW_SIZES_S, window_frames)):
            print(f"    Fly {list_i + 1}/{n_examples}, tb={tb_s:.1f}s ...",
                  end="\r", flush=True)
            tb_data = _compute_tb_data(trace, tb_f)
            time_bins_data.append(tb_data)

        fly_json_list.append({"label": label, "time_bins": time_bins_data})

    print()  # newline after \r

    # --- Colours & colorscales ---
    tab20_colors = _tab20_hex()
    dfe_colors   = _bin_hex("plasma",  N_DFE_BINS,  DFE_CMIN,  DFE_CMAX)
    plasma_cs    = _plotly_colorscale("plasma")
    inferno_cs   = _plotly_colorscale("inferno")
    viridis_cs   = _plotly_colorscale("viridis")

    # Initial state (fly 0, default time bin)
    init_tb = fly_json_list[0]["time_bins"][_DEFAULT_TB_IDX]

    # --- Build Plotly figure: rows=3, cols=4 with colspan for rows 1-2 ---
    fig = make_subplots(
        rows=3, cols=4,
        specs=[
            [{"colspan": 2}, None, {"colspan": 2}, None],
            [{"colspan": 2}, None, {"colspan": 2}, None],
            [{}, {}, {}, {}],
        ],
        row_heights=[0.38, 0.38, 0.24],
        subplot_titles=[
            "Time bin index", "Distance from edge",
            "Tortuosity", "Heading rate of change",
            "Forward velocity (mm/s)", "Dist from edge (mm)",
            "Tortuosity", "Heading rate (deg/s)",
        ],
        horizontal_spacing=0.12,
        vertical_spacing=0.12,
    )

    # SP1 (r1c1): 20 tab20 categorical traces (0–19) + arena (20)
    for c in range(N_TAB20_TRACES):
        fig.add_trace(go.Scatter(
            x=init_tb["sp1_x"][c], y=init_tb["sp1_y"][c],
            mode="lines", line=dict(color=tab20_colors[c], width=2.0),
            showlegend=False, hoverinfo="skip",
        ), row=1, col=1)
    fig.add_trace(go.Scatter(
        x=arena_x, y=arena_y, mode="lines",
        line=dict(color="lightgrey", width=1),
        showlegend=False, hoverinfo="skip",
    ), row=1, col=1)

    # SP2 (r1c3): 8 dist-from-edge traces (21–28) + arena (29) + cbar (30)
    for b in range(N_DFE_BINS):
        fig.add_trace(go.Scatter(
            x=init_tb["sp2_x"][b], y=init_tb["sp2_y"][b],
            mode="lines", line=dict(color=dfe_colors[b], width=2.0),
            showlegend=False, hoverinfo="skip",
        ), row=1, col=3)
    fig.add_trace(go.Scatter(
        x=arena_x, y=arena_y, mode="lines",
        line=dict(color="lightgrey", width=1),
        showlegend=False, hoverinfo="skip",
    ), row=1, col=3)
    fig.add_trace(go.Scatter(
        x=[None], y=[None], mode="markers",
        marker=dict(
            color=[DFE_CMIN], colorscale=plasma_cs,
            cmin=DFE_CMIN, cmax=DFE_CMAX, size=0.001,
            colorbar=dict(
                title="Dist from edge (mm)",
                len=0.30, x=0.99, y=0.86, yanchor="middle", thickness=12,
            ),
            showscale=True,
        ),
        showlegend=False, hoverinfo="skip",
    ), row=1, col=3)

    # SP3 (r2c1): 8 tortuosity traces (31–38) + arena (39) + cbar (40)
    for b in range(N_TORT_BINS):
        fig.add_trace(go.Scatter(
            x=init_tb["sp3_x"][b], y=init_tb["sp3_y"][b],
            mode="lines",
            line=dict(color=init_tb["sp3_colors"][b], width=2.0),
            showlegend=False, hoverinfo="skip",
        ), row=2, col=1)
    fig.add_trace(go.Scatter(
        x=arena_x, y=arena_y, mode="lines",
        line=dict(color="lightgrey", width=1),
        showlegend=False, hoverinfo="skip",
    ), row=2, col=1)
    fig.add_trace(go.Scatter(
        x=[None], y=[None], mode="markers",
        marker=dict(
            color=[init_tb["tort_cmin"]], colorscale=inferno_cs,
            cmin=init_tb["tort_cmin"], cmax=init_tb["tort_cmax"], size=0.001,
            colorbar=dict(
                title="Tortuosity",
                len=0.30, x=0.44, y=0.45, yanchor="middle", thickness=12,
            ),
            showscale=True,
        ),
        showlegend=False, hoverinfo="skip",
    ), row=2, col=1)

    # SP4 (r2c3): 8 heading-rate traces (41–48) + arena (49) + cbar (50)
    for b in range(N_HDG_BINS):
        fig.add_trace(go.Scatter(
            x=init_tb["sp4_x"][b], y=init_tb["sp4_y"][b],
            mode="lines",
            line=dict(color=init_tb["sp4_colors"][b], width=2.0),
            showlegend=False, hoverinfo="skip",
        ), row=2, col=3)
    fig.add_trace(go.Scatter(
        x=arena_x, y=arena_y, mode="lines",
        line=dict(color="lightgrey", width=1),
        showlegend=False, hoverinfo="skip",
    ), row=2, col=3)
    fig.add_trace(go.Scatter(
        x=[None], y=[None], mode="markers",
        marker=dict(
            color=[init_tb["hdg_cmin"]], colorscale=viridis_cs,
            cmin=init_tb["hdg_cmin"], cmax=init_tb["hdg_cmax"], size=0.001,
            colorbar=dict(
                title="Heading rate (deg/s)",
                len=0.30, x=0.99, y=0.45, yanchor="middle", thickness=12,
            ),
            showscale=True,
        ),
        showlegend=False, hoverinfo="skip",
    ), row=2, col=3)

    # TS traces (row 3): step plots for each metric
    ts_line = dict(width=2, shape="hv")
    fig.add_trace(go.Scatter(
        x=init_tb["ts_t"], y=init_tb["ts_fv"],
        mode="lines", line=dict(**ts_line, color="steelblue"),
        showlegend=False, hoverinfo="x+y",
    ), row=3, col=1)
    fig.add_trace(go.Scatter(
        x=init_tb["ts_t"], y=init_tb["ts_dfe"],
        mode="lines", line=dict(**ts_line, color="darkorchid"),
        showlegend=False, hoverinfo="x+y",
    ), row=3, col=2)
    fig.add_trace(go.Scatter(
        x=init_tb["ts_t"], y=init_tb["ts_tort"],
        mode="lines", line=dict(**ts_line, color="firebrick"),
        showlegend=False, hoverinfo="x+y",
    ), row=3, col=3)
    fig.add_trace(go.Scatter(
        x=init_tb["ts_t"], y=init_tb["ts_hdg"],
        mode="lines", line=dict(**ts_line, color="seagreen"),
        showlegend=False, hoverinfo="x+y",
    ), row=3, col=4)

    # --- Axis layout ---
    ts_x_range = [0, STIM_DURATION_S]
    ts_x_title = "Time from stimulus onset (s)"

    fig.update_layout(
        # Spatial subplots: equal aspect, fixed range, all linked
        xaxis  = dict(scaleanchor="y",  scaleratio=1, range=x_range, title="x (mm)"),
        yaxis  = dict(range=y_range, title="y (mm)"),
        xaxis2 = dict(matches="x", scaleanchor="y2", scaleratio=1, range=x_range, title="x (mm)"),
        yaxis2 = dict(matches="y", range=y_range),
        xaxis3 = dict(matches="x", scaleanchor="y3", scaleratio=1, range=x_range, title="x (mm)"),
        yaxis3 = dict(matches="y", range=y_range, title="y (mm)"),
        xaxis4 = dict(matches="x", scaleanchor="y4", scaleratio=1, range=x_range, title="x (mm)"),
        yaxis4 = dict(matches="y", range=y_range),
        # TS subplots: shared x (time), independent y
        xaxis5 = dict(title=ts_x_title, range=ts_x_range),
        yaxis5 = dict(title="mm/s"),
        xaxis6 = dict(matches="x5", title=ts_x_title, range=ts_x_range),
        yaxis6 = dict(title="mm", range=[0, DFE_CMAX]),
        xaxis7 = dict(matches="x5", title=ts_x_title, range=ts_x_range),
        yaxis7 = dict(title="path/displacement"),
        xaxis8 = dict(matches="x5", title=ts_x_title, range=ts_x_range),
        yaxis8 = dict(title="deg/s"),
        height = 1100,
        margin = dict(t=50, b=60, l=70, r=120),
        paper_bgcolor="white",
        plot_bgcolor="white",
    )

    plot_div = fig.to_html(
        include_plotlyjs="cdn", full_html=False, div_id="traj-plot"
    )

    # --- JS data payload ---
    all_data = {
        "flies":       fly_json_list,
        "tb_s":        WINDOW_SIZES_S,
        "sp1_start":   _SP1_START,
        "sp2_start":   _SP2_START,
        "sp3_start":   _SP3_START,
        "sp3_cbar":    _SP3_CBAR,
        "sp4_start":   _SP4_START,
        "sp4_cbar":    _SP4_CBAR,
        "n_tab20":     N_TAB20_TRACES,
        "n_dfe_bins":  N_DFE_BINS,
        "n_tort_bins": N_TORT_BINS,
        "n_hdg_bins":  N_HDG_BINS,
        "ts1_idx":     _TS1_IDX,
        "ts2_idx":     _TS2_IDX,
        "ts3_idx":     _TS3_IDX,
        "ts4_idx":     _TS4_IDX,
    }
    data_json = json.dumps(all_data, allow_nan=False)

    fly_options = "\n".join(
        f'                <option value="{i}">{fly["label"]}</option>'
        for i, fly in enumerate(fly_json_list)
    )

    init_n_bins = init_tb["n_bins"]
    init_tb_s   = WINDOW_SIZES_S[_DEFAULT_TB_IDX]
    n_tb        = len(WINDOW_SIZES_S)

    return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Trajectory Colorby Explorer &mdash; {strain}</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, sans-serif;
               max-width: 1500px; margin: 0 auto; padding: 20px;
               background: #fafafa; color: #333; }}
        h1 {{ border-bottom: 2px solid #ddd; padding-bottom: 10px; }}
        .metadata {{ background: #f0f0f0; padding: 15px; border-radius: 5px;
                     margin: 20px 0; font-size: 14px; }}
        .metadata span {{ margin-right: 25px; }}
        .controls {{ display: flex; align-items: flex-end; gap: 28px;
                     margin: 18px 0 10px; flex-wrap: wrap; }}
        .ctrl-group {{ display: flex; flex-direction: column; gap: 4px; }}
        .ctrl-group label {{ font-size: 13px; font-weight: 600; color: #555; }}
        .ctrl-group select {{ font-size: 14px; padding: 5px 8px;
                              border: 1px solid #ccc; border-radius: 4px;
                              background: white; min-width: 320px; }}
        .ctrl-group input[type=range] {{ width: 220px; }}
        #bin-info {{ font-size: 13px; color: #777; margin-top: 3px; }}
        p.desc {{ font-size: 13px; color: #777; margin: 6px 0 16px; }}
    </style>
</head>
<body>
    <h1>Trajectory Colorby Explorer</h1>
    <div class="metadata">
        <span><strong>Strain:</strong> {strain}</span>
        <span><strong>Files:</strong> {n_files}</span>
        <span><strong>Flies (QC passed):</strong> {n_flies_total}</span>
        <span><strong>Excluded:</strong> {n_excluded}</span>
        <span><strong>Showing:</strong> {n_examples} example flies</span>
        <span><strong>Arena radius:</strong> {ARENA_RADIUS_MM:.0f} mm</span>
    </div>
    <p class="desc">
        <strong>Top-left:</strong> Time-bin index (tab20, cycling for &gt;20 bins).&nbsp;
        <strong>Top-right:</strong> Distance from arena edge (plasma, 0&ndash;{DFE_CMAX:.0f}&thinsp;mm, fixed).&nbsp;
        <strong>Bot-left:</strong> Tortuosity = path&thinsp;length&thinsp;/&thinsp;displacement
            (inferno, adaptive per fly).&nbsp;
        <strong>Bot-right:</strong> Mean absolute heading rate
            (viridis, adaptive per fly).&nbsp;
        Stimulus period only ({BASELINE_FRAMES // FPS}&ndash;{STIM_OFFSET_FRAME // FPS}&thinsp;s).
        Zoom or pan any spatial plot to update all four simultaneously.
        Bottom row shows per-bin step plots over the same stimulus period.
    </p>

    <div class="controls">
        <div class="ctrl-group">
            <label for="fly-select">Fly</label>
            <select id="fly-select" onchange="update(+this.value, currentTbIdx)">
{fly_options}
            </select>
        </div>
        <div class="ctrl-group">
            <label for="tb-slider">Time-bin width</label>
            <input type="range" id="tb-slider"
                   min="0" max="{n_tb - 1}" step="1" value="{_DEFAULT_TB_IDX}"
                   oninput="update(currentFlyIdx, +this.value)">
            <div id="bin-info">{init_n_bins} bins &times; {init_tb_s:.1f}s</div>
        </div>
    </div>

    {plot_div}

    <script>
    const ALL_DATA = {data_json};
    let currentFlyIdx = 0;
    let currentTbIdx  = {_DEFAULT_TB_IDX};

    function update(flyIdx, tbIdx) {{
        currentFlyIdx = flyIdx;
        currentTbIdx  = tbIdx;

        const fly  = ALL_DATA.flies[flyIdx];
        const tb   = fly.time_bins[tbIdx];
        const sp1s = ALL_DATA.sp1_start, sp2s = ALL_DATA.sp2_start;
        const sp3s = ALL_DATA.sp3_start, sp4s = ALL_DATA.sp4_start;
        const n1   = ALL_DATA.n_tab20,   n2   = ALL_DATA.n_dfe_bins;
        const n3   = ALL_DATA.n_tort_bins, n4  = ALL_DATA.n_hdg_bins;

        const idx1 = Array.from({{length: n1}}, (_, i) => sp1s + i);
        const idx2 = Array.from({{length: n2}}, (_, i) => sp2s + i);
        const idx3 = Array.from({{length: n3}}, (_, i) => sp3s + i);
        const idx4 = Array.from({{length: n4}}, (_, i) => sp4s + i);

        // Update trajectory x/y data (4 separate calls — avoids row-2 drop bug)
        Plotly.restyle('traj-plot', {{x: tb.sp1_x, y: tb.sp1_y}}, idx1);
        Plotly.restyle('traj-plot', {{x: tb.sp2_x, y: tb.sp2_y}}, idx2);
        Plotly.restyle('traj-plot', {{x: tb.sp3_x, y: tb.sp3_y}}, idx3);
        Plotly.restyle('traj-plot', {{x: tb.sp4_x, y: tb.sp4_y}}, idx4);

        // Update adaptive line colours for SP3 and SP4
        Plotly.restyle('traj-plot', {{'line.color': tb.sp3_colors}}, idx3);
        Plotly.restyle('traj-plot', {{'line.color': tb.sp4_colors}}, idx4);

        // Update colorbar ranges for SP3 and SP4
        Plotly.restyle('traj-plot',
            {{'marker.cmin': [tb.tort_cmin], 'marker.cmax': [tb.tort_cmax]}},
            [ALL_DATA.sp3_cbar]);
        Plotly.restyle('traj-plot',
            {{'marker.cmin': [tb.hdg_cmin], 'marker.cmax': [tb.hdg_cmax]}},
            [ALL_DATA.sp4_cbar]);

        // Update time series step plots
        Plotly.restyle('traj-plot', {{x: [tb.ts_t], y: [tb.ts_fv]}},   [ALL_DATA.ts1_idx]);
        Plotly.restyle('traj-plot', {{x: [tb.ts_t], y: [tb.ts_dfe]}},  [ALL_DATA.ts2_idx]);
        Plotly.restyle('traj-plot', {{x: [tb.ts_t], y: [tb.ts_tort]}}, [ALL_DATA.ts3_idx]);
        Plotly.restyle('traj-plot', {{x: [tb.ts_t], y: [tb.ts_hdg]}},  [ALL_DATA.ts4_idx]);

        const tbS   = ALL_DATA.tb_s[tbIdx];
        const nBins = tb.n_bins;
        document.getElementById('bin-info').textContent =
            nBins + ' bins \u00d7 ' + tbS.toFixed(1) + 's';
    }}
    </script>
</body>
</html>"""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate an interactive HTML trajectory colorby explorer."
    )
    parser.add_argument("--strain", default=DEFAULT_STRAIN,
                        help=f"Strain folder name (default: {DEFAULT_STRAIN})")
    parser.add_argument("--n_flies", type=int, default=None,
                        help="Max flies to show (default: up to 5 per zone × 4 zones = 20)")
    parser.add_argument("--output", default=None,
                        help="Output HTML path (default: src/analysis/trajectory_colorby_explorer_<strain>.html)")
    args = parser.parse_args()

    data_dir = RESULTS_PATH / "protocol_27" / args.strain / "F"
    if not data_dir.exists():
        print(f"Data directory not found: {data_dir}")
        sys.exit(1)

    print(f"Loading data from {data_dir} ...")
    fly_traces, n_files, n_excluded = load_colorby_data(data_dir)
    n_flies_total = len(fly_traces)
    print(f"  {n_flies_total} flies passed QC, {n_excluded} excluded")

    if n_flies_total == 0:
        print("No flies passed QC. Exiting.")
        sys.exit(1)

    n_per_zone = N_PER_ZONE
    if args.n_flies is not None:
        n_per_zone = max(1, (args.n_flies + N_ZONES - 1) // N_ZONES)

    print("Building explorer HTML ...")
    html = build_explorer(
        fly_traces, args.strain, n_files, n_flies_total, n_excluded,
        n_per_zone=n_per_zone,
    )

    if args.output:
        output_path = Path(args.output)
    else:
        output_path = (
            REPO_ROOT / "src" / "analysis"
            / f"trajectory_colorby_explorer_{args.strain}.html"
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding="utf-8")
    print(f"Saved to {output_path}")


if __name__ == "__main__":
    main()

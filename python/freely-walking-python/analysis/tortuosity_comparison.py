"""Multi-strain tortuosity profile comparison.

Generates a standalone HTML page comparing mean tortuosity profiles
(mean ± SEM by distance from edge) across all strains in protocol 27.

Two plots are displayed — Stimulus and Baseline — with a window-size
dropdown.  The control strain (jfrc100_es_shibire_kir) is always
visible; the other strains are toggled via HTML checkboxes.

Usage:
    python -m analysis.tortuosity_comparison
    python -m analysis.tortuosity_comparison --output /tmp/comparison.html
"""

import argparse
import json
import re
import sys
from pathlib import Path

import numpy as np
import plotly.graph_objects as go
import plotly.io as pio

# Ensure repo root is importable
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

from config.config import REPO_ROOT, RESULTS_PATH
from dashboard.constants import BASELINE_FRAMES, FPS, STIM_OFFSET_FRAME

from analysis.tortuosity_explorer import (
    ARENA_RADIUS_MM,
    DIST_BIN_CENTRES,
    DIST_BIN_EDGES,
    MAX_TORTUOSITY,
    N_DIST_BINS,
    WINDOW_SIZES_F,
    WINDOW_SIZES_S,
    compute_windowed_tortuosity,
    load_condition_data,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
CONTROL_STRAIN = "jfrc100_es_shibire_kir"
PROTOCOL = "protocol_27"
DEFAULT_WS_IDX = WINDOW_SIZES_S.index(2.0)

# Plotly qualitative colour palette for experimental strains
_PLOTLY_COLORS = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
    "#aec7e8", "#ffbb78", "#98df8a", "#ff9896", "#c5b0d5",
    "#c49c94", "#f7b6d2", "#c7c7c7",
]


# ---------------------------------------------------------------------------
# Strain name helpers
# ---------------------------------------------------------------------------
def _short_name(folder_name: str) -> str:
    """Extract a human-readable short name from the strain folder.

    Examples:
        jfrc100_es_shibire_kir -> JFRC100 (control)
        ss2344_T4_shibire_kir  -> T4 (ss2344)
        ss00297_Dm4_shibire_kir -> Dm4 (ss00297)
        l1l4_jfrc100_shibire_kir -> L1L4-JFRC100
        ss324_t4t5_shibire_kir -> t4t5 (ss324)
        2575_LPC1_shibire_kir -> LPC1 (ss2575)
    """
    name = folder_name
    # Strip common suffixes
    name = re.sub(r"_shibire_kir$", "", name)

    if name == "jfrc100_es":
        return "JFRC100 (control)"

    if name.startswith("l1l4_jfrc100"):
        return "L1L4-JFRC100"

    # Handle ss-prefixed strains: ss<digits>_<celltype>
    m = re.match(r"^(ss\d+)_(.+)$", name)
    if m:
        ss_id = m.group(1)
        cell_type = m.group(2)
        return f"{cell_type} ({ss_id})"

    # Handle missing-ss strains like 2575_LPC1
    m2 = re.match(r"^(\d+)_(.+)$", name)
    if m2:
        num = m2.group(1)
        cell_type = m2.group(2)
        return f"{cell_type} (ss{num})"

    return name


# ---------------------------------------------------------------------------
# Data computation
# ---------------------------------------------------------------------------
def compute_strain_profiles(data_dir: Path) -> dict | None:
    """Load one strain and compute tortuosity profiles at ALL window sizes.

    Returns dict with per-window, per-period mean ± SEM per distance bin,
    or None if loading fails.
    """
    fly_traces, n_files, n_excluded = load_condition_data(data_dir)

    n_flies = len(fly_traces)
    result: dict = {"n_flies": n_flies, "n_excluded": n_excluded,
                    "n_files": n_files, "windows": {}}

    if not fly_traces:
        for ws_idx in range(len(WINDOW_SIZES_S)):
            result["windows"][ws_idx] = {
                "stimulus": {"mean": [float("nan")] * N_DIST_BINS,
                             "sem": [float("nan")] * N_DIST_BINS},
                "baseline": {"mean": [float("nan")] * N_DIST_BINS,
                             "sem": [float("nan")] * N_DIST_BINS},
            }
        return result

    # Collect per-bin values for mean ± SEM at each window size
    profile_data: dict[int, dict[str, dict[int, list]]] = {}
    for ws_idx in range(len(WINDOW_SIZES_F)):
        profile_data[ws_idx] = {
            "baseline": {b: [] for b in range(N_DIST_BINS)},
            "stimulus": {b: [] for b in range(N_DIST_BINS)},
        }

    for trace in fly_traces:
        x, y = trace["x"], trace["y"]
        dist_from_edge = ARENA_RADIUS_MM - trace["dist"]

        for ws_idx, wf in enumerate(WINDOW_SIZES_F):
            tort = compute_windowed_tortuosity(x, y, wf)
            tort_clipped = np.clip(tort, 1.0, MAX_TORTUOSITY)

            n_seg = len(tort)
            stim_end = min(STIM_OFFSET_FRAME, n_seg)

            for period, sl in [
                ("baseline", slice(0, BASELINE_FRAMES)),
                ("stimulus", slice(BASELINE_FRAMES, stim_end)),
            ]:
                valid = ~np.isnan(tort_clipped[sl])
                t_vals = tort_clipped[sl][valid]
                d_vals = dist_from_edge[sl][valid]

                for b_idx in range(N_DIST_BINS):
                    mask = (d_vals >= DIST_BIN_EDGES[b_idx]) & (
                        d_vals < DIST_BIN_EDGES[b_idx + 1]
                    )
                    if mask.any():
                        profile_data[ws_idx][period][b_idx].extend(
                            t_vals[mask].tolist()
                        )

    # Compute mean ± SEM per bin per window
    for ws_idx in range(len(WINDOW_SIZES_S)):
        ws_result = {}
        for period in ("stimulus", "baseline"):
            means = []
            sems = []
            for b in range(N_DIST_BINS):
                vals = profile_data[ws_idx][period][b]
                if len(vals) > 1:
                    means.append(float(np.mean(vals)))
                    sems.append(float(np.std(vals) / np.sqrt(len(vals))))
                else:
                    means.append(None)
                    sems.append(None)
            ws_result[period] = {"mean": means, "sem": sems}
        result["windows"][ws_idx] = ws_result

    return result


# ---------------------------------------------------------------------------
# Plot construction
# ---------------------------------------------------------------------------
def make_comparison_plots(
    all_profiles: dict[str, dict],
    control_strain: str,
    exp_strains: list[str],
    color_map: dict[str, str],
) -> tuple[go.Figure, go.Figure]:
    """Create stimulus and baseline comparison figures.

    The control trace is always visible (black).
    Experimental traces are initially hidden and coloured.

    Returns (stimulus_fig, baseline_fig).
    """
    figs = {}
    for period, title in [
        ("stimulus", "Stimulus — Mean Tortuosity by Distance from Edge"),
        ("baseline", "Baseline — Mean Tortuosity by Distance from Edge"),
    ]:
        fig = go.Figure()

        # Control trace (always visible, thick black)
        ctrl = all_profiles[control_strain]
        n_ctrl = ctrl["n_flies"]
        ws_data = ctrl["windows"][DEFAULT_WS_IDX]
        fig.add_trace(
            go.Scatter(
                x=DIST_BIN_CENTRES.tolist(),
                y=ws_data[period]["mean"],
                error_y=dict(
                    type="data",
                    array=ws_data[period]["sem"],
                    visible=True,
                ),
                mode="lines+markers",
                name=f"{_short_name(control_strain)} (n={n_ctrl})",
                line=dict(color="black", width=3),
                marker=dict(size=6),
            )
        )

        # Experimental traces (initially hidden)
        for strain in exp_strains:
            prof = all_profiles[strain]
            n_flies = prof["n_flies"]
            color = color_map[strain]
            sname = _short_name(strain)
            ws_data = prof["windows"][DEFAULT_WS_IDX]

            fig.add_trace(
                go.Scatter(
                    x=DIST_BIN_CENTRES.tolist(),
                    y=ws_data[period]["mean"],
                    error_y=dict(
                        type="data",
                        array=ws_data[period]["sem"],
                        visible=True,
                    ),
                    mode="lines+markers",
                    name=f"{sname} (n={n_flies})",
                    line=dict(color=color, width=2),
                    marker=dict(size=5),
                    visible=False,
                )
            )

        fig.update_layout(
            title_text=title,
            xaxis_title="Distance from edge (mm)",
            yaxis_title="Mean tortuosity ± SEM",
            height=450,
            template="plotly_white",
            showlegend=False,
            margin=dict(l=60, r=30, t=50, b=50),
        )

        figs[period] = fig

    return figs["stimulus"], figs["baseline"]


# ---------------------------------------------------------------------------
# HTML assembly
# ---------------------------------------------------------------------------
def _build_profile_json(
    all_profiles: dict[str, dict],
    control_strain: str,
    exp_strains: list[str],
) -> str:
    """Build JSON data for all strains × all windows, for JS restyle."""
    data = {}
    strain_keys = [control_strain] + exp_strains
    for strain in strain_keys:
        prof = all_profiles[strain]
        ws_data = {}
        for ws_idx in range(len(WINDOW_SIZES_S)):
            wd = prof["windows"][ws_idx]
            ws_data[str(ws_idx)] = {
                "stimulus": wd["stimulus"],
                "baseline": wd["baseline"],
            }
        data[strain] = ws_data
    return json.dumps(data)


def build_comparison_html(
    stim_fig: go.Figure,
    base_fig: go.Figure,
    all_profiles: dict[str, dict],
    control_strain: str,
    exp_strains: list[str],
    color_map: dict[str, str],
) -> str:
    """Build the standalone HTML page with plots + checkbox panel."""

    # Render the two Plotly figures as HTML div strings
    stim_html = pio.to_html(stim_fig, full_html=False, include_plotlyjs=False,
                            div_id="stim_plot")
    base_html = pio.to_html(base_fig, full_html=False, include_plotlyjs=False,
                            div_id="base_plot")

    # Build profile data JSON for window switching
    profile_json = _build_profile_json(all_profiles, control_strain, exp_strains)

    # Strain order list for JS (control first, then experimental)
    strain_keys_json = json.dumps([control_strain] + exp_strains)

    # Window size options
    ws_options = "\n".join(
        f'<option value="{i}"{" selected" if i == DEFAULT_WS_IDX else ""}>'
        f'{ws}s</option>'
        for i, ws in enumerate(WINDOW_SIZES_S)
    )

    # Build checkbox items for experimental strains
    checkbox_items = []
    for i, strain in enumerate(exp_strains):
        prof = all_profiles[strain]
        sname = _short_name(strain)
        n_flies = prof["n_flies"]
        color = color_map[strain]
        label = f"{sname} (n={n_flies})"
        # trace_idx is i+1 because trace 0 is the control
        checkbox_items.append(
            f'<label class="strain-label">'
            f'<input type="checkbox" class="strain-toggle" '
            f'data-trace-idx="{i + 1}" onchange="toggleStrain(this)">'
            f' <span style="color:{color}; font-weight:bold;">●</span> '
            f'{label}</label>'
        )

    checkbox_html = "\n".join(checkbox_items)

    # Metadata summary
    n_strains = len(all_profiles)
    n_experimental = len(exp_strains)
    ctrl_n = all_profiles[control_strain]["n_flies"]
    total_flies = sum(p["n_flies"] for p in all_profiles.values())

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Tortuosity Profile Comparison — Protocol 27</title>
<script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script>
<style>
  * {{ box-sizing: border-box; }}
  body {{ font-family: Arial, Helvetica, sans-serif; margin: 20px; background: #fafafa; }}
  h1 {{ color: #333; border-bottom: 2px solid #1f77b4; padding-bottom: 8px; margin-bottom: 10px; }}
  .meta {{ color: #555; margin-bottom: 12px; font-size: 0.95em; }}

  .window-selector {{
    margin-bottom: 14px;
  }}
  .window-selector label {{
    font-weight: bold; margin-right: 8px;
  }}
  .window-selector select {{
    font-size: 1em; padding: 4px 8px;
  }}

  .main-layout {{
    display: flex; gap: 16px; align-items: flex-start;
  }}

  .sidebar {{
    flex: 0 0 240px;
    background: white; border: 1px solid #ddd; border-radius: 6px;
    padding: 12px 14px;
    max-height: 80vh; overflow-y: auto;
    position: sticky; top: 20px;
  }}
  .sidebar h3 {{
    margin: 0 0 8px 0; font-size: 1.0em; color: #333;
  }}
  .sidebar .btn-row {{
    margin-bottom: 8px;
  }}
  .sidebar button {{
    padding: 3px 10px; cursor: pointer; font-size: 0.85em;
    margin-right: 4px;
  }}
  .strain-label {{
    display: block; padding: 2px 0; white-space: nowrap;
    font-size: 0.9em; cursor: pointer;
  }}
  .strain-label:hover {{ background: #f0f0f0; }}

  .plots-column {{
    flex: 1 1 0; min-width: 0;
  }}
  .plots-column > div {{ margin-bottom: 16px; }}
</style>
</head>
<body>
<h1>Tortuosity Profile Comparison — Protocol 27</h1>

<div class="meta">
  <strong>{n_strains} strains loaded</strong> ({n_experimental} experimental + 1 control) &nbsp;|&nbsp;
  <strong>{total_flies} total flies</strong> &nbsp;|&nbsp;
  Control: {_short_name(control_strain)} (n={ctrl_n})
</div>

<div class="window-selector">
  <label for="ws-select">Window size:</label>
  <select id="ws-select" onchange="changeWindow(this.value)">
    {ws_options}
  </select>
</div>

<div class="main-layout">
  <div class="sidebar">
    <h3>Experimental strains</h3>
    <div class="btn-row">
      <button onclick="toggleAll(true)">Select all</button>
      <button onclick="toggleAll(false)">Deselect all</button>
    </div>
    {checkbox_html}
  </div>

  <div class="plots-column">
    <div>{stim_html}</div>
    <div>{base_html}</div>
  </div>
</div>

<script>
// Embedded profile data: strain -> ws_idx -> period -> {{mean, sem}}
var PROFILE_DATA = {profile_json};
var STRAIN_KEYS = {strain_keys_json};  // [control, exp1, exp2, ...]
var currentWsIdx = {DEFAULT_WS_IDX};

function toggleStrain(cb) {{
  var idx = parseInt(cb.dataset.traceIdx);
  var vis = cb.checked ? true : false;
  Plotly.restyle('stim_plot', {{'visible': vis}}, [idx]);
  Plotly.restyle('base_plot', {{'visible': vis}}, [idx]);
}}

function toggleAll(state) {{
  var boxes = document.querySelectorAll('.strain-toggle');
  var indices = [];
  var visArr = [];
  boxes.forEach(function(cb) {{
    cb.checked = state;
    indices.push(parseInt(cb.dataset.traceIdx));
    visArr.push(state ? true : false);
  }});
  Plotly.restyle('stim_plot', {{'visible': visArr}}, indices);
  Plotly.restyle('base_plot', {{'visible': visArr}}, indices);
}}

function changeWindow(wsIdx) {{
  wsIdx = parseInt(wsIdx);
  currentWsIdx = wsIdx;
  var wsLabel = ['0.5s', '1.0s', '2.0s', '3.0s', '5.0s', '7.0s'][wsIdx];

  // Update each trace's y and error_y for both plots
  for (var t = 0; t < STRAIN_KEYS.length; t++) {{
    var strain = STRAIN_KEYS[t];
    var d = PROFILE_DATA[strain][String(wsIdx)];

    Plotly.restyle('stim_plot', {{
      'y': [d.stimulus.mean],
      'error_y.array': [d.stimulus.sem]
    }}, [t]);

    Plotly.restyle('base_plot', {{
      'y': [d.baseline.mean],
      'error_y.array': [d.baseline.sem]
    }}, [t]);
  }}

  // Update plot titles
  Plotly.relayout('stim_plot', {{
    'title.text': 'Stimulus — Mean Tortuosity by Distance from Edge (' + wsLabel + ' window)'
  }});
  Plotly.relayout('base_plot', {{
    'title.text': 'Baseline — Mean Tortuosity by Distance from Edge (' + wsLabel + ' window)'
  }});
}}

// Set initial titles with window label
window.addEventListener('load', function() {{
  changeWindow({DEFAULT_WS_IDX});
}});
</script>
</body>
</html>"""
    return html


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="Multi-strain tortuosity profile comparison"
    )
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Output HTML path (default: src/analysis/tortuosity_comparison.html)",
    )
    args = parser.parse_args()

    protocol_dir = RESULTS_PATH / PROTOCOL
    if not protocol_dir.is_dir():
        print(f"Protocol directory not found: {protocol_dir}")
        sys.exit(1)

    # Discover strain folders
    strain_dirs = sorted(
        d for d in protocol_dir.iterdir()
        if d.is_dir() and (d / "F").is_dir()
    )
    if not strain_dirs:
        print(f"No strain folders (with F/ subfolder) found in {protocol_dir}")
        sys.exit(1)

    print(f"Found {len(strain_dirs)} strains in {protocol_dir}")

    # Load each strain's data and compute profiles at all window sizes
    all_profiles: dict[str, dict] = {}
    strain_order: list[str] = []

    for sd in strain_dirs:
        strain_name = sd.name
        f_dir = sd / "F"
        mat_files = sorted(f_dir.glob("*.mat"))
        if not mat_files:
            print(f"  [{strain_name}] No .mat files — skipping")
            continue

        print(f"  [{strain_name}] Loading {len(mat_files)} files...")
        profile = compute_strain_profiles(f_dir)

        if profile is not None:
            all_profiles[strain_name] = profile
            strain_order.append(strain_name)
            print(
                f"  [{strain_name}] {profile['n_flies']} flies "
                f"({profile['n_excluded']} excluded)"
            )
        else:
            print(f"  [{strain_name}] Failed to load — skipping")

    if CONTROL_STRAIN not in all_profiles:
        print(f"ERROR: Control strain '{CONTROL_STRAIN}' not found!")
        sys.exit(1)

    # Build ordered experimental strain list, sorted by short name
    exp_strains = sorted(
        [s for s in strain_order if s != CONTROL_STRAIN],
        key=lambda s: _short_name(s).lower(),
    )

    # Build consistent colour map for experimental strains
    color_map: dict[str, str] = {}
    for i, strain in enumerate(exp_strains):
        color_map[strain] = _PLOTLY_COLORS[i % len(_PLOTLY_COLORS)]

    print(f"\nBuilding comparison plots...")
    stim_fig, base_fig = make_comparison_plots(
        all_profiles, CONTROL_STRAIN, exp_strains, color_map
    )

    print("Assembling HTML...")
    html = build_comparison_html(
        stim_fig, base_fig, all_profiles, CONTROL_STRAIN, exp_strains,
        color_map
    )

    # Determine output path
    if args.output:
        out_path = Path(args.output)
    else:
        out_dir = REPO_ROOT / "src" / "analysis"
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / "tortuosity_comparison.html"

    out_path.write_text(html)
    print(f"\nSaved comparison page: {out_path}")
    print(f"  File size: {out_path.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()

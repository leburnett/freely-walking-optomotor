"""Dash callbacks for all three dashboard tabs."""

import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from dash import Input, Output, State, callback_context, no_update

from dashboard.constants import (
    CONDITION_COLORS,
    CONDITION_NAMES,
    DIRECTION_CHANGE_FRAME,
    DOWNSAMPLE_FACTOR,
    FPS,
    METRIC_LABELS,
    METRIC_RANGES,
    METRICS,
    STIM_OFFSET_FRAME,
    STIM_ONSET_FRAME,
    STRAIN_COLORS,
)


def _add_stim_markers(fig, y_range, row=None, col=None, n_conditions=12):
    """Add vertical lines for stimulus onset, direction change, and offset."""
    kwargs = {}
    if row is not None:
        kwargs["row"] = row
        kwargs["col"] = col

    onset_t = STIM_ONSET_FRAME / FPS
    direction_t = DIRECTION_CHANGE_FRAME / FPS
    offset_t = STIM_OFFSET_FRAME / FPS

    for t in [onset_t, direction_t, offset_t]:
        fig.add_vline(
            x=t, line=dict(color="rgba(160,160,160,0.5)", width=1, dash="dot"),
            **kwargs,
        )


def _make_trace(x, y_mean, y_sem, color, name, show_legend=True):
    """Create a mean line with SEM shaded band."""
    traces = []
    # SEM band
    r, g, b = _parse_rgb(color)
    traces.append(go.Scatter(
        x=np.concatenate([x, x[::-1]]),
        y=np.concatenate([y_mean + y_sem, (y_mean - y_sem)[::-1]]),
        fill="toself",
        fillcolor=f"rgba({r},{g},{b},0.15)",
        line=dict(width=0),
        showlegend=False,
        hoverinfo="skip",
        name=name,
    ))
    # Mean line
    traces.append(go.Scatter(
        x=x, y=y_mean,
        line=dict(color=color, width=2),
        name=name,
        showlegend=show_legend,
    ))
    return traces


def _parse_rgb(color_str: str) -> tuple[int, int, int]:
    """Parse 'rgb(r,g,b)' string to (r, g, b) ints."""
    inner = color_str.replace("rgb(", "").replace(")", "")
    parts = inner.split(",")
    return int(parts[0]), int(parts[1]), int(parts[2])


def register_callbacks(app, data_store):
    """Register all Dash callbacks."""

    # ---- Sidebar: update strain options when data path changes ----
    @app.callback(
        Output("strain-dropdown", "options"),
        Output("strain-dropdown", "value"),
        Output("data-status", "children"),
        Input("data-path-input", "value"),
    )
    def update_strain_options(data_path):
        if not data_path:
            return [], None, "Enter a data path above."

        from pathlib import Path
        from dashboard.data_loader import DataStore

        preprocessed_dir = Path(data_path).parent / f"{Path(data_path).name}_preprocessed"
        if not preprocessed_dir.exists():
            return [], None, f"Preprocessed data not found at {preprocessed_dir}. Run preprocess.py first."

        # Update the global data store
        data_store.__init__(preprocessed_dir)
        if not data_store.is_valid:
            return [], None, "Invalid preprocessed directory."

        strains = data_store.get_strains()
        options = [{"label": s.replace("_", " "), "value": s} for s in strains]
        default = strains[0] if strains else None
        return options, default, f"Loaded {len(strains)} strains from {preprocessed_dir.name}"

    # ---- Tab 1: Update cohort dropdown when strain changes ----
    @app.callback(
        Output("cohort-dropdown", "options"),
        Output("cohort-dropdown", "value"),
        Input("strain-dropdown", "value"),
    )
    def update_cohort_options(strain):
        if not strain:
            return [], None
        cohorts = data_store.get_cohorts_for_strain(strain)
        if not cohorts:
            return [], None
        options = [{"label": c.rsplit("_data", 1)[0], "value": c} for c in cohorts]
        return options, cohorts[0]

    # ---- Tab 1: Cohort View Plot ----
    @app.callback(
        Output("cohort-plot", "figure"),
        Input("strain-dropdown", "value"),
        Input("cohort-dropdown", "value"),
        Input("condition-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("qc-toggle", "value"),
    )
    def update_cohort_plot(strain, cohort_id, condition, metric, qc_on):
        if not strain or not cohort_id or not metric:
            return go.Figure()

        apply_qc = bool(qc_on)

        if condition == "all":
            return _cohort_all_conditions(strain, cohort_id, metric, apply_qc, data_store)
        else:
            cond_n = int(condition)
            return _cohort_single_condition(strain, cohort_id, cond_n, metric, apply_qc, data_store)

    # ---- Tab 2: Strain Aggregate View ----
    @app.callback(
        Output("strain-plot", "figure"),
        Input("strain-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("qc-toggle", "value"),
        Input("rep-toggle", "value"),
        Input("strain-view-mode", "value"),
    )
    def update_strain_plot(strain, metric, qc_on, rep_mode, view_mode):
        if not strain or not metric:
            return go.Figure()

        apply_qc = bool(qc_on)
        use_default = (not apply_qc) and (rep_mode == "interleave")

        if view_mode == "tiled":
            return _strain_tiled(strain, metric, apply_qc, rep_mode, use_default, data_store)
        else:
            return _strain_overlaid(strain, metric, apply_qc, rep_mode, use_default, data_store)

    # ---- Tab 3: Cross-Strain Comparison ----
    @app.callback(
        Output("comparison-plot", "figure"),
        Input("comparison-condition-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("comparison-strains", "value"),
        Input("qc-toggle", "value"),
        Input("rep-toggle", "value"),
        Input("comparison-view-mode", "value"),
    )
    def update_comparison_plot(condition, metric, selected_strains, qc_on, rep_mode, view_mode):
        if not metric or not selected_strains:
            return go.Figure()

        apply_qc = bool(qc_on)
        use_default = (not apply_qc) and (rep_mode == "interleave")

        if view_mode == "single" and condition:
            cond_n = int(condition)
            return _comparison_single(cond_n, metric, selected_strains, apply_qc, rep_mode, use_default, data_store)
        else:
            return _comparison_grid(metric, selected_strains, apply_qc, rep_mode, use_default, data_store)

    # ---- Tab 3: Update strain checklist from available strains ----
    @app.callback(
        Output("comparison-strains", "options"),
        Output("comparison-strains", "value"),
        Input("strain-dropdown", "options"),
    )
    def update_comparison_strains(strain_options):
        if not strain_options:
            return [], []
        options = [{"label": o["label"], "value": o["value"]} for o in strain_options]
        # Pre-check the control strain if available
        values = [o["value"] for o in options]
        default = ["jfrc100_es_shibire_kir"] if "jfrc100_es_shibire_kir" in values else []
        return options, default


# ---- Helper functions for building plots ----

def _cohort_single_condition(strain, cohort_id, cond_n, metric, apply_qc, store):
    """Plot individual fly traces + cohort mean for one condition."""
    df = store.get_cohort_data(strain, cohort_id, cond_n, metric, qc_only=apply_qc)
    if df.empty:
        fig = go.Figure()
        fig.add_annotation(text="No data available", xref="paper", yref="paper", x=0.5, y=0.5, showarrow=False)
        return fig

    color = CONDITION_COLORS[cond_n - 1] if cond_n <= len(CONDITION_COLORS) else "rgb(100,100,100)"
    fig = go.Figure()

    # Individual fly traces (thin, transparent)
    fly_reps = df.groupby(["fly_idx", "rep"])
    for (fly_idx, rep), group in fly_reps:
        fig.add_trace(go.Scatter(
            x=group["time_s"],
            y=group[metric],
            mode="lines",
            line=dict(width=0.5, color=f"rgba(150,150,150,0.3)"),
            showlegend=False,
            hoverinfo="skip",
        ))

    # Cohort mean + SEM
    grouped = df.groupby("time_s")[metric].agg(["mean", "std", "count"]).reset_index()
    grouped["sem"] = grouped["std"] / np.sqrt(grouped["count"])
    x = grouped["time_s"].values
    y_mean = grouped["mean"].values
    y_sem = grouped["sem"].values

    for trace in _make_trace(x, y_mean, y_sem, color, CONDITION_NAMES.get(cond_n, f"Cond {cond_n}")):
        fig.add_trace(trace)

    # Stimulus markers
    y_range = METRIC_RANGES.get(metric)
    if y_range:
        fig.update_yaxes(range=list(y_range))
    _add_stim_markers(fig, y_range)

    cond_name = CONDITION_NAMES.get(cond_n, f"Condition {cond_n}")
    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {cohort_id.rsplit('_data', 1)[0]} - {cond_name}",
        xaxis_title="Time (s)",
        yaxis_title=METRIC_LABELS.get(metric, metric),
        template="plotly_white",
        height=450,
        margin=dict(t=50, b=50, l=60, r=20),
    )
    return fig


def _cohort_all_conditions(strain, cohort_id, metric, apply_qc, store):
    """12-panel subplot grid showing all conditions for one cohort."""
    n_conds = len(CONDITION_NAMES)
    fig = make_subplots(
        rows=n_conds, cols=1, shared_xaxes=True, vertical_spacing=0.02,
        subplot_titles=[CONDITION_NAMES[i] for i in range(1, n_conds + 1)],
    )

    for cond_n in range(1, n_conds + 1):
        df = store.get_cohort_data(strain, cohort_id, cond_n, metric, qc_only=apply_qc)
        color = CONDITION_COLORS[cond_n - 1]

        if df.empty:
            continue

        grouped = df.groupby("time_s")[metric].agg(["mean", "std", "count"]).reset_index()
        grouped["sem"] = grouped["std"] / np.sqrt(grouped["count"])
        x = grouped["time_s"].values
        y_mean = grouped["mean"].values
        y_sem = grouped["sem"].values

        for trace in _make_trace(x, y_mean, y_sem, color, CONDITION_NAMES[cond_n], show_legend=False):
            fig.add_trace(trace, row=cond_n, col=1)

        y_range = METRIC_RANGES.get(metric)
        if y_range:
            fig.update_yaxes(range=list(y_range), row=cond_n, col=1)

    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {cohort_id.rsplit('_data', 1)[0]} - {METRIC_LABELS.get(metric, metric)}",
        height=200 * n_conds,
        template="plotly_white",
        showlegend=False,
        margin=dict(t=50, b=30, l=60, r=20),
    )
    fig.update_xaxes(title_text="Time (s)", row=n_conds, col=1)
    return fig


def _get_summary_data(strain, cond_n, metric, apply_qc, rep_mode, use_default, store):
    """Get mean/SEM data, using pre-computed summary when possible."""
    if use_default:
        df = store.get_strain_summary(strain, cond_n, metric)
        if not df.empty:
            return df["time_s"].values, df["mean"].values, df["sem"].values, df["n_flies"].values
    # Fall back to on-the-fly computation
    df = store.compute_summary_on_the_fly(strain, cond_n, metric, rep_mode, apply_qc)
    if df.empty:
        return None, None, None, None
    return df["time_s"].values, df["mean"].values, df["sem"].values, df["n_flies"].values


def _strain_tiled(strain, metric, apply_qc, rep_mode, use_default, store):
    """12-panel tiled layout for one strain, all conditions."""
    n_conds = len(CONDITION_NAMES)
    fig = make_subplots(
        rows=n_conds, cols=1, shared_xaxes=True, vertical_spacing=0.02,
        subplot_titles=[CONDITION_NAMES[i] for i in range(1, n_conds + 1)],
    )

    for cond_n in range(1, n_conds + 1):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store
        )
        if x is None:
            continue

        color = CONDITION_COLORS[cond_n - 1]
        label = f"{CONDITION_NAMES[cond_n]} (n={n_flies[0] if len(n_flies) > 0 else 0})"

        for trace in _make_trace(x, y_mean, y_sem, color, label, show_legend=False):
            fig.add_trace(trace, row=cond_n, col=1)

        y_range = METRIC_RANGES.get(metric)
        if y_range:
            fig.update_yaxes(range=list(y_range), row=cond_n, col=1)

        # N-flies annotation
        n = int(n_flies[0]) if len(n_flies) > 0 else 0
        fig.add_annotation(
            text=f"n={n}", xref=f"x{cond_n} domain" if cond_n > 1 else "x domain",
            yref=f"y{cond_n} domain" if cond_n > 1 else "y domain",
            x=0.98, y=0.9, showarrow=False, font=dict(size=10, color="grey"),
        )

    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {METRIC_LABELS.get(metric, metric)}",
        height=180 * n_conds,
        template="plotly_white",
        showlegend=False,
        margin=dict(t=50, b=30, l=60, r=20),
    )
    fig.update_xaxes(title_text="Time (s)", row=n_conds, col=1)
    return fig


def _strain_overlaid(strain, metric, apply_qc, rep_mode, use_default, store):
    """All 12 conditions overlaid on one plot for one strain."""
    fig = go.Figure()

    for cond_n in range(1, len(CONDITION_NAMES) + 1):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store
        )
        if x is None:
            continue

        color = CONDITION_COLORS[cond_n - 1]
        n = int(n_flies[0]) if len(n_flies) > 0 else 0
        label = f"{CONDITION_NAMES[cond_n]} (n={n})"

        for trace in _make_trace(x, y_mean, y_sem, color, label):
            fig.add_trace(trace)

    y_range = METRIC_RANGES.get(metric)
    if y_range:
        fig.update_yaxes(range=list(y_range))
    _add_stim_markers(fig, y_range)

    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {METRIC_LABELS.get(metric, metric)}",
        xaxis_title="Time (s)",
        yaxis_title=METRIC_LABELS.get(metric, metric),
        template="plotly_white",
        height=550,
        legend=dict(font=dict(size=10)),
        margin=dict(t=50, b=50, l=60, r=20),
    )
    return fig


def _comparison_single(cond_n, metric, selected_strains, apply_qc, rep_mode, use_default, store):
    """Overlaid traces for multiple strains, one condition."""
    fig = go.Figure()

    for i, strain in enumerate(selected_strains):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store
        )
        if x is None:
            continue

        color = STRAIN_COLORS[i % len(STRAIN_COLORS)]
        n = int(n_flies[0]) if len(n_flies) > 0 else 0
        label = f"{strain.replace('_', ' ')} (n={n})"

        for trace in _make_trace(x, y_mean, y_sem, color, label):
            fig.add_trace(trace)

    y_range = METRIC_RANGES.get(metric)
    if y_range:
        fig.update_yaxes(range=list(y_range))
    _add_stim_markers(fig, y_range)

    cond_name = CONDITION_NAMES.get(cond_n, f"Condition {cond_n}")
    fig.update_layout(
        title=f"Cross-Strain: {cond_name} - {METRIC_LABELS.get(metric, metric)}",
        xaxis_title="Time (s)",
        yaxis_title=METRIC_LABELS.get(metric, metric),
        template="plotly_white",
        height=550,
        legend=dict(font=dict(size=10)),
        margin=dict(t=50, b=50, l=60, r=20),
    )
    return fig


def _comparison_grid(metric, selected_strains, apply_qc, rep_mode, use_default, store):
    """12-panel grid with multiple strains overlaid per panel."""
    n_conds = len(CONDITION_NAMES)
    n_cols = 3
    n_rows = (n_conds + n_cols - 1) // n_cols

    fig = make_subplots(
        rows=n_rows, cols=n_cols, shared_xaxes=True, shared_yaxes=True,
        vertical_spacing=0.06, horizontal_spacing=0.04,
        subplot_titles=[CONDITION_NAMES[i] for i in range(1, n_conds + 1)],
    )

    for cond_n in range(1, n_conds + 1):
        row = (cond_n - 1) // n_cols + 1
        col = (cond_n - 1) % n_cols + 1

        for i, strain in enumerate(selected_strains):
            x, y_mean, y_sem, n_flies = _get_summary_data(
                strain, cond_n, metric, apply_qc, rep_mode, use_default, store
            )
            if x is None:
                continue

            color = STRAIN_COLORS[i % len(STRAIN_COLORS)]
            show_legend = cond_n == 1  # Only show legend for first condition
            label = strain.replace("_", " ")

            for trace in _make_trace(x, y_mean, y_sem, color, label, show_legend=show_legend):
                fig.add_trace(trace, row=row, col=col)

        y_range = METRIC_RANGES.get(metric)
        if y_range:
            fig.update_yaxes(range=list(y_range), row=row, col=col)

    fig.update_layout(
        title=f"Cross-Strain Comparison - {METRIC_LABELS.get(metric, metric)}",
        height=300 * n_rows,
        template="plotly_white",
        legend=dict(font=dict(size=10)),
        margin=dict(t=60, b=30, l=60, r=20),
    )
    return fig

"""Dash callbacks for all three dashboard tabs."""

import numpy as np
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from dash import Input, Output, State, callback_context, html, no_update

from dashboard.constants import (
    CONDITION_COLORS,
    CONDITION_NAMES,
    DERIVED_METRICS,
    DIRECTION_CHANGE_FRAME,
    DOWNSAMPLE_FACTOR,
    FPS,
    METRIC_LABELS,
    METRICS,
    STIM_OFFSET_FRAME,
    STIM_ONSET_FRAME,
    STRAIN_COLORS,
)


def _add_stim_markers(fig, row=None, col=None, n_conditions=12):
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
        preferred = "jfrc100_es_shibire_kir"
        default = preferred if preferred in strains else (strains[0] if strains else None)

        # Build rich multi-line status text
        summary = data_store.get_dataset_summary()

        # Line 1: counts
        line1 = f"\u2713 {summary['n_strains']} strains \u00b7 {summary['n_cohorts_total']} cohorts"

        # Line 2: path
        line2 = summary["preprocessed_dir"]

        # Line 3: date range
        if summary.get("date_min") and summary.get("date_max"):
            if summary["date_min"] == summary["date_max"]:
                line3 = f"Acquired: {summary['date_min']}"
            else:
                line3 = f"Acquired: {summary['date_min']} to {summary['date_max']}"
        else:
            line3 = None

        # Line 4: preprocessing timestamp
        line4 = f"Preprocessed: {summary['preprocessed_on']}" if summary.get("preprocessed_on") else None

        status_children = [line1]
        for line in [line2, line3, line4]:
            if line is not None:
                status_children += [html.Br(), line]

        return options, default, status_children

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
        Input("central-tendency-toggle", "value"),
        Input("dispersion-toggle", "value"),
    )
    def update_cohort_plot(strain, cohort_id, condition, metric, qc_on,
                           central_tendency, dispersion):
        if not strain or not cohort_id or not metric:
            return go.Figure()

        apply_qc = bool(qc_on)

        if condition == "all":
            return _cohort_all_conditions(strain, cohort_id, metric, apply_qc, data_store,
                                          central_tendency, dispersion)
        else:
            cond_n = int(condition)
            return _cohort_single_condition(strain, cohort_id, cond_n, metric, apply_qc, data_store,
                                            central_tendency, dispersion)

    # ---- Tab 2: Strain Aggregate View ----
    @app.callback(
        Output("strain-plot", "figure"),
        Input("strain-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("qc-toggle", "value"),
        Input("rep-toggle", "value"),
        Input("strain-view-mode", "value"),
        Input("central-tendency-toggle", "value"),
        Input("dispersion-toggle", "value"),
    )
    def update_strain_plot(strain, metric, qc_on, rep_mode, view_mode,
                           central_tendency, dispersion):
        if not strain or not metric:
            return go.Figure()

        apply_qc = bool(qc_on)
        use_default = (
            not apply_qc
            and rep_mode == "interleave"
            and central_tendency == "mean"
            and dispersion == "sem"
        )

        if view_mode == "tiled":
            return _strain_tiled(strain, metric, apply_qc, rep_mode, use_default, data_store,
                                 central_tendency, dispersion)
        else:
            return _strain_overlaid(strain, metric, apply_qc, rep_mode, use_default, data_store,
                                    central_tendency, dispersion)

    # ---- Tab 3: Cross-Strain Comparison ----
    @app.callback(
        Output("comparison-plot", "figure"),
        Input("comparison-condition-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("comparison-strains", "value"),
        Input("qc-toggle", "value"),
        Input("rep-toggle", "value"),
        Input("comparison-view-mode", "value"),
        Input("central-tendency-toggle", "value"),
        Input("dispersion-toggle", "value"),
    )
    def update_comparison_plot(condition, metric, selected_strains, qc_on, rep_mode, view_mode,
                               central_tendency, dispersion):
        if not metric or not selected_strains:
            return go.Figure()

        apply_qc = bool(qc_on)
        use_default = (
            not apply_qc
            and rep_mode == "interleave"
            and central_tendency == "mean"
            and dispersion == "sem"
        )

        if view_mode == "single" and condition:
            cond_n = int(condition)
            return _comparison_single(cond_n, metric, selected_strains, apply_qc, rep_mode, use_default, data_store,
                                      central_tendency, dispersion)
        else:
            return _comparison_grid(metric, selected_strains, apply_qc, rep_mode, use_default, data_store,
                                    central_tendency, dispersion)

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

    # ---- Tab 4: Metadata ----
    @app.callback(
        Output("metadata-table", "data"),
        Output("metadata-table", "columns"),
        Output("metadata-gantt", "figure"),
        Output("metadata-temp", "figure"),
        Input("data-path-input", "value"),
    )
    def update_metadata_tab(data_path):
        empty_fig = go.Figure()
        empty_fig.add_annotation(
            text="Enter a data path to load metadata.",
            xref="paper", yref="paper", x=0.5, y=0.5, showarrow=False,
        )

        if not data_store.is_valid:
            return [], [], empty_fig, empty_fig

        df = data_store.get_metadata_summary()
        if df.empty:
            return [], [], empty_fig, empty_fig

        # ---- Summary table (per-strain aggregation) ----
        summary = (
            df.groupby("strain", sort=False)
            .agg(
                Cohorts=("cohort_id", "count"),
                Total_Flies=("n_flies", "sum"),
                First_Tested=("date", "min"),
                Last_Tested=("date", "max"),
            )
            .reset_index()
        )
        summary.rename(columns={"strain": "Strain"}, inplace=True)
        summary["Strain"] = summary["Strain"].str.replace("_", " ")
        summary = summary.sort_values("Strain").reset_index(drop=True)

        col_labels = {
            "Strain": "Strain",
            "Cohorts": "Cohorts",
            "Total_Flies": "Total Flies",
            "First_Tested": "First Tested",
            "Last_Tested": "Last Tested",
        }
        table_columns = [{"name": col_labels.get(c, c), "id": c} for c in summary.columns]
        table_data = summary.to_dict("records")

        # ---- Acquisition timeline (Gantt bars, one bar per strain×day) ----
        plot_df = df.copy()
        plot_df["Date"] = pd.to_datetime(plot_df["date"])
        plot_df["Strain"] = plot_df["strain"].str.replace("_", " ")

        # Aggregate to one row per (Strain, date): count cohorts, collect fly counts
        agg = (
            plot_df.groupby(["Strain", "date"])
            .agg(
                n_cohorts=("cohort_id", "count"),
                flies_list=("n_flies", list),
                Start=("Date", "min"),
            )
            .reset_index()
        )
        agg["Finish"] = agg["Start"] + pd.Timedelta(days=1)
        agg["Number of flies"] = agg["flies_list"].apply(lambda lst: str(lst))

        strains_ordered = sorted(agg["Strain"].unique(), reverse=True)
        gantt_fig = px.timeline(
            agg.sort_values("Strain"),
            x_start="Start",
            x_end="Finish",
            y="Strain",
            color="n_cohorts",
            color_continuous_scale="Blues",
            hover_data={
                "Number of flies": True,
                "n_cohorts": True,
                "Start": False,
                "Finish": False,
                "date": False,
            },
            labels={"n_cohorts": "Cohorts"},
        )
        gantt_fig.update_yaxes(autorange="reversed", categoryorder="array", categoryarray=strains_ordered)
        gantt_fig.update_traces(marker_line=dict(width=1, color="rgba(120,120,120,0.5)"))
        gantt_fig.update_layout(
            title="Acquisition Timeline by Strain",
            template="plotly_white",
            height=max(400, 32 * len(strains_ordered) + 120),
            margin=dict(t=70, b=50, l=210, r=100),
            xaxis=dict(title="Date", tickformat="%b %Y"),
            coloraxis_colorbar=dict(title="Cohorts", thickness=15, x=1.01),
        )

        # ---- Temperature timeline (Gantt bars, one bar per measurement×day) ----
        temp_df = data_store.load_temperatures()
        if temp_df.empty:
            temp_fig = go.Figure()
            temp_fig.add_annotation(
                text="No temperature data available. Re-preprocess to add it.",
                xref="paper", yref="paper", x=0.5, y=0.5, showarrow=False,
            )
        else:
            id_cols = ["cohort_id", "strain", "datetime"]
            melt = temp_df.melt(id_vars=id_cols, var_name="temp_type", value_name="temp_c")
            melt["dt"] = pd.to_datetime(melt["datetime"], errors="coerce")
            melt["date"] = melt["dt"].dt.date.astype(str)
            melt["Strain"] = melt["strain"].str.replace("_", " ")

            label_map = {
                "start_temp_outside": "Outside (Start)",
                "start_temp_ring":    "Ring (Start)",
                "end_temp_outside":   "Outside (End)",
                "end_temp_ring":      "Ring (End)",
            }
            melt["Type"] = melt["temp_type"].map(label_map)
            row_order = ["Outside (Start)", "Outside (End)", "Ring (Start)", "Ring (End)"]

            # Aggregate to one bar per (Type, date): mean temp, per-cohort details
            agg_temp = (
                melt.groupby(["Type", "date"])
                .agg(
                    mean_temp=("temp_c", "mean"),
                    temps_list=("temp_c", list),
                    strains_list=("Strain", list),
                )
                .reset_index()
            )
            agg_temp["Start"] = pd.to_datetime(agg_temp["date"])
            agg_temp["Finish"] = agg_temp["Start"] + pd.Timedelta(days=1)

            # Build per-cohort tooltip text
            def _fmt_temp_details(row):
                parts = []
                for t, s in zip(row["temps_list"], row["strains_list"]):
                    parts.append(f"{t:.1f}\u00b0C ({s})")
                return " | ".join(parts)

            agg_temp["Cohort temps"] = agg_temp.apply(_fmt_temp_details, axis=1)
            agg_temp["Mean temp (\u00b0C)"] = agg_temp["mean_temp"].round(1)

            temp_fig = px.timeline(
                agg_temp.sort_values("Type"),
                x_start="Start",
                x_end="Finish",
                y="Type",
                color="mean_temp",
                color_continuous_scale="RdYlBu_r",
                hover_data={
                    "Mean temp (\u00b0C)": True,
                    "Cohort temps": True,
                    "mean_temp": False,
                    "Start": False,
                    "Finish": False,
                    "date": False,
                },
                labels={"mean_temp": "Temp (\u00b0C)"},
            )
            temp_fig.update_yaxes(
                autorange="reversed",
                categoryorder="array",
                categoryarray=row_order,
            )
            temp_fig.update_traces(marker_line=dict(width=1, color="rgba(120,120,120,0.5)"))
            temp_fig.update_layout(
                title="Temperature Timeline (each bar = one day; colour = mean temp)",
                template="plotly_white",
                height=300,
                margin=dict(t=60, b=50, l=160, r=100),
                xaxis=dict(title="Date", tickformat="%b %Y"),
                coloraxis_colorbar=dict(title="\u00b0C", thickness=15, x=1.01),
            )

        return table_data, table_columns, gantt_fig, temp_fig

    # ---- Acclimation baseline callbacks ----
    @app.callback(
        Output("acclim-stats-text", "children"),
        Input("strain-dropdown", "value"),
        Input("cohort-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("qc-toggle", "value"),
    )
    def update_acclim_stats(strain, cohort_id, metric, qc_on):
        if not strain or not cohort_id or not metric:
            return "No data selected."

        summary = data_store.get_acclim_summary(strain, cohort_id, metric, bool(qc_on))
        if not summary:
            return "No acclimation data available for this cohort."

        metric_label = METRIC_LABELS.get(metric, metric)
        return html.Div([
            html.Span(f"n = {summary['n_flies']} flies  |  ", style={"fontWeight": "bold"}),
            html.Span(f"Mean {metric_label}: {summary['overall_mean']:.2f} "),
            html.Span(f"\u00b1 {summary['overall_sem']:.2f} (SEM)"),
        ])

    @app.callback(
        Output("acclim-plot-collapse", "is_open"),
        Input("acclim-plot-toggle", "n_clicks"),
        State("acclim-plot-collapse", "is_open"),
    )
    def toggle_acclim_plot(n_clicks, is_open):
        if n_clicks:
            return not is_open
        return is_open

    @app.callback(
        Output("acclim-plot", "figure"),
        Input("acclim-plot-collapse", "is_open"),
        Input("strain-dropdown", "value"),
        Input("cohort-dropdown", "value"),
        Input("metric-dropdown", "value"),
        Input("qc-toggle", "value"),
    )
    def update_acclim_plot(is_open, strain, cohort_id, metric, qc_on):
        if not is_open or not strain or not cohort_id or not metric:
            return go.Figure()

        df = data_store.get_acclim_data(strain, cohort_id, metric, bool(qc_on))
        if df.empty:
            fig = go.Figure()
            fig.add_annotation(
                text="No acclimation data available",
                xref="paper", yref="paper", x=0.5, y=0.5, showarrow=False,
            )
            return fig

        fig = go.Figure()

        # Individual fly traces (thin, transparent)
        for fly_idx, group in df.groupby("fly_idx"):
            fig.add_trace(go.Scatter(
                x=group["time_s"],
                y=group[metric],
                mode="lines",
                line=dict(width=0.5, color="rgba(150,150,150,0.3)"),
                showlegend=False,
                hoverinfo="skip",
            ))

        # Cohort mean + SEM
        grouped = df.groupby("time_s")[metric].agg(["mean", "std", "count"]).reset_index()
        grouped["sem"] = grouped["std"] / np.sqrt(grouped["count"])
        x = grouped["time_s"].values
        y_mean = grouped["mean"].values
        y_sem = grouped["sem"].values

        for trace in _make_trace(x, y_mean, y_sem, "rgb(100,100,100)", "Acclim mean"):
            fig.add_trace(trace)

        fig.update_layout(
            title="Acclimation Baseline (pre-stimulus dark)",
            xaxis_title="Time (s)",
            yaxis_title=METRIC_LABELS.get(metric, metric),
            template="plotly_white",
            height=200,
            margin=dict(t=30, b=30, l=50, r=10),
            showlegend=False,
        )
        return fig


# ---- Helper functions for building plots ----

def _cohort_single_condition(strain, cohort_id, cond_n, metric, apply_qc, store,
                             central_tendency="mean", dispersion="sem"):
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

    # Cohort central tendency + dispersion
    x, y_center, y_disp = _compute_cohort_stats(df, metric, central_tendency, dispersion)
    ct_label = "Median" if central_tendency == "median" else "Mean"
    disp_label = "MAD" if dispersion == "mad" else "SEM"
    trace_name = f"{CONDITION_NAMES.get(cond_n, f'Cond {cond_n}')} ({ct_label} \u00b1 {disp_label})"

    for trace in _make_trace(x, y_center, y_disp, color, trace_name):
        fig.add_trace(trace)

    _add_stim_markers(fig)

    # Acclimation baseline reference line
    acclim_summary = store.get_acclim_summary(strain, cohort_id, metric, apply_qc)
    if acclim_summary:
        fig.add_hline(
            y=acclim_summary["overall_mean"],
            line=dict(color="rgba(100,100,100,0.5)", width=1, dash="dash"),
            annotation_text=f"Acclim baseline ({acclim_summary['overall_mean']:.1f})",
            annotation_position="top left",
            annotation_font=dict(size=9, color="grey"),
        )

    cond_name = CONDITION_NAMES.get(cond_n, f"Condition {cond_n}")
    n_unique_flies = df["fly_idx"].nunique()
    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {cohort_id.rsplit('_data', 1)[0]} - {cond_name} (n={n_unique_flies} flies)",
        xaxis_title="Time (s)",
        yaxis_title=METRIC_LABELS.get(metric, metric),
        template="plotly_white",
        height=450,
        margin=dict(t=50, b=50, l=60, r=20),
    )
    return fig


def _cohort_all_conditions(strain, cohort_id, metric, apply_qc, store,
                           central_tendency="mean", dispersion="sem"):
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

        x, y_center, y_disp = _compute_cohort_stats(df, metric, central_tendency, dispersion)

        for trace in _make_trace(x, y_center, y_disp, color, CONDITION_NAMES[cond_n], show_legend=False):
            fig.add_trace(trace, row=cond_n, col=1)

        # N-flies annotation
        n_unique = df["fly_idx"].nunique()
        fig.add_annotation(
            text=f"n={n_unique}",
            xref=f"x{cond_n} domain" if cond_n > 1 else "x domain",
            yref=f"y{cond_n} domain" if cond_n > 1 else "y domain",
            x=0.98, y=0.9, showarrow=False, font=dict(size=10, color="grey"),
        )

    fig.update_layout(
        title=f"{strain.replace('_', ' ')} - {cohort_id.rsplit('_data', 1)[0]} - {METRIC_LABELS.get(metric, metric)}",
        height=200 * n_conds,
        template="plotly_white",
        showlegend=False,
        margin=dict(t=50, b=30, l=60, r=20),
    )
    fig.update_xaxes(title_text="Time (s)", row=n_conds, col=1)
    return fig


def _compute_cohort_stats(df, metric, central_tendency="mean", dispersion="sem"):
    """Compute per-frame central tendency and dispersion from cohort data."""
    # For move_to_centre: if dist_data is present, compute it; otherwise it's already pre-computed
    if metric == "move_to_centre" and "dist_data" in df.columns:
        onset_vals = (
            df[df["frame"] == STIM_ONSET_FRAME]
            .groupby(["fly_idx", "rep"])["dist_data"]
            .first()
            .rename("_onset_val")
            .reset_index()
        )
        df = df.copy().merge(onset_vals, on=["fly_idx", "rep"], how="left")
        df["_metric"] = df["dist_data"] - df["_onset_val"]
        col = "_metric"
    elif metric == "move_to_centre":
        # Already computed by get_cohort_data — use column directly
        col = "move_to_centre"
    else:
        col = metric

    frame_groups = df.groupby("time_s")

    if central_tendency == "median":
        center = frame_groups[col].median()
    else:
        center = frame_groups[col].mean()

    if dispersion == "mad":
        med_per_frame = frame_groups[col].median()
        df_with_med = df.merge(
            med_per_frame.rename("_frame_median").reset_index(),
            on="time_s",
        )
        df_with_med["_abs_dev"] = np.abs(df_with_med[col] - df_with_med["_frame_median"])
        disp = df_with_med.groupby("time_s")["_abs_dev"].median()
    else:
        std = frame_groups[col].std()
        count = frame_groups[col].count()
        disp = std / np.sqrt(count.clip(lower=1))

    x = center.index.values
    return x, center.values, disp.values


def _get_summary_data(strain, cond_n, metric, apply_qc, rep_mode, use_default, store,
                      central_tendency="mean", dispersion="sem"):
    """Get central tendency / dispersion data, using pre-computed summary when possible."""
    # Derived metrics are always computed on-the-fly (no pre-computed data available)
    if use_default and metric not in DERIVED_METRICS:
        df = store.get_strain_summary(strain, cond_n, metric)
        if not df.empty:
            return df["time_s"].values, df["mean"].values, df["sem"].values, df["n_flies"].values
    # Fall back to on-the-fly computation
    df = store.compute_summary_on_the_fly(
        strain, cond_n, metric, rep_mode, apply_qc,
        central_tendency=central_tendency,
        dispersion=dispersion,
    )
    if df.empty:
        return None, None, None, None
    return df["time_s"].values, df["mean"].values, df["sem"].values, df["n_flies"].values


def _strain_tiled(strain, metric, apply_qc, rep_mode, use_default, store,
                  central_tendency="mean", dispersion="sem"):
    """12-panel tiled layout for one strain, all conditions."""
    n_conds = len(CONDITION_NAMES)
    fig = make_subplots(
        rows=n_conds, cols=1, shared_xaxes=True, vertical_spacing=0.02,
        subplot_titles=[CONDITION_NAMES[i] for i in range(1, n_conds + 1)],
    )

    for cond_n in range(1, n_conds + 1):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store,
            central_tendency, dispersion,
        )
        if x is None:
            continue

        color = CONDITION_COLORS[cond_n - 1]
        label = f"{CONDITION_NAMES[cond_n]} (n={n_flies[0] if len(n_flies) > 0 else 0})"

        for trace in _make_trace(x, y_mean, y_sem, color, label, show_legend=False):
            fig.add_trace(trace, row=cond_n, col=1)

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


def _strain_overlaid(strain, metric, apply_qc, rep_mode, use_default, store,
                     central_tendency="mean", dispersion="sem"):
    """All 12 conditions overlaid on one plot for one strain."""
    fig = go.Figure()

    for cond_n in range(1, len(CONDITION_NAMES) + 1):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store,
            central_tendency, dispersion,
        )
        if x is None:
            continue

        color = CONDITION_COLORS[cond_n - 1]
        n = int(n_flies[0]) if len(n_flies) > 0 else 0
        label = f"{CONDITION_NAMES[cond_n]} (n={n})"

        for trace in _make_trace(x, y_mean, y_sem, color, label):
            fig.add_trace(trace)

    _add_stim_markers(fig)

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


def _comparison_single(cond_n, metric, selected_strains, apply_qc, rep_mode, use_default, store,
                       central_tendency="mean", dispersion="sem"):
    """Overlaid traces for multiple strains, one condition."""
    fig = go.Figure()

    for i, strain in enumerate(selected_strains):
        x, y_mean, y_sem, n_flies = _get_summary_data(
            strain, cond_n, metric, apply_qc, rep_mode, use_default, store,
            central_tendency, dispersion,
        )
        if x is None:
            continue

        color = STRAIN_COLORS[i % len(STRAIN_COLORS)]
        n = int(n_flies[0]) if len(n_flies) > 0 else 0
        label = f"{strain.replace('_', ' ')} (n={n})"

        for trace in _make_trace(x, y_mean, y_sem, color, label):
            fig.add_trace(trace)

    _add_stim_markers(fig)

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


def _comparison_grid(metric, selected_strains, apply_qc, rep_mode, use_default, store,
                     central_tendency="mean", dispersion="sem"):
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
        n_labels = []

        for i, strain in enumerate(selected_strains):
            x, y_mean, y_sem, n_flies = _get_summary_data(
                strain, cond_n, metric, apply_qc, rep_mode, use_default, store,
                central_tendency, dispersion,
            )
            if x is None:
                continue

            color = STRAIN_COLORS[i % len(STRAIN_COLORS)]
            n = int(n_flies[0]) if len(n_flies) > 0 else 0
            show_legend = cond_n == 1  # Only show legend for first condition
            label = strain.replace("_", " ")
            if show_legend:
                label = f"{label} (n={n})"
            n_labels.append(f"n={n}")

            for trace in _make_trace(x, y_mean, y_sem, color, label, show_legend=show_legend):
                fig.add_trace(trace, row=row, col=col)

        # N-flies annotation per subplot
        if n_labels:
            axis_idx = (row - 1) * n_cols + col
            xref = f"x{axis_idx} domain" if axis_idx > 1 else "x domain"
            yref = f"y{axis_idx} domain" if axis_idx > 1 else "y domain"
            fig.add_annotation(
                text=", ".join(n_labels),
                xref=xref, yref=yref,
                x=0.98, y=0.92, showarrow=False, font=dict(size=8, color="grey"),
            )

    fig.update_layout(
        title=f"Cross-Strain Comparison - {METRIC_LABELS.get(metric, metric)}",
        height=300 * n_rows,
        template="plotly_white",
        legend=dict(font=dict(size=10)),
        margin=dict(t=60, b=30, l=60, r=20),
    )
    return fig

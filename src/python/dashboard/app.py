"""Freely-walking optomotor experiment data dashboard.

Usage:
    pixi run -e default --manifest-path python/freely-walking-python/pixi.toml \
        python -m dashboard.app
"""

from pathlib import Path

import dash
import dash_bootstrap_components as dbc
from dash import dash_table, dcc, html

from dashboard.callbacks import register_callbacks
from dashboard.constants import (
    ALL_METRICS,
    CONDITION_NAMES,
    DEFAULT_DATA_DIR,
    METRIC_LABELS,
)
from dashboard.data_loader import DataStore

# Initialise app
app = dash.Dash(
    __name__,
    external_stylesheets=[dbc.themes.FLATLY],
    suppress_callback_exceptions=True,
)
app.title = "Freely-Walking Optomotor Dashboard"

# Initialise data store (will be populated when user provides data path)
default_preprocessed = Path(DEFAULT_DATA_DIR).parent / f"{Path(DEFAULT_DATA_DIR).name}_preprocessed"
data_store = DataStore(default_preprocessed)

# ---- Sidebar ----
sidebar = dbc.Card(
    [
        dbc.CardBody([
            # Data path
            dbc.Label("Data Directory", className="fw-bold"),
            dbc.Input(
                id="data-path-input",
                type="text",
                value=DEFAULT_DATA_DIR,
                placeholder="Path to protocol results folder...",
                debounce=True,
                className="mb-1",
                size="sm",
            ),
            html.Small(id="data-status", className="text-muted d-block mb-3"),

            html.Hr(),

            # Strain selector
            dbc.Label("Strain", className="fw-bold"),
            dcc.Dropdown(id="strain-dropdown", className="mb-3", clearable=False),

            # Metric selector
            dbc.Label("Metric", className="fw-bold"),
            dcc.Dropdown(
                id="metric-dropdown",
                options=[{"label": METRIC_LABELS[m], "value": m} for m in ALL_METRICS],
                value="fv_data",
                className="mb-3",
                clearable=False,
            ),

            html.Hr(),

            # QC toggle
            dbc.Label("Quality Control", className="fw-bold"),
            dbc.Switch(
                id="qc-toggle",
                label="Exclude low-quality flies",
                value=True,
                className="mb-2",
            ),
            html.Small(
                "Excludes flies with mean fv < 3 mm/s or min dist > 110 mm",
                className="text-muted d-block mb-3",
            ),

            # Rep mode toggle
            dbc.Label("Rep Handling", className="fw-bold"),
            dbc.RadioItems(
                id="rep-toggle",
                options=[
                    {"label": "Interleave R1 & R2", "value": "interleave"},
                    {"label": "Average R1 & R2 per fly", "value": "average"},
                ],
                value="average",
                className="mb-3",
            ),

            html.Hr(),

            # Central tendency toggle
            dbc.Label("Central Tendency", className="fw-bold"),
            dbc.RadioItems(
                id="central-tendency-toggle",
                options=[
                    {"label": "Mean", "value": "mean"},
                    {"label": "Median", "value": "median"},
                ],
                value="mean",
                className="mb-2",
            ),

            # Dispersion toggle
            dbc.Label("Dispersion", className="fw-bold"),
            dbc.RadioItems(
                id="dispersion-toggle",
                options=[
                    {"label": "SEM", "value": "sem"},
                    {"label": "MAD", "value": "mad"},
                ],
                value="sem",
                className="mb-3",
            ),
        ]),
    ],
    className="sticky-top",
    style={"top": "10px"},
)

# ---- Tab 1: Cohort View ----
cohort_controls = dbc.Row([
    dbc.Col([
        dbc.Label("Cohort"),
        dcc.Dropdown(id="cohort-dropdown", clearable=False),
    ], width=6),
    dbc.Col([
        dbc.Label("Condition"),
        dcc.Dropdown(
            id="condition-dropdown",
            options=(
                [{"label": "All conditions", "value": "all"}]
                + [{"label": f"{n}. {name}", "value": str(n)} for n, name in CONDITION_NAMES.items()]
            ),
            value="all",
            clearable=False,
        ),
    ], width=6),
], className="mb-3")

cohort_tab = dbc.Tab(
    label="Cohort View",
    tab_id="tab-cohort",
    children=[
        html.Div([
            cohort_controls,
            # Acclimation baseline info panel
            dbc.Card([
                dbc.CardHeader(
                    dbc.Row([
                        dbc.Col(
                            html.H6("Acclimation Baseline (pre-stimulus dark)", className="mb-0"),
                            width="auto",
                        ),
                        dbc.Col(
                            dbc.Button(
                                "Show timeseries",
                                id="acclim-plot-toggle",
                                color="link",
                                size="sm",
                                className="p-0",
                            ),
                            width="auto",
                        ),
                    ], align="center", justify="between"),
                ),
                dbc.CardBody([
                    html.Div(id="acclim-stats-text", className="mb-2"),
                    dbc.Collapse(
                        dcc.Graph(
                            id="acclim-plot",
                            config={"displayModeBar": False},
                            style={"height": "200px"},
                        ),
                        id="acclim-plot-collapse",
                        is_open=False,
                    ),
                ]),
            ], className="mb-3"),
            dcc.Graph(id="cohort-plot", config={"displayModeBar": True, "scrollZoom": True}),
            dcc.Graph(id="cohort-boxchart", config={"displayModeBar": False}),
        ], className="p-3"),
    ],
)

# ---- Tab 2: Strain Aggregate View ----
strain_controls = dbc.Row([
    dbc.Col([
        dbc.Label("View Mode"),
        dbc.RadioItems(
            id="strain-view-mode",
            options=[
                {"label": "Tiled (one per condition)", "value": "tiled"},
                {"label": "Overlaid (all on one plot)", "value": "overlaid"},
            ],
            value="overlaid",
            inline=True,
        ),
    ]),
], className="mb-3")

strain_tab = dbc.Tab(
    label="Strain View",
    tab_id="tab-strain",
    children=[
        html.Div([
            strain_controls,
            dcc.Graph(id="strain-plot", config={"displayModeBar": True, "scrollZoom": True}),
            dcc.Graph(id="strain-boxchart", config={"displayModeBar": False}),
        ], className="p-3"),
    ],
)

# ---- Tab 3: Cross-Strain Comparison ----
comparison_controls = dbc.Row([
    dbc.Col([
        dbc.Label("Condition"),
        dcc.Dropdown(
            id="comparison-condition-dropdown",
            options=[{"label": f"{n}. {name}", "value": str(n)} for n, name in CONDITION_NAMES.items()],
            value="1",
            clearable=False,
        ),
    ], width=4),
    dbc.Col([
        dbc.Label("View Mode"),
        dbc.RadioItems(
            id="comparison-view-mode",
            options=[
                {"label": "Single condition", "value": "single"},
                {"label": "All conditions grid", "value": "grid"},
            ],
            value="single",
            inline=True,
        ),
    ], width=4),
], className="mb-3")

comparison_strains = html.Div([
    dbc.Label("Select Strains to Compare", className="fw-bold"),
    dbc.Checklist(
        id="comparison-strains",
        options=[],
        value=[],
        inline=False,
        className="mb-3",
        style={"maxHeight": "200px", "overflowY": "auto"},
    ),
], className="mb-3")

comparison_tab = dbc.Tab(
    label="Cross-Strain Comparison",
    tab_id="tab-comparison",
    children=[
        html.Div([
            comparison_controls,
            comparison_strains,
            dcc.Graph(id="comparison-plot", config={"displayModeBar": True, "scrollZoom": True}),
            dcc.Graph(id="comparison-boxchart", config={"displayModeBar": False}),
        ], className="p-3"),
    ],
)

# ---- Tab 4: Metadata ----
metadata_tab = dbc.Tab(
    label="Metadata",
    tab_id="tab-metadata",
    children=[
        html.Div([
            html.H5("Dataset Overview", className="mb-3"),
            dash_table.DataTable(
                id="metadata-table",
                columns=[],
                data=[],
                sort_action="native",
                style_header={
                    "fontWeight": "bold",
                    "backgroundColor": "#f8f9fa",
                    "border": "1px solid #dee2e6",
                },
                style_data_conditional=[
                    {
                        "if": {"row_index": "odd"},
                        "backgroundColor": "#f8f9fa",
                    }
                ],
                style_cell={
                    "padding": "8px 12px",
                    "fontSize": "14px",
                    "fontFamily": "inherit",
                    "border": "1px solid #dee2e6",
                    "textAlign": "left",
                },
                style_table={"marginBottom": "24px"},
            ),
            html.Hr(),
            html.H5("Acquisition Timeline", className="mb-3"),
            dcc.Graph(
                id="metadata-gantt",
                config={"displayModeBar": True, "scrollZoom": True},
            ),
            html.Hr(),
            html.H5("Temperature Timeline", className="mb-3"),
            dcc.Graph(
                id="metadata-temp",
                config={"displayModeBar": True, "scrollZoom": True},
            ),
        ], className="p-3"),
    ],
)

# ---- Main Layout ----
app.layout = dbc.Container(
    [
        dbc.Row([
            dbc.Col(
                html.H3("Freely-Walking Optomotor Dashboard", className="text-primary my-3"),
            ),
        ]),
        dbc.Row([
            dbc.Col(sidebar, width=3),
            dbc.Col(
                dbc.Tabs(
                    [cohort_tab, strain_tab, comparison_tab, metadata_tab],
                    id="main-tabs",
                    active_tab="tab-metadata",
                ),
                width=9,
            ),
        ]),
    ],
    fluid=True,
)

# Register callbacks
register_callbacks(app, data_store)

if __name__ == "__main__":
    app.run(debug=True, port=8050)

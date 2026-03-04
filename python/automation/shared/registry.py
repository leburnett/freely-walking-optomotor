"""
Global pipeline status registry and HTML status page generator.

Maintains a single pipeline_status.json on the network drive that aggregates
the status of all experiments. Both machines read/write this file.
"""

import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)


def _get_registry_path():
    """Return the path to the global pipeline registry."""
    sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))
    from config.config import PIPELINE_REGISTRY
    return str(PIPELINE_REGISTRY)


def _read_registry(registry_path):
    """Read the global registry, returning a dict."""
    if os.path.exists(registry_path):
        try:
            with open(registry_path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            logger.warning(f"Error reading registry: {e}")
    return {"last_updated": None, "experiments": []}


def _write_registry(registry_path, data):
    """Write the global registry dict to file."""
    data["last_updated"] = datetime.now().isoformat(timespec="seconds")
    os.makedirs(os.path.dirname(registry_path), exist_ok=True)
    # Write to temp file then rename for atomicity
    tmp_path = registry_path + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(data, f, indent=2)
        # On Windows, os.replace handles overwriting
        os.replace(tmp_path, registry_path)
    except OSError as e:
        logger.error(f"Error writing registry: {e}")
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def update_registry(experiment_status):
    """Upsert an experiment entry in the global registry.

    Args:
        experiment_status: Dict from read_status() with experiment data.
    """
    registry_path = _get_registry_path()
    data = _read_registry(registry_path)

    exp_id = experiment_status.get("experiment_id", "unknown")
    summary = {
        "experiment_id": exp_id,
        "date": experiment_status.get("date", ""),
        "protocol": experiment_status.get("protocol", ""),
        "strain": experiment_status.get("strain", ""),
        "sex": experiment_status.get("sex", ""),
        "current_stage": experiment_status.get("current_stage", ""),
        "last_updated": datetime.now().isoformat(timespec="seconds"),
        "has_errors": len(experiment_status.get("errors", [])) > 0,
    }

    # Upsert: replace existing or append
    experiments = data.get("experiments", [])
    found = False
    for i, exp in enumerate(experiments):
        if exp.get("experiment_id") == exp_id:
            # Preserve cross-reference fields if not in the new summary
            for field in (
                "has_data_local_acquisition",
                "has_data_local_processing",
                "has_data_network",
                "has_local_results_acquisition",
                "has_local_results_processing",
                "has_network_results",
            ):
                if field not in summary and field in exp:
                    summary[field] = exp[field]
            experiments[i] = summary
            found = True
            break
    if not found:
        experiments.append(summary)

    data["experiments"] = experiments
    _write_registry(registry_path, data)
    logger.info(f"Registry updated for {exp_id}: stage={summary['current_stage']}")

    # Regenerate the HTML status page
    generate_status_page(registry_path)


def get_all_experiments(registry_path=None):
    """Return list of all experiment entries from the global registry."""
    if registry_path is None:
        registry_path = _get_registry_path()
    data = _read_registry(registry_path)
    return data.get("experiments", [])


_LOCATION_FIELDS = (
    "has_data_local_acquisition",
    "has_data_local_processing",
    "has_data_network",
    "has_local_results_acquisition",
    "has_local_results_processing",
    "has_network_results",
)


def _is_unresolved(exp):
    """Return True if an experiment has no useful metadata.

    An experiment is considered unresolved when both protocol and strain
    are unknown/empty AND none of the location booleans are set.  These
    are typically legacy entries merged from an older registry that can
    no longer be matched to a real experiment folder.
    """
    proto = exp.get("protocol", "") or ""
    strain = exp.get("strain", "") or ""
    if proto not in ("unknown", "") or strain not in ("unknown", ""):
        return False
    return not any(exp.get(f, False) for f in _LOCATION_FIELDS)


def generate_status_page(registry_path=None):
    """Generate a static HTML status page from the pipeline registry.

    Writes pipeline_status.html next to the registry JSON file.
    Experiments with no useful metadata are excluded from the HTML
    table and written to a companion *_excluded.txt* file instead.

    Args:
        registry_path: Path to the registry JSON. If None, auto-detected.
    """
    if registry_path is None:
        registry_path = _get_registry_path()

    data = _read_registry(registry_path)
    all_experiments = data.get("experiments", [])
    last_updated = data.get("last_updated", "Never")

    # Separate resolved from unresolved experiments
    experiments = []
    excluded = []
    for exp in all_experiments:
        if _is_unresolved(exp):
            excluded.append(exp)
        else:
            experiments.append(exp)

    if excluded:
        logger.info(
            f"Excluding {len(excluded)} unresolved experiments from HTML "
            f"(no protocol/strain/location data)"
        )

    # Count experiments by stage (only resolved ones)
    stage_counts = {}
    error_count = 0
    for exp in experiments:
        stage = exp.get("current_stage", "unknown") or "unknown"
        stage_counts[stage] = stage_counts.get(stage, 0) + 1
        if exp.get("has_errors"):
            error_count += 1

    # Build HTML
    html = _build_html(experiments, last_updated, stage_counts, error_count,
                       excluded_count=len(excluded))

    # Write next to the registry
    html_path = registry_path.replace(".json", ".html")
    try:
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(html)
        logger.info(f"Status page generated: {html_path}")
    except OSError as e:
        logger.error(f"Error writing status page: {e}")

    # Write excluded experiments to a txt file
    if excluded:
        txt_path = registry_path.replace(".json", "_excluded.txt")
        try:
            with open(txt_path, "w", encoding="utf-8") as f:
                f.write(f"# Excluded experiments — {len(excluded)} entries\n")
                f.write(f"# Generated: {last_updated}\n")
                f.write(f"# These experiments have no protocol/strain metadata\n")
                f.write(f"# and no location data. They are legacy entries from\n")
                f.write(f"# older registry runs.\n")
                f.write("#\n")
                f.write(f"# {'Date':<14} {'Time':<12} {'Stage':<22} Experiment ID\n")
                f.write(f"# {'-'*13} {'-'*11} {'-'*21} {'-'*40}\n")
                for exp in sorted(excluded, key=lambda e: (
                    e.get("date", ""), e.get("time", "")
                )):
                    f.write(
                        f"  {exp.get('date', ''):<14}"
                        f" {exp.get('time', ''):<12}"
                        f" {exp.get('current_stage', ''):<22}"
                        f" {exp.get('experiment_id', '')}\n"
                    )
            logger.info(f"Excluded experiments written to: {txt_path}")
        except OSError as e:
            logger.error(f"Error writing excluded file: {e}")


def _stage_color(stage):
    """Return a CSS color for each pipeline stage."""
    colors = {
        "acquired": "#6c757d",
        "copied_to_network": "#0d6efd",
        "tracked": "#0dcaf0",
        "processed": "#198754",
        "synced_to_network": "#20c997",
    }
    return colors.get(stage, "#ffc107")


def _build_html(experiments, last_updated, stage_counts, error_count,
                excluded_count=0):
    """Build the full HTML page string."""
    # Sort experiments by date descending, then time
    experiments_sorted = sorted(
        experiments,
        key=lambda e: (e.get("date", ""), e.get("experiment_id", "")),
        reverse=True,
    )

    # Summary cards
    total = len(experiments)
    summary_items = []
    for stage, count in sorted(stage_counts.items()):
        color = _stage_color(stage)
        label = stage.replace("_", " ").title()
        summary_items.append(
            f'<span class="badge" style="background-color:{color}">'
            f"{label}: {count}</span>"
        )

    summary_html = " ".join(summary_items)

    # Cross-reference counts — data folders
    data_acq_count = sum(1 for e in experiments if e.get("has_data_local_acquisition"))
    data_proc_count = sum(1 for e in experiments if e.get("has_data_local_processing"))
    data_net_count = sum(1 for e in experiments if e.get("has_data_network"))
    # Cross-reference counts — results files
    res_acq_count = sum(1 for e in experiments if e.get("has_local_results_acquisition"))
    res_proc_count = sum(1 for e in experiments if e.get("has_local_results_processing"))
    res_net_count = sum(1 for e in experiments if e.get("has_network_results"))

    # Embed experiment data as JS for charts
    js_data = json.dumps([
        {"stage": e.get("current_stage", "unknown") or "unknown",
         "protocol": e.get("protocol", ""),
         "strain": e.get("strain", ""),
         "date": e.get("date", ""),
         "time": e.get("time", "")}
        for e in experiments
    ], separators=(",", ":"))

    # Table rows
    rows = []
    for exp in experiments_sorted:
        stage = exp.get("current_stage", "unknown") or "unknown"
        color = _stage_color(stage)
        has_errors = exp.get("has_errors", False)
        error_indicator = ' <span class="error-dot">&#9679;</span>' if has_errors else ""
        stage_label = stage.replace("_", " ").title()

        # Data folder location indicators
        d_acq = "&#10003;" if exp.get("has_data_local_acquisition") else ""
        d_proc = "&#10003;" if exp.get("has_data_local_processing") else ""
        d_net = "&#10003;" if exp.get("has_data_network") else ""

        # Results file location indicators
        r_acq = "&#10003;" if exp.get("has_local_results_acquisition") else ""
        r_proc = "&#10003;" if exp.get("has_local_results_processing") else ""
        r_net = "&#10003;" if exp.get("has_network_results") else ""

        rows.append(f"""        <tr>
            <td>{exp.get('date', '')}</td>
            <td>{exp.get('protocol', '')}</td>
            <td>{exp.get('strain', '')}</td>
            <td><span class="badge" style="background-color:{color}">{stage_label}</span>{error_indicator}</td>
            <td class="check-cell">{d_acq}</td>
            <td class="check-cell">{d_proc}</td>
            <td class="check-cell">{d_net}</td>
            <td class="check-cell">{r_acq}</td>
            <td class="check-cell">{r_proc}</td>
            <td class="check-cell">{r_net}</td>
            <td>{exp.get('last_updated', '')}</td>
        </tr>""")

    rows_html = "\n".join(rows)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pipeline Status</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; padding: 20px; background: #f8f9fa; color: #212529; }}
        h1 {{ margin-bottom: 5px; font-size: 1.5rem; }}
        .subtitle {{ color: #6c757d; margin-bottom: 20px; font-size: 0.9rem; }}
        .summary {{ margin-bottom: 20px; display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }}
        .summary .total {{ font-weight: 600; margin-right: 10px; }}
        .badge {{ display: inline-block; padding: 4px 10px; border-radius: 12px; color: white; font-size: 0.8rem; font-weight: 500; }}
        .error-count {{ background: #dc3545; }}
        .error-dot {{ color: #dc3545; font-size: 0.7rem; }}
        #status-table {{ width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
        #status-table thead {{ background: #212529; color: white; }}
        #status-table th {{ padding: 10px 14px; text-align: left; font-weight: 500; font-size: 0.85rem; cursor: pointer; user-select: none; }}
        #status-table th:hover {{ background: #343a40; }}
        #status-table td {{ padding: 8px 14px; border-bottom: 1px solid #e9ecef; font-size: 0.85rem; }}
        #status-table tr:hover td {{ background: #f1f3f5; }}
        .check-cell {{ text-align: center; color: #198754; font-size: 1rem; }}
        .filter-row {{ margin-bottom: 15px; }}
        .filter-row input {{ padding: 6px 12px; border: 1px solid #ced4da; border-radius: 6px; font-size: 0.85rem; width: 300px; }}
        /* Pipeline info sections */
        .pipeline-info {{ margin-bottom: 16px; background: white; border-radius: 8px; padding: 12px 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
        .pipeline-info summary {{ cursor: pointer; font-size: 0.9rem; margin-bottom: 8px; }}
        .info-table {{ width: 100%; border-collapse: collapse; font-size: 0.82rem; margin-top: 8px; }}
        .info-table th {{ background: #f8f9fa; padding: 6px 10px; text-align: left; border-bottom: 2px solid #dee2e6; font-weight: 600; cursor: default; color: #212529; }}
        .info-table th:hover {{ background: #f8f9fa; }}
        .info-table td {{ padding: 6px 10px; border-bottom: 1px solid #e9ecef; }}
        /* Flowchart */
        .flowchart {{ margin-top: 10px; overflow-x: auto; }}
        .flow-row {{ display: flex; align-items: stretch; gap: 0; padding: 10px 0; min-width: 780px; }}
        .flow-node {{ flex: 1; border: 2px solid; border-radius: 8px; text-align: center; padding: 0; background: white; min-width: 130px; display: flex; flex-direction: column; }}
        .flow-label {{ color: white; padding: 5px 8px; font-size: 0.75rem; font-weight: 600; border-radius: 6px 6px 0 0; }}
        .flow-desc {{ padding: 6px 4px; font-size: 0.72rem; color: #495057; line-height: 1.3; flex: 1; }}
        .flow-req {{ padding: 3px 6px; font-size: 0.68rem; color: #868e96; font-style: italic; }}
        .flow-script {{ padding: 3px 4px 5px; font-size: 0.65rem; color: #6c757d; font-family: monospace; border-top: 1px solid #e9ecef; }}
        .flow-arrow {{ font-size: 1.4rem; color: #adb5bd; padding: 0 6px; flex-shrink: 0; display: flex; align-items: center; }}
        .flow-machines {{ margin-top: 6px; display: flex; min-width: 780px; gap: 4px; }}
        .flow-machine {{ display: flex; align-items: center; gap: 6px; padding: 4px 8px; border-radius: 4px; background: #f8f9fa; }}
        .machine-label {{ white-space: nowrap; color: #6c757d; font-weight: 500; font-size: 0.72rem; }}
        .machine-bar {{ height: 3px; flex: 1; border-radius: 2px; }}
        .machine-acq {{ background: #6c757d; }}
        .machine-proc {{ background: #198754; }}
        /* Stacked bar charts */
        .chart-legend {{ display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 10px; font-size: 0.75rem; }}
        .legend-item {{ display: flex; align-items: center; gap: 4px; color: #495057; }}
        .legend-swatch {{ width: 12px; height: 12px; border-radius: 2px; flex-shrink: 0; }}
        .stacked-chart {{ margin-top: 6px; }}
        .stacked-bar-row {{ display: flex; align-items: center; gap: 6px; font-size: 0.78rem; margin-bottom: 3px; }}
        .stacked-bar-label {{ width: 150px; text-align: right; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #495057; flex-shrink: 0; }}
        .stacked-bar-track {{ flex: 1; display: flex; background: #e9ecef; border-radius: 3px; height: 18px; min-width: 60px; overflow: hidden; }}
        .stacked-bar-segment {{ height: 100%; }}
        .stacked-bar-segment:first-child {{ border-radius: 3px 0 0 3px; }}
        .stacked-bar-segment:last-child {{ border-radius: 0 3px 3px 0; }}
        .stacked-bar-segment:only-child {{ border-radius: 3px; }}
        .stacked-bar-count {{ width: 36px; text-align: right; font-weight: 600; color: #212529; flex-shrink: 0; }}
        /* Timeline chart */
        .timeline-container {{ overflow-x: auto; position: relative; margin-top: 8px; }}
        .timeline-container canvas {{ display: block; }}
        .timeline-tooltip {{ display: none; position: absolute; background: #212529; color: white; padding: 6px 10px; border-radius: 6px; font-size: 0.75rem; pointer-events: none; white-space: nowrap; z-index: 10; box-shadow: 0 2px 8px rgba(0,0,0,0.2); }}
    </style>
</head>
<body>
    <h1>Freely Walking Optomotor &mdash; Pipeline Status</h1>
    <p class="subtitle">Last updated: {last_updated}</p>

    <div class="summary">
        <span class="total">Total: {total}</span>
        {summary_html}
        {"<span class='badge error-count'>Errors: " + str(error_count) + "</span>" if error_count else ""}
        {"<span class='badge' style='background-color:#495057'>Data-Acq: " + str(data_acq_count) + "</span>" if data_acq_count else ""}
        {"<span class='badge' style='background-color:#495057'>Data-Proc: " + str(data_proc_count) + "</span>" if data_proc_count else ""}
        {"<span class='badge' style='background-color:#495057'>Data-Net: " + str(data_net_count) + "</span>" if data_net_count else ""}
        {"<span class='badge' style='background-color:#6f42c1'>Res-Acq: " + str(res_acq_count) + "</span>" if res_acq_count else ""}
        {"<span class='badge' style='background-color:#6f42c1'>Res-Proc: " + str(res_proc_count) + "</span>" if res_proc_count else ""}
        {"<span class='badge' style='background-color:#6f42c1'>Res-Net: " + str(res_net_count) + "</span>" if res_net_count else ""}
        {"<span class='badge' style='background-color:#adb5bd' title='Legacy entries with no metadata — see pipeline_status_excluded.txt'>Excluded: " + str(excluded_count) + "</span>" if excluded_count else ""}
    </div>

    <details class="pipeline-info" open>
        <summary><strong>Pipeline Stages</strong></summary>
        <table class="info-table">
            <thead>
                <tr>
                    <th>Stage</th>
                    <th>Description</th>
                    <th>Set By</th>
                    <th>Requirements</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><span class="badge" style="background-color:#6c757d">Acquired</span></td>
                    <td>Raw experiment data exists on acquisition machine</td>
                    <td><code>monitor_and_copy.py</code></td>
                    <td>stamp_log, .mat, and .ufmf files present</td>
                </tr>
                <tr>
                    <td><span class="badge" style="background-color:#0d6efd">Copied To Network</span></td>
                    <td>Data copied to network unprocessed folder</td>
                    <td><code>monitor_and_copy.py</code></td>
                    <td>Folder copied to network drive</td>
                </tr>
                <tr>
                    <td><span class="badge" style="background-color:#0dcaf0">Tracked</span></td>
                    <td>FlyTracker completed, trx.mat generated</td>
                    <td><code>monitor_and_track.py</code></td>
                    <td>trx.mat exists in recording subfolder</td>
                </tr>
                <tr>
                    <td><span class="badge" style="background-color:#198754">Processed</span></td>
                    <td>MATLAB processing complete, result _data.mat generated</td>
                    <td><code>daily_processing.py</code></td>
                    <td>Result file exists in local results folder</td>
                </tr>
                <tr>
                    <td><span class="badge" style="background-color:#20c997">Synced To Network</span></td>
                    <td>Results, figures, and videos copied to network</td>
                    <td><code>daily_processing.py</code></td>
                    <td>Result file exists in network exp_results</td>
                </tr>
            </tbody>
        </table>
    </details>

    <details class="pipeline-info" open>
        <summary><strong>Pipeline Flow</strong></summary>
        <div class="flowchart">
            <div class="flow-row">
                <div class="flow-node" style="border-color:#6c757d">
                    <div class="flow-label" style="background:#6c757d">Acquired</div>
                    <div class="flow-desc">Raw data on<br>acquisition machine</div>
                    <div class="flow-req">stamp_log + .mat + .ufmf</div>
                    <div class="flow-script">monitor_and_copy.py</div>
                </div>
                <div class="flow-arrow">&rarr;</div>
                <div class="flow-node" style="border-color:#0d6efd">
                    <div class="flow-label" style="background:#0d6efd">Copied to Network</div>
                    <div class="flow-desc">Data on network<br>unprocessed folder</div>
                    <div class="flow-req">robocopy to \\\\prfs</div>
                    <div class="flow-script">monitor_and_copy.py</div>
                </div>
                <div class="flow-arrow">&rarr;</div>
                <div class="flow-node" style="border-color:#0dcaf0">
                    <div class="flow-label" style="background:#0dcaf0">Tracked</div>
                    <div class="flow-desc">FlyTracker complete<br>trx.mat generated</div>
                    <div class="flow-req">batch_track_ufmf()</div>
                    <div class="flow-script">monitor_and_track.py</div>
                </div>
                <div class="flow-arrow">&rarr;</div>
                <div class="flow-node" style="border-color:#198754">
                    <div class="flow-label" style="background:#198754">Processed</div>
                    <div class="flow-desc">MATLAB processing<br>results generated</div>
                    <div class="flow-req">process_freely_walking_data()</div>
                    <div class="flow-script">daily_processing.py</div>
                </div>
                <div class="flow-arrow">&rarr;</div>
                <div class="flow-node" style="border-color:#20c997">
                    <div class="flow-label" style="background:#20c997">Synced to Network</div>
                    <div class="flow-desc">Results &amp; figures<br>on network drive</div>
                    <div class="flow-req">copy to exp_results</div>
                    <div class="flow-script">daily_processing.py</div>
                </div>
            </div>
            <div class="flow-machines">
                <div class="flow-machine" style="flex:2">
                    <span class="machine-label">Acquisition Machine</span>
                    <div class="machine-bar machine-acq"></div>
                </div>
                <div class="flow-machine" style="flex:3">
                    <span class="machine-label">Processing Machine</span>
                    <div class="machine-bar machine-proc"></div>
                </div>
            </div>
        </div>
    </details>

    <details class="pipeline-info">
        <summary><strong>Experiments by Protocol</strong></summary>
        <div class="chart-legend" id="chart-legend-proto"></div>
        <div class="stacked-chart" id="stacked-protocol"></div>
    </details>

    <details class="pipeline-info">
        <summary><strong>Experiments by Strain</strong></summary>
        <div class="chart-legend" id="chart-legend-strain"></div>
        <div class="stacked-chart" id="stacked-strain"></div>
    </details>

    <details class="pipeline-info">
        <summary><strong>Experiment Timeline</strong></summary>
        <div class="chart-legend" id="chart-legend-timeline"></div>
        <div class="timeline-container" id="timeline-container">
            <canvas id="timeline-canvas"></canvas>
            <div id="timeline-tooltip" class="timeline-tooltip"></div>
        </div>
    </details>

    <div class="filter-row">
        <input type="text" id="filter" placeholder="Filter by date, strain, protocol..." oninput="filterTable()">
    </div>

    <table id="status-table">
        <thead>
            <tr>
                <th onclick="sortTable(0)">Date</th>
                <th onclick="sortTable(1)">Protocol</th>
                <th onclick="sortTable(2)">Strain</th>
                <th onclick="sortTable(3)">Stage</th>
                <th onclick="sortTable(4)" title="Experiment data folder on acquisition machine">Data Acq</th>
                <th onclick="sortTable(5)" title="Experiment data folder on processing machine">Data Proc</th>
                <th onclick="sortTable(6)" title="Experiment data folder on network drive">Data Net</th>
                <th onclick="sortTable(7)" title="Results file on acquisition machine">Res Acq</th>
                <th onclick="sortTable(8)" title="Results file on processing machine">Res Proc</th>
                <th onclick="sortTable(9)" title="Results file in network exp_results">Res Net</th>
                <th onclick="sortTable(10)">Last Updated</th>
            </tr>
        </thead>
        <tbody>
{rows_html}
        </tbody>
    </table>

    <script>
    const expData = {js_data};
    const stageOrder = ['acquired','copied_to_network','tracked','processed','synced_to_network'];
    const stageColors = {{
        'acquired': '#6c757d',
        'copied_to_network': '#0d6efd',
        'tracked': '#0dcaf0',
        'processed': '#198754',
        'synced_to_network': '#20c997'
    }};
    const stageLabels = {{
        'acquired': 'Acquired',
        'copied_to_network': 'Copied to Network',
        'tracked': 'Tracked',
        'processed': 'Processed',
        'synced_to_network': 'Synced to Network'
    }};
    let sortDir = {{}};

    // Clean up known metadata issues for chart display:
    //  - Protocols that look like dates (YYYY_MM_DD) -> "unknown"
    //  - Strains that look like protocol names -> "unknown"
    const datePattern = /^\\d{{4}}_\\d{{2}}_\\d{{2}}$/;
    const protoPattern = /^protocol_\\d+$|^Protocol_v\\d+$/i;
    expData.forEach(e => {{
        if (datePattern.test(e.protocol)) e.protocol = 'unknown';
        if (protoPattern.test(e.strain)) e.strain = 'unknown';
        if (!e.protocol || e.protocol === '') e.protocol = 'unknown';
        if (!e.strain || e.strain === '') e.strain = 'unknown';
    }});

    function sortTable(col) {{
        const table = document.getElementById('status-table');
        const tbody = table.tBodies[0];
        const rows = Array.from(tbody.rows);
        sortDir[col] = !sortDir[col];
        rows.sort((a, b) => {{
            const aText = a.cells[col].textContent.trim();
            const bText = b.cells[col].textContent.trim();
            return sortDir[col] ? aText.localeCompare(bText) : bText.localeCompare(aText);
        }});
        rows.forEach(r => tbody.appendChild(r));
    }}

    function filterTable() {{
        const q = document.getElementById('filter').value.toLowerCase();
        const rows = document.querySelectorAll('#status-table tbody tr');
        rows.forEach(r => {{
            r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
        }});
    }}

    function buildLegend(containerId) {{
        const el = document.getElementById(containerId);
        let html = '';
        stageOrder.forEach(s => {{
            html += '<span class="legend-item">' +
                '<span class="legend-swatch" style="background:' + stageColors[s] + '"></span>' +
                (stageLabels[s] || s) + '</span>';
        }});
        // Add unknown if present
        if (expData.some(e => !stageOrder.includes(e.stage))) {{
            html += '<span class="legend-item">' +
                '<span class="legend-swatch" style="background:#ffc107"></span>Unknown</span>';
        }}
        el.innerHTML = html;
    }}

    function buildStackedChart(containerId, groupKey) {{
        const groups = {{}};
        expData.forEach(e => {{
            const key = e[groupKey] || 'unknown';
            if (!groups[key]) groups[key] = {{}};
            const stage = e.stage || 'unknown';
            groups[key][stage] = (groups[key][stage] || 0) + 1;
        }});

        const sorted = Object.entries(groups).map(([name, stageCnts]) => {{
            const total = Object.values(stageCnts).reduce((a, b) => a + b, 0);
            return {{ name, stageCnts, total }};
        }}).sort((a, b) => b.name.localeCompare(a.name));

        const container = document.getElementById(containerId);
        let html = '';
        sorted.forEach(g => {{
            html += '<div class="stacked-bar-row">';
            html += '<span class="stacked-bar-label" title="' + g.name + '">' + g.name + '</span>';
            html += '<div class="stacked-bar-track">';
            // Render known stages first in order, then any unknown
            const allStages = [...stageOrder];
            Object.keys(g.stageCnts).forEach(s => {{
                if (!allStages.includes(s)) allStages.push(s);
            }});
            allStages.forEach(stage => {{
                const count = g.stageCnts[stage] || 0;
                if (count > 0) {{
                    const pct = (count / g.total) * 100;
                    const color = stageColors[stage] || '#ffc107';
                    const label = stageLabels[stage] || stage;
                    html += '<div class="stacked-bar-segment" style="width:' + pct +
                        '%;background:' + color + '" title="' + label + ': ' + count + '"></div>';
                }}
            }});
            html += '</div>';
            html += '<span class="stacked-bar-count">' + g.total + '</span>';
            html += '</div>';
        }});
        container.innerHTML = html;
    }}

    // ---- Timeline scatter chart (equally spaced, day boundaries) ----
    function buildTimeline() {{
        const canvas = document.getElementById('timeline-canvas');
        const container = document.getElementById('timeline-container');
        const tooltip = document.getElementById('timeline-tooltip');
        if (!canvas || !container) return;

        const ctx = canvas.getContext('2d');
        const dpr = window.devicePixelRatio || 1;

        // Parse dates and build point array
        const points = [];
        expData.forEach(e => {{
            if (!e.date || !e.time) return;
            const dp = e.date.split('_');
            const tp = e.time.split('_');
            if (dp.length !== 3 || tp.length !== 3) return;
            const dt = new Date(+dp[0], +dp[1]-1, +dp[2], +tp[0], +tp[1], +tp[2]);
            if (isNaN(dt.getTime())) return;
            const stageIdx = stageOrder.indexOf(e.stage);
            if (stageIdx < 0) return;
            points.push({{
                ts: dt.getTime(), date: dt, dateKey: e.date,
                stage: e.stage, stageIdx: stageIdx,
                protocol: e.protocol || 'unknown',
                strain: e.strain || 'unknown'
            }});
        }});
        if (points.length === 0) return;

        // Sort oldest → newest
        points.sort((a, b) => a.ts - b.ts);

        // Layout constants
        const marginLeft = 130;
        const marginRight = 20;
        const marginTop = 20;
        const marginBottom = 55;
        const rowH = 36;
        const numStages = stageOrder.length;
        const chartH = marginTop + numStages * rowH + marginBottom;
        const colW = Math.max(6, Math.min(12, 3000 / points.length));
        const chartW = Math.max(container.clientWidth,
                                marginLeft + points.length * colW + marginRight);

        // Set canvas size (CSS pixels); use dpr for crisp rendering
        canvas.style.width = chartW + 'px';
        canvas.style.height = chartH + 'px';
        canvas.width = Math.round(chartW * dpr);
        canvas.height = Math.round(chartH * dpr);
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

        // Scales: equally spaced on x, stage rows on y
        function xPos(i) {{ return marginLeft + (i + 0.5) * colW; }}
        function yPos(stageIdx) {{
            return marginTop + (numStages - 1 - stageIdx) * rowH + rowH / 2;
        }}

        // Alternating row backgrounds
        for (let r = 0; r < numStages; r++) {{
            const y = marginTop + r * rowH;
            ctx.fillStyle = r % 2 === 0 ? '#f8f9fa' : '#ffffff';
            ctx.fillRect(marginLeft, y, chartW - marginLeft - marginRight, rowH);
        }}

        // Horizontal grid lines
        ctx.strokeStyle = '#e9ecef';
        ctx.lineWidth = 1;
        for (let r = 0; r <= numStages; r++) {{
            const y = marginTop + r * rowH;
            ctx.beginPath();
            ctx.moveTo(marginLeft, y);
            ctx.lineTo(chartW - marginRight, y);
            ctx.stroke();
        }}

        // Day-boundary vertical lines + date labels
        ctx.font = '10px -apple-system, BlinkMacSystemFont, sans-serif';
        ctx.textBaseline = 'top';
        let prevDateKey = null;
        const dayStarts = [];  // {{idx, dateKey}}
        for (let i = 0; i < points.length; i++) {{
            if (points[i].dateKey !== prevDateKey) {{
                dayStarts.push({{ idx: i, dateKey: points[i].dateKey }});
                prevDateKey = points[i].dateKey;
            }}
        }}
        dayStarts.forEach((ds, di) => {{
            const x = marginLeft + ds.idx * colW;
            // Light grey vertical line at day boundary
            ctx.strokeStyle = '#dee2e6';
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(x, marginTop);
            ctx.lineTo(x, chartH - marginBottom);
            ctx.stroke();
            // Date label (show every Nth label to avoid overlap)
            const labelEvery = Math.max(1, Math.ceil(dayStarts.length / 30));
            if (di % labelEvery === 0) {{
                const labelDate = ds.dateKey.replace(/_/g, '-');
                ctx.fillStyle = '#6c757d';
                ctx.textAlign = 'left';
                ctx.save();
                ctx.translate(x + 2, chartH - marginBottom + 4);
                ctx.rotate(Math.PI / 4);
                ctx.fillText(labelDate, 0, 0);
                ctx.restore();
            }}
        }});

        // Y-axis labels (stage names)
        ctx.textAlign = 'right';
        ctx.textBaseline = 'middle';
        ctx.font = '12px -apple-system, BlinkMacSystemFont, sans-serif';
        for (let s = 0; s < numStages; s++) {{
            const label = stageLabels[stageOrder[s]] || stageOrder[s];
            ctx.fillStyle = stageColors[stageOrder[s]] || '#6c757d';
            ctx.fillText(label, marginLeft - 10, yPos(s));
        }}

        // Draw markers — store CSS-pixel positions for tooltip hit-testing
        const radius = Math.max(3, Math.min(5, colW * 0.4));
        const stored = [];  // {{cx, cy, pt}}
        points.forEach((p, i) => {{
            const cx = xPos(i);
            const cy = yPos(p.stageIdx);
            const color = stageColors[p.stage] || '#ffc107';
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2);
            ctx.fillStyle = color;
            ctx.fill();
            stored.push({{ cx, cy, pt: p }});
        }});

        // Tooltip: mouse coords → CSS pixels (accounting for scroll)
        const hitR = radius + 3;
        canvas.addEventListener('mousemove', function(evt) {{
            const rect = canvas.getBoundingClientRect();
            // Scale from viewport to CSS-pixel coordinate space
            const scaleX = chartW / rect.width;
            const scaleY = chartH / rect.height;
            const mx = (evt.clientX - rect.left) * scaleX;
            const my = (evt.clientY - rect.top) * scaleY;

            let found = null;
            for (const s of stored) {{
                const dx = mx - s.cx;
                const dy = my - s.cy;
                if (dx * dx + dy * dy <= hitR * hitR) {{
                    found = s;
                    break;
                }}
            }}

            if (found) {{
                const d = found.pt.date;
                const ds = d.getFullYear() + '-' +
                    String(d.getMonth()+1).padStart(2,'0') + '-' +
                    String(d.getDate()).padStart(2,'0') + ' ' +
                    String(d.getHours()).padStart(2,'0') + ':' +
                    String(d.getMinutes()).padStart(2,'0');
                const sl = stageLabels[found.pt.stage] || found.pt.stage;
                tooltip.innerHTML =
                    '<strong>' + ds + '</strong><br>' +
                    'Protocol: ' + found.pt.protocol + '<br>' +
                    'Strain: ' + found.pt.strain + '<br>' +
                    'Stage: ' + sl;
                tooltip.style.display = 'block';
                // Position relative to the scrollable container
                const cRect = container.getBoundingClientRect();
                tooltip.style.left = (evt.clientX - cRect.left + container.scrollLeft + 12) + 'px';
                tooltip.style.top  = (evt.clientY - cRect.top + 0) + 'px';
            }} else {{
                tooltip.style.display = 'none';
            }}
        }});
        canvas.addEventListener('mouseleave', function() {{
            tooltip.style.display = 'none';
        }});
    }}

    // Build charts on page load
    buildLegend('chart-legend-proto');
    buildLegend('chart-legend-strain');
    buildLegend('chart-legend-timeline');
    buildStackedChart('stacked-protocol', 'protocol');
    buildStackedChart('stacked-strain', 'strain');
    buildTimeline();
    </script>
</body>
</html>"""

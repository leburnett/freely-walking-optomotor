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


def generate_status_page(registry_path=None):
    """Generate a static HTML status page from the pipeline registry.

    Writes pipeline_status.html next to the registry JSON file.

    Args:
        registry_path: Path to the registry JSON. If None, auto-detected.
    """
    if registry_path is None:
        registry_path = _get_registry_path()

    data = _read_registry(registry_path)
    experiments = data.get("experiments", [])
    last_updated = data.get("last_updated", "Never")

    # Count experiments by stage
    stage_counts = {}
    error_count = 0
    for exp in experiments:
        stage = exp.get("current_stage", "unknown") or "unknown"
        stage_counts[stage] = stage_counts.get(stage, 0) + 1
        if exp.get("has_errors"):
            error_count += 1

    # Build HTML
    html = _build_html(experiments, last_updated, stage_counts, error_count)

    # Write next to the registry
    html_path = registry_path.replace(".json", ".html")
    try:
        with open(html_path, "w", encoding="utf-8") as f:
            f.write(html)
        logger.info(f"Status page generated: {html_path}")
    except OSError as e:
        logger.error(f"Error writing status page: {e}")


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


def _build_html(experiments, last_updated, stage_counts, error_count):
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
            f'<span class="badge" style="background-color:{color}">{label}: {count}</span>'
        )

    summary_html = " ".join(summary_items)

    # Table rows
    rows = []
    for exp in experiments_sorted:
        stage = exp.get("current_stage", "unknown") or "unknown"
        color = _stage_color(stage)
        has_errors = exp.get("has_errors", False)
        error_indicator = ' <span class="error-dot">&#9679;</span>' if has_errors else ""
        stage_label = stage.replace("_", " ").title()

        rows.append(f"""        <tr>
            <td>{exp.get('date', '')}</td>
            <td>{exp.get('protocol', '')}</td>
            <td>{exp.get('strain', '')}</td>
            <td>{exp.get('sex', '')}</td>
            <td><span class="badge" style="background-color:{color}">{stage_label}</span>{error_indicator}</td>
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
        table {{ width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }}
        thead {{ background: #212529; color: white; }}
        th {{ padding: 10px 14px; text-align: left; font-weight: 500; font-size: 0.85rem; cursor: pointer; user-select: none; }}
        th:hover {{ background: #343a40; }}
        td {{ padding: 8px 14px; border-bottom: 1px solid #e9ecef; font-size: 0.85rem; }}
        tr:hover td {{ background: #f1f3f5; }}
        .filter-row {{ margin-bottom: 15px; }}
        .filter-row input {{ padding: 6px 12px; border: 1px solid #ced4da; border-radius: 6px; font-size: 0.85rem; width: 300px; }}
    </style>
</head>
<body>
    <h1>Freely Walking Optomotor &mdash; Pipeline Status</h1>
    <p class="subtitle">Last updated: {last_updated}</p>

    <div class="summary">
        <span class="total">Total: {total}</span>
        {summary_html}
        {"<span class='badge error-count'>Errors: " + str(error_count) + "</span>" if error_count else ""}
    </div>

    <div class="filter-row">
        <input type="text" id="filter" placeholder="Filter by date, strain, protocol..." oninput="filterTable()">
    </div>

    <table id="status-table">
        <thead>
            <tr>
                <th onclick="sortTable(0)">Date</th>
                <th onclick="sortTable(1)">Protocol</th>
                <th onclick="sortTable(2)">Strain</th>
                <th onclick="sortTable(3)">Sex</th>
                <th onclick="sortTable(4)">Stage</th>
                <th onclick="sortTable(5)">Last Updated</th>
            </tr>
        </thead>
        <tbody>
{rows_html}
        </tbody>
    </table>

    <script>
    let sortDir = {{}};
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
    </script>
</body>
</html>"""

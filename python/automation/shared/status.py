"""
Per-experiment pipeline status tracking.

Each experiment's time folder contains a pipeline_status.json file that records
which stages of the pipeline have been completed, when, and by which machine.
"""

import json
import os
from datetime import datetime
from pathlib import Path

STATUS_FILENAME = "pipeline_status.json"

# Ordered pipeline stages
PIPELINE_STAGES = [
    "acquired",
    "copied_to_network",
    "tracked",
    "processed",
    "synced_to_network",
]


def _status_path(folder_path):
    """Return the path to pipeline_status.json inside the given folder."""
    return os.path.join(folder_path, STATUS_FILENAME)


def _get_machine_role():
    """Return the MACHINE_ROLE from environment."""
    return os.environ.get("MACHINE_ROLE", "unknown").lower()


def init_status(folder_path, date, protocol, strain, sex, time_str):
    """Create a new pipeline_status.json in the experiment folder.

    Args:
        folder_path: Path to the experiment time folder.
        date: Date string (YYYY_MM_DD).
        protocol: Protocol name (e.g., 'protocol_27').
        strain: Strain name (e.g., 'jfrc100_es').
        sex: Sex ('F' or 'M').
        time_str: Time string (HH_MM_SS).

    Returns:
        The status dict that was written.
    """
    experiment_id = f"{date}_{time_str}_{strain}_{protocol}_{sex}"
    status = {
        "experiment_id": experiment_id,
        "date": date,
        "protocol": protocol,
        "strain": strain,
        "sex": sex,
        "time": time_str,
        "stages": {},
        "current_stage": None,
        "errors": [],
    }
    _write_status(folder_path, status)
    return status


def update_stage(folder_path, stage_name, status="complete", **extra_fields):
    """Update a pipeline stage in the experiment's status file.

    Args:
        folder_path: Path to the experiment time folder.
        stage_name: One of PIPELINE_STAGES.
        status: 'complete', 'in_progress', or 'failed'.
        **extra_fields: Additional key-value pairs to store (e.g., trx_mat_found=True).
    """
    data = read_status(folder_path)
    if data is None:
        # If no status file exists yet, create a minimal one
        data = {
            "experiment_id": "unknown",
            "date": "",
            "protocol": "",
            "strain": "",
            "sex": "",
            "time": "",
            "stages": {},
            "current_stage": None,
            "errors": [],
        }

    stage_entry = {
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "machine": _get_machine_role(),
        "status": status,
    }
    stage_entry.update(extra_fields)
    data["stages"][stage_name] = stage_entry

    if status == "complete":
        data["current_stage"] = stage_name

    _write_status(folder_path, data)
    return data


def record_error(folder_path, stage, message, details=""):
    """Append an error entry to the experiment's status file.

    Args:
        folder_path: Path to the experiment time folder.
        stage: Which stage the error occurred in.
        message: Short error message.
        details: Full error details (e.g., stderr output).
    """
    data = read_status(folder_path)
    if data is None:
        data = {
            "experiment_id": "unknown",
            "stages": {},
            "current_stage": None,
            "errors": [],
        }

    data["errors"].append({
        "stage": stage,
        "timestamp": datetime.now().isoformat(timespec="seconds"),
        "message": message,
        "details": details,
    })

    # Also mark the stage as failed
    if stage in data.get("stages", {}):
        data["stages"][stage]["status"] = "failed"
    else:
        data.setdefault("stages", {})[stage] = {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "machine": _get_machine_role(),
            "status": "failed",
        }

    _write_status(folder_path, data)
    return data


def read_status(folder_path):
    """Read and return the pipeline status dict, or None if no file exists."""
    path = _status_path(folder_path)
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return None


def get_current_stage(folder_path):
    """Return the current_stage string, or None."""
    data = read_status(folder_path)
    if data is None:
        return None
    return data.get("current_stage")


def _write_status(folder_path, data):
    """Write the status dict to pipeline_status.json."""
    path = _status_path(folder_path)
    os.makedirs(folder_path, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)

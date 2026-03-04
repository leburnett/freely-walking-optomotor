# CLAUDE.md - Automation Pipeline Context

This file provides complete context for Claude Code sessions working on the automation pipeline. It captures the rationale, architecture, and current state of a major refactoring effort completed in early 2026.

---

## Why This Refactoring Was Done

The automation pipeline moves Drosophila freely-walking optomotor experiment data through five stages: acquisition, network copy, FlyTracker tracking, MATLAB processing, and network sync. Before this refactoring, the pipeline had several problems:

- **Duplicated code**: `reprocessing_script.py` was ~95% identical to `daily_processing.py`
- **Scattered logging**: Each script wrote its own `.log` to CWD; batch files wrote dated `.txt` logs elsewhere
- **No per-experiment status**: Pipeline stage was inferred solely from folder location. If something failed mid-pipeline, there was no record
- **Hardcoded paths in batch files**: Python exe paths, log directories, and script paths were user-specific
- **No overview**: No way to see all experiments and their current pipeline status at a glance
- **Two machines, one codebase**: The acquisition and processing machines both need the same code but with different path configurations

The refactoring introduced: a shared utilities module, per-experiment status tracking, a global registry with HTML dashboard, centralized rotating logs, machine-aware configuration, and a backfill script for existing data.

---

## Architecture Overview

### Pipeline Flow

```
ACQUISITION MACHINE                    PROCESSING MACHINE
=======================                =======================

MATLAB writes experiment data
  (stamp_log, .mat, .ufmf)
         |
         v
  monitor_and_copy.py ──────────> monitor_and_track.py
  [acquired]                      [tracked]
  [copied_to_network]                   |
         |                              v
         |                       daily_processing.py
         |                       [processed]
         |                       [synced_to_network]
         v                              |
    NETWORK DRIVE  <────────────────────┘
    (\\prfs.hhmi.org\reiserlab\oaky-cokey)
```

### Pipeline Stages (ordered)

| Stage | Description | Set by |
|-------|-------------|--------|
| `acquired` | Raw experiment data exists | monitor_and_copy.py |
| `copied_to_network` | Copied to network unprocessed folder | monitor_and_copy.py |
| `tracked` | FlyTracker completed, trx.mat generated | monitor_and_track.py |
| `processed` | MATLAB processing complete, results generated | daily_processing.py |
| `synced_to_network` | Results, figures, videos copied to network | daily_processing.py |

### Directory Structure

```
python/automation/
├── CLAUDE.md                          # This file
├── backfill_registry.py               # One-time backfill for existing experiments
├── generate_batch_files.py            # Generates .bat launchers from config
├── shared/                            # Shared utilities module
│   ├── __init__.py
│   ├── status.py                      # Per-experiment pipeline_status.json CRUD
│   ├── registry.py                    # Global registry + HTML status page
│   ├── logging_config.py             # Centralized rotating log setup
│   ├── file_ops.py                    # File/folder operations
│   └── matlab.py                      # MATLAB subprocess runner
├── monitor_and_copy/                  # Stage 1: acquisition -> network
│   ├── monitor_and_copy.py
│   └── run_monitor_and_copy.bat
├── monitor_and_track/                 # Stage 2: network -> tracked
│   ├── monitor_and_track.py
│   └── run_monitor_and_track.bat
└── daily_processing/                  # Stage 3: tracked -> processed -> synced
    ├── daily_processing.py
    ├── copy_movies_to_network.py      # Standalone video backfill utility
    └── run_daily_processing.bat
```

---

## Configuration

### Machine Detection (`config/config.py`)

Both machines share the same codebase. They are distinguished by the `MACHINE_ROLE` environment variable, set once per machine:

```cmd
setx MACHINE_ROLE acquisition    # On acquisition machine (admin terminal, once)
setx MACHINE_ROLE processing     # On processing machine (admin terminal, once)
```

The config file (`config/config.py`) reads this variable and sets machine-specific paths:

```python
MACHINE_ROLE = os.environ.get("MACHINE_ROLE", "").lower()

if MACHINE_ROLE == "acquisition":
    PROJECT_ROOT = Path(r"C:\Users\labadmin\Documents\freely-walking-optomotor")
    SOURCE_ROOT = Path(r"C:\MatlabRoot\FreeWalkOptomotor\data")  # Where MATLAB writes raw data
elif MACHINE_ROLE == "processing":
    PROJECT_ROOT = Path(r"C:\Users\labadmin\Documents\freely-walking-optomotor")
    SOURCE_ROOT = None  # Not used on processing machine
```

### Key Path Variables (from config.py)

| Variable | Purpose |
|----------|---------|
| `PROJECT_ROOT` | Root for local data/results |
| `SOURCE_ROOT` | Where MATLAB writes raw experiment data (acquisition only) |
| `REPO_ROOT` | Auto-detected git repo root |
| `DATA_UNPROCESSED` | `PROJECT_ROOT/DATA/00_unprocessed` |
| `DATA_TRACKED` | `PROJECT_ROOT/DATA/01_tracked` |
| `DATA_PROCESSED` | `PROJECT_ROOT/DATA/02_processed` |
| `RESULTS_PATH` | `PROJECT_ROOT/results` |
| `FIGURES_PATH` | `PROJECT_ROOT/figures` |
| `LOG_DIR` | `PROJECT_ROOT/logs` |
| `PYTHON_EXE` | Full path to Python interpreter |
| `NETWORK_ROOT` | `\\prfs.hhmi.org\reiserlab\oaky-cokey` |
| `NETWORK_UNPROCESSED` | `NETWORK_ROOT\data\0_unprocessed` |
| `NETWORK_TRACKED` | `NETWORK_ROOT\data\1_tracked` |
| `NETWORK_PROCESSED` | `NETWORK_ROOT\data\2_processed` |
| `NETWORK_RESULTS` | `NETWORK_ROOT\exp_results` |
| `NETWORK_FIGS` | `NETWORK_ROOT\exp_figures\overview_figs` |
| `PIPELINE_REGISTRY` | `NETWORK_ROOT\pipeline_status.json` |

---

## Shared Modules (`shared/`)

### `status.py` — Per-Experiment Status Tracking

Each experiment's time folder contains a `pipeline_status.json` file tracking its journey through the pipeline.

**Key functions:**
- `init_status(folder_path, date, protocol, strain, sex, time_str)` -- creates initial status JSON
- `update_stage(folder_path, stage_name, status="complete", **extra_fields)` -- records stage completion with timestamp and machine role
- `record_error(folder_path, stage, message, details="")` -- appends error with stage context, marks stage as failed
- `read_status(folder_path)` -- returns parsed JSON dict or None
- `get_current_stage(folder_path)` -- returns highest completed stage string

**Status file structure:**
```json
{
  "experiment_id": "2025_02_26_14_30_00_jfrc100_es_protocol_27_F",
  "date": "2025_02_26",
  "protocol": "protocol_27",
  "strain": "jfrc100_es",
  "sex": "F",
  "time": "14_30_00",
  "stages": {
    "acquired": {"timestamp": "...", "machine": "acquisition", "status": "complete"},
    "tracked": {"timestamp": "...", "machine": "processing", "status": "complete", "trx_mat_found": true}
  },
  "current_stage": "tracked",
  "errors": []
}
```

The `machine` field uses the `MACHINE_ROLE` value ("acquisition" or "processing"), not the hostname.

### `registry.py` — Global Registry + HTML Dashboard

Aggregates all experiment statuses into one JSON file on the network drive, and generates a static HTML status page.

**Key functions:**
- `update_registry(experiment_status)` -- upserts experiment entry, auto-regenerates HTML
- `get_all_experiments(registry_path=None)` -- returns list of all experiment summaries
- `generate_status_page(registry_path=None)` -- generates `pipeline_status.html` with sortable/filterable table

**Stage color coding (used in both HTML and Dash dashboard):**
- acquired: gray
- copied_to_network: blue
- tracked: cyan
- processed: green
- synced_to_network: teal
- errors: red

**HTML status page features:**
- Pipeline stage description table (collapsible, default open)
- CSS flowchart diagram showing pipeline flow and machine assignments
- Sortable/filterable experiment table with color-coded stage badges
- "Local" and "Network" checkmark columns showing whether result files exist in each location
- Summary badges with total counts per stage and cross-reference counts
- `update_registry()` preserves `has_local_results`/`has_network_results` fields when live pipeline scripts upsert entries

### `logging_config.py` — Centralized Logging

Replaces per-script `logging.basicConfig()` with rotating file handlers.

**Key function:**
- `setup_logging(script_name, log_dir=None, level=logging.INFO)` -- returns logger writing to `{LOG_DIR}/{script_name}.log` (5MB max, 3 backups) + console

### `file_ops.py` — File Operations

Consolidates duplicated file/folder utilities from all pipeline scripts.

**Key functions:**
- `is_folder_complete(folder_path)` -- checks for stamp_log*, .mat, .ufmf files
- `list_date_folders(path)` -- lists YYYY_MM_DD folders, sorted
- `move_folder(src, dst, overwrite=False)` -- moves folder with optional overwrite
- `copy_files_by_extension(src_root, dst_root, extensions, filename_filter=None)` -- recursive copy preserving directory structure
- `cleanup_empty_parents(path, stop_at)` -- removes empty parent directories
- `parse_experiment_path(folder_path, base_path)` -- extracts `{date, protocol, strain, sex, time}` from hierarchical path

### `matlab.py` — MATLAB Subprocess Runner

**Key function:**
- `run_matlab(function_name, *args, setup_path=None)` -- runs MATLAB function in batch mode, returns `(success: bool, stdout: str, stderr: str)`

---

## Pipeline Scripts

### `monitor_and_copy.py` (Acquisition Machine)

Watches `SOURCE_ROOT` for new experiment folders, copies completed ones to the network.

- Uses watchdog file system observer
- Checks folder completeness (stamp_log + .mat + .ufmf)
- Copies to `NETWORK_UNPROCESSED` preserving relative path
- Creates `pipeline_status.json` with `acquired` and `copied_to_network` stages
- Updates global registry
- Runs continuously (no CLI timeout flag)

### `monitor_and_track.py` (Processing Machine)

Scans network unprocessed folder for new experiments, runs FlyTracker.

**CLI arguments:**
```
--timeout <minutes>    Exit after N minutes idle (default: 75, 0 = forever)
```

**Flow per experiment:**
1. Copy from `NETWORK_UNPROCESSED` to local `DATA_UNPROCESSED`
2. Run MATLAB `batch_track_ufmf(folder_path)` via `run_matlab()`
3. Verify `trx.mat` exists
4. Archive to local `DATA_TRACKED`
5. Move to `NETWORK_TRACKED`, delete from `NETWORK_UNPROCESSED`
6. Clean up empty parent directories
7. Update status: `tracked` stage complete
8. Update global registry

**Scan interval:** 300 seconds (5 minutes)

### `daily_processing.py` (Processing Machine)

Processes tracked data, syncs results to network.

**CLI arguments:**
```
--reprocess              Reprocess all dates, ignoring existing results
<date1> <date2> ...      Process specific date folders only (positional)
```

**Flow per date:**
1. Scan `DATA_TRACKED` for YYYY_MM_DD date folders
2. Run MATLAB `process_freely_walking_data(date_str)` via `run_matlab()`
3. Copy result .mat files to `NETWORK_RESULTS` (filtered by date prefix)
4. Copy .pdf/.png figures to `NETWORK_FIGS` (filtered by date prefix)
5. Move date folder: `DATA_TRACKED` -> `DATA_PROCESSED`
6. Move date folder: `NETWORK_TRACKED` -> `NETWORK_PROCESSED`
7. Copy .mp4 videos to `NETWORK_PROCESSED`
8. Update status: `processed` and `synced_to_network` stages complete
9. Update global registry

**Note:** `reprocessing_script.py` was deleted -- its functionality is now the `--reprocess` flag on this script.

### `copy_movies_to_network.py` (Standalone Utility)

Backfill tool that copies .mp4 videos from `DATA_PROCESSED` to `NETWORK_PROCESSED` for experiments where videos were missed. Not part of normal pipeline flow.

---

## Batch Files

All `.bat` files are auto-generated by `generate_batch_files.py`. They are simple launchers:

```bat
@echo off
REM Auto-generated by generate_batch_files.py - do not edit manually.
"C:\...\python.exe" "C:\...\script.py" %*
```

The `%*` passes any CLI arguments through (e.g., `run_daily_processing.bat --reprocess`).

**To regenerate after changing paths in config.py:**
```cmd
python generate_batch_files.py
```

---

## Pipeline Status Tracking

### Per-Experiment: `pipeline_status.json`

Written into each experiment's time folder (the leaf folder like `date/protocol/strain/sex/time/`). Tracks which stages are complete, when they were completed, which machine completed them, and any errors.

### Global Registry: `pipeline_status.json` (on network drive)

Aggregates all experiment statuses. Located at `PIPELINE_REGISTRY` path (default: `\\prfs.hhmi.org\reiserlab\oaky-cokey\pipeline_status.json`). Both machines read/write this file. Uses atomic writes (temp file + rename) to prevent corruption.

### Static HTML: `pipeline_status.html`

Generated alongside the global registry. Provides a sortable, filterable table with color-coded stage badges. Can be opened by anyone on the network by double-clicking the file.

### Dash Dashboard: Pipeline Status Tab (Tab 6)

The existing Dash dashboard (`python/freely-walking-python/dashboard/`) has a 6th tab showing pipeline status. It reads the same `pipeline_status.json` registry and provides:
- Interactive DataTable with native filtering/sorting (25 rows per page)
- Color-coded rows by stage (green=processed/synced, cyan=tracked, blue=copied, red=errors)
- Summary badges showing experiment counts per stage
- Auto-refresh every 60 seconds + manual refresh button

**Files modified for dashboard integration:**
- `python/freely-walking-python/dashboard/app.py` -- Tab 6 layout
- `python/freely-walking-python/dashboard/callbacks.py` -- `update_pipeline_table()` callback

---

## Backfill Script (`backfill_registry.py`)

One-time utility to retroactively generate `pipeline_status.json` files for hundreds of pre-existing experiments that were processed before the status tracking system was introduced.

### CLI Usage

```cmd
python backfill_registry.py --scan-paths "C:\MatlabRoot\FreeWalkOptomotor\data" --dry-run
python backfill_registry.py --scan-paths "D:\FreeWalkOptomotor\data" --dry-run
python backfill_registry.py --all
python backfill_registry.py --all --output-registry pipeline_status.json
```

**Arguments:**
- `--scan-paths <path> [<path>...]` -- directories to scan (mutually exclusive with --all)
- `--all` -- scan all known data locations (hardcoded list in script)
- `--results-path <path>` -- network exp_results path for cross-referencing (default: network)
- `--local-results-path <path>` -- local results path for cross-referencing (default: from config RESULTS_PATH)
- `--output-registry <path>` -- where to write global registry (default: from config)
- `--workers <n>` -- parallel workers (default: 4)
- `--skip-existing` -- skip folders that already have pipeline_status.json
- `--dry-run` -- report without writing

### Stage Inference Logic

For each experiment folder, checks (highest first):
1. Matching `*_data.mat` in network `exp_results/` -> `synced_to_network`
2. Matching `*_data.mat` in local `results/` -> `processed`
3. Folder path contains "processed" -> `processed`
4. `trx.mat` exists inside recording subfolder -> `tracked`
5. Folder is on network drive -> `copied_to_network`
6. Folder has basic experiment files -> `acquired`

### Cross-Reference Fields

The backfill also computes two boolean fields per experiment:
- `has_local_results` -- whether a matching `*_data.mat` exists in the local results folder (`RESULTS_PATH`)
- `has_network_results` -- whether a matching `*_data.mat` exists in the network results folder (`NETWORK_RESULTS`)

These are stored in the global registry and displayed as checkmark columns in the HTML status page.

### Metadata Extraction

Three strategies (tried in order):
1. **Hierarchical path**: `date/protocol/strain/sex/time/` parsed by `parse_experiment_path()`
2. **LOG*.mat file**: Post-Oct 2024 files have `LOG.meta` struct with `func_name` (protocol), `fly_strain`, `fly_sex` -- requires scipy
3. **Path fallback**: Extract whatever date/time info is available from path components

### Known Data Locations (used by --all)

| Location | Structure |
|----------|-----------|
| `D:\FreeWalkOptomotor\data` | Mixed: flat pre-Oct 2024, hierarchical post-Oct 2024 |
| `C:\MatlabRoot\FreeWalkOptomotor\data` | Hierarchical |
| `\\prfs.hhmi.org\...\0_unprocessed` | Hierarchical |
| `\\prfs.hhmi.org\...\1_tracked` | Hierarchical |
| `\\prfs.hhmi.org\...\2_processed` | Hierarchical |

### Re-running After Deleting Experiments

**Important:** The backfill script merges with the existing global registry to preserve entries written by the other machine. This means if you delete experiment folders and re-run the backfill, the deleted experiments' entries will persist in the registry (carried over from the previous run's merge).

To cleanly regenerate the registry after deleting experiment folders:

1. Delete the existing global `pipeline_status.json` and `pipeline_status.html`
2. Re-run the backfill: `python backfill_registry.py --all --output-dir <path>`

The per-experiment `pipeline_status.json` files inside the deleted folders are automatically removed when the folders are deleted — no extra cleanup needed for those.

### Current State

The backfill script has been run on this machine (acquisition). Per-experiment `pipeline_status.json` files and a global `pipeline_status.json` + `pipeline_status.html` have been generated. The HTML status page is viewable.

---

## Machine Setup Checklist

### Both Machines

1. Set environment variable (admin terminal, once):
   ```cmd
   setx MACHINE_ROLE acquisition   # or: setx MACHINE_ROLE processing
   ```
2. Close and reopen terminal for the variable to take effect
3. Verify: `echo %MACHINE_ROLE%` should print the role
4. Ensure Python 3.13+ is installed at the path specified in `config.py`
5. Ensure MATLAB is installed and on PATH
6. Ensure network drive is accessible: `dir \\prfs.hhmi.org\reiserlab\oaky-cokey`
7. Run `python generate_batch_files.py` to create/update .bat launchers

### Acquisition Machine

- `monitor_and_copy.py` runs continuously (e.g., via Task Scheduler)
- `SOURCE_ROOT` must point to where MATLAB writes experiment data

### Processing Machine

- `monitor_and_track.py` runs continuously or with timeout
- `daily_processing.py` runs daily (e.g., via Task Scheduler)
- Local data directories (`DATA_UNPROCESSED`, `DATA_TRACKED`, `DATA_PROCESSED`) must exist

---

## Common Tasks

### Check pipeline status
- Open `pipeline_status.html` (next to the global `pipeline_status.json`)
- Or run the Dash dashboard: `cd python/freely-walking-python && pixi run dashboard`

### Reprocess specific dates
```cmd
run_daily_processing.bat --reprocess 2025_02_26 2025_02_27
```

### Reprocess all dates
```cmd
run_daily_processing.bat --reprocess
```

### Run tracking indefinitely
```cmd
run_monitor_and_track.bat --timeout 0
```

### Regenerate batch files after config change
```cmd
python generate_batch_files.py
```

### Backfill status for existing data
```cmd
python backfill_registry.py --scan-paths "C:\path\to\data" --dry-run    # Preview first
python backfill_registry.py --scan-paths "C:\path\to\data"              # Then write
```

### View an experiment's status
Look for `pipeline_status.json` inside the experiment's time folder (the leaf folder containing .mat, .ufmf, stamp_log files).

---

## Experiment Folder Structure

Experiments use a hierarchical folder structure:

```
{root}/
  {YYYY_MM_DD}/                    # Date
    {protocol_XX}/                 # Protocol name
      {strain_name}/               # Fly strain/genotype
        {sex}/                     # F, M, or NaN
          {HH_MM_SS}/              # Time (experiment folder)
            LOG_YYYY_MM_DD_HH_MM_SS.mat
            REC__cam_0_date_..._v001.ufmf
            stamp_log_cam0.txt
            pipeline_status.json   # <-- Added by this pipeline
```

**Exception:** Old data on `D:\FreeWalkOptomotor\data` (pre-Oct 2024) uses a flat `date/time/` structure without protocol/strain/sex subfolders.

---

## Files Created or Modified in This Refactoring

### Created
| File | Purpose |
|------|---------|
| `python/automation/shared/__init__.py` | Package init |
| `python/automation/shared/status.py` | Per-experiment status CRUD |
| `python/automation/shared/registry.py` | Global registry + HTML generator |
| `python/automation/shared/logging_config.py` | Centralized rotating logs |
| `python/automation/shared/file_ops.py` | Shared file operations |
| `python/automation/shared/matlab.py` | MATLAB subprocess wrapper |
| `python/automation/generate_batch_files.py` | Batch file generator |
| `python/automation/backfill_registry.py` | Backfill status for existing data |
| `python/automation/CLAUDE.md` | This file |

### Modified
| File | Changes |
|------|---------|
| `config/config.py` | Added MACHINE_ROLE detection, LOG_DIR, PIPELINE_REGISTRY, PYTHON_EXE |
| `python/automation/monitor_and_copy/monitor_and_copy.py` | Refactored to use shared utilities, writes status metadata |
| `python/automation/monitor_and_track/monitor_and_track.py` | Refactored, added --timeout flag, writes status metadata |
| `python/automation/daily_processing/daily_processing.py` | Refactored, added --reprocess flag, writes status metadata |
| `python/automation/daily_processing/copy_movies_to_network.py` | Refactored to use shared logging |
| `python/automation/monitor_and_copy/run_monitor_and_copy.bat` | Regenerated (simplified launcher) |
| `python/automation/monitor_and_track/run_monitor_and_track.bat` | Regenerated (simplified launcher) |
| `python/automation/daily_processing/run_daily_processing.bat` | Regenerated (simplified launcher) |
| `python/freely-walking-python/dashboard/app.py` | Added Tab 6: Pipeline Status |
| `python/freely-walking-python/dashboard/callbacks.py` | Added pipeline status callback |

### Deleted
| File | Reason |
|------|--------|
| `python/automation/daily_processing/reprocessing_script.py` | Replaced by `--reprocess` flag on daily_processing.py |

---

## Known Issues

1. **scipy not in system Python**: The backfill script's LOG.meta parsing requires scipy, which is only in the pixi environment. Without scipy, it falls back to path-based metadata extraction (works fine for hierarchical folders, returns "unknown" for truly flat pre-Oct 2024 folders).

2. **Network drive accessibility**: The network UNC path (`\\prfs.hhmi.org\...`) must be accessible. If not mounted/connected, scripts that write to the network will warn and skip those operations.

3. **Logging before argparse help**: `setup_logging()` runs at script startup and prints a "Script Started" log line before `--help` output. This is cosmetic only.

4. **Pre-October 2024 data**: Experiments from June-September 2024 on `D:\FreeWalkOptomotor\data` have flat `date/time/` structure with no metadata in LOG files. These will always show protocol/strain/sex as "unknown" in the status system.

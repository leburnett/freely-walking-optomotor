#!/usr/bin/env bash
# Launch the Freely-Walking Optomotor Dashboard
# Usage: dash-freely              (start the dashboard)
#        dash-freely preprocess   (preprocess .mat files first)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIXI_DIR="$SCRIPT_DIR/python/freely-walking-python"

if [ "$1" = "preprocess" ]; then
    shift
    echo "Preprocessing .mat files → Parquet…"
    pixi run -e default --manifest-path "$PIXI_DIR/pixi.toml" python -m dashboard.preprocess "$@"
else
    # Kill any existing process on port 8050
    existing_pid=$(lsof -ti :8050 2>/dev/null || true)
    if [ -n "$existing_pid" ]; then
        echo "Killing existing process on port 8050 (PID: $existing_pid)…"
        kill $existing_pid 2>/dev/null
        sleep 0.5
    fi
    echo "Starting dashboard on http://localhost:8050 …"
    pixi run -e default --manifest-path "$PIXI_DIR/pixi.toml" dashboard
fi

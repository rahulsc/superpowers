#!/usr/bin/env bash
# Stop the forge-viz server
# Usage: stop-server.sh [--project-dir <path>] | stop-server.sh <forge_local_dir>
#
# Kills the server process identified by the PID file in .forge/local/.

FORGE_DIR=""

if [[ $# -eq 0 ]]; then
  FORGE_DIR="$(pwd)/.forge/local"
elif [[ "$1" == "--project-dir" ]]; then
  FORGE_DIR="${2}/.forge/local"
else
  # Legacy: accept the forge local dir directly
  FORGE_DIR="$1"
fi

if [[ -z "$FORGE_DIR" ]]; then
  echo '{"error": "Usage: stop-server.sh [--project-dir <path>] | stop-server.sh <forge_local_dir>"}'
  exit 1
fi

PID_FILE="${FORGE_DIR}/.forge-viz-server.pid"

if [[ -f "$PID_FILE" ]]; then
  pid=$(cat "$PID_FILE")
  kill "$pid" 2>/dev/null
  rm -f "$PID_FILE" "${FORGE_DIR}/.forge-viz-server.log" "${FORGE_DIR}/.forge-viz-info"
  echo '{"status": "stopped"}'
else
  echo '{"status": "not_running"}'
fi

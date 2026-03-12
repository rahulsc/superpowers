#!/usr/bin/env bash
# Start the forge-viz server and output connection info
# Usage: start-server.sh [--project-dir <path>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
#
# Starts the Forge workflow visualization server on a random high port.
# Outputs JSON with URL on success.
#
# Options:
#   --project-dir <path>  Project root; server watches <path>/.forge/local/ (default: cwd)
#   --host <bind-host>    Host/interface to bind (default: 127.0.0.1)
#                         Use 0.0.0.0 in remote/containerized environments.
#   --url-host <host>     Hostname shown in returned URL JSON.
#   --foreground          Run server in the current terminal (no backgrounding).
#   --background          Force background mode (overrides auto-foreground detection).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
PROJECT_DIR=""
FOREGROUND="false"
FORCE_BACKGROUND="false"
BIND_HOST="127.0.0.1"
URL_HOST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --host)
      BIND_HOST="$2"
      shift 2
      ;;
    --url-host)
      URL_HOST="$2"
      shift 2
      ;;
    --foreground|--no-daemon)
      FOREGROUND="true"
      shift
      ;;
    --background|--daemon)
      FORCE_BACKGROUND="true"
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown argument: $1\"}"
      exit 1
      ;;
  esac
done

if [[ -z "$URL_HOST" ]]; then
  if [[ "$BIND_HOST" == "127.0.0.1" || "$BIND_HOST" == "localhost" ]]; then
    URL_HOST="localhost"
  else
    URL_HOST="$BIND_HOST"
  fi
fi

# Auto-foreground in environments that reap detached processes
if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
  FOREGROUND="true"
fi

# Resolve the forge_dir from project dir
if [[ -n "$PROJECT_DIR" ]]; then
  FORGE_DIR="${PROJECT_DIR}/.forge/local"
else
  FORGE_DIR="$(pwd)/.forge/local"
fi

# Server info and pid files live inside forge_dir
PID_FILE="${FORGE_DIR}/.forge-viz-server.pid"
LOG_FILE="${FORGE_DIR}/.forge-viz-server.log"

# Create forge local dir if needed
mkdir -p "$FORGE_DIR"

# Kill any existing forge-viz server
if [[ -f "$PID_FILE" ]]; then
  old_pid=$(cat "$PID_FILE")
  kill "$old_pid" 2>/dev/null
  rm -f "$PID_FILE"
fi

# Resolve the harness PID (grandparent of this script)
OWNER_PID="$(ps -o ppid= -p "$PPID" 2>/dev/null | tr -d ' ')"
if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
  OWNER_PID="$PPID"
fi

# Foreground mode
if [[ "$FOREGROUND" == "true" ]]; then
  echo "$$" > "$PID_FILE"
  exec env \
    FORGE_VIZ_DIR="$FORGE_DIR" \
    FORGE_VIZ_HOST="$BIND_HOST" \
    FORGE_VIZ_URL_HOST="$URL_HOST" \
    FORGE_VIZ_OWNER_PID="$OWNER_PID" \
    node "$SCRIPT_DIR/server.js"
fi

# Background mode
nohup env \
  FORGE_VIZ_DIR="$FORGE_DIR" \
  FORGE_VIZ_HOST="$BIND_HOST" \
  FORGE_VIZ_URL_HOST="$URL_HOST" \
  FORGE_VIZ_OWNER_PID="$OWNER_PID" \
  node "$SCRIPT_DIR/server.js" > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
disown "$SERVER_PID" 2>/dev/null
echo "$SERVER_PID" > "$PID_FILE"

# Wait for server-started message (check log file)
for i in {1..50}; do
  if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
    # Verify server stayed alive
    alive="true"
    for _ in {1..20}; do
      if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        alive="false"
        break
      fi
      sleep 0.1
    done
    if [[ "$alive" != "true" ]]; then
      echo "{\"error\": \"Server started but was killed. Retry with --foreground flag.\"}"
      exit 1
    fi
    grep "server-started" "$LOG_FILE" | head -1
    exit 0
  fi
  sleep 0.1
done

echo '{"error": "Server failed to start within 5 seconds"}'
exit 1

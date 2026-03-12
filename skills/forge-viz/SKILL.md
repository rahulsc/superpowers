---
name: forge-viz
description: Use when wanting to visualize current Forge workflow progress, evidence collection status, or pipeline state in a browser dashboard
---

# Forge Workflow Visualization

## Overview

Browser-based dashboard showing pipeline progress and evidence status. Zero-dependency Node.js server reads `.forge/local/` state and pushes updates via WebSocket. Read-only — never writes to project state.

## Starting the Server

```bash
bash skills/forge-viz/scripts/start-server.sh [--project-dir <path>] [--host <bind-host>]
```

Output (JSON):
```json
{"type":"server-started","port":52341,"url":"http://localhost:52341","forge_dir":"/path/to/.forge/local"}
```

Open the URL in your browser to see the dashboard.

Stop when done:
```bash
bash skills/forge-viz/scripts/stop-server.sh <forge_dir>
```

### Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--project-dir <path>` | cwd | Project root (server watches `<path>/.forge/local/`) |
| `--host <host>` | `127.0.0.1` | Bind host (use `0.0.0.0` for remote/container environments) |
| `--foreground` | — | Run in current terminal (no background daemon) |

## Views

### Pipeline View

Horizontal pipeline showing Forge workflow phases:

```
[design] → [setup] → [planning] → [executing] → [verification] → [review] → [completion]
   ✓          ✓          ✓            ●                ○               ○           ○
```

- Done (✓, green) — phase completed
- Active (●, blue highlight) — current phase
- Pending (○, dimmed gray) — not yet started

### Evidence View

Table showing evidence collection status per task, cross-referenced with risk tier requirements:

| Task | Risk Tier | test-output | review-notes | verification-log | Status |
|------|-----------|-------------|--------------|-----------------|--------|
| T-1  | elevated  | ✓           | ✓            | missing          | incomplete |
| T-2  | standard  | ✓           | —            | ✓               | complete |

Missing evidence is highlighted in red. Complete tasks show green.

## Activation

- Opt-in by default — start manually when needed
- Auto-offered at elevated and critical risk tiers
- Persistent across phases once opened (server auto-exits after 30 min idle)

## Integration

The server watches `.forge/local/` for any file changes (state.json, evidence/, etc.) and pushes live updates to all connected browsers via WebSocket. No polling required.

The dashboard reconnects automatically if the server restarts (exponential backoff, max 30 seconds).

## WebSocket Message Format

```json
{
  "type": "state-update",
  "phase": "executing",
  "risk_tier": "elevated",
  "evidence": {
    "collected": ["test-output", "review-notes"],
    "missing": ["verification-log"]
  },
  "tasks": { "total": 8, "complete": 3, "active": 2 }
}
```

## Architecture

```
.forge/local/ state changes
       | (fs.watch)
  forge-viz server (zero-dep Node.js)
       | (WebSocket push)
  Browser dashboard
```

Server auto-exits after 30 minutes of no browser connections. It also exits if the owner process (Claude Code) terminates.

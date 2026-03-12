# Task 19: Forge Workflow Visualization Server

**Specialist:** implementer-3
**Depends on:** Task 2 (reads state via `forge-state` to populate views), Task 4 (hooks trigger state changes that the viz reflects in real time)
**Produces:** Browser-based workflow visualization showing pipeline state and evidence; consumed by users during elevated+ workflows for situational awareness

## Goal

Evolve the brainstorming visual companion into a full Forge pipeline and evidence visualization server.

## Acceptance Criteria

- [ ] Zero-dependency Node.js server (same constraint as brainstorming server -- no npm install)
- [ ] File watcher on `.forge/local/` -- detects state changes via `fs.watch` and pushes updates to connected browser clients via WebSocket
- [ ] Pipeline view: shows current workflow phase (design / setup / planning / execution / verification / review / completion), which phases are done (checkmark), which is active (highlight), what is next (dimmed)
- [ ] Evidence view: shows collected evidence per task (test output, review notes, verification logs), shows what is missing per risk tier (table cross-referencing risk tier requirements from design Section 3 against evidence on file)
- [ ] Auto-lifecycle: server starts on request, auto-exits after 30 minutes of idle (no WebSocket connections and no state file changes)
- [ ] Read-only: server reads `.forge/local/` state but never writes to it
- [ ] Server binds to `localhost` by default with `--host` flag for remote access (same pattern as brainstorming server)
- [ ] Startup returns JSON with port and URL (same format as brainstorming server)
- [ ] Skill file created to launch and manage the viz server
- [ ] Server serves an HTML dashboard with CSS inline (no external dependencies)
- [ ] WebSocket reconnection: browser client auto-reconnects on connection drop (exponential backoff)
- [ ] Graceful shutdown on SIGTERM/SIGINT

## Test Expectations

- **Test:** Server starts, WebSocket connects, state change in `.forge/local/` appears in browser within 2 seconds
- **Expected red failure:** Server process does not start (script not found or syntax error), or WebSocket connection refused, or state change not reflected (file watcher not triggering push)
- **Expected green:** Server starts on specified port, WebSocket connection established, writing `forge-state set phase executing` causes pipeline view to update "execution" phase to active state in browser within 2 seconds

## Files

- Create: `skills/forge-viz/SKILL.md` (skill to launch, manage, and describe the viz)
- Create: `skills/forge-viz/scripts/server.js` (the viz server -- file watcher, WebSocket, HTTP, state reader)
- Create: `skills/forge-viz/scripts/start-server.sh` (startup script, same pattern as `skills/brainstorming/scripts/start-server.sh`)
- Create: `skills/forge-viz/scripts/stop-server.sh` (shutdown script)
- Create: `skills/forge-viz/scripts/dashboard-template.html` (the HTML dashboard served to browsers)
- Test: `tests/forge-viz/server-lifecycle.test.sh` (start, verify port open, stop, verify port closed)
- Test: `tests/forge-viz/state-push.test.sh` (start server, connect WebSocket, change state file, verify push received)

## Implementation Notes

**Architecture (from design Section 5):**
```
.forge/local/ state changes
       | (fs.watch)
  forge-viz server (zero-dep Node.js)
       | (WebSocket push)
  Browser dashboard
```

**Evolving from brainstorming server:**
The existing brainstorming visual companion (`skills/brainstorming/scripts/server.js`) provides the proven pattern:
- Zero-dep Node.js HTTP server with `http.createServer`
- File watching with `fs.watch`
- WebSocket via raw `http.upgrade` handler (no ws library)
- Auto-lifecycle with idle timeout
- Shell wrapper scripts for start/stop
- JSON startup response with port/URL

The forge-viz server should reuse this architecture but change the content model:
- **Brainstorming server:** watches a directory for new HTML files, serves the newest one
- **Forge-viz server:** watches `.forge/local/` for state changes, reads state via `forge-state` CLI (or directly from state.json/forge.sqlite), pushes structured JSON to browser, browser renders dashboard

**State reading approach:**
The server should read state by either:
1. Parsing `.forge/local/state.json` directly (JSON backend) -- simpler, no subprocess
2. Calling `forge-state get <key>` via `child_process.execSync` (works with both backends)

For v0, option 1 (direct JSON read) is acceptable since the server needs to be fast and the JSON backend is the universal fallback. If SQLite backend is active, the server can detect `.forge/local/forge.sqlite` and shell out to `sqlite3` for reads.

**Dashboard template structure:**
```html
<!-- Pipeline view -->
<div id="pipeline">
  <div class="phase done">Design</div>
  <div class="phase active">Execution</div>
  <div class="phase pending">Verification</div>
  ...
</div>

<!-- Evidence view -->
<div id="evidence">
  <table>
    <tr><th>Artifact</th><th>Required (tier)</th><th>Status</th></tr>
    <tr><td>Test evidence</td><td>All tiers</td><td>Collected</td></tr>
    <tr><td>Security review</td><td>Critical</td><td>Missing</td></tr>
  </table>
</div>
```

**WebSocket message format:**
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

**forge-viz SKILL.md structure:**
```markdown
---
name: forge-viz
description: Use when wanting to visualize current Forge workflow progress, evidence collection status, or pipeline state in a browser dashboard
---

# Forge Workflow Visualization

## Overview
Browser-based dashboard showing pipeline progress and evidence status.

## Starting the Server
[instructions for launching, same pattern as brainstorming visual companion]

## Views
### Pipeline View
[what it shows, how to read it]
### Evidence View
[what it shows, how to read it]

## Activation
- Opt-in by default
- Auto-offered at elevated/critical tiers (by setting-up-project or execution skills)
- Persistent across phases once opened
```

**v0 scope (from design Section 5):**
- Pipeline view and evidence view only
- Wave view, team view, and compliance view are v0.1 (not in scope)

**Auto-lifecycle details:**
- Start: shell script launches Node.js process, writes PID and connection info to `.forge/local/cache/viz-server.json`
- Idle detection: 30-minute timer resets on any WebSocket message or state file change
- Stop: shell script reads PID from cache file, sends SIGTERM
- The 30-minute idle timeout matches the brainstorming server pattern

**YAGNI:**
- Do NOT implement wave view, team view, or compliance view (v0.1 per design)
- Do NOT implement write-back (dashboard is read-only)
- Do NOT implement authentication (localhost-only by default)
- Do NOT add npm dependencies (zero-dep constraint)
- Do NOT build a WebSocket library -- use raw HTTP upgrade as in the brainstorming server

## Commit

`feat: add forge-viz workflow visualization server and skill`

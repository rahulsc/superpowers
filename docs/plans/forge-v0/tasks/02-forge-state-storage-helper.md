# Task 2: `forge-state` Storage Abstraction Layer

**Specialist:** implementer-2
**Depends on:** None *(parallel with Task 1)*
**Produces:** `forge-state` CLI helper script callable by hooks and skills, supporting both SQLite and JSON backends

## Goal

Build the storage abstraction that all skills and hooks use to read/write Forge state, with pluggable SQLite and JSON backends and automatic backend detection.

## Acceptance Criteria

- [ ] `forge-state get <key>` retrieves a value from state storage, returns it on stdout
- [ ] `forge-state set <key> <value>` writes a value to state storage, exits 0 on success
- [ ] `forge-state get` on a non-existent key exits non-zero with a clear error message
- [ ] `forge-memory add <type> <content>` stores a memory entry with timestamp, type, content, and auto-assigned confidence (1.0 for explicit adds)
- [ ] `forge-memory query <type>` returns all memories of that type, newest first
- [ ] `forge-memory query <type> --similar <text>` returns keyword-matched memories when using JSON backend, and (when sqlite-vec is available) vector-similar memories with SQLite backend
- [ ] `forge-evidence add <task-id> <artifact>` stores evidence for a task (artifact is a string: file path, command output reference, or inline text)
- [ ] `forge-evidence list <task-id>` returns all evidence for a task
- [ ] Auto-detection: uses SQLite backend when `sqlite3` is on PATH, falls back to JSON
- [ ] Manual override: respects `storage: json` or `storage: sqlite` from `.forge/project.yaml` when present
- [ ] JSON backend creates files under `.forge/local/` (state.json, memory/*.json, evidence/*.json)
- [ ] SQLite backend creates `.forge/local/forge.sqlite` with tables: `state`, `memory`, `evidence`
- [ ] Both backends produce identical output format for all commands
- [ ] Script is executable and works with `bash` (no exotic dependencies beyond sqlite3 for SQLite mode)
- [ ] `forge-state init` creates the `.forge/local/` directory and initializes the chosen backend

## Test Expectations

- **Test:** get/set roundtrip with both backends; memory add/query; evidence add/list; backend auto-detection; fallback when sqlite3 is not on PATH; init creates correct structure.
- **Expected red failure:** `Error: forge-state: command not found` before script is created; `Error: key not found: <key>` when getting a non-existent key; `Error: .forge/local/ not initialized` before init is run.
- **Expected green:** All CRUD operations work identically with both backends. Auto-detection picks SQLite when sqlite3 exists. JSON fallback works when sqlite3 is absent. Init creates the appropriate backend files.

## Files

- Create: `.forge/bin/forge-state` (shell script -- the unified CLI entry point)
- Create: `.forge/bin/lib/backend-sqlite.sh` (SQLite backend implementation)
- Create: `.forge/bin/lib/backend-json.sh` (JSON backend implementation)
- Create: `.forge/bin/forge-memory` (shell script -- memory subcommands, or integrated into forge-state)
- Create: `.forge/bin/forge-evidence` (shell script -- evidence subcommands, or integrated into forge-state)
- Test: `tests/forge-state/test-get-set.sh`
- Test: `tests/forge-state/test-memory.sh`
- Test: `tests/forge-state/test-evidence.sh`
- Test: `tests/forge-state/test-backend-detection.sh`
- Test: `tests/forge-state/test-init.sh`

## Implementation Notes

**Design reference:** Section 2 of `docs/plans/forge-v0/design.md` -- storage backend section, abstraction layer API, and the "What Goes in Local State" table.

**API surface** (from design):
```
forge-state get <key>
forge-state set <key> <value>
forge-state init
forge-memory add <type> <content>
forge-memory query <type> [--similar <text>]
forge-evidence add <task-id> <artifact>
forge-evidence list <task-id>
```

**SQLite schema:**
```sql
CREATE TABLE state (key TEXT PRIMARY KEY, value TEXT, updated_at TEXT);
CREATE TABLE memory (id INTEGER PRIMARY KEY, type TEXT, content TEXT, confidence REAL, source TEXT, created_at TEXT);
CREATE TABLE evidence (id INTEGER PRIMARY KEY, task_id TEXT, artifact TEXT, created_at TEXT);
```

**JSON backend structure:**
```
.forge/local/
  state.json          # { "key": "value", ... }
  memory/
    <type>.json       # [{ "content": "...", "confidence": 1.0, "created_at": "..." }, ...]
  evidence/
    <task-id>.json    # [{ "artifact": "...", "created_at": "..." }, ...]
```

**Backend detection priority:**
1. Explicit `storage:` field in `.forge/project.yaml` (if file exists and field is set)
2. `sqlite3` on PATH -> SQLite
3. Fallback -> JSON

**Implementation approach:** Single bash entry-point script that sources the appropriate backend library. Backend libraries export the same function signatures. This keeps the interface clean without requiring Node.js.

**YAGNI notes:**
- Do NOT implement vector search / sqlite-vec integration -- keyword grep is sufficient for v0. The `--similar` flag does keyword matching only.
- Do NOT implement checkpoints or discoveries tables -- those are post-v0.
- Do NOT implement cache management -- that is a separate concern.
- Do NOT validate `.forge/project.yaml` schema -- that is Task 1's template responsibility and Task 3/4's validation responsibility.
- Keep the script POSIX-compatible where possible, but bash is acceptable (existing hooks use bash).

**Testing approach:** Tests should create a temporary `.forge/` directory, run commands against both backends, and compare outputs. Use `PATH` manipulation to simulate sqlite3 absence for fallback testing.

## Commit

`feat: add forge-state storage helper with SQLite and JSON backends`

---
name: diagnosing-forge
description: Use when Forge skills fail, state seems corrupted, or after disruptive git operations — runs health checks on .forge/ directory, state, hooks, and storage
---

# Diagnosing Forge

**Announce at start:** "I'm using the diagnosing-forge skill to run health checks on this Forge installation."

Forge diagnostics run six check categories. Run all checks before reporting — do not stop on first failure.


## When to Use

- After installation issues or unexpected behavior
- When skills fail to find `.forge/` state
- Periodically as a health check
- After disruptive git operations (rebase, merge conflicts, force-push)
- When storage seems inconsistent or state reads return unexpected values


## Output Format

Each check result uses this format:
```
[icon] [severity] [check-name]: [message]
  Fix: [suggested remediation]
```

Icons by severity:
- `[OK]` — passed, no action needed
- `[WARN]` — warning, degraded but functional
- `[ERR]` — error, functionality broken

Example output:
```
[OK]   info    directory-structure: all required directories present
[WARN] warning project-yaml: 'commands.lint' field missing
  Fix: Add lint command to .forge/project.yaml
[ERR]  error   storage-health: SQLite integrity check failed
  Fix: Run forge-state repair --project-dir . or restore from backup
```


## Check 1 — Directory Structure Integrity

Verify the `.forge/` directory exists and contains required subdirectories.

**Required directories:**
- `.forge/policies/`
- `.forge/workflows/`
- `.forge/packs/`
- `.forge/adapters/`
- `.forge/shared/`
- `.forge/local/`

**Check procedure:**
1. Verify `.forge/` exists at repo root
2. For each required directory, check existence
3. Report missing directories as `[ERR]`

```
[ERR] error directory-structure: missing required directories: .forge/adapters/, .forge/shared/
  Fix: Run forge:adopting-forge to recreate missing structure, or mkdir -p .forge/adapters .forge/shared
```

If `.forge/` does not exist at all:
```
[ERR] error directory-structure: .forge/ directory not found
  Fix: Run forge:adopting-forge to initialize Forge in this repository
```
Then skip remaining checks — no `.forge/` means nothing else can be validated.


## Check 2 — project.yaml Validation

Read and validate `.forge/project.yaml`.

**Required fields:**
- `name` — non-empty string
- `stack` — non-empty string
- `commands` — object with at least `test` key
- `storage` — one of: `json`, `sqlite`

**Optional but recommended:**
- `commands.lint`
- `commands.build`
- `version`

**Check procedure:**
1. Verify `project.yaml` exists
2. Parse as YAML (if parse fails → `[ERR]`)
3. Check required fields are present and non-empty
4. Check `storage` value is valid
5. Warn on missing recommended fields

```
[OK]   info    project-yaml: all required fields present
[WARN] warning project-yaml: 'commands.lint' not configured
  Fix: Add lint command to .forge/project.yaml under commands.lint
```

If file missing:
```
[ERR] error project-yaml: .forge/project.yaml not found
  Fix: Run forge:adopting-forge to create project configuration
```


## Check 3 — Hook Installation

Verify Forge hooks are registered in `hooks/hooks.json`.

**Required Forge hooks:**
- `SessionStart` — must include a Forge hook entry
- `PreCommit` — must include a Forge hook entry
- `TaskCompleted` — must include a Forge hook entry

**Check procedure:**
1. Check if `hooks/hooks.json` exists
2. Parse JSON (if parse fails → `[ERR]`)
3. Verify each required hook event has a Forge handler entry
4. Check handler commands reference `.forge/` or `forge-` tooling

```
[OK]   info    hook-install: SessionStart hook present
[OK]   info    hook-install: PreCommit hook present
[WARN] warning hook-install: TaskCompleted hook not registered
  Fix: Re-run forge:adopting-forge hook registration, or manually add TaskCompleted entry to hooks/hooks.json
```

If `hooks/hooks.json` does not exist:
```
[WARN] warning hook-install: hooks/hooks.json not found — hooks not installed
  Fix: Run forge:adopting-forge with full adoption mode to install hooks
```


## Check 4 — Storage Backend Health

Verify the state storage backend is functional and data is intact.

Read `storage` field from `project.yaml` to determine backend.

**SQLite backend** (`storage: sqlite`):
1. Locate `.forge/local/forge-state.db` (or path from config)
2. Run: `sqlite3 .forge/local/forge-state.db "PRAGMA integrity_check;"`
3. Expected output: `ok`
4. If output is not `ok` → `[ERR]`

```
[OK]   info    storage-health: SQLite integrity check passed
```

**JSON backend** (`storage: json`):
1. Locate `.forge/local/state.json` (or path from config)
2. Attempt to parse as valid JSON
3. If parse fails → `[ERR]`
4. Check top-level keys are objects (not corrupted scalars)

```
[OK]   info    storage-health: JSON state file is valid
```

**File not found** (either backend):
```
[WARN] warning storage-health: state file not found (normal if Forge never run)
  Fix: Run forge-state init --project-dir . to initialize storage
```

**Parse/integrity failure:**
```
[ERR] error storage-health: storage integrity check failed
  Fix: Restore from backup at .forge/local/backups/ or run forge-state repair
```


## Check 5 — Stale State Detection

Check for orphaned worktrees, incomplete tasks, and zombie checkpoints.

**Orphaned worktrees:**
1. Run `git worktree list` to get active worktrees
2. Check `.forge/local/` for worktree state files
3. Flag state files referencing worktree paths no longer in `git worktree list`

```
[WARN] warning stale-state: orphaned worktree state: .forge/local/wt-feature-x.json
  Fix: Run git worktree prune and remove .forge/local/wt-feature-x.json
```

**Incomplete tasks:**
1. Read forge-state for tasks with status `in_progress` older than 7 days (by timestamp)
2. Flag as stale

```
[WARN] warning stale-state: 2 tasks in_progress for >7 days
  Fix: Review and close or reassign stale tasks
```

**Zombie checkpoints:**
1. Check `.forge/local/checkpoints/` if directory exists
2. Flag checkpoint files with no corresponding active task

```
[INFO] info    stale-state: no zombie checkpoints found
```

If no stale state found:
```
[OK]   info    stale-state: no stale state detected
```


## Check 6 — Pack Integrity

Only run if `.forge/packs/` exists and contains at least one pack.

For each pack under `.forge/packs/`:
1. Verify `pack.yaml` exists in the pack directory
2. Verify `pack.yaml` has `name` and `version` fields
3. Verify pack does not reference missing policy files

```
[OK]   info    pack-integrity: forge-pack-security v1.2.0 — valid
[WARN] warning pack-integrity: forge-pack-docs — missing version field in pack.yaml
  Fix: Edit .forge/packs/forge-pack-docs/pack.yaml and add version field
```

If no packs installed:
```
[OK]   info    pack-integrity: no packs installed
```


## Final Report

After all checks complete, print a summary:

```
=== Forge Diagnostics Report ===

Checks run: 6
  [OK]   4 passed
  [WARN] 1 warning
  [ERR]  1 error

Action required:
  1. [ERR] storage-health: SQLite integrity check failed
     Fix: Restore from backup or run forge-state repair
  2. [WARN] hook-install: TaskCompleted hook not registered
     Fix: Re-run forge:adopting-forge hook registration

No action needed:
  directory-structure, project-yaml, stale-state, pack-integrity
```

**Do NOT auto-fix issues.** Report with suggested fix only. User must apply fixes.


## Scope Limits

- Do NOT modify any `.forge/` files during diagnostics
- Do NOT auto-fix diagnosed issues — report with suggested fix only
- Do NOT run destructive commands (no `DROP TABLE`, no `rm` of state files)
- Do NOT access network resources during checks


## Integration

Called by: users on-demand, `forge:adopting-forge` (Step 6 verification)
Pairs with: `forge:syncing-forge` (refresh after fixing issues), `forge:adopting-forge` (initial setup)

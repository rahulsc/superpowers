# Task 18: `syncing-forge` and `diagnosing-forge` Skills (NEW)

**Specialist:** implementer-2
**Depends on:** Task 7 (adopting-forge establishes the `.forge/` directory that sync/diagnose operate on)
**Produces:** Two new adoption support skills consumed by users for ongoing Forge maintenance; `syncing-forge` also consumed by Task 20 (pack protocol, which integrates pack update checks into sync)

## Goal

Create `syncing-forge` (regenerate adapters, refresh state) and `diagnosing-forge` (health checks, diagnostics) to support ongoing Forge maintenance after initial adoption.

## Acceptance Criteria

### syncing-forge
- [ ] Re-scans repo for changes since adoption: new files, changed stack indicators, new risk areas (files matching policy rules that were not present at adoption time)
- [ ] Regenerates CLAUDE.md from current `.forge/project.yaml` and `.forge/policies/` (same generation logic as adopting-forge, but as a refresh)
- [ ] Regenerates AGENTS.md from current `.forge/project.yaml` for Codex compatibility
- [ ] Checks for pack updates if any packs are installed in `.forge/packs/` (lists installed packs, flags if pack source has changed -- actual update mechanics deferred to Task 20)
- [ ] Refreshes `.forge/local/cache/` if cache directory exists (regenerate file index, clear stale entries)
- [ ] Reports what changed: list of files regenerated, new risk areas detected, packs with available updates
- [ ] Description starts with "Use when..." per design doc Section 8
- [ ] Skill under 500 lines / 5,000 words

### diagnosing-forge
- [ ] Checks `.forge/` directory structure integrity: all required directories exist (`policies/`, `workflows/`, `packs/`, `adapters/`, `shared/`, `local/`), `project.yaml` exists
- [ ] Validates `project.yaml` against expected fields (name, stack, commands, storage) -- reports missing or malformed fields
- [ ] Checks hook installation: verifies `hooks/hooks.json` exists and contains expected Forge hooks (SessionStart, PreCommit, TaskCompleted)
- [ ] Verifies storage backend health: if SQLite, runs `PRAGMA integrity_check` on `forge.sqlite`; if JSON, validates `state.json` is parseable JSON
- [ ] Checks for stale state: orphaned worktrees (paths in state but no longer on disk), incomplete tasks (tasks with evidence but no completion marker), zombie checkpoints
- [ ] Reports all issues with categorized severity (error/warning/info) and suggested fixes for each
- [ ] Description starts with "Use when..." per design doc Section 8
- [ ] Skill under 500 lines / 5,000 words

## Test Expectations

- **Test:** Sync regenerates adapters after project.yaml changes. Doctor reports health status on healthy install. Doctor catches broken hook.
- **Expected red failure:** `syncing-forge` skill directory does not exist (skill not yet created), or `diagnosing-forge` fails to detect a deliberately broken hook (hook file removed but hooks.json still references it)
- **Expected green:** Sync produces updated CLAUDE.md reflecting changed project.yaml. Doctor reports all-clear on a healthy `.forge/` install (exit 0, "All checks passed"). Doctor detects and reports a missing hook script with suggested fix ("Hook script missing at hooks/run-hook.cmd. Re-run forge:adopting-forge or restore from git.").

## Files

- Create: `skills/syncing-forge/SKILL.md` (new skill)
- Create: `skills/diagnosing-forge/SKILL.md` (new skill)
- Test: `tests/skills/syncing-forge/adapter-regen.test.sh` (modify project.yaml, run sync, verify CLAUDE.md updated)
- Test: `tests/skills/diagnosing-forge/health-check.test.sh` (healthy install passes; deliberately break hook, verify detection)

## Implementation Notes

**syncing-forge structure:**

```markdown
## When to Use
- After modifying `.forge/project.yaml` (added new stack items, changed commands)
- After adding/removing files that match policy rules
- Periodically to refresh adapters and check pack freshness
- After a teammate modifies `.forge/shared/` or `.forge/policies/`

## Process
1. Read current `.forge/project.yaml`
2. Scan repo structure for changes (new directories, changed file patterns)
3. Compare detected stack/traits against project.yaml -- report differences
4. Regenerate CLAUDE.md (using same template logic as adopting-forge)
5. Regenerate AGENTS.md (if Codex compatibility enabled in project.yaml)
6. Check installed packs for available updates
7. Refresh local cache if present
8. Report summary of changes
```

**diagnosing-forge structure:**

```markdown
## When to Use
- After installation issues or unexpected behavior
- When skills fail to find `.forge/` state
- Periodically as a health check
- After git operations that may have disrupted `.forge/` (rebase, merge conflicts)

## Checks
1. Directory structure integrity
2. project.yaml validation
3. Hook installation
4. Storage backend health
5. Stale state detection
6. Pack integrity (if packs installed)

## Output Format
[icon] [severity] [check-name]: [message]
  Fix: [suggested remediation]
```

**CLAUDE.md regeneration:**
Both `adopting-forge` (Task 7) and `syncing-forge` need to generate CLAUDE.md from `.forge/` config. Factor the generation logic into a shared reference or document the template clearly enough that both skills produce consistent output. The simplest approach for v0: the sync skill reads the current CLAUDE.md, diffs against what it would generate, and only rewrites if there are changes. The generation template is documented in the skill itself (no shared code -- skills are documentation, not programs).

**AGENTS.md generation:**
Same approach as CLAUDE.md but for Codex. The AGENTS.md format is simpler (task instructions, allowed tools). Generate from project.yaml commands and policy rules.

**Hook installation check:**
Read `hooks/hooks.json`, verify it contains hooks for the lifecycle events that Forge requires (SessionStart for context loading, PreCommit for risk-tier gate, TaskCompleted for evidence gate). Do not verify the exact command strings (those may change) -- verify that the hook event types exist and the referenced scripts are on disk.

**Stale state detection:**
```bash
# Orphaned worktrees
for path in $(forge-state get worktree.* | grep path); do
  [ -d "$path" ] || echo "warning: worktree path $path no longer exists"
done

# Incomplete tasks
for task in $(forge-evidence list-tasks); do
  completion=$(forge-state get "task.$task.complete")
  [ "$completion" = "true" ] || echo "info: task $task has evidence but is not marked complete"
done
```

**YAGNI:**
- Do NOT implement actual pack update/upgrade logic (sync only flags that updates may be available -- Task 20 handles pack lifecycle)
- Do NOT implement automatic CLAUDE.md regeneration on every session start (sync is manual/on-demand)
- Do NOT implement auto-fix for diagnosed issues (report with suggested fix, user decides)
- Do NOT implement configuration drift detection between `.forge/` and actual repo state beyond what is listed in acceptance criteria

## Commit

`feat: add syncing-forge and diagnosing-forge adoption support skills`

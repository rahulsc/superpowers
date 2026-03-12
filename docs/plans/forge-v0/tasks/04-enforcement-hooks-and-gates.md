# Task 4: Enforcement Hooks and State Gates

**Specialist:** implementer-2
**Depends on:** Task 1 (`.forge/` structure for project detection), Task 2 (storage helper for state reads/writes)
**Produces:** Claude Code hook scripts for SessionStart, TaskCompleted, PreCommit lifecycle events; reusable state gate checking logic

## Goal

Implement Layer 2 (state gates) and Layer 3 (hook gates) enforcement from the design, ensuring that required artifacts and phase preconditions cannot be bypassed by LLM rationalization.

## Acceptance Criteria

- [ ] **SessionStart hook** detects `.forge/project.yaml` in the current directory or any parent -> loads Forge context into the session (injects `forge-routing` skill content, similar to how `session-start` currently injects `using-superpowers`)
- [ ] **SessionStart hook** falls back gracefully when no `.forge/project.yaml` exists (Forge is not active, no error)
- [ ] **TaskCompleted hook** checks that verification evidence exists for the current task via `forge-evidence list <task-id>` -> blocks (exit 2) with message when missing, allows (exit 0) when present
- [ ] **PreCommit hook** reads current risk tier from state -> checks tier-specific requirements are met -> blocks (exit 2) with specific message listing what is missing, allows (exit 0) when all requirements satisfied
- [ ] **PreCommit hook** is a no-op (exit 0) when risk tier is `minimal` (verification-only, checked by TaskCompleted)
- [ ] **State gate script** provides reusable gate checks: `forge-gate check <gate-name>` returns exit 0 (passed) or exit 2 (blocked) with a human-readable message
- [ ] Gate: `design.approved` -- blocks `writing-plans` phase entry unless design is approved in state
- [ ] Gate: `plan.approved` -- blocks execution phase entry unless plan is approved in state
- [ ] Gate: `wave.compliance` -- blocks next wave start unless current wave tasks have `compliance: passed`
- [ ] Gate: `verification.passed` -- blocks `finishing-a-development-branch` unless verification evidence is present
- [ ] All hooks return exit code 2 (not 1) to block + provide feedback, per Claude Code hook contract
- [ ] `hooks.json` is updated to register all new hooks alongside existing ones
- [ ] Existing `session-start` hook functionality is preserved (backward compatibility with Superpowers mode)

## Test Expectations

- **Test:** Hook blocks completion when evidence missing (exit 2). Hook allows when evidence present (exit 0). State gate prevents phase progression without preconditions. PreCommit blocks elevated-tier commit without review evidence.
- **Expected red failure:** Hook exits 0 (allows) when it should exit 2 (block) -- e.g., TaskCompleted allows completion with no evidence recorded. State gate allows writing-plans entry when `design.approved` is not set.
- **Expected green:** TaskCompleted blocks with `Cannot complete: missing verification evidence for task <id>`. TaskCompleted allows after evidence is added. PreCommit blocks with `Risk tier [elevated] requires: [review]. Missing: [review]`. State gate blocks with `Gate [design.approved] not met: design must be approved before planning`.

## Files

- Create: `hooks/forge-session-start` (new Forge-aware session start script)
- Create: `hooks/forge-task-completed` (TaskCompleted enforcement hook)
- Create: `hooks/forge-pre-commit` (PreCommit risk-tier enforcement hook)
- Create: `hooks/forge-gate` (reusable gate-checking script: `forge-gate check <gate-name>`)
- Modify: `hooks/hooks.json` (section: add TaskCompleted and update PreCommit/SessionStart entries for Forge hooks)
- Modify: `hooks/session-start` (section: add Forge detection -- if `.forge/project.yaml` exists, delegate to `forge-session-start`; otherwise run existing Superpowers logic)
- Test: `tests/forge-hooks/test-session-start.sh`
- Test: `tests/forge-hooks/test-task-completed.sh`
- Test: `tests/forge-hooks/test-pre-commit.sh`
- Test: `tests/forge-hooks/test-state-gates.sh`

## Implementation Notes

**Design reference:** Section 4 of `docs/plans/forge-v0/design.md` -- three enforcement layers, enforcement per risk tier table, validation agent, failure handling.

**Hook contract (Claude Code):**
- Exit 0: allow the action
- Exit 2: block the action, message in stdout is shown to the LLM
- stdout JSON format for SessionStart: `{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": "..." } }`
- stdout for TaskCompleted/PreCommit blocking: plain text message (Claude Code shows it to the LLM)

**SessionStart Forge detection logic:**
```bash
# Walk up from cwd looking for .forge/project.yaml
dir="$PWD"
while [ "$dir" != "/" ]; do
  if [ -f "$dir/.forge/project.yaml" ]; then
    FORGE_ROOT="$dir"
    break
  fi
  dir="$(dirname "$dir")"
done
```

When Forge is detected, the session-start hook should:
1. Read `skills/forge-routing/SKILL.md` content (like current hook reads `using-superpowers`)
2. Inject it as session context so the LLM knows it is in Forge mode
3. Include the project name from `project.yaml` in the context

**Enforcement per risk tier (from design):**

| Gate | Minimal | Standard | Elevated | Critical |
|------|---------|----------|----------|----------|
| Design approval in state | - | - | Required | Required |
| Plan approval in state | - | Required | Required | Required |
| Test evidence per task | Required | Required | Required | Required |
| Verification at completion | Required | Required | Required | Required + rollback |
| Review evidence | - | Optional | Required | Required + specialist |
| Hook-enforced commit gate | - | - | Yes | Yes |

**The forge-gate script** is invoked by skills (prompt-level) and by hooks. Skills call it to check preconditions before entering a phase. Hooks call it as a last resort when skills fail to self-enforce.

**Gate definitions:**
```
forge-gate check design.approved
  -> forge-state get design.approved
  -> if != "true": exit 2 "Gate [design.approved] not met: design must be approved before planning"

forge-gate check plan.approved
  -> forge-state get plan.approved
  -> if != "true": exit 2 "Gate [plan.approved] not met: plan must be approved before execution"

forge-gate check verification.passed
  -> forge-state get verification.passed
  -> if != "true": exit 2 "Gate [verification.passed] not met: verification must pass before finishing"
```

**Backward compatibility:** The existing `session-start` hook must continue to work for repos without `.forge/`. The approach is: detect Forge first; if not found, run existing Superpowers injection logic unchanged.

**YAGNI notes:**
- Do NOT implement the validation agent (`validating-wave-compliance`) -- that is a separate skill (Task 10).
- Do NOT implement user override recording in hooks -- overrides are handled by the risk engine (Task 3).
- Do NOT implement hook-based enforcement for every possible gate -- start with the four listed gates and the three lifecycle hooks. More can be added later.
- PreCommit hook only enforces for elevated+ tiers. Minimal and standard tiers rely on TaskCompleted and prompt-level enforcement.

## Commit

`feat: add enforcement hooks and state gates for Forge lifecycle`

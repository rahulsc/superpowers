# Task 12: `agent-team-driven-development` Skill Evolution

**Specialist:** implementer-2
**Depends on:** Task 9 (writing-plans format -- reads plan with wave analysis), Task 10 (wave validation invoked between waves), Task 11 (shares state/evidence patterns with SDD -- implementer-1 establishes the pattern)
**Produces:** ATDD wired into Forge state, risk-aware, with Forge team management; consumed by Task 14 (verification skill invoked at completion)

## Goal

Evolve agent-team-driven-development to read/write `.forge/` state, manage team worktrees via Forge conventions, invoke wave validation between waves, and aggregate per-agent evidence at wave boundaries.

## Acceptance Criteria

- [ ] All state references changed from `.superpowers/state.yml` to `forge-state get`/`forge-state set` calls
- [ ] Team roster read from `.forge/` state via `forge-state get team.roster` instead of `.superpowers/state.yml`
- [ ] Per-implementer worktree tracking in `.forge/local/` via `forge-state set worktree.implementers.<name>.path` etc.
- [ ] Cold resume reads from `.forge/local/` state: `forge-state get plan.current_wave`, `forge-state get plan.completed_tasks`
- [ ] Evidence collection per task via `forge-evidence add <task-id> <artifact>` (same pattern as Task 11)
- [ ] Pipelined TDD evidence (RED/GREEN) written via `forge-evidence add` for each task
- [ ] Cross-agent evidence aggregation at wave boundaries: after all wave tasks complete, aggregate evidence into a wave summary
- [ ] Wave validation invoked between waves at elevated and critical risk tiers via `forge:validating-wave-compliance`
- [ ] Wave validation skipped at minimal and standard tiers
- [ ] Risk-tier-aware review tiering (same mapping as Task 11):
  - Minimal: light review (single combined pass)
  - Standard: standard two-stage
  - Elevated: standard two-stage + wave validation
  - Critical: standard two-stage + wave validation + security review pass
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Implementer, spec-reviewer, and code-quality-reviewer prompt templates updated
- [ ] Execution handoff to `forge:finishing-a-development-branch`
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** ATDD reads team roster from `.forge/`, tracks implementer worktrees in state, aggregates evidence at wave boundaries, and invokes wave validation at elevated tier
- **Expected red failure:** `forge-state get team.roster` returns empty (team roster not being read from `.forge/`), or `forge-state get worktree.implementers.<name>.path` returns empty after implementer spawned (worktree tracking not in `.forge/local/`)
- **Expected green:** Team roster loaded from `.forge/` state, implementer worktree paths tracked in `.forge/local/`, per-task evidence recorded via `forge-evidence add`, wave evidence aggregated after wave completion, wave validation invoked at elevated tier between waves

## Files

- Modify: `skills/agent-team-driven-development/SKILL.md` (state tracking section, team structure, git isolation, wave execution, evidence requirements, integration section)
- Modify: `skills/agent-team-driven-development/implementer-prompt.md` (update state references, evidence format, `forge:` namespace)
- Modify: `skills/agent-team-driven-development/spec-reviewer-prompt.md` (update `superpowers:` to `forge:` namespace)
- Modify: `skills/agent-team-driven-development/code-quality-reviewer-prompt.md` (update `superpowers:` to `forge:` namespace)
- Test: `tests/skills/agent-team-driven-development/forge-evolution.test.md` (E2E: roster loading, worktree tracking, evidence aggregation, wave validation)

## Implementation Notes

**Shared patterns with Task 11 (SDD):**
Task 11 (implementer-1) establishes the `forge-state` and `forge-evidence` usage patterns. This task applies the same patterns to ATDD. Key shared patterns:
- `forge-state get`/`set` for all state reads/writes
- `forge-evidence add` for per-task evidence
- Risk tier read at skill start via `forge-state get risk.tier`
- Wave validation dispatch at elevated+ tiers

**ATDD-specific additions beyond SDD:**

1. **Team roster from state:** Replace the current `state.yml` roster read with `forge-state get team.roster`. The roster contains agent definitions, models, and specialist roles -- same structure, different storage location.

2. **Per-implementer worktree tracking:** Currently tracked in `state.yml` under `worktree.implementers.<name>`. Move to:
```
forge-state set worktree.implementers.<name>.path <path>
forge-state set worktree.implementers.<name>.branch <branch>
forge-state set worktree.implementers.<name>.last_sha <sha>
```

3. **Cross-agent evidence aggregation:** After each wave completes (all tasks reviewed and merged), aggregate evidence:
```
forge-evidence add wave-<N> summary "Tasks: [list], all tests pass, merged clean"
forge-evidence add wave-<N> integration "Test command: <cmd>, Exit: 0, N tests pass"
```
This provides a wave-level evidence trail in addition to per-task evidence.

4. **Wave validation dispatch:** At wave boundaries when risk tier is elevated or critical:
   - Collect: all diffs from wave (aggregated from per-implementer branches)
   - Collect: test output from merged integration check
   - Dispatch `forge:validating-wave-compliance` as subagent
   - Block next wave if compliance fails
   - This happens AFTER merge and integration test but BEFORE assigning next wave's tasks

**Implementer prompt template changes:**
Same pattern as Task 11 -- update references, not behavior. The persistent-implementer interaction model (SendMessage for new tasks, review feedback) stays the same. Key updates:
- State path references: `.superpowers/` -> `forge-state`
- Skill references: `superpowers:` -> `forge:`
- Evidence note: controller records evidence via `forge-evidence`, implementer reports it in SendMessage

**Between-waves checklist update:**
Current "Between waves" section has 7 steps. Add wave validation as step 3.5 (after merge + integration test, before assigning next wave):
1. All tasks pass reviews
2. Merge all implementer branches
3. Verify integration (run tests on merged result)
3.5. **If elevated/critical tier:** dispatch wave compliance validation, block if failed
4. QA writes next+1 wave tests (if QA in roster)
5. Update `plan.current_wave` in state
6. Check context, compact if needed
7. Assign next wave tasks

**YAGNI:**
- Do NOT implement cross-agent communication channels (implementers still communicate only through the lead)
- Do NOT add automatic team scaling (spawn/shutdown based on wave size is already in the skill)
- Do NOT change the merge strategy (lead merges, same as current)
- Do NOT implement the forge-state/forge-evidence helpers (Task 1) -- just wire up the calls

## Commit

`feat(agent-team-driven-development): wire into forge state, evidence, and wave validation`

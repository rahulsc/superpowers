# Task 11: `subagent-driven-development` Skill Evolution

**Specialist:** implementer-1
**Depends on:** Task 9 (writing-plans format -- reads plan output), Task 10 (wave validation invoked between waves at elevated+ tiers)
**Produces:** SDD wired into Forge state and risk-aware; consumed by Task 14 (verification skill is invoked at completion)

## Goal

Evolve subagent-driven-development to read/write `.forge/` state, collect evidence per task in `.forge/local/`, and invoke wave validation between waves at elevated+ risk tiers.

## Acceptance Criteria

- [ ] All state references changed from `.superpowers/state.yml` to `forge-state get`/`forge-state set` calls
- [ ] Cold resume reads from `.forge/local/` state: `forge-state get plan.completed_tasks`, `forge-state get plan.path`
- [ ] Evidence collection writes to `.forge/local/` via `forge-evidence add <task-id> <artifact>` for each completed task
- [ ] Evidence includes: command evidence (test output), diff evidence (commit SHA + stat), RED evidence, GREEN evidence
- [ ] Between waves (when tasks have wave groupings): invoke `forge:validating-wave-compliance` at elevated and critical risk tiers
- [ ] Wave validation skipped at minimal and standard tiers (design doc Section 3 table)
- [ ] Risk-tier-aware review tiering:
  - Minimal: light review (single combined spec+quality pass)
  - Standard: standard two-stage review (spec compliance, then code quality) -- current behavior
  - Elevated: standard two-stage + wave validation between waves
  - Critical: standard two-stage + wave validation + security-focused review pass
- [ ] Risk tier read from state via `forge-state get risk.tier` at skill start
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Implementer prompt template updated with `.forge/` state references and `forge-evidence` usage
- [ ] Spec reviewer and code quality reviewer prompts updated with `forge:` namespace
- [ ] Execution handoff to `forge:finishing-a-development-branch` (not `superpowers:`)
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** SDD reads/writes `.forge/` state correctly, records evidence per task, and invokes wave validation at elevated tier
- **Expected red failure:** `forge-state get plan.completed_tasks` returns empty after task completion (state not being written to `.forge/`), or `forge-evidence` not called (evidence not recorded in `.forge/local/`)
- **Expected green:** After task 1 completes: `forge-state get plan.completed_tasks` returns `[1]`, evidence artifacts exist in `.forge/local/` for task 1, wave validation invoked between wave boundaries at elevated tier, wave validation NOT invoked at standard tier

## Files

- Modify: `skills/subagent-driven-development/SKILL.md` (state integration section, cold resume, evidence requirements, review tiering, wave validation, integration section)
- Modify: `skills/subagent-driven-development/implementer-prompt.md` (update working directory references, evidence format references to forge-evidence)
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md` (update `superpowers:` to `forge:` namespace)
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md` (update `superpowers:` to `forge:` namespace)
- Test: `tests/skills/subagent-driven-development/forge-evolution.test.md` (E2E: state writes, evidence recording, wave validation trigger)

## Implementation Notes

**State migration pattern:**
Every occurrence of `.superpowers/state.yml` direct reads/writes must be replaced with `forge-state` helper calls. The helper abstracts the storage backend (SQLite or JSON). Key replacements:

| Current | Forge |
|---------|-------|
| Read `.superpowers/state.yml` YAML | `forge-state get <key>` |
| Write to `.superpowers/state.yml` | `forge-state set <key> <value>` |
| Check state file exists | `forge-state get plan.path` (returns empty if no state) |

**Evidence collection pattern:**
After each task completion (post-review), record evidence:
```
forge-evidence add task-<N> command "<test command output>"
forge-evidence add task-<N> diff "<commit SHA + git diff --stat>"
forge-evidence add task-<N> tdd-red "<RED evidence output>"
forge-evidence add task-<N> tdd-green "<GREEN evidence output>"
```
This replaces the current inline evidence tracking. Evidence is stored in `.forge/local/evidence/` (JSON backend) or the evidence table (SQLite backend).

**Wave validation integration:**
SDD currently executes tasks sequentially. When tasks have wave groupings (from the plan's wave analysis), the skill should recognize wave boundaries. At a wave boundary when risk tier is elevated or critical:
1. Collect all completed task diffs for the wave
2. Dispatch `forge:validating-wave-compliance` as a subagent
3. If compliance fails: stop, report deviations, fix before continuing
4. If compliance passes: proceed to next wave

At minimal/standard tiers, wave boundaries are just task boundaries -- no validation step.

**Review tiering (already partially exists):**
The current skill has a "Review Tiering" section with simple/default/critical categories. Map these to risk tiers:
- Minimal tier -> current "simple, low-risk" (single combined review pass)
- Standard tier -> current "default" (two-stage: spec then quality)
- Elevated tier -> current "default" + wave validation
- Critical tier -> current "auth/payment/data" (add security review pass) + wave validation

**Implementer prompt changes:**
The implementer prompt template is mostly unchanged. Key updates:
- Remove references to `.superpowers/` paths
- Add note that evidence will be collected via `forge-evidence` by the controller (implementer does not call forge-evidence directly -- they report evidence in their completion message, controller records it)
- Update skill references from `superpowers:test-driven-development` to `forge:test-driven-development`

**YAGNI:**
- Do NOT add automatic model selection based on risk tier (current complexity-based selection is sufficient)
- Do NOT add parallel task execution to SDD (that is ATDD's domain)
- Do NOT implement the forge-evidence helper in this task (Task 1 creates it) -- just wire up the calls assuming it exists
- Do NOT change the subagent dispatch mechanism (TaskTool usage stays the same)

## Commit

`feat(subagent-driven-development): wire into forge state, evidence, and wave validation`

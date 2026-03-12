# Task 21: Integration Testing, Description Optimization, and Cleanup

**Specialist:** all (lead-coordinated)
**Depends on:** All previous tasks (1-20)
**Produces:** Verified end-to-end Forge workflow, optimized skill descriptions, clean codebase with zero `.superpowers/` references; this is the final task before the Forge v0 feature branch is mergeable

## Goal

Verify the full Forge pipeline works end-to-end, optimize all 19 skill descriptions for reliable triggering, and remove all legacy `.superpowers/` references and dropped skills.

## Acceptance Criteria

### Sub-goal A: Integration Testing
- [ ] Full workflow chain verified on a test repo: `forge:adopting-forge` -> `forge:brainstorming` -> `forge:setting-up-project` -> `forge:writing-plans` -> `forge:subagent-driven-development` (SDD) -> `forge:validating-wave-compliance` -> `forge:verification-before-completion` -> `forge:requesting-code-review` -> `forge:finishing-a-development-branch`
- [ ] Each handoff verified: state written by skill N is readable by skill N+1 (e.g., `design.approved` written by brainstorming is read by setting-up-project)
- [ ] Enforcement hooks verified: PreCommit hook blocks commit when risk tier requirements not met; TaskCompleted hook blocks when evidence missing; SessionStart hook loads Forge context
- [ ] Risk tier ceremony verified at three levels: minimal (typo fix -- skips design, plan optional), elevated (new feature -- requires design, plan, TDD, review), critical (auth change -- requires security review, rollback evidence)
- [ ] Team mode verified: composing-teams produces roster, agent-team-driven-development uses it, per-implementer worktrees created and torn down
- [ ] Cold resume verified: mid-task interruption -> new session -> state read from `.forge/local/` -> work continues from checkpoint

### Sub-goal B: Description Optimization
- [ ] All 19 skill descriptions reviewed and updated
- [ ] Each description starts with "Use when..." and describes triggering conditions only (never workflow summary)
- [ ] Each description is specific enough to trigger reliably from a natural language scenario
- [ ] Each description is under 1024 characters (YAML frontmatter limit)
- [ ] No description summarizes the skill's internal process (CSO anti-pattern documented in writing-skills)
- [ ] Triggering test: each skill's description tested against a natural language scenario that should activate it (e.g., "I need to debug a test failure" should trigger systematic-debugging)

### Sub-goal C: Cleanup
- [ ] Zero `.superpowers/` string references in entire codebase (verified by grep)
- [ ] Zero `superpowers:` skill namespace references in entire codebase
- [ ] `skills/using-superpowers/` directory removed (replaced by `forge-routing`, Task 5)
- [ ] `skills/dispatching-parallel-agents/` directory removed (absorbed by risk-tier dispatch, design Section 8)
- [ ] `skills/executing-plans/` directory removed (YAGNI -- Claude Code and Codex have subagents, design Section 8)
- [ ] `hooks/hooks.json` updated to reference Forge hook scripts (if not already done by Task 4)
- [ ] All cross-references in remaining skills point to valid skill paths (no dangling references to removed skills)
- [ ] `.superpowers/` directory template/references removed from brainstorming visual companion scripts

## Test Expectations

- **Test:** Full adopt-to-finish workflow on a test repo. All skills trigger correctly from natural language. No `.superpowers/` references remain.
- **Expected red failure:** Any handoff failure (e.g., writing-plans cannot read design.approved from state because brainstorming wrote it to wrong key), or a skill fails to trigger from its intended scenario (e.g., "I want to review my code" does not activate requesting-code-review), or `grep -r "superpowers" skills/ hooks/` returns matches
- **Expected green:** Complete workflow passes without manual intervention at any handoff. All 19 skills trigger correctly from their intended natural language scenarios. `grep -r "superpowers" skills/ hooks/ agents/` returns zero matches. Three removed skill directories do not exist.

## Files

- Modify: All 19 skill `SKILL.md` files (description frontmatter optimization pass)
- Remove: `skills/using-superpowers/` (entire directory)
- Remove: `skills/dispatching-parallel-agents/` (entire directory)
- Remove: `skills/executing-plans/` (entire directory)
- Modify: `hooks/hooks.json` (verify/update Forge hook references)
- Modify: `skills/brainstorming/visual-companion.md` (remove `.superpowers/brainstorm/` references, update to `.forge/local/brainstorm/`)
- Modify: `skills/brainstorming/scripts/start-server.sh` (update `--project-dir` default path references from `.superpowers/` to `.forge/local/`)
- Test: `tests/integration/full-workflow-chain.test.md` (E2E chain: adopt through finish)
- Test: `tests/integration/handoff-state.test.sh` (verify each state key written by one skill is readable by the next)
- Test: `tests/integration/enforcement-hooks.test.sh` (verify hooks block correctly at each gate)
- Test: `tests/integration/skill-triggering.test.md` (19 natural language scenarios, one per skill, verify correct skill activates)
- Test: `tests/integration/no-superpowers-references.sh` (grep entire repo for "superpowers", expect zero matches in skills/, hooks/, agents/)

## Implementation Notes

**Sub-goal A execution approach:**

Create a disposable test repo with a simple Node.js project structure. Run the workflow chain:

1. `forge:adopting-forge` -- creates `.forge/` directory, generates CLAUDE.md
2. `forge:brainstorming` -- explore a simple feature (e.g., "add a greeting endpoint"), produce design doc
3. `forge:setting-up-project` -- classify risk (standard tier for this feature), create worktree, decide solo mode
4. `forge:writing-plans` -- create execution plan with 2-3 tasks
5. `forge:subagent-driven-development` -- execute tasks sequentially with TDD
6. `forge:validating-wave-compliance` -- validate implementation matches design
7. `forge:verification-before-completion` -- collect and verify evidence
8. `forge:requesting-code-review` -- dispatch reviewer
9. `forge:finishing-a-development-branch` -- create PR, clean state

At each step, verify the expected state keys are present in `.forge/local/` before proceeding. Log each handoff for the test report.

Repeat the chain at elevated and critical tiers to verify ceremony scaling:
- Elevated: requires design doc, plan, TDD, review (all present)
- Critical: requires design doc, risk register, plan, TDD, security review, rollback evidence (verify security reviewer dispatched, rollback evidence collected)

**Sub-goal B execution approach:**

For each of the 19 skills, review the description against these criteria:
1. Starts with "Use when..."
2. Describes only triggering conditions (situations, symptoms, contexts)
3. Does NOT summarize the skill's workflow or process
4. Under 1024 characters
5. Specific enough to distinguish from similar skills

**Current skill inventory (19 after removals):**
1. brainstorming
2. setting-up-project (new)
3. writing-plans
4. subagent-driven-development
5. agent-team-driven-development
6. validating-wave-compliance (new)
7. verification-before-completion
8. requesting-code-review
9. receiving-code-review
10. finishing-a-development-branch
11. systematic-debugging
12. test-driven-development
13. forge-routing (new, replaces using-superpowers)
14. writing-skills
15. using-git-worktrees
16. composing-teams
17. adopting-forge (new)
18. syncing-forge (new)
19. diagnosing-forge (new)

Test each by constructing a natural language prompt that should trigger it and verifying the description would match. Examples:
- "I have a test failing intermittently" -> systematic-debugging
- "I want to add a new feature to the payments module" -> brainstorming
- "The forge setup seems broken" -> diagnosing-forge
- "Set up this repo for Forge" -> adopting-forge

**Sub-goal C execution approach:**

```bash
# Find all remaining references
grep -rn "superpowers" skills/ hooks/ agents/ --include="*.md" --include="*.json" --include="*.sh" --include="*.js"

# Remove directories
rm -rf skills/using-superpowers/
rm -rf skills/dispatching-parallel-agents/
rm -rf skills/executing-plans/

# Verify removal
ls skills/using-superpowers/ 2>&1    # should error
ls skills/dispatching-parallel-agents/ 2>&1  # should error
ls skills/executing-plans/ 2>&1      # should error

# Find dangling cross-references
grep -rn "using-superpowers\|dispatching-parallel-agents\|executing-plans" skills/ --include="*.md"
```

Fix any dangling references found. Common replacements:
- `superpowers:using-superpowers` -> `forge:forge-routing`
- `superpowers:dispatching-parallel-agents` -> removed (use Task tool directly)
- `superpowers:executing-plans` -> removed (use `forge:subagent-driven-development`)
- `superpowers:<skill-name>` -> `forge:<skill-name>`
- `.superpowers/state.yml` -> `forge-state` commands
- `.superpowers/brainstorm/` -> `.forge/local/brainstorm/`

**Brainstorming server cleanup:**
The visual companion references `.superpowers/brainstorm/` as the persistence directory. Update:
- `visual-companion.md`: all `.superpowers/brainstorm/` references become `.forge/local/brainstorm/`
- `scripts/start-server.sh`: default `--project-dir` path behavior updated to use `.forge/local/brainstorm/`
- `scripts/server.js`: if it contains `.superpowers` string references, update them

**Coordination:**
This task is lead-coordinated across all specialists:
- Implementer-1: description optimization for skills 1-7, cleanup of removed directories
- Implementer-2: description optimization for skills 8-13, hook updates
- Implementer-3: description optimization for skills 14-19, brainstorming server cleanup
- Lead: integration test execution and verification, final grep audit

**YAGNI:**
- Do NOT add new features during integration -- this is verification and cleanup only
- Do NOT refactor skills beyond description changes and reference fixes
- Do NOT create a test runner framework -- shell scripts and markdown test files are sufficient
- Do NOT fix issues found during integration in this task -- file them as follow-up tasks if they are not blocking

## Commit

`feat: integration testing, description optimization, and superpowers cleanup`

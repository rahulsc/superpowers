# Task 16: `finishing-a-development-branch` Skill Evolution

**Specialist:** implementer-3
**Depends on:** Task 14 (verification must pass before finishing -- verification evidence checked by this skill), Task 4 (hooks enforce completion gates that this skill respects)
**Produces:** Finishing skill with state cleanup and knowledge promotion; consumed by execution skills (subagent-driven-development step 7, agent-team-driven-development phase 3) as their final handoff

## Goal

Evolve finishing to clean up `.forge/local/` state, tear down worktrees, and promote validated discoveries from local to shared.

## Acceptance Criteria

- [ ] All `.superpowers/` references replaced with `.forge/` state reads via `forge-state`
- [ ] After PR creation or local merge: clean up `.forge/local/` evidence and checkpoints for the completed task/feature (not a full wipe -- only entries related to the finished work)
- [ ] In team mode: tear down all implementer worktrees (from `forge-state get worktree.implementers.*`) in addition to the main worktree
- [ ] In solo mode: tear down the main worktree only (current behavior, unchanged)
- [ ] Knowledge promotion step added after merge/PR: scan `.forge/local/` for discoveries (memories of type `discovery` via `forge-memory query discovery`), present validated team-relevant ones to user, prompt to promote to `.forge/shared/` (architecture notes go to `shared/architecture.md`, conventions to `shared/conventions.md`, decisions to `shared/decisions/NNN-<topic>.md`)
- [ ] User can skip promotion ("none to promote" or explicit decline)
- [ ] State updated to mark phase as complete: `forge-state set phase complete`
- [ ] Verification check at entry: before presenting options, read `forge-state get verification.passed` -- if not `true`, block with "Cannot finish: verification not passed. Run forge:verification-before-completion first."
- [ ] Description updated to "Use when..." format per design doc Section 8
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] All four merge/PR/keep/discard options preserved from current implementation
- [ ] Skill stays under 500 lines / 5,000 words per design doc Section 8

## Test Expectations

- **Test:** Local state cleaned after finish. Discoveries promoted. Worktrees removed. Verification gate blocks when evidence missing.
- **Expected red failure:** After finishing, `.forge/local/` still contains evidence entries for the completed task (cleanup not triggered), or a validated discovery is not offered for promotion, or worktrees remain after team finish
- **Expected green:** `.forge/local/` evidence for the completed feature is cleaned. User is prompted about 1+ discovered conventions. Worktrees (all implementer worktrees in team mode, main worktree in solo mode) are removed. `forge-state get phase` returns `complete`.

## Files

- Modify: `skills/finishing-a-development-branch/SKILL.md` (sections: frontmatter description, add verification entry gate before Step 1, update Step 5 cleanup to include `.forge/local/` state cleanup, add new Step 6 knowledge promotion, update Team Context to use `forge-state` for worktree enumeration, update Integration section to `forge:` namespace, update all `superpowers:` references)
- Test: `tests/skills/finishing/state-cleanup.test.sh` (verify evidence entries removed for finished task after completion)
- Test: `tests/skills/finishing/knowledge-promotion.test.md` (triggering prompt test: validated discovery offered for promotion)

## Implementation Notes

**New step ordering:**
1. Verification gate (NEW) -- check `verification.passed` before proceeding
2. Verify tests (current Step 1)
3. Determine base branch (current Step 2)
4. Present options (current Step 3)
5. Execute choice (current Step 4)
6. Cleanup worktree (current Step 5, extended for team mode)
7. State cleanup (NEW) -- clean `.forge/local/` entries for finished feature
8. Knowledge promotion (NEW) -- scan discoveries, offer promotion
9. Mark phase complete (NEW) -- `forge-state set phase complete`

**State cleanup scope:**
Only clean entries related to the finished work. Use a feature/task identifier (from `forge-state get current.feature` or similar) to scope the cleanup. Do NOT wipe all of `.forge/local/` -- there may be other active features or persistent memories.

**Knowledge promotion flow:**
```
1. discoveries = forge-memory query discovery
2. Filter for validated entries (confidence >= 0.8 or explicitly marked validated)
3. Present each to user with proposed target:
   - Architecture insight -> shared/architecture.md
   - Convention learned -> shared/conventions.md
   - Decision made -> shared/decisions/NNN-<topic>.md
4. User approves/skips each one
5. Approved entries appended to target files
6. Promoted entries marked as promoted in local state
```

**Team mode worktree teardown:**
Current skill has a "Team Context" section that mentions shutting down specialists and cleaning per-agent worktrees. Evolve this to read worktree paths from `forge-state get worktree.implementers.*` and remove each one via `git worktree remove`. This replaces the manual enumeration approach.

**Verification gate:**
The hook system (Task 4) provides the strongest enforcement layer. This skill-level check is the medium (state-based) layer. Both check the same state key (`verification.passed`), providing defense in depth. The skill-level check gives a helpful error message; the hook-level check is the hard block.

**What stays the same:**
- The 4 options (merge, PR, keep, discard) -- proven UX pattern
- The confirmation flow for discard (typed "discard")
- The test verification before presenting options
- The base branch detection logic

**YAGNI:**
- Do NOT implement automatic discovery classification (user decides what is team-relevant)
- Do NOT implement discovery confidence scoring (simple validated/not-validated flag is sufficient for v0)
- Do NOT clean up `.forge/shared/` during finishing (shared knowledge persists across features)

## Commit

`feat(finishing): add state cleanup, knowledge promotion, verification gate`

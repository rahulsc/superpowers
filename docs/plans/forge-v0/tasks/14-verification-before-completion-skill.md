# Task 14: `verification-before-completion` Skill Evolution

**Specialist:** implementer-1
**Depends on:** Task 3 (risk tier determines evidence requirements), Task 4 (hooks enforce this skill's gates -- hook scripts call verification checks)
**Produces:** Verification skill wired into all completion paths with risk-tier-scaled evidence requirements; consumed by Task 11 (SDD invokes at task completion), Task 12 (ATDD invokes at task completion), and finishing-a-development-branch (final verification gate)

## Goal

Evolve verification-before-completion from an orphaned skill into the mandatory completion gate for all Forge workflows, with evidence requirements scaled to risk tier.

## Acceptance Criteria

- [ ] Reads risk tier from `.forge/` state via `forge-state get risk.tier` at invocation
- [ ] Evidence requirements scaled per tier:
  - Minimal: tests pass (command evidence only)
  - Standard: tests pass + build clean (command evidence for both)
  - Elevated: tests pass + build clean + all acceptance criteria met (command + citation evidence)
  - Critical: all above + rollback evidence + security review evidence (command + citation + diff evidence)
- [ ] Evidence checklist is dynamically generated based on risk tier (not a static list)
- [ ] Verification results written to `.forge/local/` via `forge-state set verification.result pass|fail` and `forge-evidence add verification <artifact>`
- [ ] State integration updated from `.superpowers/state.yml` to `forge-state get`/`set`
- [ ] All `superpowers:` references updated to `forge:` namespace
- [ ] Integration section updated to list all callers: SDD, ATDD, finishing-a-development-branch, hooks
- [ ] Explicit wiring instructions added: "This skill is invoked by execution skills at task completion and by hooks at commit/PR time. It is NOT optional."
- [ ] Evidence format table (Command/Citation/Diff) preserved -- this is the canonical definition other skills reference
- [ ] Re-review loop bound preserved (3 cycles then escalate)
- [ ] Rationalization prevention table preserved
- [ ] New section: "Risk-Tier Evidence Matrix" showing exactly what evidence is required per tier
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** Verification blocks completion when risk-tier evidence is incomplete; passes when all evidence for the tier is present
- **Expected red failure:** Verification passes (`verification.result: pass`) at critical tier when rollback evidence is missing (tier-specific evidence requirements not enforced -- critical tier treated same as minimal)
- **Expected green:** At minimal tier: passes with only test-pass command evidence. At standard tier: blocks if build evidence missing, passes with test + build evidence. At elevated tier: blocks if acceptance criteria citations missing. At critical tier: blocks if rollback evidence or security review evidence missing, passes only when complete evidence set provided.

## Files

- Modify: `skills/verification-before-completion/SKILL.md` (all sections -- overview, gate function, evidence format, state integration, new risk-tier matrix, integration section)
- No prompt templates to update (this skill has no subagent dispatch -- it is a gate, not a delegation)
- Test: `tests/skills/verification-before-completion/forge-evolution.test.md` (scenario tests: one per tier with incomplete and complete evidence sets)

## Implementation Notes

**Current state -- why "orphaned":**
The current skill is well-written but nothing actually references it in the workflow. SDD and ATDD mention evidence requirements inline but do not say "invoke forge:verification-before-completion." The hooks do not check verification state. The finishing skill does not gate on verification. This task wires it in by:
1. Updating the skill itself to be risk-tier-aware
2. Providing clear integration instructions that Tasks 11, 12, and the hooks (Task 4) use

**Risk-Tier Evidence Matrix (new section):**
```markdown
## Risk-Tier Evidence Matrix

| Evidence | Minimal | Standard | Elevated | Critical |
|----------|:-------:|:--------:|:--------:|:--------:|
| Tests pass (command) | Required | Required | Required | Required |
| Build clean (command) | - | Required | Required | Required |
| Acceptance criteria met (citation) | - | - | Required | Required |
| All requirements reviewed (citation) | - | - | Required | Required |
| Rollback plan tested (command) | - | - | - | Required |
| Security review passed (citation) | - | - | - | Required |
| RED/GREEN TDD evidence | - | - | Required | Required |
```

This matrix replaces the current static "Common Failures" table with a dynamic one that the skill uses to generate the checklist for each invocation.

**Gate function evolution:**
The current gate function is:
```
1. IDENTIFY what command proves this claim
2. RUN the command
3. READ output
4. VERIFY output confirms claim
5. ONLY THEN make the claim
```

This stays. The evolution adds a step 0:
```
0. LOAD risk tier from forge-state get risk.tier
   GENERATE evidence checklist for this tier (see matrix)
```

And step 4 becomes:
```
4. VERIFY: Does output confirm the claim?
   VERIFY: Is this evidence type required for this tier?
   VERIFY: Are all required evidence types for this tier present?
```

**State writes:**
```
forge-state set verification.last_run <timestamp>
forge-state set verification.task <task-number>
forge-state set verification.result pass|fail
forge-state set verification.tier <risk-tier>
forge-state set verification.missing_evidence [list]  # if fail
forge-evidence add verification-<task> <type> <content>
```

**Integration wiring:**
The "Integration" section needs to be specific about HOW callers invoke this skill:

- **SDD/ATDD (at task completion):** Before marking task complete, run the verification gate. If it fails, send back to implementer with the missing evidence list. The controller does NOT mark the task complete until verification passes.
- **Hooks (at commit/PR time):** Hook scripts check `forge-state get verification.result`. If not `pass`, block with exit code 2 and message: "Cannot complete: missing verification evidence for [risk-tier] tier. Missing: [list]."
- **Finishing skill (at branch completion):** Reads `verification.result` from state. If not `pass`, refuses to create PR/merge.

**What stays unchanged:**
- The Iron Law ("NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE")
- The evidence format definitions (Command/Citation/Diff) -- these are the canonical source other skills reference
- The rationalization prevention table
- The "When To Apply" section
- The "Key Patterns" section

**YAGNI:**
- Do NOT add evidence expiration (evidence from 10 minutes ago is still valid)
- Do NOT add partial verification passes (either all tier requirements met or fail)
- Do NOT implement automatic evidence collection (the skill is a gate, not a collector -- evidence is collected by execution skills, this skill verifies it exists)
- Do NOT add verification delegation to subagents (this is a synchronous check, not a dispatched review)

## Commit

`feat(verification-before-completion): add risk-tier-scaled evidence requirements and wire into workflow`

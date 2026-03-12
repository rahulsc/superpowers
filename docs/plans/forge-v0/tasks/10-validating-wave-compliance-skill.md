# Task 10: `validating-wave-compliance` Skill (NEW)

**Specialist:** implementer-3
**Depends on:** Task 5 (forge-routing routes to this), Task 9 (writing-plans produces the plan this validates against)
**Produces:** New validation skill for design/plan compliance checking between execution waves; consumed by Task 11 (SDD invokes between waves at elevated+) and Task 12 (ATDD invokes between waves at elevated+)

## Goal

Create a dedicated validation agent skill that checks code changes against the approved design and plan between execution waves, blocking progression when deviations are found.

## Acceptance Criteria

- [ ] New skill created at `skills/validating-wave-compliance/SKILL.md` with proper frontmatter
- [ ] Description follows "Use when..." format: "Use when an execution wave completes and changes need compliance checking against the approved design and plan before the next wave begins."
- [ ] Skill receives as input: design doc path, plan path, diff of wave's changes (git diff), test output from wave
- [ ] Performs four compliance checks:
  1. **Design compliance** -- do code changes match the approved design doc?
  2. **Plan compliance** -- does implementation match the planned approach for these tasks?
  3. **Integration check** -- do all tests pass after merging wave branches?
  4. **Convention compliance** -- does code follow `.forge/shared/conventions.md` (if it exists)?
- [ ] Produces a structured compliance report with pass/fail per check, specific deviations listed with file:line citations
- [ ] If any check fails: blocks next wave, writes `wave.N.compliance: failed` to state, lists deviations for implementers to fix
- [ ] If all checks pass: writes `wave.N.compliance: passed` to state, wave proceeds
- [ ] Convention compliance is optional (skip gracefully if `shared/conventions.md` does not exist)
- [ ] Validation agent prompt template created in `skills/validating-wave-compliance/validation-agent-prompt.md`
- [ ] Skill is invoked by execution skills (SDD/ATDD), not directly by users -- but can be invoked standalone for ad-hoc compliance checks
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** Validation catches a planted design deviation and passes when implementation matches design
- **Expected red failure:** Validation passes (returns `compliance: passed`) when a planted violation exists -- the design says "use PostgreSQL" but implementation uses SQLite (planted deviation not detected)
- **Expected green:** Planted deviations detected and listed with file:line citations in compliance report; compliant implementation receives `compliance: passed`; state updated correctly in both cases

## Files

- Create: `skills/validating-wave-compliance/SKILL.md`
- Create: `skills/validating-wave-compliance/validation-agent-prompt.md`
- Test: `tests/skills/validating-wave-compliance/compliance-detection.test.md` (pressure test with planted deviations)

## Implementation Notes

**Why a dedicated agent (design doc Section 4):**
A fresh agent reads the design/plan with no accumulated context bias from watching the implementation unfold. This parallels the spec-reviewer pattern but operates at the wave level rather than the task level. The validation agent can run as a lighter model (sonnet) since it is performing comparison, not creation.

**Skill structure:**
```markdown
---
name: validating-wave-compliance
description: Use when an execution wave completes and code changes need compliance checking against the approved design and plan before the next wave begins.
---

# Validating Wave Compliance

## Overview
Check code changes against design and plan between waves...

## Inputs
- Design doc path (from forge-state get design.path)
- Plan path (from forge-state get plan.path)
- Wave number
- Git diff of wave changes
- Test output from wave execution

## Compliance Checks
### 1. Design Compliance
### 2. Plan Compliance
### 3. Integration Check
### 4. Convention Compliance

## Output Format (Compliance Report)

## State Updates

## Integration
```

**Compliance check details:**

1. **Design compliance:** Read design doc, extract key decisions (architecture choices, technology selections, data models, API contracts). Compare against the wave's diff. Flag any code that contradicts a design decision. Example: design says "REST API" but code implements GraphQL.

2. **Plan compliance:** Read the task files for the completed wave. Compare the planned approach (files to create/modify, acceptance criteria) against what was actually implemented. Flag missing acceptance criteria or significant deviations from planned file structure.

3. **Integration check:** Verify that the test command exits 0 on the merged result. This is a simple pass/fail -- the test output is provided as input, the validator just confirms exit code 0 and no test failures.

4. **Convention compliance:** If `.forge/shared/conventions.md` exists, check that new code follows stated conventions (naming patterns, directory structure, import style). If the file does not exist, skip this check with a note in the report.

**Validation agent prompt template:**
The prompt template should be structured like the spec-reviewer prompt -- a subagent dispatch template that the execution skill (SDD/ATDD) uses to spawn the validation agent. Include the compliance report format so the agent's output is machine-parseable by the calling skill.

**Report format:**
```markdown
## Wave N Compliance Report

**Overall:** PASS | FAIL

### Design Compliance: PASS | FAIL
- [deviation description] -- [file:line]

### Plan Compliance: PASS | FAIL
- [deviation description] -- [file:line]

### Integration Check: PASS | FAIL
- Test command: [command]
- Exit code: [code]
- Failures: [count]

### Convention Compliance: PASS | SKIPPED | FAIL
- [deviation description] -- [file:line]
```

**State integration:**
```
forge-state set wave.N.compliance passed|failed
forge-state set wave.N.compliance_report <path-to-report>
```

**YAGNI:**
- Do NOT implement automatic deviation fixing (the validator reports, implementers fix)
- Do NOT add severity levels to deviations (all deviations block equally in v0)
- Do NOT add cross-wave trend analysis
- Do NOT implement the validator as a persistent agent (it runs fresh each time, like spec-reviewer)

## Commit

`feat(validating-wave-compliance): create design/plan compliance validation skill`

# Task 13: `test-driven-development` Skill Evolution

**Specialist:** implementer-3
**Depends on:** Task 3 (risk engine provides tier classification in `.forge/` state)
**Produces:** TDD skill that scales enforcement to risk tier; consumed by Task 11 (SDD implementers follow TDD), Task 12 (ATDD implementers follow TDD), and standalone invocation

## Goal

Evolve TDD to be optional at minimal/standard tiers and mandatory at elevated/critical tiers, with a clear distinction between standalone mode (always enforces) and embedded mode (respects tier).

## Acceptance Criteria

- [ ] Skill reads risk tier from `.forge/` state via `forge-state get risk.tier` at start
- [ ] Two operating modes defined:
  - **Standalone mode** (invoked directly by user or forge-routing): TDD is always enforced regardless of tier
  - **Embedded mode** (invoked by SDD/ATDD as part of task execution): enforcement scales to tier
- [ ] Embedded mode enforcement per tier:
  - Minimal: TDD is not enforced -- agent MAY skip TDD (but evidence of test passing is still required by verification-before-completion)
  - Standard: TDD is recommended but not enforced -- skill surfaces recommendation, agent decides
  - Elevated: TDD is mandatory -- Iron Law applies, RED/GREEN evidence required
  - Critical: TDD is mandatory -- Iron Law applies, RED/GREEN evidence required, additional edge case coverage expected
- [ ] Standalone mode: Iron Law always applies, all tiers treated as elevated+
- [ ] Mode detection: if risk tier is available in state AND the skill was invoked as a reference (not the primary skill), treat as embedded mode. Otherwise standalone.
- [ ] Updated "When to Use" section reflecting tier-based enforcement
- [ ] Updated "Common Rationalizations" table to include tier-aware entries (e.g., "I'm at minimal tier so I can skip" is valid in embedded mode, not in standalone)
- [ ] All `superpowers:` references updated to `forge:` namespace
- [ ] Plan-level test expectations section preserved (still mandatory for all tiers in plans)
- [ ] Execution-level evidence section updated to note that RED/GREEN evidence is mandatory at elevated+ and recommended at standard
- [ ] Pipelined TDD section preserved (applies when QA agent is in team roster, regardless of tier -- if TDD is happening, pipeline it)
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** TDD enforcement scales correctly per tier in embedded mode; standalone mode always enforces
- **Expected red failure:** TDD Iron Law enforced at minimal tier in embedded mode -- agent is blocked from writing code without a failing test first when it should be allowed to skip (enforcement too aggressive for minimal tier)
- **Expected green:** At minimal tier (embedded): agent can write code without failing test first (TDD recommended but not enforced). At elevated tier (embedded): agent blocked from writing code without failing test first (Iron Law enforced). At any tier (standalone): Iron Law always enforced. Plan-level test expectations remain mandatory at all tiers.

## Files

- Modify: `skills/test-driven-development/SKILL.md` (When to Use, Iron Law section, mode detection, tier-based enforcement, rationalizations table, evidence section, integration section)
- Modify: `skills/test-driven-development/testing-anti-patterns.md` (update `superpowers:` references to `forge:` if any)
- Test: `tests/skills/test-driven-development/forge-evolution.test.md` (scenario tests: embedded minimal skippable, embedded elevated enforced, standalone always enforced)

## Implementation Notes

**Mode detection logic:**
The TDD skill does not have explicit invocation metadata telling it "you are embedded." Instead, it infers mode from context:
- If `forge-state get risk.tier` returns a value AND the agent's current task context indicates it was invoked as a sub-skill reference (the SDD/ATDD controller told the implementer to "follow forge:test-driven-development"), treat as embedded mode.
- If invoked directly (user says "use TDD" or forge-routing activates it as the primary skill), treat as standalone mode.
- If no risk tier in state: treat as standalone mode (no Forge context, enforce everything).

In practice, this means the skill text needs conditional language:
```
IF you are implementing a task assigned by a controller (SDD/ATDD):
  Read risk tier from state. At minimal/standard, TDD is recommended but not required.
  At elevated/critical, TDD is mandatory.

IF you are working independently or TDD was invoked as your primary skill:
  TDD is always mandatory. The Iron Law applies.
```

**What stays the same:**
- The Red-Green-Refactor cycle description
- The "Good Tests" quality criteria
- The verification checklist
- The debugging integration section
- The pipelined TDD section
- The testing anti-patterns reference
- Plan-level test expectations (always mandatory -- plans must specify what to test)

**What changes:**
- "When to Use" section: add tier-aware language alongside the current "Always" list
- "The Iron Law" section: add a conditional preamble about embedded vs standalone mode BEFORE the iron law text (the iron law itself stays, but its applicability is scoped)
- "Common Rationalizations" table: add entry for "I'm at minimal tier, I can skip" with nuanced response (valid in embedded, not in standalone)
- Evidence section: RED/GREEN evidence mandatory at elevated+, recommended at standard, not required at minimal (but test-pass evidence is always required by verification-before-completion)
- Integration section: update all `superpowers:` to `forge:` namespace

**Key nuance -- test expectations vs TDD enforcement:**
These are different things:
- **Plan-level test expectations** (what to test, expected failures) are mandatory at ALL tiers. Every task in every plan must specify what to test. This is the writing-plans skill's responsibility.
- **TDD enforcement** (write test first, watch fail, then implement) is what scales by tier. At minimal, you can write code first and add tests after. At elevated, you must write the test first.

This distinction prevents confusion: even at minimal tier, tests must exist (verification-before-completion requires test evidence), but the ORDER of writing test vs code is relaxed.

**Anti-patterns file:**
The testing-anti-patterns.md file has no `superpowers:` references currently. Only update if references are found. The anti-patterns themselves are tier-independent (they are always bad regardless of risk level).

**YAGNI:**
- Do NOT add tier-specific test coverage thresholds (e.g., "critical requires 90% coverage")
- Do NOT add automatic test generation
- Do NOT change the pipelined TDD mechanism (it works at the team level, not the TDD skill level)
- Do NOT add a "strict mode" flag -- the tier-based scaling IS the strictness control

## Commit

`feat(test-driven-development): add risk-tier-scaled enforcement with standalone and embedded modes`

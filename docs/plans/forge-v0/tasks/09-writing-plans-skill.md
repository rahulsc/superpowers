# Task 9: `writing-plans` Skill Evolution

**Specialist:** implementer-2
**Depends on:** Task 5 (forge-routing), Task 6 (setting-up-project must have run before this -- provides risk tier, worktree, optional team roster in state)
**Produces:** Enhanced writing-plans skill with risk-tier-scaled plan detail and team-aware wave analysis; consumed by Task 11 (SDD), Task 12 (ATDD), and Task 10 (wave validation references plan output)

## Goal

Evolve writing-plans to scale plan detail based on risk tier and produce team-aware wave analysis when a team roster exists in `.forge/` state.

## Acceptance Criteria

- [ ] Verification gate reads from `.forge/` state via `forge-state get` instead of `.superpowers/state.yml`
- [ ] Gate checks: `design.approved == true`, `project.worktree.path` accessible, risk tier present in state
- [ ] Risk-tier scaling implemented:
  - Minimal: skip planning entirely (inline plan or single-sentence "just do it" with test expectations) -- surface recommendation to user
  - Standard: short plan (plan.md only, no task files directory), test expectations still mandatory
  - Elevated: full plan with task files, wave analysis if team roster exists
  - Critical: full plan with task files, wave analysis, risk register section, rollback planning section
- [ ] Team awareness: when `team.roster` exists in state, automatically include wave analysis, specialist assignments, and dependency graph in plan
- [ ] When `team.roster` does NOT exist, no wave analysis generated (solo execution assumed)
- [ ] "For Claude" header references correct execution skill: `forge:subagent-driven-development` (solo) or `forge:agent-team-driven-development` (team) based on team fitness + roster
- [ ] All `superpowers:` references updated to `forge:` namespace
- [ ] State writes use `forge-state set` for `plan.path`, `plan.status`, `plan.executor`, `plan.total_tasks`, `plan.risk_tier`
- [ ] Plan review loop preserved (dispatch plan-document-reviewer, iterate)
- [ ] Execution handoff updated: presents options based on what setting-up-project configured (team vs solo), then invokes chosen execution skill
- [ ] Plan frontmatter includes `risk_tier:` field alongside existing `status:` field
- [ ] Skill stays under 500 lines / 5,000 words

## Test Expectations

- **Test:** Plan scales correctly to each risk tier; team roster triggers wave analysis; no wave analysis without roster
- **Expected red failure:** Plan has no wave analysis section despite `team.roster` existing in `.forge/` state (team awareness not yet implemented)
- **Expected green:** Minimal tier produces inline plan or skip recommendation; standard tier produces plan.md without tasks/ directory; elevated tier with team roster produces full plan with wave analysis; elevated tier without roster produces full plan without wave analysis

## Files

- Modify: `skills/writing-plans/SKILL.md` (verification gate, save location, plan document structure, wave analysis trigger, execution handoff, integration section)
- Modify: `skills/writing-plans/plan-document-reviewer-prompt.md` (update `superpowers:` references to `forge:`; add risk-tier-appropriate review criteria)
- Test: `tests/skills/writing-plans/forge-evolution.test.md` (scenario tests: one per tier x roster combination)

## Implementation Notes

**Verification gate changes:**
Replace the current `.superpowers/state.yml` check block with `forge-state get` calls:
```
REQUIRED:
  forge-state get design.approved == true
  forge-state get project.worktree.path is accessible
  forge-state get risk.tier is set

IF team plan:
  forge-state get team.roster exists
```

**Risk-tier plan scaling logic:**
The key insight is that risk tier determines plan *detail*, not plan *existence*. Even minimal-tier work benefits from knowing what to test. The scaling is:

| Tier | Plan format | Task files? | Wave analysis? | Risk register? |
|------|-------------|-------------|----------------|----------------|
| Minimal | Inline (embedded in state or single paragraph) | No | No | No |
| Standard | plan.md only | No | No | No |
| Elevated | plan.md + tasks/ | If team roster | No | No |
| Critical | plan.md + tasks/ | Always | If team roster | Yes |

At minimal tier, the skill should suggest to the user: "This is minimal-risk work. I recommend skipping the formal plan and proceeding directly to execution with just test expectations. Agree?" If user agrees, write minimal state and hand off. If user wants a plan anyway, write a short one.

**Team awareness trigger:**
The current skill already has a "Wave Analysis (Team Plans Only)" section and a "Team Fitness Check." The evolution is:
1. Team fitness check is no longer done here -- setting-up-project already decided team vs solo and populated `team.roster` in state.
2. If `team.roster` exists in state, include wave analysis automatically.
3. If no roster, skip wave analysis and use serial task list.
4. The "Team Fitness Check" section should be replaced with a simpler conditional: "If team.roster exists in state, this is a team plan. Include wave analysis."

**Execution handoff changes:**
Replace the current generic two-option handoff with a context-aware one:
- If team roster exists: default to `forge:agent-team-driven-development`, offer `forge:subagent-driven-development` as alternative
- If no roster: default to `forge:subagent-driven-development`
- Remove `executing-plans` fallback (being dropped per design doc Section 8)
- Remove `superpowers:executing-plans` references entirely

**Plan document reviewer update:**
The reviewer should be aware of risk tier. At elevated/critical, review more strictly (check for risk register at critical, check wave analysis completeness). At standard, review for completeness only. At minimal, no review needed (plan is too short to warrant one).

**YAGNI:**
- Do NOT implement the plan-document-reviewer as a separate forge skill (it stays as a subagent prompt template)
- Do NOT add automatic plan approval (user still approves)
- Do NOT change the plan.md file format beyond adding `risk_tier:` to frontmatter

## Commit

`feat(writing-plans): add risk-tier scaling and team-aware wave analysis`

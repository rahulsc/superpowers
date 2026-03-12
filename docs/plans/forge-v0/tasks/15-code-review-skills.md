# Task 15: `requesting-code-review` and `receiving-code-review` Skill Evolution

**Specialist:** implementer-2
**Depends on:** Task 3 (risk tier available via `forge-state get risk.tier`), Task 11/12 (execution skills dispatch reviews and produce evidence that feeds into review context)
**Produces:** Team-aware, risk-aware code review skills consumed by execution skills (subagent-driven-development, agent-team-driven-development) and finishing-a-development-branch (which requires review evidence at elevated+ tiers)

## Goal

Evolve both review skills to dispatch specialist reviewers based on risk tier and support team mode with dedicated reviewer agents.

## Acceptance Criteria

- [ ] `requesting-code-review`: at critical tier, dispatch `security-reviewer` agent in addition to `code-reviewer` for files matching auth/payment/migration policy rules
- [ ] `requesting-code-review`: at elevated+ tiers, review is mandatory (not "optional but valuable") -- remove the optional framing for elevated and critical
- [ ] `requesting-code-review`: in team mode, use dedicated reviewer agent from team roster (not an implementer doing double duty) when roster includes a reviewer-tier agent
- [ ] `requesting-code-review`: read risk tier from `.forge/` state via `forge-state get risk.tier` to determine review ceremony level
- [ ] `requesting-code-review`: read team roster from `.forge/` state via `forge-state get team.roster` to determine reviewer dispatch strategy
- [ ] `requesting-code-review`: reviewer dispatch table added mapping tier to reviewer requirements (minimal: none, standard: optional code-reviewer, elevated: mandatory code-reviewer, critical: mandatory code-reviewer + security-reviewer)
- [ ] `requesting-code-review`: all `superpowers:` skill references updated to `forge:` namespace
- [ ] `requesting-code-review`: description updated to "Use when..." format per design doc Section 8
- [ ] `requesting-code-review`: code-reviewer.md template unchanged (it is agent-facing, not tier-aware -- the dispatching logic lives in SKILL.md)
- [ ] `receiving-code-review`: all `superpowers:` references updated to `forge:` (light touch -- no structural changes needed)
- [ ] `receiving-code-review`: duplicate "From Team Peers" section removed (lines 125-132 duplicate lines 117-124 in current file)
- [ ] `receiving-code-review`: description updated to "Use when..." format per design doc Section 8
- [ ] Both skills stay under 500 lines / 5,000 words per design doc Section 8

## Test Expectations

- **Test:** Specialist reviewer dispatched at critical tier for auth changes; standard reviewer only at elevated; no reviewer required at minimal
- **Expected red failure:** Simulated auth-touching task at critical tier dispatches only `code-reviewer` (no security reviewer) -- missing specialist dispatch
- **Expected green:** Critical auth task dispatches both `code-reviewer` and `security-reviewer`. Elevated task dispatches `code-reviewer` only. Minimal task makes review optional. Team mode uses roster's dedicated reviewer agent instead of default `code-reviewer`.

## Files

- Modify: `skills/requesting-code-review/SKILL.md` (sections: frontmatter description, "When to Request Review" to add tier-based mandatory/optional table, "How to Request" to add tier-aware dispatch logic, "Team-Aware Review" to use roster lookup, "Security Review Tier" to integrate with risk engine instead of ad-hoc detection, "Integration" to update namespace, remove `superpowers:` references throughout)
- Modify: `skills/requesting-code-review/code-reviewer.md` (minimal: update any `superpowers:` references if present -- currently none exist, so likely no changes)
- Modify: `skills/receiving-code-review/SKILL.md` (sections: frontmatter description, remove duplicate "From Team Peers" block, update `superpowers:` to `forge:` throughout, update Integration section)
- Test: `tests/skills/code-review/tier-dispatch.test.md` (triggering prompt test: critical auth change triggers security reviewer)
- Test: `tests/skills/code-review/team-mode-reviewer.test.md` (triggering prompt test: team roster reviewer used instead of default)

## Implementation Notes

**Risk-tier reviewer dispatch table** (new content for requesting-code-review):

| Tier | Code Review | Security Review | Required? |
|------|------------|----------------|-----------|
| Minimal | - | - | Not required |
| Standard | code-reviewer | - | Optional |
| Elevated | code-reviewer | - | Mandatory |
| Critical | code-reviewer | security-reviewer | Mandatory |

This replaces the current ad-hoc "Security Review Tier" section, which says "For tasks touching auth, payment, or sensitive data: after standard code quality review, add a security-focused review pass." The new version reads the risk tier from state and dispatches based on the table, rather than relying on the agent to manually detect auth/payment files.

**Team mode reviewer dispatch:**
Current skill says "When a team roster includes reviewer agents, use those agent definitions for review dispatch." This is correct but needs to be more specific: read `forge-state get team.roster`, parse for agents in the "Reviewers" tier (from composing-teams), and use those for dispatch. If no dedicated reviewer is on the roster, fall back to default `code-reviewer`.

**What NOT to change in code-reviewer.md:**
The code-reviewer template is agent-facing instructions, not caller-facing routing logic. Tier awareness belongs in SKILL.md (which decides who to dispatch), not in the template (which tells the dispatched agent how to review). Keep the template stable.

**Duplicate section fix:**
`receiving-code-review` has "From Team Peers" duplicated at lines 117-132. Remove the second copy (lines 125-132). This is a bug in the current file, not a Forge change, but clean it up while evolving the skill.

**YAGNI:**
- Do NOT add re-review loop changes (the current 3-cycle bound is correct)
- Do NOT add evidence writing to review skills (evidence capture is the execution skill's responsibility)
- Do NOT add risk classification logic (read the tier, do not compute it)

## Commit

`feat(code-review): add risk-tier dispatch, team-aware reviewer routing`

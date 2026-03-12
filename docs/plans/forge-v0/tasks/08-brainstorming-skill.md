# Task 8: `brainstorming` Skill Evolution

**Specialist:** implementer-1
**Depends on:** Task 5 (forge-routing routes to this), Task 6 (setting-up-project takes over setup duties)
**Produces:** Stripped-down brainstorming skill focused solely on design exploration; consumed by setting-up-project (which reads design output) and writing-plans (which reads design doc)

## Goal

Refactor brainstorming to focus only on exploring ideas and producing a design doc -- remove worktree creation, team composition, and state setup (moved to setting-up-project).

## Acceptance Criteria

- [ ] Steps 1-6 preserved: explore context, offer visual companion, challenge assumptions, clarify, propose approaches, present design
- [ ] Step 7 (write design doc) preserved but path updated: writes to `docs/<project>/design/design.md` (same as current -- backward compatible with writing-plans)
- [ ] Design review loop (dispatch design-document-reviewer, iterate) preserved
- [ ] User review gate preserved (ask user to review written spec before proceeding)
- [ ] Step 10 (create worktree) removed entirely -- no call to `using-git-worktrees`
- [ ] Step 11 (compose team? decision framework) removed entirely -- no call to `composing-teams`
- [ ] State writes use `.forge/` instead of `.superpowers/`: writes `design.approved`, `design.path`, `design.approved_at` via `forge-state set`
- [ ] No `worktree.main.path` written by this skill (moved to setting-up-project)
- [ ] After user approves spec, hand off to `forge:setting-up-project` instead of directly to `writing-plans`
- [ ] Description updated to "Use when..." format per Anthropic best practices (design doc Section 8)
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Process flow diagram updated to remove worktree and team composition nodes
- [ ] Checklist renumbered to reflect removed steps (should be 7-9 items, not 11)
- [ ] Skill stays under 500 lines / 5,000 words (design doc Section 8)

## Test Expectations

- **Test:** Brainstorming produces design doc at expected path and writes state, but does NOT create a worktree or compose a team
- **Expected red failure:** After brainstorming completes, `forge-state get worktree.main.path` returns a value (worktree creation still happens -- unwanted side effect persists)
- **Expected green:** Design doc exists at `docs/<project>/design/design.md`, `forge-state get design.approved` returns `true`, `forge-state get worktree.main.path` returns empty/null, no `composing-teams` invocation in skill text

## Files

- Modify: `skills/brainstorming/SKILL.md` (all sections -- description frontmatter, checklist, process flow, "After the Design" section, integration section)
- Modify: `skills/brainstorming/design-document-reviewer-prompt.md` (update `superpowers:` references to `forge:` if any; update design path references)
- No new files created
- Test: `tests/skills/brainstorming/forge-evolution.test.md` (triggering prompt test: verify design-only output, no worktree side effects)

## Implementation Notes

**What to keep (steps 1-6 + review + user gate):**
The core brainstorming flow is excellent and should be preserved almost verbatim. The explore-challenge-clarify-propose-present cycle, the visual companion offer, the design review loop, and the user review gate all stay.

**What to remove:**
- The entire "Worktree" subsection under "After the Design" (step 10)
- The entire "Team decision" subsection including the criterion table and QA agent recommendation (step 11)
- The process flow nodes: "Create worktree", "4+ tasks AND 2+ independent AND 2+ specialist domains?", "Invoke composing-teams"
- References to `superpowers:using-git-worktrees` and `superpowers:composing-teams` in the Integration section

**What to change:**
- Description frontmatter: change from "You MUST use this before any creative work..." to "Use when exploring ideas, requirements, and design before implementation -- for any creative work including features, components, or behavior changes."
- State writes: replace `.superpowers/state.yml` with `forge-state set` calls (the forge-state helper abstracts the backend)
- Handoff: after user approves spec, invoke `forge:setting-up-project` (not writing-plans directly). Setting-up-project handles worktree, risk classification, team decision, then routes to writing-plans.
- Integration section: "After this skill" becomes `forge:setting-up-project` only. Remove direct references to writing-plans, composing-teams, and using-git-worktrees as "after" skills.
- The pipelined TDD recommendation currently in the design presentation step (step 6) can stay -- it is design content the brainstorming skill surfaces to the user, not an execution concern.

**Design doc path decision:**
Keep `docs/<project>/design/design.md` as the canonical output location. This is where writing-plans expects it (reads `design.path` from state). The `.forge/shared/designs/` directory from the design doc is for team-curated knowledge that survives beyond a single feature -- the brainstorming output is per-project and belongs in the project directory. The state key `design.path` serves as the cross-skill reference.

**YAGNI:**
- Do NOT add risk-tier awareness to brainstorming (that is setting-up-project's job)
- Do NOT add `.forge/` directory creation (that is adopting-forge's job)
- Do NOT add any state initialization beyond design.* keys

## Commit

`feat(brainstorming): strip setup duties, focus on design exploration only`

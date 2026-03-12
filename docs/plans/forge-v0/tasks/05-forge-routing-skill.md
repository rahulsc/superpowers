# Task 5: `forge-routing` Skill

**Specialist:** implementer-1
**Depends on:** Task 3 (risk engine for tier-aware routing), Task 4 (hooks for SessionStart integration that injects this skill)
**Produces:** The `forge-routing` skill that replaces `using-superpowers` as the meta-router and establishes Forge identity

## Goal

Create the Forge identity and routing engine that detects task intent, classifies risk, and routes to the appropriate workflow phase -- replacing `using-superpowers` as the entry-point skill.

## Acceptance Criteria

- [ ] Skill description starts with `Use when` per Anthropic best practices and describes triggering conditions only -- never summarizes the workflow
- [ ] Skill establishes Forge identity: the LLM knows it is operating in Forge mode, not raw Superpowers
- [ ] Skill maintains the "invoke skills BEFORE any response" discipline from `using-superpowers`
- [ ] Task intent detection covers: new feature, bug fix, refactor, adoption (`forge adopt`), diagnosis, and sync requests
- [ ] Routing table maps intents to skills: feature -> brainstorming, bug fix -> systematic-debugging, refactor -> brainstorming (with refactor framing), adopt -> adopting-forge, diagnose -> diagnosing-forge, sync -> syncing-forge
- [ ] Risk-aware routing: elevated+ features route through the full pipeline (brainstorming -> setting-up-project -> writing-plans -> execution). Minimal tasks can skip design and go directly to execution.
- [ ] Instruction priority is preserved: user instructions (CLAUDE.md) > Forge skills > default system prompt
- [ ] Skill includes red flags / rationalization prevention table (carried forward and updated from `using-superpowers`)
- [ ] Skill references are updated: `forge:` prefix instead of `superpowers:` for all skill invocations
- [ ] Skill stays under 500 lines / 5,000 words per design Section 8 sizing constraint
- [ ] Subagent-stop directive is preserved: subagents spawned for specific tasks skip the router
- [ ] Team-aware skills section is updated to reference Forge skill names

## Test Expectations

- **Test:** Router detects task intent correctly and routes to the right skill. Router falls back gracefully when no skill matches. Risk tier influences routing decisions.
- **Expected red failure:** Router returns no skill match for "Build a user authentication system" (should route to brainstorming). Router returns wrong skill for "Fix the null pointer in auth.js" (should route to systematic-debugging, not brainstorming).
- **Expected green:** "Build a payment system" -> brainstorming. "Fix crash on login" -> systematic-debugging. "Adopt Forge for this repo" -> adopting-forge. "Refactor the data layer" -> brainstorming (refactor framing). Minimal-risk "Fix typo in README" -> direct execution (skip design).

## Files

- Create: `skills/forge-routing/SKILL.md`
- Test: `tests/skill-triggering/forge-routing-prompts/` (directory with intent-specific prompt files)
- Test: `tests/skill-triggering/test-forge-routing.sh`

## Implementation Notes

**Design reference:** Section 8 of `docs/plans/forge-v0/design.md` -- skill architecture, description convention, skill sizing.

**What to carry forward from `using-superpowers` (read `skills/using-superpowers/SKILL.md`):**
- The "invoke skills BEFORE any response" discipline -- this is core and must be preserved
- Instruction priority hierarchy (user > skills > system prompt)
- Red flags / rationalization prevention table
- Skill access instructions (Skill tool in Claude Code, activate_skill in Gemini)
- Platform adaptation note (Codex tool equivalents)
- Subagent context section (subagents don't auto-receive framework)
- The `<EXTREMELY-IMPORTANT>` emphasis on skill invocation
- The stuck-state check

**What changes from `using-superpowers`:**
- Branding: "Forge" not "Superpowers" throughout
- Skill prefix: `forge:` not `superpowers:` in all invocations
- Routing is risk-aware: detect risk tier (via classify-risk or heuristic) before routing
- Routing table is explicit: intent -> skill mapping with tier-based fast paths
- Team support references updated to Forge skill names
- Process flow diagram updated to show Forge phases (design -> setup -> plan -> execute -> verify -> review -> finish)
- `EnterPlanMode` note updated: Forge handles planning through brainstorming -> setting-up-project -> writing-plans

**Routing decision flow:**
```
1. Detect intent: feature | bugfix | refactor | adopt | diagnose | sync | unknown
2. If adopt/diagnose/sync: route directly to the adoption skill
3. If bugfix: route to systematic-debugging
4. If feature/refactor:
   a. Quick risk check (file patterns, description keywords)
   b. If minimal risk: suggest direct execution (skip brainstorming)
   c. If standard+: route to brainstorming
5. If unknown: ask user to clarify before routing
```

**Skill invocation format for Forge:**
```
"Using forge:brainstorming to explore the design before implementing."
"Using forge:systematic-debugging to investigate the reported issue."
"Using forge:adopting-forge to set up Forge for this repository."
```

**YAGNI notes:**
- Do NOT implement workflow orchestration logic -- this skill routes to the FIRST skill in the chain; each skill hands off to the next.
- Do NOT embed risk classification logic -- invoke `classify-risk` or signal to the LLM to assess.
- Do NOT duplicate skill content -- reference skills by name, don't inline their instructions.
- Do NOT remove `skills/using-superpowers/` yet -- that happens in Task 21 (integration cleanup). Both must coexist during development.

## Commit

`feat: add forge-routing skill as Forge identity and meta-router`

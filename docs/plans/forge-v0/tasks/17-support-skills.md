# Task 17: Support Skills Evolution (debugging, worktrees, teams, writing-skills)

**Specialist:** implementer-1
**Depends on:** Task 1 (`.forge/` directory structure for path references), Task 3 (risk engine for debugging ceremony scaling)
**Produces:** Four support skills updated for Forge, consumed by execution skills (which invoke worktrees, teams, debugging) and by skill authors (writing-skills)

## Goal

Update systematic-debugging, using-git-worktrees, composing-teams, and writing-skills with Forge references and minor enhancements.

## Acceptance Criteria

### systematic-debugging
- [ ] All `.superpowers/state.yml` references replaced with `forge-state` calls
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Risk tier integration: read `forge-state get risk.tier` -- elevated+ bugs require documented root cause written to `.forge/local/` via `forge-memory add discovery "<root-cause-description>"`
- [ ] Debugging state persistence updated: replace `.superpowers/state.yml` `debug:` block with `forge-state set debug.<key> <value>` calls
- [ ] Duplicate "Team Context" section removed (lines 348-358 duplicate lines 336-346 in current file)
- [ ] `dispatching-parallel-agents` reference in parallel hypothesis section replaced with `forge:composing-teams` or Task tool dispatch (since dispatching-parallel-agents is being removed)
- [ ] Description preserved (current description is already good "Use when..." format)

### using-git-worktrees
- [ ] All `.superpowers/state.yml` references replaced with `forge-state` calls: `forge-state set worktree.main.path <path>`, `forge-state set worktree.main.branch <branch>`, etc.
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Worktree paths recorded via `forge-state set worktree.*` instead of writing YAML directly
- [ ] "Record in state.yml" subsection (Step 4) rewritten to use `forge-state set` commands
- [ ] State key names preserved for compatibility: `worktree.main.path`, `worktree.main.branch`, `worktree.main.repo_root`, `worktree.implementers.<role>.*`

### composing-teams
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Team roster written to `.forge/` state via `forge-state set team.roster.<role> <agent-def>` instead of only writing to design doc
- [ ] Agent discovery scan paths updated: `.claude/agents/` remains, but shipped defaults reference Forge `agents/` directory
- [ ] "Invoke superpowers:writing-plans" reference updated to `forge:writing-plans`
- [ ] Integration section updated: "Before this skill" becomes `forge:brainstorming` or `forge:setting-up-project`

### writing-skills
- [ ] All `superpowers:` skill references updated to `forge:` namespace
- [ ] Pack authoring guidance added: new section "Writing Skills for Packs" explaining how skills in packs differ (pack.yaml registration, `source: pack/<name>` annotation, pack skill namespace)
- [ ] Forge naming conventions referenced: skill names use `forge:` prefix in cross-references (not `superpowers:`)
- [ ] Description convention section updated to match design doc Section 8 ("All descriptions start with 'Use when...'")
- [ ] Personal skill directory paths updated: add note that Forge pack skills go in `forge-pack-<name>/skills/`

### All four skills
- [ ] Zero remaining `superpowers:` references in any of the four files
- [ ] Zero remaining `.superpowers/` path references in any of the four files
- [ ] Each skill stays under 500 lines / 5,000 words per design doc Section 8

## Test Expectations

- **Test:** All four skills reference `.forge/` not `.superpowers/`. Debugging writes discoveries to `.forge/local/`. Worktree state recorded via forge-state. Team roster in forge state.
- **Expected red failure:** `grep -r "superpowers" skills/systematic-debugging/SKILL.md skills/using-git-worktrees/SKILL.md skills/composing-teams/SKILL.md skills/writing-skills/SKILL.md` returns matches (old references still present)
- **Expected green:** Zero `superpowers` matches in all four files. `forge-memory query discovery` returns debugging root cause entries after elevated+ debugging session. `forge-state get worktree.main.path` returns correct path after worktree creation. `forge-state get team.roster` returns roster after team composition.

## Files

- Modify: `skills/systematic-debugging/SKILL.md` (sections: frontmatter description check, State Persistence section, Parallel Hypothesis section, Team Context duplicate removal, all `superpowers:` references, add risk-tier ceremony note to Phase 4)
- Modify: `skills/using-git-worktrees/SKILL.md` (sections: "Record in state.yml" Step 4, "Report Location" Step 5, Team Mode state writes, Optional Skip state write, Integration section, all `superpowers:` references)
- Modify: `skills/composing-teams/SKILL.md` (sections: discovery scan paths, Output Team Roster step to also write state, Route to Planning step, Integration section, all `superpowers:` references)
- Modify: `skills/writing-skills/SKILL.md` (sections: add "Writing Skills for Packs" after "File Organization", update cross-reference examples to `forge:`, update CSO section examples, all `superpowers:` references)
- Test: `tests/skills/support/no-superpowers-references.sh` (grep all four files for `superpowers`, expect zero matches)
- Test: `tests/skills/debugging/forge-state-integration.test.md` (triggering prompt: elevated bug writes root cause discovery)

## Implementation Notes

**Scope control:** These are primarily reference updates (find-and-replace `superpowers:` with `forge:`, `.superpowers/state.yml` with `forge-state` calls) plus three targeted enhancements:
1. Debugging risk-tier ceremony (read tier, require root cause doc at elevated+)
2. Composing-teams writing roster to forge state (in addition to design doc)
3. Writing-skills pack authoring section (new content, ~50-80 lines)

**systematic-debugging specifics:**
- The "State Persistence (Cross-Session Debugging)" section currently writes a `debug:` YAML block to `.superpowers/state.yml`. Replace with equivalent `forge-state set` calls: `forge-state set debug.issue "..."`, `forge-state set debug.phase 2`, etc.
- The risk-tier note goes in Phase 4 (Implementation): "At elevated+ tiers, write root cause to `.forge/local/` via `forge-memory add discovery 'Root cause: <description>'` before implementing the fix. This discovery may be promoted to `shared/` during finishing."
- The duplicate Team Context at lines 348-358 is identical to lines 336-346. Remove the second copy.
- Replace `superpowers:dispatching-parallel-agents` reference with a note about using Task tool dispatch for parallel hypothesis testing, since that skill is being removed (Task 21 cleanup).

**using-git-worktrees specifics:**
- Replace direct YAML write instructions with `forge-state set` calls. The state key structure (`worktree.main.path`, `worktree.main.branch`, `worktree.main.repo_root`) stays the same -- only the write mechanism changes.
- The "Optional Skip" section currently writes `worktree: null` to state.yml. Replace with `forge-state set worktree.skipped true`.

**composing-teams specifics:**
- Currently writes team roster only to the design doc table. Add a parallel write to forge state: after building the roster table, also run `forge-state set team.roster.<instance-name> <agent-definition>` for each member. This lets downstream skills (requesting-code-review, agent-team-driven-development) read the roster from state without parsing the design doc.

**writing-skills pack authoring section:**
New section covering:
- Pack skill structure: `forge-pack-<name>/skills/<skill-name>/SKILL.md`
- Pack manifest registration: skill listed in `pack.yaml` `provides.skills` array
- Namespace: pack skills use `forge:<pack-name>:<skill-name>` when cross-referenced
- Policy annotation: pack skills that add policies must include `source: pack/<name>` annotation
- Testing: pack skills tested the same way (RED-GREEN-REFACTOR) but tested against the pack install flow

**YAGNI:**
- Do NOT rewrite the core debugging process (four phases are proven)
- Do NOT add worktree management commands to forge-state (worktree lifecycle stays in git)
- Do NOT add team communication protocols to composing-teams (that is agent-team-driven-development's concern)
- Do NOT add pack dependency resolution to writing-skills (post-v0)

## Commit

`feat(support-skills): update debugging, worktrees, teams, writing-skills for Forge`

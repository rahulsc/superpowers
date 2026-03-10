# Upstream Rebase onto v5.0.1 — Design

**Date:** 2026-03-10
**Status:** Pending approval

## Context

Our fork (rahulsc/Superpowers) is 68 commits ahead and 27 commits behind obra/superpowers upstream. We rebase our changes on top of upstream so we can contribute back. This is the second rebase; the first produced the `6_0_0_upstream_rebase` branch.

## Upstream Changes (27 commits since merge base `33e55e6`)

Upstream released v5.0.1 with:

- **Gemini CLI extension** — `GEMINI.md`, `gemini-extension.json`, `references/gemini-tools.md`
- **Brainstorming** — spec review loop added to checklist/flow (+21/-21 lines), visual companion scripts moved into skill dir, bundled node_modules
- **using-superpowers** — minor text tweaks, Gemini reference (+8/-8 lines)
- **Hooks** — `session-start` double-quote fix for Windows/Linux (GH-585)
- **Infrastructure** — removed `lib/skills-core.js` (208 lines), plugin.json version bumps
- **Tests** — brainstorm server test fix, removed skills-core tests
- **Docs** — README Gemini/Cursor install updates, `RELEASE-NOTES.md` added

## Our Commits (68 ahead)

All additions on top of upstream's base:
- Agent team support, agent definitions (architect, implementer, qa-engineer, security-reviewer)
- composing-teams skill
- Skills audit (phases 1-3): evidence gates, state management, pipelined TDD, worktree rework
- Test infrastructure (pressure tests, workflow chains, E2E)
- Research docs (upstream issues/PRs/forks analysis)
- Version bumps through v6.0.0

## Conflict Assessment

Expected conflicts in 2-3 files where both sides touched:
- `skills/brainstorming/SKILL.md` — both modified (spec review loop upstream, our audit changes)
- `skills/using-superpowers/SKILL.md` — both modified (Gemini ref upstream, our audit changes)
- `hooks/session-start` — possible (upstream quote fix, our bash compat fix)

Most of our 68 commits touch files upstream didn't change (agent definitions, new skills, docs, tests), so they should replay cleanly.

## Approach

### Step 1: Safety branch
```
git branch 6_0_0_pre_rebase_v5.0.1 main
```
Preserves current main in case anything goes wrong.

### Step 2: Create rebase branch and rebase
```
git checkout -b 7_0_0_upstream_rebase main
git rebase upstream/main
```
Resolve conflicts as they arise. For each conflict:
- Keep our additions layered on top of upstream's changes
- Accept upstream's structural changes where they don't conflict with our additions
- For brainstorming/using-superpowers: integrate upstream's new content into our richer version

### Step 3: Rewrite commit messages to suppress GitHub backlinking
During the rebase, rewrite all commit messages that contain bare `#NNN` issue references to use `obra superpowers GH-NNN` format instead. These issue numbers refer to the upstream repo (obra/superpowers), not our fork. When we push commits containing `#NNN` to our fork, GitHub still creates backlinks in the upstream issues, generating noise. The `obra superpowers GH-NNN` format avoids this while still being searchable. Note: we avoid writing `obra/superpowers` in commit messages too, as GitHub also backlinks org/repo references.

Known references to rewrite:
- `#448` → `obra superpowers GH-448`
- `#521` → `obra superpowers GH-521`
- `#534` → `obra superpowers GH-534`
- `#572` → `obra superpowers GH-572`
- `#578` → `obra superpowers GH-578`
- `#584` → `obra superpowers GH-584`

### Step 4: Verify
- Confirm all skill files are present and well-formed
- Confirm no unintended deletions
- Compare file list against pre-rebase

### Step 5: Update main
```
git checkout main
git reset --hard 7_0_0_upstream_rebase
```

### Step 6: Force-push
```
git push origin main --force-with-lease
```

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Issue reference format | `obra superpowers GH-NNN` (not clickable) | Prevents upstream backlink noise from both `#NNN` and `org/repo` formats; manual lookup is acceptable |
| Rebase vs merge | Rebase | Keeps linear history, easier to contribute back |
| Safety branch | Yes | Low cost, high value if something goes wrong |

## Testing Strategy

No code changes — this is a git operation. Verification is structural:
- All 16+ skill SKILL.md files present
- All agent definitions present
- All test files present
- No unexpected file deletions vs pre-rebase

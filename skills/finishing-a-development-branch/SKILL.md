---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work — guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Shutdown team → Present options → Execute choice → Update state → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Shutdown Agent Team (if applicable)

If this work was done by an agent team, shut down all specialists BEFORE merging:

1. Send `shutdown_request` via SendMessage to each implementer
2. Wait for all to confirm shutdown
3. `TeamDelete` after all members confirm
4. Verify all implementer worktrees are removed (their branches already merged in prior waves)

**Skip this step** if no agent team was used (solo or subagent-driven execution).

### Step 2: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run from the main worktree (not an implementer worktree)
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 3.

**If tests pass:** Continue to Step 3.

### Step 3: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main — is that correct?"

### Step 4: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** — keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 6)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Keep the worktree** — do not remove it. The branch is still active.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first using AskUserQuestion:**

```
Ask: "This will permanently delete branch <name> and all its commits
(<commit-list>). The worktree at <path> will also be removed. Are you sure?"
```

Wait for explicit confirmation before proceeding.

If confirmed:
```bash
# IMPORTANT: cd to repo root FIRST (from state.yml worktree.main.repo_root)
# Never run worktree remove from inside the worktree being removed
cd <worktree.main.repo_root>

git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 6)

### Step 6: Cleanup Worktree

**Only for Options 1 and 4** (merge and discard). Skip for Options 2 and 3.

**CRITICAL — cd to repo root first:**

```bash
# Get repo root from state.yml (worktree.main.repo_root)
# or fall back to:
cd $(git -C <worktree-path> rev-parse --show-toplevel)
```

**Never run worktree remove from inside the worktree being removed.** This causes the CWD to disappear mid-command.

**Detect cleanup method:**

```bash
git worktree list | grep <worktree-path>
```

If the worktree was created by **native EnterWorktree tool:** Claude Code may handle cleanup automatically on session exit. Check whether the worktree still exists before running manual cleanup:

```bash
# Only remove if still present
if git worktree list | grep -q "<worktree-path>"; then
  git worktree remove "<worktree-path>"
fi
```

If the worktree was created **manually** (`git worktree add`):

```bash
git worktree remove "<worktree-path>"
```

### Step 7: Update State

After completing the chosen option, write to `.superpowers/state.yml`:

```yaml
phase: idle
plan:
  status: executed
# Clear worktree entries:
worktree:
  main: null
  implementers: {}
# Clear team if applicable:
team: null
```

This signals to any future session that no active work is in progress.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | — | — | ✓ |
| 2. Create PR | — | ✓ | ✓ | — |
| 3. Keep as-is | — | — | ✓ | — |
| 4. Discard | — | — | — | ✓ (force) |

## Common Mistakes

**Removing worktree from inside it**
- **Problem:** CWD disappears, command errors or hangs
- **Fix:** Always `cd` to `worktree.main.repo_root` from state.yml first

**Skipping team shutdown**
- **Problem:** Orphaned implementer agents, uncommitted work lost
- **Fix:** Step 1 — shutdown all team members before merging

**Cleaning up worktree for Option 2**
- **Problem:** Removes the worktree while branch is still active and may need changes
- **Fix:** Option 2 keeps the worktree; only Options 1 and 4 clean it up

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Use AskUserQuestion; wait for explicit confirmation

**Forgetting state.yml update**
- **Problem:** Next session thinks work is still in progress
- **Fix:** Step 7 — always write `phase: idle` and clear worktree entries

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without explicit user confirmation
- Force-push without explicit request
- Run `git worktree remove` from inside the worktree being removed
- Clean up worktree for Option 2 (PR) or Option 3 (keep)

**Always:**
- Shutdown agent team before merging (Step 1)
- Verify tests before offering options (Step 2)
- `cd` to repo root before any worktree cleanup
- Present exactly 4 options
- Update state.yml to `phase: idle` after completion

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) — After all tasks complete
- **executing-plans** (Step 5) — After all batches complete
- **agent-team-driven-development** (Phase 3) — After all waves complete and all reviews pass

**Pairs with:**
- **using-git-worktrees** — Cleans up worktree created by that skill; reads `worktree.main.repo_root` from state.yml for safe CWD

**Reads from state.yml:** `worktree.main.path`, `worktree.main.repo_root`, `plan.path`, `team.roster`
**Writes to state.yml:** `phase: idle`, `plan.status: executed`, clears `worktree.*`, clears `team`

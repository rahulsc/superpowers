---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work — choose between merge, PR creation, or branch cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify gate → Verify tests → Present options → Execute choice → Promote knowledge → Clean up state.

**Announce at start:** "I'm using the forge:finishing-a-development-branch skill to complete this work."

## The Process

### Step 0: Verification Gate

**Before doing anything, check that verification has passed:**

```bash
forge-state get verification.result
```

**If not `pass`**, block immediately:
```
Cannot finish: verification has not passed.
Run forge:verification-before-completion first, then retry.
```

Stop. Don't proceed to Step 1.

**If true:** Continue to Step 1.

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 4: Execute Choice

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

Then: Knowledge Promotion (Step 5) → Cleanup (Step 6)

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

Then: Knowledge Promotion (Step 5) → Cleanup (Step 6)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.** Skip to Knowledge Promotion (Step 5).

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup (Step 6) — skip knowledge promotion for discarded work.

### Step 5: Knowledge Promotion

**After merge or PR (Options 1, 2, 3), promote validated discoveries from `.forge/local/` to `.forge/shared/`:**

1. **Scan for discoveries:**
   ```bash
   forge-memory query discovery
   ```

2. **Present validated discoveries to user:**
   ```
   Found <N> discoveries during this work:

   1. [architecture] <discovery summary> → propose target: .forge/shared/architecture.md
   2. [convention] <discovery summary> → propose target: .forge/shared/conventions.md
   3. [decision] <discovery summary> → propose target: .forge/shared/decisions/<name>.md

   Approve/skip each? (a=approve, s=skip, A=approve all)
   ```

3. **For each approved discovery**, append to the target file in `.forge/shared/`.

4. **Skip entirely for Option 4** (discarded work has no discoveries to promote).

### Step 6: Task List Cleanup

**Mark all remaining `in_progress` tasks as `completed`:**

```
TaskList → for each task with status "in_progress":
  TaskUpdate(taskId, status: "completed")
```

This catches any sub-tasks (impl-task-*, review-task-*, qa-wave*, etc.) left behind by agent teams or subagent workflows. Do this BEFORE worktree/state cleanup so the status line is clean.

### Step 7: State Cleanup and Worktree Teardown

**Clean `.forge/local/` evidence for the completed feature:**

```bash
# Clean local evidence and state for this feature
rm -rf .forge/local/evidence/<feature-branch>/
rm -rf .forge/local/plans/<feature-branch>/

# Mark phase complete
forge-state set phase complete
```

**Worktree cleanup (Options 1, 2, 4):**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

**Team mode — tear down implementer worktrees:**

```bash
# Get implementer worktree paths from state
forge-state get worktree.implementers.*

# Remove each implementer worktree
for path in <implementer-worktree-paths>; do
    git worktree remove "$path"
done
```

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Promote Knowledge |
|--------|-------|------|---------------|----------------|-------------------|
| 1. Merge locally | yes | - | - | yes | yes |
| 2. Create PR | - | yes | yes | - | yes |
| 3. Keep as-is | - | - | yes | - | yes |
| 4. Discard | - | - | - | yes (force) | - |

## Common Mistakes

**Skipping verification gate**
- **Problem:** Finish unverified work
- **Fix:** Always check `forge-state get verification.result` before proceeding

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 3)
- **Fix:** Only cleanup worktrees for Options 1, 2, and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

**Forgetting knowledge promotion**
- **Problem:** Discoveries lost when branch is finished
- **Fix:** Always scan forge-memory for discoveries before cleanup

**Leaving stale state**
- **Problem:** `.forge/local/` accumulates stale evidence from old features
- **Fix:** Always clean `.forge/local/` evidence for completed feature

**Leaving stale tasks**
- **Problem:** Sub-tasks (impl-task-*, review-task-*, qa-wave*) left in `in_progress` after work completes, causing stuck status spinners
- **Fix:** Always run task list cleanup (Step 6) before state/worktree cleanup

## Red Flags

**Never:**
- Proceed without checking verification.result
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Check verification gate before anything else
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Promote knowledge before cleanup
- Clean up all remaining `in_progress` tasks (Step 6) before state cleanup
- Clean `.forge/local/` evidence after finish
- Clean up worktree for Options 1, 2 & 4

## Integration

**Called by:**
- **forge:subagent-driven-development** (Step 7) - After all tasks complete
- **forge:subagent-driven-development** (Step 5) - After all batches complete
- **forge:agent-team-driven-development** (Phase 3) - After all waves and reviews pass

**Pairs with:**
- **forge:using-git-worktrees** - Cleans up worktree created by that skill
- **forge:verification-before-completion** - Must pass before this skill runs

## Team Context

When completing work done by an agent team:

1. **Shutdown all specialists** — send `shutdown_request` via SendMessage to each implementer before merging
2. **Cleanup per-agent worktrees** — tear down implementer worktrees from `forge-state get worktree.implementers.*`
3. **Final cross-cutting review** — dispatch a code reviewer for the entire implementation (all tasks combined) before presenting merge options
4. See `forge:agent-team-driven-development` Phase 3 for the complete cleanup sequence

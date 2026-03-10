---
name: executing-plans
description: Thin fallback for executing plans without subagent support — prefer subagent-driven-development when subagents are available
---

# Executing Plans (Fallback)

Simple plan executor for environments without subagent support. If subagents are available, use **superpowers:subagent-driven-development** instead — it provides fresh context per task, two-stage review, and higher quality output.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Session Start: Cold Resume

On every session start, check for `.superpowers/state.yml`:

```yaml
plan:
  path: docs/plans/my-feature/plan.md
  completed_tasks: [1, 2, 3]
  total_tasks: 6
```

If resuming, announce: "Resuming from task 4 of 6 (tasks 1-3 complete)." Load the plan and skip to the next incomplete task. Do not re-execute completed tasks.

## The Process

### Step 1: Load and Review Plan

Read the plan from `plan.path` in state.yml (or as provided by the user). If directory-based (`docs/plans/<project>/`), load task files individually as you reach them.

Review critically. If concerns exist, raise them before starting. If no concerns, create tasks with TaskCreate and proceed.

### Step 2: Execute All Tasks

For each task:
1. Mark as in_progress with TaskUpdate
2. Follow plan intent — make implementation decisions within that intent
3. Run verifications as specified
4. Mark as completed with TaskUpdate
5. Update `plan.completed_tasks` in state.yml

### Step 3: Complete Development

After all tasks complete:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## Plan Revision Escalation

If during execution you discover the plan is fundamentally wrong (not just a minor adjustment):
- **STOP execution** — do not silently deviate from the plan
- **Report to the user:** what you found, why the plan needs revision, what you recommend
- **Wait for approval** before continuing with a modified approach
- Minor adjustments (file path changes, small API differences) are fine — document them

## Remember
- Check state.yml on session start for cold resume
- Load individual task files, not entire plan at once
- Follow plan intent, not plan steps literally
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Preferred alternative:** **superpowers:subagent-driven-development** — use when subagents are available for higher quality execution with fresh context per task and two-stage review.

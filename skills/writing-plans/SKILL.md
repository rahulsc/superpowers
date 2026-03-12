---
name: writing-plans
description: Use when you have an approved design and need an implementation plan before touching code
---

# Writing Plans

## Overview

Write implementation plans that specify **what to build, where to put it, and why** — agents decide how. Provide enough context that a specialist who has never seen the codebase can implement correctly without guessing.

**Not "complete code in plan"** — specify the interface, the file locations, the test expectations, and the acceptance criteria. Agents write the actual implementation.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

<HARD-GATE>
Do NOT use `EnterPlanMode` or `ExitPlanMode` during plan writing. These tools trap the session in plan mode where Write/Edit tools are restricted, preventing the writing-plans skill from saving the plan document.
</HARD-GATE>

## Verification Gate

Before starting, check Forge state:

```bash
forge-gate check design.approved --project-dir .   # user has signed off on design
forge-state get worktree.main.path                  # isolated workspace must exist
```

For team plans also check:
```bash
forge-state get team.roster                         # composing-teams has run
```

If any check fails: stop. Report which precondition is missing. Do not write a plan until prerequisites are met.

## Scope Check

If the design covers multiple independent subsystems, it should have been broken into sub-project designs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## Save Location

Use directory-based plan structure:

```
docs/<project>/
├── design/            # already exists (brainstorming output — do not touch)
│   └── design.md      # or multiple files when split
├── plans/
│   ├── plan.md        # write this (overview + task list)
│   └── tasks/         # write one file per task (optional, for 4+ task plans)
│       ├── 01-<slug>.md
│       ├── 02-<slug>.md
│       └── ...
```

`<project>` is the kebab-case name from the design doc (e.g., `user-auth`, `payment-refactor`).

**Do NOT use date-prefixed filenames.** The directory name carries enough context and Forge state stores the path for cross-session discovery.

**Worktree context:** The plan executes in the worktree at `worktree.main.path` (from `forge-state get worktree.main.path`). Include this path context in the plan header so executors know where to work.

## After Writing

Write to Forge state:

```bash
forge-state set plan.path "docs/<project>/plans/plan.md"
forge-state set plan.status "pending"
forge-state set plan.total_tasks "N"
forge-state set phase "planning"
```

**Plan frontmatter status:** The plan.md template includes `status: pending` in its YAML frontmatter. Executors update this to `status: executed` on completion. This allows tools and agents to check plan status directly from the document without consulting state.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Prefer smaller, focused files over large ones that do too much. Agents reason best about code they can hold in context at once, and edits are more reliable when files are focused.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure — but if a file being modified has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each task covers one coherent piece of work (not one line of code):**
- "Add Zod schema for user preferences" — one task
- "Create DB migration and table" — one task
- "Implement API route with validation" — one task

Within each task, the implementer follows TDD: write failing test, verify it fails, implement, verify it passes, commit. The plan specifies *what* the test should cover and what failure to expect — not the exact test code.

## Risk-Tier-Aware Planning

Before writing the plan, run risk classification on the files that will be touched:

```bash
classify-risk --files "<path1> <path2>" --project-dir .
```

The detected tier determines plan ceremony:

| Tier | Required plan artifacts |
|------|------------------------|
| minimal | Goal + tasks (no design-doc gate required) |
| standard | Goal + tasks + test expectations + forge-gate check plan.approved |
| elevated | All standard + design doc reference + wave analysis if team |
| critical | All elevated + risk register reference + rollback plan + security review note |

Include the tier in the plan header. If classify-risk is unavailable, infer tier from the file paths being modified using the policy rules in `.forge/policies/`.

## Plan Document Structure

### plan.md

```markdown
---
status: pending
risk_tier: <minimal|standard|elevated|critical>
---

# [Feature Name] Implementation Plan

> See [design](../design/design.md) for context and rationale.
> **Risk tier:** [tier] — [required artifacts for this tier]
> **For Claude:** Use [execution-skill] to execute this plan.

**Goal:** [One sentence]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies]

---

## Tasks

1. Task 1: [Title]
2. Task 2: [Title]
3. Task 3: [Title]

[Wave analysis if team plan — see below]

## Test Expectations Summary

| Task | What to test | Expected red failure |
|------|-------------|----------------------|
| 1 | [behavior] | [specific error message or missing symbol] |
| 2 | [behavior] | [specific error message or missing symbol] |
```

**Write the header last.** Why: the header includes the execution approach recommendation (serial vs. team), which you cannot know until you have:
1. Drafted all tasks and their dependencies
2. Run the Team Fitness Check (see below) to determine whether parallel execution is warranted
3. Decided the execution approach — only then write the header with the correct `> **For Claude:** Use [execution-skill]` line

### plans/tasks/<NN>-<slug>.md (one per task, for 4+ task plans)

```markdown
# Task N: [Title]

**Specialist:** [role] *(team plans only)*
**Depends on:** Task X (for [specific output]) *(or None)*
**Produces:** [what later tasks consume]

## Goal

One sentence.

## Acceptance Criteria

- [ ] [Specific, verifiable criterion]
- [ ] [Specific, verifiable criterion]

## Test Expectations

- **Test:** [what behavior to test — e.g., "rejects empty email with 400"]
- **Expected red failure:** [specific error — e.g., "TypeError: submitForm is not a function"]
- **Expected green:** [what the passing assertion looks like]

## Files

- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py` (section: lines ~123-145)
- Test: `tests/exact/path/to/test_feature.py`

## Implementation Notes

[Context the implementer needs that isn't in the design]
[Interfaces they must match]
[Patterns from existing code to follow]
[What NOT to build — YAGNI notes]

## Commit

`feat: [description]`
```

**For plans with fewer than 4 tasks:** Embed the full task content in `plan.md` directly (no `plans/tasks/` directory needed).

## Plan-Level Test Expectations

Every task MUST include test expectations. This is not optional.

**What to specify:**
- The behavior being tested (not the test code)
- The specific error or failure that proves the test runs before the implementation exists
- What passing looks like

**Why this matters:** Test expectations in the plan make tests impossible to "forget." The QA agent (pipelined TDD) or the implementer (solo TDD) uses these to write the failing test before touching production code.

**Good test expectations:**
```
- Test: POST /api/users rejects missing email field
- Expected red failure: AssertionError: expected 400, got 500 (route doesn't validate yet)
- Expected green: response.status === 400, body.error === "email required"
```

**Too vague:**
```
- Test: validate user input
```

## Team Fitness Check

After drafting all tasks and their dependencies, evaluate whether this plan benefits from team execution.

**Use team execution when ALL of these are true:**
- At least 2 waves have 2+ tasks each (real parallel work exists)
- At least 2 distinct specialist roles are needed
- 4+ tasks total (team overhead pays for itself)

**Use standard serial format when ANY of these are true:**
- Every wave has only 1 task (purely serial chain)
- Fewer than 4 tasks total
- Only 1 specialist role needed
- Tasks are tightly coupled with pervasive shared state

If serial is the better fit, announce: *"After analyzing dependencies, this plan is essentially serial — [reason]. Using standard serial format."*

## Wave Analysis (Team Plans Only)

Include immediately after the header when Team Fitness Check passes.

````markdown
## Wave Analysis

### Specialists

| Role | Expertise | Tasks |
|------|-----------|-------|
| [role-name] | [technologies, domain] | Tasks N, M |

### Waves

**Wave 0: [Foundation/Setup]**
- Task A ([role-name]) — migrations, schema, config scaffolding, etc.
- *(parallel)* QA writes failing tests for Wave 1 tasks (if pipelined TDD)

  *Parallel-safe because:* QA writes test files; foundation tasks write different files

**Wave 1: [Theme]**
- Task N ([role-name]) — [one-line summary]
- *(parallel)* QA writes failing tests for Wave 2 tasks

  *Parallel-safe because:* [different directories, no import relationship]
  *QA parallel because:* QA writes test files in lead's worktree; implementers work in their own worktrees

**Wave 2: [Theme]** — needs Wave 1 [what specifically]
- Task X ([role-name]) — [one-line summary]
- *(parallel)* QA writes failing tests for Wave 3 tasks (or verifies all tests on final wave)

  *Depends on Wave 1:* [specific outputs — file paths, types, tables]

**Important:** QA test-writing is always a parallel activity WITHIN each wave, not a separate sequential step. Implementers and QA work simultaneously — implementers run pre-written tests RED→GREEN while QA writes the next wave's tests.

### Dependency Graph

```
Wave 0: foundation + QA tests W1
              │
              ▼
Wave 1: impl + QA tests W2
              │
              ▼
Wave 2: impl + QA tests W3
              │
              ▼
Wave 3: impl + QA verify all
```
````

**Wave grouping rules:**
- Tasks in the same wave MUST NOT touch the same files
- Tasks in the same wave MUST NOT have an import relationship
- Max 3 tasks per wave (max 3 simultaneous implementers)
- When unsure → serialize

## Plan Review

Before handing off for execution, consider a plan review:
- Re-read every task against the design doc acceptance criteria
- Check that test expectations are specific enough for a QA agent to write tests without clarification
- Verify no task assumes output from a same-wave task (would cause conflicts)
- Confirm file paths exist or are clearly new

For critical or complex plans, a separate review pass (treating yourself as a new reader with no context) catches gaps that are obvious once implementation starts.

## Remember

- Exact file paths always
- Specify what/where/why — not complete code
- Every task needs test expectations (behavior + red failure + green)
- Reference relevant skills by name: `forge:skill-name`
- DRY, YAGNI, TDD, frequent commits
- For team plans: every task must have Specialist, Depends on, Produces fields
- For team plans: Wave Analysis must justify why same-wave tasks are parallel-safe
- For team plans: dependency graph must be acyclic, max 3 tasks per wave

## Plan Review Loop

After completing each chunk of the plan:

1. Dispatch plan-document-reviewer subagent (see `plan-document-reviewer-prompt.md`) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
   - Provide: chunk content, path to design document
2. If issues found:
   - Fix the issues in the chunk
   - Re-dispatch reviewer for that chunk
   - Repeat until approved
3. If approved: proceed to next chunk (or execution handoff if last chunk)

**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be at most 1000 lines and logically self-contained.

**Review loop guidance:**
- Same agent that wrote the plan fixes it (preserves context)
- If loop exceeds 5 iterations, surface to human for guidance
- Reviewers are advisory — explain disagreements if you believe feedback is incorrect

## Execution Handoff

After saving the plan and writing Forge state, offer execution choice:

**"Plan saved to `docs/<project>/plans/plan.md`. Two execution options:**

**1. Agent Team-Driven (this session)** — Parallel specialist agents, wave-based execution, two-stage review after each task. Best for 4+ tasks with parallelism. Uses `forge:agent-team-driven-development`.

**2. Subagent-Driven (this session)** — Fresh subagent per task, review between tasks. Best for serial plans or fewer tasks. Uses `forge:subagent-driven-development`.

**Which approach?"**

**Automatic fallback:** If the harness does not support subagents (no TaskTool available), execution falls back to `forge:subagent-driven-development` which runs tasks in the current session with batch checkpoints.

After user chooses, run `forge-state set plan.executor "<skill>"`, then invoke the chosen execution skill.

## Integration

**Before this skill:**
- **forge:brainstorming** — Creates the design this skill plans from; `design.approved` must be true
- **forge:using-git-worktrees** — Isolated workspace; `worktree.main.path` must exist

**After this skill:**
- **forge:agent-team-driven-development** — Parallel execution (4+ tasks with independence)
- **forge:subagent-driven-development** — Serial execution (same session)
- **forge:subagent-driven-development** — Fallback for no-subagent platforms

**Reads from Forge state:** `design.approved`, `design.path`, `worktree.main.path`, `team.roster`
**Writes to Forge state:** `plan.path`, `plan.status`, `plan.executor`, `plan.total_tasks`, `phase`
**Creates:** `docs/<project>/plans/plan.md`, `docs/<project>/plans/tasks/*.md`

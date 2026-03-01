---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

````markdown
# [Feature Name] Implementation Plan

> **For Claude:** Use [execution-skill] to execute this plan — [execution summary].

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
````

**Write the header last** — after the Team Fitness Check determines which execution approach to use. The execution skill and summary in the header depend on the chosen approach.

## Team Fitness Check

**After drafting all tasks and their dependencies, evaluate whether this plan benefits from team execution.**

This check applies when a team roster exists (from composing-teams). If no roster exists, skip this section and use standard serial format.

**Use team execution (add Wave Analysis and specialist metadata) when ALL of these are true:**
- At least 2 waves have 2+ tasks each (real parallel work exists)
- At least 2 distinct specialist roles are needed
- 4+ tasks total (team overhead pays for itself)

**Use standard serial format when ANY of these are true:**
- Every wave has only 1 task (it's a purely serial chain)
- Fewer than 4 tasks total
- Only 1 specialist role needed (no domain diversity)
- Tasks are tightly coupled with pervasive shared state

**If serial is the better fit:**

Announce to the user: *"After analyzing dependencies, this plan is essentially serial — [reason: e.g., every task depends on the previous one / only 3 tasks / single specialist needed]. Team overhead wouldn't pay off. Using standard serial format."*

Then: omit the Wave Analysis section and per-task team metadata (Specialist/Depends on/Produces). Use the standard Task Structure below.

**If team execution is a good fit, proceed with the Wave Analysis section below.**

## Wave Analysis (Conditional — Team Plans Only)

Include this section immediately after the header when the Team Fitness Check passes. This is the team lead's roadmap for orchestration.

````markdown
## Wave Analysis

### Specialists

| Role | Expertise | Tasks |
|------|-----------|-------|
| [role-name] | [technologies, domain] | Tasks N, M |
| [role-name] | [technologies, domain] | Tasks X, Y |

### Waves

**Wave 1: [Theme]** — [why these are the foundation]
- Task N ([role-name]) — [one-line summary]
- Task M ([role-name]) — [one-line summary]

  *Parallel-safe because:* [why these tasks don't conflict — different directories, no import relationship, etc.]

**Wave 2: [Theme]** — needs Wave 1 [what specifically]
- Task X ([role-name]) — [one-line summary]
- Task Y ([role-name]) — [one-line summary]

  *Parallel-safe because:* [justification]
  *Depends on Wave 1:* [specific outputs — file paths, types, tables]

### Dependency Graph

```
Task 1 ──→ Task 3 ──→ Task 5
Task 2 ──→ Task 4 ──↗
```
````

**Rules for wave grouping:**
- Tasks in the same wave MUST NOT touch the same files
- Tasks in the same wave MUST NOT have an import relationship
- Max 3 tasks per wave (max 3 simultaneous implementers)
- When unsure about independence → serialize into separate waves
- Earlier waves produce foundations (types, schemas, configs); later waves consume them

## Task Structure

````markdown
### Task N: [Component Name]

**Agent:** [agent-definition-name] *(optional — when a specific agent definition should be used)*
**Specialist:** [role-name] *(conditional — team plans only)*
**Depends on:** Task X (for [specific thing]) *(conditional — team plans only)*
**Produces:** [what later tasks need] *(conditional — team plans only)*

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

### Per-Task Metadata Rules

**`Agent:` (optional, any plan)** — The agent definition to use when dispatching this task. References an agent from `.claude/agents/`, `~/.claude/agents/`, or the superpowers `agents/` directory. If omitted, uses default agent.

**`Specialist:` (conditional, team plans only)** — The role name that should implement this task. Match to the Specialists table in the Wave Analysis. Use descriptive role names: `backend-engineer`, `react-engineer`, `swift-engineer`, `schema-engineer`.

**`Depends on:` (conditional, team plans only)** — Either `None` (wave 1 task) or explicit task references with what's needed. Example: `Task 1 (Zod schemas at packages/shared/src/schemas/)`. This tells the team lead what `addBlockedBy` relationships to set and what cross-wave context to provide.

**`Produces:` (conditional, team plans only)** — What this task creates that later tasks consume. Example: `Drizzle schema at apps/server/src/db/schema.ts, migration at apps/server/drizzle/`. This tells the team lead what context to forward when assigning dependent tasks in later waves.

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits
- For team plans: every task must have Specialist, Depends on, and Produces fields
- For team plans: Wave Analysis must justify why same-wave tasks are parallel-safe
- For team plans: dependency graph must be acyclic
- For team plans: max 3 tasks per wave, max 3 specialist roles total

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Three execution options:**

**1. Agent Team-Driven (this session)** - Parallel specialist agents, wave-based execution, two-stage review after each task. Best for 4+ tasks with parallelism.

**2. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration. Best for serial plans or fewer tasks.

**3. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints. Best for human-in-loop between batches.

**Which approach?"**

**If Agent Team-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use agent-team-driven-development
- Stay in this session
- Team lead spawns specialists, orchestrates waves, runs reviews

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans

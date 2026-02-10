---
name: writing-plans-for-teams
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans for Teams

## Overview

Write comprehensive implementation plans designed for parallel execution by a team of specialist agents. Plans must be structured so the team lead can analyze dependencies, group tasks into waves, spawn the right specialists, and provide cross-wave context — all without re-reading the plan.

Assume implementers are skilled developers with zero codebase context. Document everything: which files to touch, complete code, testing commands, dependency relationships, and what each task produces for later tasks. DRY. YAGNI. TDD. Frequent commits.

**Announce at start:** "I'm using the writing-plans-for-teams skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Plan Document Structure

Every plan has four sections in order: Header, Wave Analysis, Tasks, Execution Handoff.

### 1. Header

**Write the header last** — after the Team Fitness Check determines which execution approach to use.

If team execution (wave analysis passed fitness check):
```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use agent-team-driven-development to execute this plan.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

If serial execution (fitness check redirected to writing-plans):
```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### 2. Wave Analysis

Immediately after the header. This is the team lead's roadmap for orchestration.

**Before writing the full wave analysis, draft the task list and dependency graph. Then evaluate whether this plan actually benefits from team execution.**

#### Team Fitness Check

After identifying tasks and dependencies, ask: **does this plan have real parallelism?**

**Use team execution (continue with this skill) when:**
- At least 2 waves have 2+ tasks (real parallel work exists)
- At least 2 distinct specialist roles are needed
- 4+ tasks total (team overhead pays for itself)

**Fall back to serial execution when ANY of these are true:**
- Every wave has only 1 task (it's a purely serial chain)
- Fewer than 4 tasks total
- Only 1 specialist role needed (no domain diversity)
- Tasks are tightly coupled with pervasive shared state

**If serial is the better fit:**

Announce to the user: *"After analyzing dependencies, this plan is essentially serial — [reason: e.g., every task depends on the previous one / only 3 tasks / single specialist needed]. Team overhead wouldn't pay off. I'm switching to the standard writing-plans format with subagent-driven execution."*

Then:
- **REQUIRED SUB-SKILL:** Switch to `superpowers:writing-plans`
- Drop the Wave Analysis section and per-task metadata (Specialist/Depends on/Produces)
- Use the standard plan format with `superpowers:executing-plans` or `superpowers:subagent-driven-development` in the header
- Continue writing the plan using that skill's conventions

**If team execution is a good fit, proceed with the wave analysis below.**

#### Wave Analysis Format

```markdown
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

**Wave 3: [Theme]** — needs Wave 2 [what specifically]
- ...

### Dependency Graph

```
Task 1 ──→ Task 3 ──→ Task 5
Task 2 ──→ Task 4 ──↗
```
```

**Rules for wave grouping:**
- Tasks in the same wave MUST NOT touch the same files
- Tasks in the same wave MUST NOT have an import relationship
- Max 3 tasks per wave (max 3 simultaneous implementers)
- When unsure about independence → serialize into separate waves
- Earlier waves produce foundations (types, schemas, configs); later waves consume them

### 3. Tasks

Each task carries its own dependency and specialist metadata so the team lead can hand it off without cross-referencing.

```markdown
### Task N: [Component Name]

**Specialist:** [role-name]
**Depends on:** Task X (for [specific thing — types, DB table, API route])
**Produces:** [what later tasks need from this — file paths, exports, patterns]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `exact/path/to/test.ts`

**Step 1: Write the failing test**

```typescript
// test code
```

**Step 2: Run test to verify it fails**

Run: `bun test path/to/test.ts`
Expected: FAIL with "..."

**Step 3: Write minimal implementation**

```typescript
// implementation code
```

**Step 4: Run test to verify it passes**

Run: `bun test path/to/test.ts`
Expected: PASS

**Step 5: Commit**

```bash
git add [specific files]
git commit -m "feat: add specific feature"
```
```

### 4. Execution Handoff

```markdown
---

## Execution

Plan complete and saved to `docs/plans/<filename>.md`.

**Recommended: Agent Team-Driven** — Parallel specialist agents, wave-based execution, two-stage review after each task.

**Alternative: Subagent-Driven** — Serial execution, simpler orchestration, no team overhead. Better if <3 tasks or tasks are tightly coupled.

Which approach?
```

## Bite-Sized Task Granularity

Same as any plan — each step is one action (2-5 minutes):
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

## Task Metadata Rules

Every task MUST have these three fields:

**`Specialist:`** — The role name that should implement this task. Match to the Specialists table in the Wave Analysis. Use descriptive role names: `backend-engineer`, `react-engineer`, `swift-engineer`, `schema-engineer`.

**`Depends on:`** — Either `None` (wave 1 task) or explicit task references with what's needed. Example: `Task 1 (Zod schemas at packages/shared/src/schemas/)`. This tells the team lead what `addBlockedBy` relationships to set and what cross-wave context to provide.

**`Produces:`** — What this task creates that later tasks consume. Example: `Drizzle schema at apps/server/src/db/schema.ts, migration at apps/server/drizzle/`. This tells the team lead what context to forward when assigning dependent tasks in later waves.

## Remember

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits
- Every task must have Specialist, Depends on, and Produces fields
- Wave Analysis must justify why same-wave tasks are parallel-safe
- Dependency graph must be acyclic
- Max 3 tasks per wave, max 3 specialist roles total

## Execution Handoff

After saving the plan, present the execution choice shown in Section 4 above.

**If Agent Team-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use agent-team-driven-development
- Stay in this session
- Team lead spawns specialists, orchestrates waves, runs reviews

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task, serial execution

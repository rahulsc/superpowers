---
name: agent-team-driven-development
description: Use when executing implementation plans with independent tasks — orchestrates a team of specialist agents working in parallel
---

# Agent Team-Driven Development

Execute plans by orchestrating a team of persistent specialist agents working in parallel where possible, with two-stage review (spec compliance then code quality) after each task.

**Core principle:** Wave-based parallel execution + persistent specialist implementers + two-stage review = fast delivery, high quality

## When to Use

- Have an implementation plan with multiple tasks
- Tasks have identifiable independence (can run in parallel)
- Want maximum throughput in a single session
- Tasks are substantial enough that parallelism pays off

**vs. Subagent-Driven Development:**
- Parallel execution across independent tasks
- Persistent implementers fix review issues without context loss
- Specialists carry domain knowledge across waves
- Better for plans with 4+ tasks where parallelism pays off

**Don't use when:**
- Tasks are tightly coupled with no parallelism
- Plan has fewer than 3 tasks (subagent-driven is simpler)
- Tasks each take under a minute (team overhead not worth it)

## Team Structure

| Role | How Spawned | Persistence | Count |
|------|------------|-------------|-------|
| Lead (you) | Main agent | Session lifetime | 1 |
| Specialist Implementer | `general-purpose` team member | Persistent, reused across waves | 1 per parallel task (max 3) |
| Spec Reviewer | `general-purpose` subagent | Fresh per review | As needed |
| Code Quality Reviewer | `superpowers:code-reviewer` subagent | Fresh per review | As needed |

**Implementers are team members** because they benefit from persistence:
- Within a task: reviewer finds issues → message the same implementer → they fix without re-learning
- Across waves: implementer who built the schema in wave 1 already knows the codebase for wave 3

**Reviewers are subagents** because they benefit from fresh context:
- No accumulated bias from watching implementation
- "Do not trust the implementer's report" works better with zero prior context

**Implementers are specialists, not generic.** The lead analyzes the plan and spawns by role:
- `name: "react-engineer"` — React/TypeScript expertise, component patterns
- `name: "backend-engineer"` — API design, database, server conventions
- `name: "swift-engineer"` — Swift/SwiftUI, iOS patterns

Name implementers by role, not by number. Assign tasks to the specialist who matches.

**Max 3 simultaneous implementers.** More than that hits diminishing returns: git conflicts, resource overhead, harder to coordinate.

## The Process

### Phase 1: Plan Analysis & Team Setup

1. **Read plan** once, extract every task with its full description
2. **Analyze dependencies** between tasks (see Dependency Analysis below)
3. **Group into waves** — tasks in the same wave must be independent and not touch the same files
4. **Decide specializations** — what expertise does each wave need? Name implementers by role
5. **Create team** via `TeamCreate`
6. **Create task list** — `TaskCreate` for each task, `TaskUpdate` to set `addBlockedBy` for cross-wave dependencies
7. **Spawn implementers** — one per task in wave 1, specialized by role, using `./implementer-prompt.md`

### Phase 2: Wave Execution

**Per task (staggered — reviews start as each implementer finishes, don't wait for the whole wave):**

1. **Implementer reports completion** via `SendMessage`
2. **Spec review** — dispatch subagent using `./spec-reviewer-prompt.md`
   - If issues: message implementer with specific feedback → they fix → dispatch fresh spec reviewer
   - Repeat until pass
3. **Code quality review** — dispatch subagent using `./code-quality-reviewer-prompt.md`
   - If issues: same fix loop
   - Repeat until pass
4. **Mark task complete** via `TaskUpdate`

**Staggered reviews within a wave:**
While implementer-2 is still coding, implementer-1's completed task can already be under review. This natural pipelining is a key throughput advantage over serial execution.

**Between waves:**
- All tasks in current wave must pass both reviews before starting next wave
- Message existing implementers with next wave's tasks + context from previous waves
- If a wave needs a different specialty, shut down the unneeded implementer and spawn a new specialist

### Phase 3: Completion

1. All waves done, all tasks reviewed
2. Dispatch final cross-cutting code reviewer (`superpowers:code-reviewer`) for entire implementation
3. Shutdown all implementers via `SendMessage` with `type: "shutdown_request"`
4. `TeamDelete` after all members confirm shutdown
5. Use `superpowers:finishing-a-development-branch`

## Dependency Analysis

**Safe to parallelize (same wave):**
- Different directories/modules
- No import relationship between them
- Different layers (unrelated API routes, unrelated UI pages)
- Different specialists can own them cleanly

**Must serialize (different waves):**
- Task B imports something Task A creates (types, schemas, utilities)
- Both tasks modify the same file
- Task B needs Task A's database table/migration
- Task B calls an API route Task A builds

**When unsure → serialize.** Wrong-wave parallelism causes merge conflicts, which are far more expensive than the time saved.

**Example:**
```
Plan: Add user preferences feature
  Task 1: Zod schemas              (packages/shared)
  Task 2: DB table + migration     (apps/server)
  Task 3: API routes               (apps/server)
  Task 4: React UI page            (apps/web)
  Task 5: Update iOS model docs    (docs/)

Dependencies:
  Task 2 → needs Task 1 (schema types)
  Task 3 → needs Task 1 + Task 2 (types + DB table)
  Task 4 → needs Task 1 + Task 3 (types + API)
  Task 5 → needs Task 1 (schema types)

Waves:
  Wave 1: [Task 1]          — foundation, everything else needs these types
  Wave 2: [Task 2, Task 5]  — both need only Task 1, different modules
  Wave 3: [Task 3]          — needs Task 2's DB table
  Wave 4: [Task 4]          — needs Task 3's API

Specialists: backend-engineer (Tasks 1-3), react-engineer (Task 4), docs-writer (Task 5)
```

## Prompt Templates

- `./implementer-prompt.md` — Spawn specialist + follow-up task assignment + review feedback
- `./spec-reviewer-prompt.md` — Dispatch spec compliance reviewer (subagent)
- `./code-quality-reviewer-prompt.md` — Dispatch code quality reviewer (subagent)

## Example Workflow

```
Lead: Starting Agent Team-Driven Development.

[Read plan: docs/plans/phase-2-web-app.md]
[Extract 6 tasks, analyze dependencies]

Wave analysis:
  Wave 1: Task 1 (API client + hooks), Task 2 (Layout + routing)
  Wave 2: Task 3 (Categories page), Task 4 (Merchants page)
  Wave 3: Task 5 (Budget dashboard)
  Wave 4: Task 6 (Settings page)

Specialists needed: react-engineer, frontend-architect

[TeamCreate: "phase-2-web-app"]
[TaskCreate x 6, set blockedBy]
[Spawn react-engineer, frontend-architect]
[Assign Task 1 → react-engineer, Task 2 → frontend-architect]

--- Wave 1 (parallel) ---

react-engineer: "Task 1 done. API client with typed hooks, 4 tests passing. abc123."
frontend-architect: [still working]

[Don't wait — dispatch spec reviewer for Task 1 immediately]
Spec reviewer: Spec compliant
[Dispatch code quality reviewer for Task 1]
Code reviewer: Approved
[Mark Task 1 complete]

frontend-architect: "Task 2 done. Layout shell, routing, 3 tests passing. def456."

[Dispatch spec reviewer for Task 2]
Spec reviewer: Missing breadcrumb navigation (spec requirement)
[Message frontend-architect: fix breadcrumbs]
frontend-architect: "Fixed. Breadcrumbs added, committed ghi789."
[Dispatch fresh spec reviewer]
Spec reviewer: Spec compliant now
[Dispatch code quality reviewer]
Code reviewer: Approved
[Mark Task 2 complete]

Wave 1 complete → unblocks Wave 2

--- Wave 2 (parallel) ---

[Message react-engineer: "New task: Categories page. Hooks from Task 1
 at apps/web/src/hooks/api/. Layout uses <Outlet>. Full task: ..."]
[Message frontend-architect: "New task: Merchants page. Same context..."]

... [similar flow] ...

--- Waves 3, 4 ---
... [continue] ...

[All 6 tasks done]
[Dispatch final cross-cutting reviewer]
[Shutdown react-engineer, frontend-architect]
[TeamDelete]
[Use superpowers:finishing-a-development-branch]
```

## Red Flags

**Sequencing — never:**
- Start code quality review before spec compliance passes
- Start a new wave before current wave's reviews all pass
- Let an implementer start their next task while their current task has open review issues
- Start work on main/master without explicit user consent

**Parallelism — never:**
- More than 3 simultaneous implementers
- Tasks touching the same files in the same wave
- Proceed when unsure about independence (serialize instead)
- Give an implementer more than one task at a time

**Communication — never:**
- Make implementers read plan files (provide full text)
- Omit previous-wave context when assigning later-wave tasks
- Rush implementers past their questions
- Forward vague review feedback ("there were issues" — give file:line specifics)

**Reviews — never:**
- Skip re-review after fixes
- Let self-review replace actual review (both needed)
- Skip either review stage (spec compliance AND code quality required)
- Proceed with unfixed issues

**Recovery:**
- Implementer stuck → check what's blocking via SendMessage, provide guidance
- Implementer failed entirely → shut them down, spawn a fresh specialist with context about what went wrong
- Never try to fix manually from the lead (context pollution)

## Team Lifecycle

1. **Create** — `TeamCreate` at start of plan execution
2. **Spawn** — specialists for wave 1 tasks
3. **Reuse** — message existing implementers with new tasks for subsequent waves. If a wave needs a different specialty, shut down the unneeded implementer and spawn a new specialist
4. **Shutdown** — `SendMessage` with `type: "shutdown_request"` to each implementer when all their work is reviewed and done
5. **Delete** — `TeamDelete` after all members confirm shutdown

## Integration

**Before this skill:**
- **superpowers:using-git-worktrees** — Isolated workspace before starting
- **superpowers:writing-plans** — Creates the plan this skill executes

**During this skill:**
- **superpowers:test-driven-development** — Implementers follow TDD
- **superpowers:requesting-code-review** — Review methodology for quality reviewers

**After this skill:**
- **superpowers:finishing-a-development-branch** — Merge/PR/cleanup decision

**Alternative approaches:**
- **superpowers:subagent-driven-development** — Serial execution, simpler, no team overhead
- **superpowers:executing-plans** — Parallel session instead of same-session

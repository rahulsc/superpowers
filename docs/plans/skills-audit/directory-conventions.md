# Directory-Based Plan Conventions

> Foundation document for the skills audit implementation.
> See `docs/plans/skills-audit/design.md` Section 2 for the approved design rationale.

## Purpose

Each project gets its own subdirectory under `docs/plans/`. Files within the directory have strict ownership rules — no skill overwrites another skill's output.

## Directory Structure

```text
docs/plans/
└── <project>/
    ├── design.md          # brainstorming output (never overwritten)
    ├── plan.md            # writing-plans output (overview + task list)
    ├── tasks/             # one file per task (token-efficient loading)
    │   ├── 01-schema.md
    │   ├── 02-api-routes.md
    │   └── 03-ui-page.md
    └── waves.md           # team mode only
```

## Naming Convention

`<project>` is a **kebab-case descriptive name** based on what the work is, not when it started.

- Good: `user-auth`, `payment-refactor`, `api-v2`
- Avoid: `2026-03-01-user-auth` (date-prefixed), `my_feature` (underscores), `UserAuth` (capitalized)

The name is chosen during brainstorming and stored in `state.yml` via `plan.path` for discovery in future sessions.

## File Ownership Rules

| File | Created by | Modified by | Never touched by |
|---|---|---|---|
| `design.md` | brainstorming | brainstorming only | writing-plans, executors, finishing |
| `plan.md` | writing-plans | writing-plans only | brainstorming, executors |
| `tasks/*.md` | writing-plans | writing-plans only | executors (read-only) |
| `waves.md` | writing-plans (team mode) | writing-plans only | executors (read-only) |

**The most important rule: `design.md` is immutable after brainstorming completes.**

- `plan.md` must reference `design.md` (link to it) but never overwrite it
- Executors load task files individually — they do not write back to them
- If a plan needs revision, writing-plans updates `plan.md` and `tasks/*.md` only

## Token Savings Rationale

Loading individual task files instead of a monolithic plan document provides approximately **2.7x token savings** during execution.

Example: A 6-task plan where each task is ~300 tokens.

| Loading strategy | Tokens per executor invocation |
|---|---|
| Monolithic `plan.md` (all tasks) | ~1,800 tokens |
| Individual `tasks/01-schema.md` | ~300 tokens |
| Savings | ~1,500 tokens (~2.7x) |

Executors load only the task file for their current task. This keeps each executor's context lean and allows more tokens for implementation work.

## state.yml Integration

The `plan.path` field in `state.yml` stores the path to `plan.md` for cross-session discovery.

```yaml
plan:
  path: docs/plans/my-feature/plan.md
  ...
```

On cold start (new session), the session-start hook reads `state.yml`, finds `plan.path`, and the executor can locate individual task files by convention:

```text
docs/plans/my-feature/tasks/01-*.md
docs/plans/my-feature/tasks/02-*.md
...
```

## plan.md Structure

`plan.md` is the overview document. It contains:

1. A link to `design.md`: `See [design](design.md) for context.`
2. An ordered task list (task number + title only)
3. Wave assignments (if team mode, or reference to `waves.md`)
4. Test expectations per task (3-5 lines each — what to test, expected red failure mode)

Task details live in `tasks/<NN>-<slug>.md`, not in `plan.md`.

## tasks/ File Format

Each task file covers one task completely:

```markdown
# Task N: <Title>

## Goal
One sentence.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Test Expectations
- Test: <what to test>
- Expected red failure: <what fails and why>
- Expected green: <what passes>

## Implementation Notes
Any context the executor needs that isn't in design.md.
```

## waves.md Format (Team Mode Only)

```markdown
# Waves

## Wave 0 (QA setup)
- QA: write tests for Wave 1 tasks

## Wave 1
- react-engineer: Task 1, Task 2
- backend-engineer: Task 3

## Wave 2
- react-engineer: Task 4
- backend-engineer: Task 5
- QA: write tests for Wave 3
```

## Problems Solved

| Issue | How directory conventions fix it |
|---|---|
| #565 (design overwritten by plan) | `design.md` immutable after brainstorming — explicit rule |
| Finding I (token efficiency) | Individual task files load ~2.7x fewer tokens than monolithic plan |
| Finding O (no structure) | Standard directory layout all skills agree on |
| H2 (roster location) | Team roster in `state.yml`, not in plan files — avoids confusion |

# `.superpowers/state.yml` Schema Reference

> Foundation document for the skills audit implementation.
> See `docs/plans/skills-audit/design.md` Section 1 for the approved design rationale.

## Purpose

`state.yml` provides persistent state across sessions and handoffs. It is the single source of truth for:
- Current workflow phase
- Design doc and plan locations
- Worktree paths (lead + per-implementer)
- Team roster
- Task completion progress

## Location and Gitignore

- File path: `.superpowers/state.yml` in project root
- The `.superpowers/` directory is gitignored automatically on first write
- State is project-local and never committed to version control

## Full Schema with Example

```yaml
version: 1
phase: executing  # brainstorming | planning | composing | executing | finishing | idle

design:
  path: docs/plans/my-feature/design.md
  approved: true
  approved_at: 2026-03-01T10:30:00Z

plan:
  path: docs/plans/my-feature/plan.md
  status: in_progress  # pending | in_progress | executed
  executor: agent-team-driven
  total_tasks: 6
  completed_tasks: [1, 2, 3]
  current_wave: 2

worktree:
  main:
    path: /home/user/project/.worktrees/my-feature
    branch: feature/my-feature
    repo_root: /home/user/project
  implementers:
    react-engineer:
      path: /tmp/.claude/worktrees/wt-abc123
      branch: wt-abc123
      last_sha: a1b2c3d

team:
  name: my-feature-team
  roster:
    - role: react-engineer
      agent: react-engineer
      model: sonnet

last_session: 2026-03-01T14:22:00Z
```

## Field Reference

| Field | Type | Description |
|---|---|---|
| `version` | integer | Schema version for future migration. Currently `1`. |
| `phase` | string | Current workflow phase. One of: `brainstorming`, `planning`, `composing`, `executing`, `finishing`, `idle`. |
| `design.path` | string | Relative path to `design.md` from project root. |
| `design.approved` | boolean | Whether the user has approved the design. Gate for downstream skills. |
| `design.approved_at` | ISO 8601 datetime | Timestamp of approval. |
| `plan.path` | string | Relative path to `plan.md` from project root. |
| `plan.status` | string | One of: `pending`, `in_progress`, `executed`. |
| `plan.executor` | string | Which executor skill runs the plan: `subagent-driven`, `agent-team-driven`, or `executing-plans`. |
| `plan.total_tasks` | integer | Total number of tasks in the plan. |
| `plan.completed_tasks` | integer[] | Array of completed task numbers (1-indexed). |
| `plan.current_wave` | integer | Current wave number (team mode only). |
| `worktree.main.path` | string | Absolute path to the lead's worktree. |
| `worktree.main.branch` | string | Git branch name for the lead's worktree. |
| `worktree.main.repo_root` | string | Absolute path to the original repository root. |
| `worktree.implementers.<role>.path` | string | Absolute path to the implementer's worktree. |
| `worktree.implementers.<role>.branch` | string | Git branch name for the implementer's worktree. |
| `worktree.implementers.<role>.last_sha` | string | Last known commit SHA in that worktree. |
| `team.name` | string | Team name for this session. |
| `team.roster` | object[] | List of team members with `role`, `agent`, and `model` fields. |
| `last_session` | ISO 8601 datetime | Timestamp of the last active session. |

## Phase Values

| Phase | Set by | Meaning |
|---|---|---|
| `brainstorming` | brainstorming skill | Design exploration in progress |
| `planning` | writing-plans skill | Plan authoring in progress |
| `composing` | composing-teams skill | Team composition in progress |
| `executing` | any executor skill | Plan execution in progress |
| `finishing` | finishing skill | Completion and cleanup in progress |
| `idle` | finishing skill (on exit) | No active work |

## Write Points by Skill

Each skill writes to state.yml only at key transition points, not continuously.

| Skill | Writes | When |
|---|---|---|
| brainstorming | `phase: brainstorming`, `design.path`, `design.approved`, `design.approved_at` | On design approval |
| using-git-worktrees | `worktree.main.*` | After worktree created |
| composing-teams | `team.name`, `team.roster`, `phase: composing` | After roster finalized |
| writing-plans | `plan.path`, `plan.status: pending`, `plan.executor`, `plan.total_tasks`, `phase: planning` | After plan written |
| subagent-driven / agent-team-driven / executing-plans | `plan.completed_tasks`, `plan.current_wave`, `worktree.implementers.*`, `phase: executing` | After each task completes |
| finishing | `phase: idle`, `plan.status: executed`, clears `worktree.implementers`, clears `team` | On session completion |

## Read Points

| When | Who reads | What they check |
|---|---|---|
| Session start | Session-start hook | All fields — populate context for recovery |
| Skill entry | Any skill | Phase, precondition fields for verification gates |
| Cross-session resume | New session (cold start) | `phase`, `plan.completed_tasks`, `worktree.main.path` |

## Verification Gates

Skills check these fields before proceeding. See `design.md` Section 3 for full gate logic.

| Entering | Required state |
|---|---|
| composing-teams | `design.approved == true`, `worktree.main.path` accessible |
| writing-plans | `design.approved == true`, worktree accessible, `team.roster` if from composing-teams |
| any executor | `plan.path` accessible, `plan.status == pending`, worktree accessible |
| finishing | `plan.completed_tasks` covers all tasks, `worktree.main.repo_root` exists, `worktree.implementers` empty (team mode) |

## Schema Migration

When the schema needs to change, increment `version`. Skills should validate `version == 1` before trusting fields. For unknown versions, warn and ask the user before proceeding.

## Solves

- H3, H4, H5, H6, H8, H13: fully resolved — cross-session state is now explicit
- H1, H2, H7, H10, H11: partially resolved — gates and worktree tracking reduce handoff gaps

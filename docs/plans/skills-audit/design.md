# Skills Audit & Improvement — Design Document

> **Date:** 2026-03-01
> **Status:** Approved — ready for worktree creation + team composition + writing-plans
> **Approach:** Foundation First — build infrastructure that unblocks everything, then fix skills top-down
> **Audit source:** `docs/plans/2026-03-01-skills-audit-brainstorm.md`

## Goal

Systematically improve all 16 Superpowers skills based on a comprehensive audit cross-referencing 104 open issues and 84 open PRs from upstream (obra/superpowers), plus a backwards dependency audit of every skill handoff.

## Findings Summary

- **5 Critical** issues (TDD enforcement, phantom completion, review skipping)
- **33 High** priority issues across 16 skills
- **26 workflow-level findings** (A through Z)
- **13 handoff gaps** (H1 through H13) — nearly all trace to missing persistent state
- **12 upstream worktree issues** — most-reported pain point

## Architecture

### Core Infrastructure (Phase 1)

#### 1. Persistent State File (`.superpowers/state.yml`)

Location: `.superpowers/` in project root, gitignored automatically on first write.

Tracks: workflow phase, design doc path, plan path + status, worktree paths (lead + per-implementer), team roster, completed tasks, current wave.

Each skill writes at key transition points (not continuously). Session-start hook loads it. Any skill reads it mid-session. New sessions read it cold for cross-session recovery.

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

**Write points:** brainstorming (phase, design), using-git-worktrees (worktree), composing-teams (team), writing-plans (plan), executors (progress, implementer worktrees), finishing (cleanup, phase: idle).

**Solves:** H3, H4, H5, H6, H8, H13 (fully), H1, H2, H7, H10, H11 (partially).

#### 2. Directory-Based Plans

```
docs/plans/
└── my-feature/
    ├── design.md          # brainstorming output (never overwritten)
    ├── plan.md            # writing-plans output (overview + task list)
    ├── tasks/             # one file per task (token-efficient loading)
    │   ├── 01-schema.md
    │   ├── 02-api-routes.md
    │   └── 03-ui-page.md
    └── waves.md           # team mode only
```

Rules:
- brainstorming creates directory + `design.md` — never touched by other skills
- writing-plans writes `plan.md` + `tasks/*.md` + optionally `waves.md`
- Executors load individual task files rather than re-reading monolithic plan (~2.7x token savings)
- state.yml stores `plan.path` for cross-session discovery

**Solves:** #565 (overwrite), Finding I (token efficiency), Finding O (structure), H2 (roster location).

#### 3. Verification Gates at Handoffs

Each skill checks its preconditions via state.yml before starting:

| Handoff | Gate checks |
|---|---|
| → composing-teams | state.yml exists, design.approved == true, worktree.main.path accessible |
| → writing-plans | design.approved, worktree accessible, team.roster (if from composing-teams) |
| → any executor | plan.path accessible, plan.status == pending, worktree accessible, roster (if team) |
| → finishing | plan.completed_tasks covers all, worktree.repo_root exists, implementers empty (team) |

Decision framework for composing-teams trigger (replaces vibes-based "if work benefits from specialist agents"):
- Design has 4+ distinct tasks AND 2+ are independent AND 2+ specialist domains → compose team
- Otherwise → skip to writing-plans

**Solves:** H1 (worktree skipped), H9 (vibes-based decision).

#### 4. Canonical Evidence Format

Defined in `verification-before-completion`, referenced by all other skills.

Three evidence types:

| Type | Used by | Contains |
|---|---|---|
| **Command** | Implementers, TDD, verification | command, verbatim output, exit code |
| **Citation** | Reviewers | file:line, code excerpt, verdict per requirement |
| **Diff** | Implementer completion reports | git diff --stat, commit SHA |

Rejection rule: Any report missing required evidence is sent back with "Missing evidence. Required: [type]."

**Solves:** Finding V (evidence-based review), Finding Y (canonical format), phantom completion across all executors.

### Critical Path Fixes (Phase 2)

#### 5. TDD Structural Enforcement

Two mechanisms:

**Plan-level:** writing-plans requires test expectations per task (3-5 lines: what to test, expected red failure mode). Lightweight but makes tests impossible to "forget."

**Execution-level:** All three executors require RED evidence (test fails for right reason) then GREEN evidence (test passes) before marking implementation complete. Uses canonical evidence format.

**Pipelined TDD (team mode):** QA agents write tests one wave ahead. Wave 0 = QA writes tests for Wave 1. Wave N = implementation + QA writes tests for Wave N+1. QA works in lead's worktree (test files don't conflict with implementation in separate worktrees).

Two TDD modes documented in the skill:
- **Solo TDD:** Same agent writes test + implements (non-team)
- **Pipelined TDD:** QA writes test, implementer implements (team mode)

**Solves:** Finding K (biggest systemic gap), Finding P (pipelined), Finding R (test-writer role), #566, #384, #373.

#### 6. Worktree Rework

Layer safety on native `EnterWorktree` tool, don't reimplement:

1. Optional check — skip worktree if user opted out or task is trivial
2. Create via native `EnterWorktree`
3. Layer: baseline test verification, record in state.yml, record repo_root
4. Team mode: `isolation: "worktree"` per implementer, lead tracks in state.yml

Drop: directory selection logic, gitignore verification (native tool handles). Keep: baseline tests, state recording, skip option, setup commands.

Team worktree lifecycle: lead worktree (brainstorming) + implementer worktrees (agent-team). Between waves: merge implementer branches → lead worktree. Implementer worktrees persist while agent is alive, auto-clean on shutdown.

QA agents write in lead's worktree (no conflict with implementers).

**Solves:** 12 upstream issues (#583, #574, #371, #348, #299, #279, #238, #186, #167, #5, PR #483, PR #391), Finding X, H7, H10, H11, H12.

### Mechanical Fixes (Phase 1)

#### 7. TodoWrite → TaskCreate + Generalization

Global find-replace of `TodoWrite` → `TaskCreate`/`TaskUpdate` across all SKILL.md files (6+ occurrences).

Generalize Jesse-specific language: "your human partner" → "the user", "Circle K" signal → "Flag the concern explicitly", "24 failure memories" → "From observed failure patterns".

**Solves:** Finding E, Finding Z.

## Phases

### Phase 1: Foundation
- `.superpowers/state.yml` implementation
- `.superpowers/journal/` structure
- Directory-based plans (`design.md` / `plan.md` / `tasks/`)
- Verification gates at every handoff
- TodoWrite → TaskCreate global rename
- "your human partner" generalization

### Phase 2: Critical Path
- TDD structural enforcement (plan-level + execution-level)
- Canonical evidence format in verification-before-completion
- Evidence requirements in all three executors
- Worktree rework (native EnterWorktree + safety layer)
- Pipelined TDD support in agent-team-driven
- Test-writer agent definition

### Phase 3: Per-Skill Fixes
- Work through each skill's issue table by severity
- Brainstorming: assumption challenging, research step, smart batching
- Writing-plans: role clarity (what/where/why not how), plan review stage
- Reviewing-plans skill (from PR #448)
- Writing-skills: Anthropic guide alignment
- Spawn prompt minimization when project agents exist

### Phase 4: New Capabilities
- Review tiering (light / standard / critical)
- Model tiering (opus / sonnet / haiku defaults)
- Workflow tiering (quick / standard / complex)

## Risks

| Risk | Mitigation |
|---|---|
| State file becomes stale/corrupt | Version field for migration; skills validate before trusting |
| Prompt-based gates still skippable | Evidence format provides structural checksum — harder to fake than prose |
| Worktree rework breaks existing workflows | Optional skip preserves current behavior for users who prefer it |
| Pipelined TDD adds complexity | Solo TDD remains default; pipelined only activates with QA in roster |
| 16-skill refactor is large | Foundation first — each phase is independently valuable |

## References

- Full audit with per-skill issue tables: `docs/plans/2026-03-01-skills-audit-brainstorm.md`
- Upstream repo: https://github.com/obra/superpowers (104 issues, 84 PRs)
- Key upstream PRs: #578 (evidence-based review), #448 (reviewing-plans), #534 (quick mode), #520 (smart batching)

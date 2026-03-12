---
status: pending
---

# Forge v0 Implementation Plan

> See [design](design.md) for context and rationale.
> **For Claude:** Use `superpowers:agent-team-driven-development` to execute this plan.

**Goal:** Build the complete Forge v0 MVP — a structured operating mode for AI-assisted development with risk-scaled ceremony, enforcement hooks, and pack protocol — as a Claude Code plugin evolving from the current Superpowers fork.

**Architecture:** Forge replaces `.superpowers/` with `.forge/` directory containing checked-in config (YAML), shared team knowledge (markdown), and gitignored local state (SQLite or JSON). A risk engine classifies work into 4 tiers (minimal/standard/elevated/critical) crossed with scope (solo/team). Three enforcement layers (prompts → state gates → hooks) prevent skipping required steps. 19 skills orchestrate the full workflow from adoption through completion.

**Tech Stack:** Markdown (skills), YAML (config/policies), Shell (hooks, storage helper), Node.js (viz server, storage helper), SQLite + sqlite-vec (optional local state backend), JSON (fallback backend)

**Worktree:** `/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0` (branch: `worktree-forge-v0`)

---

## Tasks

1. [`.forge/` directory structure and YAML schemas](tasks/01-forge-directory-and-schemas.md)
2. [`forge-state` storage abstraction layer](tasks/02-forge-state-storage-helper.md)
3. [Risk classification engine](tasks/03-risk-classification-engine.md)
4. [Enforcement hooks and state gates](tasks/04-enforcement-hooks-and-gates.md)
5. [`forge-routing` skill](tasks/05-forge-routing-skill.md)
6. [`setting-up-project` skill](tasks/06-setting-up-project-skill.md)
7. [`adopting-forge` skill](tasks/07-adopting-forge-skill.md)
8. [`brainstorming` skill evolution](tasks/08-brainstorming-skill.md)
9. [`writing-plans` skill evolution](tasks/09-writing-plans-skill.md)
10. [`validating-wave-compliance` skill](tasks/10-validating-wave-compliance-skill.md)
11. [`subagent-driven-development` skill evolution](tasks/11-subagent-driven-development-skill.md)
12. [`agent-team-driven-development` skill evolution](tasks/12-agent-team-driven-development-skill.md)
13. [`test-driven-development` skill evolution](tasks/13-test-driven-development-skill.md)
14. [`verification-before-completion` skill evolution](tasks/14-verification-before-completion-skill.md)
15. [`requesting-code-review` and `receiving-code-review` skill evolution](tasks/15-code-review-skills.md)
16. [`finishing-a-development-branch` skill evolution](tasks/16-finishing-skill.md)
17. [Support skills evolution (debugging, worktrees, teams, writing-skills)](tasks/17-support-skills.md)
18. [`syncing-forge` and `diagnosing-forge` skills](tasks/18-sync-and-diagnose-skills.md)
19. [Forge workflow visualization server](tasks/19-forge-viz-server.md)
20. [Pack protocol and hello-world pack](tasks/20-pack-protocol.md)
21. [Integration testing, description optimization, and cleanup](tasks/21-integration-and-cleanup.md)

## Wave Analysis

### Specialists

| Role | Expertise | Tasks |
|------|-----------|-------|
| implementer-1 | Foundation, infrastructure, storage | 1, 3, 5, 8, 11, 14, 17, 20 |
| implementer-2 | Hooks, enforcement, adoption | 2, 4, 7, 9, 12, 15, 18 |
| implementer-3 | Skills, viz, integration | 6, 10, 13, 16, 19 |
| qa-engineer | Test design, behavioral tests | Pipelined TDD — writes tests one wave ahead |
| code-reviewer | Compliance review | Post-wave reviews |

### Waves

**Wave 0: QA writes tests for Wave 1**
- QA writes directory structure validation tests
- QA writes storage helper unit tests (both backends)

**Wave 1: Foundation** — no dependencies
- Task 1 (implementer-1) — `.forge/` directory structure, all YAML schemas, shared/ templates
- Task 2 (implementer-2) — `forge-state` storage helper with SQLite + JSON backends

  *Parallel-safe because:* Task 1 creates directory structure and schema definitions (YAML/markdown files). Task 2 builds a separate CLI tool (shell/Node.js script). No overlapping files.

**Wave 2: Risk + Enforcement** — needs Wave 1 (directory structure + storage helper)
- Task 3 (implementer-1) — Risk classification engine (policy parsing, tier inference, scope assessment)
- Task 4 (implementer-2) — Enforcement hooks (SessionStart, TaskCompleted, PreCommit) + state gate logic

  *Parallel-safe because:* Task 3 creates risk classification logic (reads policies, outputs tier). Task 4 creates hook scripts (reads state, blocks/allows actions). Different files, no import relationship. Both consume the storage helper from Wave 1.

**Wave 3: Core New Skills** — needs Wave 2 (risk engine + hooks)
- Task 5 (implementer-1) — `forge-routing` skill (replaces `using-superpowers`)
- Task 6 (implementer-3) — `setting-up-project` skill (new bridge between design and execution)
- Task 7 (implementer-2) — `adopting-forge` skill (repo inspection, layout proposal, mode selection)

  *Parallel-safe because:* Each is a separate skill directory (`skills/forge-routing/`, `skills/setting-up-project/`, `skills/adopting-forge/`). No overlapping files. Task 5 defines routing logic that 6 and 7 will be routed by, but they don't import from each other — routing is done by the Claude Code skill system at runtime.

**Wave 4: Workflow Skills — Design & Planning** — needs Wave 3 (forge-routing, setting-up-project)
- Task 8 (implementer-1) — `brainstorming` (strip down to design-only, remove worktree/teams/state)
- Task 9 (implementer-2) — `writing-plans` (add risk awareness, team awareness, Forge state)
- Task 10 (implementer-3) — `validating-wave-compliance` (new — compliance checking between waves)

  *Parallel-safe because:* Three separate skill directories. No overlapping files. Task 8 reduces brainstorming, Task 9 enhances writing-plans, Task 10 creates a new skill.

**Wave 5: Workflow Skills — Execution** — needs Wave 4 (planning skills define what execution receives)
- Task 11 (implementer-1) — `subagent-driven-development` (wire to `.forge/`, risk-aware, evidence)
- Task 12 (implementer-2) — `agent-team-driven-development` (wire to `.forge/`, risk-aware, evidence)
- Task 13 (implementer-3) — `test-driven-development` (risk-tier integration, standalone + embedded)

  *Parallel-safe because:* Three separate skill directories. Task 11 and 12 share patterns but are in different directories and don't import from each other. Task 13 is a standalone skill used by 11 and 12 at runtime.

**Wave 6: Workflow Skills — Review & Completion** — needs Wave 5 (execution skills produce what review/verification consume)
- Task 14 (implementer-1) — `verification-before-completion` (risk-tier evidence requirements, wired in)
- Task 15 (implementer-2) — `requesting-code-review` + `receiving-code-review` (team/risk aware)
- Task 16 (implementer-3) — `finishing-a-development-branch` (state cleanup, knowledge promotion)

  *Parallel-safe because:* Separate skill directories. Verification, review, and finishing are independent workflow phases.

**Wave 7: Support Skills + Viz + Adoption Support** — needs Wave 3 (adopting-forge established)
- Task 17 (implementer-1) — `systematic-debugging` + `using-git-worktrees` + `composing-teams` + `writing-skills` (minor Forge updates)
- Task 18 (implementer-2) — `syncing-forge` + `diagnosing-forge` (new adoption support skills)
- Task 19 (implementer-3) — Forge viz server (pipeline view + evidence view, evolve brainstorm server)

  *Parallel-safe because:* Task 17 touches 4 skill directories (minor updates). Task 18 creates 2 new skill directories. Task 19 works on the viz server (separate from skills). No overlapping files.

**Wave 8: Pack Protocol** — needs Wave 7 (adoption support skills for pack discovery)
- Task 20 (implementer-1) — Pack manifest schema, install/remove mechanics, hello-world pack

**Wave 9: Integration** — needs all previous waves
- Task 21 (all) — End-to-end testing, description optimization pass across all 19 skills, `.superpowers/` removal

### Dependency Graph

```
Wave 0 (QA)
    ↓
Task 1 ──┬──→ Task 3 ──┬──→ Task 5 ──┬──→ Task 8 ──┬──→ Task 11 ──┬──→ Task 14 ──→ Task 17 ──→ Task 20 ──→ Task 21
Task 2 ──┘    Task 4 ──┘    Task 6 ──┘    Task 9 ──┘    Task 12 ──┘    Task 15 ──→ Task 18 ──┘
                             Task 7 ──┘    Task 10 ─┘    Task 13 ──┘    Task 16 ──→ Task 19 ──┘
```

## Test Expectations Summary

| Task | What to test | Expected red failure |
|------|-------------|----------------------|
| 1 | `forge-state` rejects ops when `.forge/` structure is invalid | "Error: .forge/project.yaml not found" |
| 2 | Storage helper get/set/query with both backends | "Error: forge-state: command not found" or key-not-found |
| 3 | Risk tier classification given known file patterns + policies | "Error: classify-risk: unknown tier" or wrong tier returned |
| 4 | Hook blocks completion when evidence missing | Hook exits 0 (allows) instead of exit 2 (blocks) |
| 5 | Forge router detects task intent and routes to correct skill | Router returns no skill match or wrong skill |
| 6 | Project setup creates worktree, inits state, classifies risk | "Error: state not initialized" or missing risk tier |
| 7 | Adoption creates `.forge/` and generates CLAUDE.md from repo scan | "Error: .forge/ not created" or empty project.yaml |
| 8 | Brainstorming produces design doc only, no worktree/team/state side effects | Brainstorming still creates worktree (unwanted side effect) |
| 9 | Writing-plans produces team-aware waves when team roster exists | Plan has no wave analysis despite team roster in state |
| 10 | Validation agent catches planted design deviation | Validation passes when it should fail (planted violation missed) |
| 11 | SDD reads/writes `.forge/` state, collects evidence per task | "Error: state.yml not found" or evidence not recorded |
| 12 | ATDD reads/writes `.forge/` state, manages team worktrees | "Error: state.yml not found" or team state not tracked |
| 13 | TDD enforcement scales to risk tier (optional at standard, required at elevated+) | TDD enforced at minimal tier (should be skipped) |
| 14 | Verification blocks completion when risk-tier evidence is incomplete | Verification passes with missing rollback evidence at critical tier |
| 15 | Code review dispatches specialist reviewer at critical tier | No security reviewer dispatched for critical auth change |
| 16 | Finishing cleans up `.forge/local/` state and promotes discoveries to shared/ | Local state not cleaned, or discoveries not promoted |
| 17 | Support skills reference `.forge/` not `.superpowers/` | "Error: .superpowers/state.yml not found" (old reference) |
| 18 | Sync regenerates adapters, doctor reports health status | "Error: syncing-forge skill not found" |
| 19 | Viz server shows pipeline state via WebSocket | Server doesn't start or no WebSocket connection |
| 20 | Pack install merges policies, pack remove is clean | "Error: pack.yaml invalid" or orphaned policy after removal |
| 21 | Full workflow: adopt → design → plan → implement → verify → review → finish | Any step fails to hand off to the next |

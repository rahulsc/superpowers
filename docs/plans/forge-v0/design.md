# Forge v0 — Design Document

**Date:** 2026-03-12
**Status:** Approved

---

## 1. Product Identity & Constraints

### Product

Forge (working title) — a structured operating mode for AI-assisted software development.

### Thesis

Forge gives engineers structured workflows, durable project memory, risk-scaled ceremony, and evidence-gated completion — without surrendering direction or reviewability.

### Target User

- Primary: Senior/staff engineers who want AI help with production-quality guardrails
- Secondary: Infra/security/compliance-heavy teams wanting better planning/review artifacts

### Distribution

- Claude Code plugin (tier 1 — primary development and testing environment)
- Codex adapter (fast-follow via AGENTS.md generation)
- Existing upstream harness support maintained but not perfected (Cursor, OpenCode, Gemini)

### Hard Constraints

1. **Self-evolving post-MVP**: v0 is built with current Superpowers. After MVP ships, all future Forge development uses Forge to build itself.
2. **No big bang**: Existing workflows keep working throughout evolution. Migration is incremental.
3. **Enforcement is real**: Gates must be hook-backed and state-checked, not prompt-only.
4. **Risk-proportional**: Ceremony scales with blast radius. A typo fix is not a database migration.
5. **Lightweight infrastructure**: Markdown + YAML + hooks + skills + optional SQLite. No Go daemons, no databases requiring servers, no tmux dependency.
6. **Brownfield-first**: Must work on existing repos, not just greenfield.

### Not in Scope for v0

- Final product name / public branding
- Open source release
- Real packs (beyond hello-world)
- Perfected non-Claude-Code harnesses
- Standalone CLI
- Remote pack registry

---

## 2. `.forge/` Directory Structure & State Model

### Directory Layout

```
.forge/
  project.yaml              # Project identity, stack, commands, repo traits (checked in)
  workflows/                 # Workflow definitions and customizations (checked in)
  policies/                  # Risk rules, file-match policies (checked in)
  packs/                     # Pack manifests — which packs are enabled (checked in)
  adapters/                  # Generated harness file sources (checked in)

  shared/                    # Team-shared knowledge (checked in)
    architecture.md          # Inferred repo structure, module map, key patterns
    conventions.md           # Team coding conventions
    decisions/               # ADR-style decision records
      NNN-<topic>.md

  local/                     # === Everything below is gitignored ===
    forge.sqlite             # (SQLite backend) All local state in one file
    — OR —
    state.json               # (JSON backend) Session/phase state
    memory/                  # (JSON backend) Project-learned knowledge
    evidence/                # (JSON backend) Per-task evidence artifacts
    checkpoints/             # (JSON backend) Resumable work state
    cache/                   # Ephemeral, safe to delete (both backends)
```

### Key Design Decisions

**Checked-in surface is minimal.** Only `project.yaml`, workflows, policies, pack manifests, adapter sources, and curated team knowledge in `shared/` are checked in. Everything noisy stays in `local/`.

**Shared knowledge is team-facing.** `shared/` contains architecture notes, conventions, and decision records that all team members and their AI agents should know. These are markdown — diffable, mergeable, reviewable in PRs.

**Local state is machine-facing.** Everything in `local/` is gitignored and owned by the agent. Session state, evidence, checkpoints, discoveries, execution plans, task breakdowns — all local. Only outcomes get promoted to `shared/` when validated and team-relevant.

**The local staging area rule.** Discoveries start local. When validated and team-relevant, they get promoted to `shared/`. When formalized into rules, they become `policies/`. When irrelevant, they expire.

```
local discovery → validated → shared/ (team knowledge)
                → formalized → policies/*.yaml (enforced rules)
                → irrelevant → expires/deleted
```

**Execution plans stay local.** Design docs have team relevance and go in `shared/`. Execution plans, task breakdowns, and test expectations are implementation machinery — they stay in `local/` and are disposable after completion. This directly counters document sprawl.

### Storage Backend

Hybrid architecture with pluggable local storage:

**Checked-in config**: YAML (human-editable, diffable)
**Shared team knowledge**: Markdown (diffable, mergeable, reviewable)
**Local state**: SQLite or JSON (configurable in `project.yaml`)

**SQLite backend** (`storage: sqlite` — default when `sqlite3` is on PATH):
- Single `forge.sqlite` file for all local state
- Full SQL queryability for structured data
- `sqlite-vec` extension for semantic/vector search when available
- Proven pattern (Codex uses SQLite for pipeline state)

**JSON backend** (`storage: json` — fallback, zero dependencies):
- Structured JSON files in `local/` subdirectories
- No vector/semantic search (keyword grep fallback)
- Human-inspectable files
- Works everywhere

**Auto-detection**: If `sqlite3` is on PATH, default to SQLite. Otherwise fall back to JSON. User can override in `project.yaml`.

**Abstraction layer**: Skills interact with storage through a thin helper (shell script or Node.js), never referencing a backend directly:
```
forge-state get <key>
forge-state set <key> <value>
forge-memory add <type> <content>
forge-memory query <type> [--similar <text>]
forge-evidence add <task-id> <artifact>
```

### What Goes in Local State

| Category | Examples | Why local? |
|----------|----------|------------|
| Session state | Current phase, active task, gates passed, worktrees | Ephemeral to current work |
| Execution plans | Task breakdowns, wave assignments, test expectations | Implementation machinery |
| Work-in-progress evidence | Test output, verification logs, review notes | Per-developer, verbose |
| Checkpoints | Resume state for cold restart mid-feature | Per-developer |
| Runtime discoveries | "CI takes 12 min", "tests need Docker" | Not yet validated for sharing |
| Error patterns | "Edits to auth/ trigger lint rule X" | Agent-learned, dev-specific |
| Developer context | "Works on payments module", "prefers verbose errors" | Personal |
| Cache | File index, symbol map, pack registry | Regenerable, ephemeral |
| Vector embeddings | Semantic index of codebase/memories | Machine-generated, large |

---

## 3. Risk-Scaled Ceremony

### Two-Dimensional Risk Model

Risk is assessed on two dimensions: **blast radius** and **scope/complexity**.

**Blast radius × scope matrix:**

| | Small scope (1-3 tasks) | Medium scope (4-8 tasks) | Large scope (9+ tasks) |
|---|---|---|---|
| **Minimal blast radius** | Minimal tier, solo | Standard tier, solo | Standard tier, team optional |
| **Standard blast radius** | Standard tier, solo | Elevated tier, team recommended | Elevated tier, team required |
| **High blast radius** | Elevated tier, solo | Critical tier, team required | Critical tier, team required |

### Risk Tiers

| Tier | Examples | Required Artifacts |
|------|----------|-------------------|
| **Minimal** | Typo fix, doc edit, log message change | Verification evidence only |
| **Standard** | New helper function, bug fix, isolated refactor | Plan (can be inline) + test evidence + verification |
| **Elevated** | New feature, cross-file refactor, API change | Design doc + plan + TDD + evidence-gated verification + review |
| **Critical** | DB migration, auth/authz, API contract, payment flow | Design doc + risk register + plan + TDD + security review + rollback evidence + reviewer role requirements |

### Risk Determination (Priority Order)

1. **Policy rules** (explicit, in `policies/*.yaml`):
```yaml
rules:
  - match: ["db/migrations/**"]
    tier: critical
    require: ["rollback-plan", "compat-check"]

  - match: ["auth/**", "permissions/**"]
    tier: critical
    require: ["security-review"]

  - match: ["src/api/public/**"]
    tier: elevated
    require: ["contract-check"]

  - match: ["docs/**", "*.md"]
    tier: minimal
```

2. **Agent inference** — when no policy matches, assess scope/reversibility/blast radius and propose a tier with rationale.

3. **User override** — always available, always recorded in evidence.

### What Changes Per Tier

| Capability | Minimal | Standard | Elevated | Critical |
|------------|:-------:|:--------:|:--------:|:--------:|
| Design doc | - | - | Required | Required |
| Execution plan | - | Inline or skip | Required | Required |
| Worktree isolation | Optional | Recommended | Required | Required |
| TDD | - | Optional | Required | Required |
| Wave validation | - | - | Required | Required |
| Verification evidence | Required | Required | Required | Required + rollback |
| Code review | - | Optional | Required | Required + specialist |
| Risk register | - | - | - | Required |
| User approval gates | - | - | Design approval | Design + plan + merge |

### Team Mode Requirements

| Capability | Solo | Team |
|------------|------|------|
| Worktree isolation | Optional/recommended | Required (per-agent) |
| Coordinator agent | N/A | Required |
| Wave validation | Post-wave check | Post-wave + cross-agent consistency |
| Pipelined TDD | N/A | QA writes tests one wave ahead |
| Communication protocol | N/A | Shared task list + messaging |
| Evidence aggregation | Single stream | Per-agent, merged by coordinator |
| Review | Single reviewer | Dedicated reviewer agent |

### Risk Classification Decision Flow

1. Determine blast radius (policy rules → agent inference → user override)
2. Determine scope (task count from plan decomposition)
3. Matrix lookup → tier + execution strategy (solo vs team)
4. Agent proposes: "This looks like an elevated-tier task with 6 independent tasks. I recommend team execution. Agree?"
5. User confirms or adjusts

---

## 4. Enforcement & Validation

### Three Enforcement Layers

**Layer 1: Prompt-level gates (weakest)**
Skills contain instructions ("do NOT proceed without evidence"). LLMs routinely rationalize past these.

**Layer 2: State-based gates (medium)**
Before allowing progression, check `.forge/local/` state. If required precondition isn't recorded, block.

- Can't start `writing-plans` unless `design.approved: true`
- Can't start execution unless `plan.approved: true`
- Can't start next wave unless current wave tasks have `compliance: passed`
- Can't run `finishing-a-development-branch` unless `verification.passed: true`

**Layer 3: Hook-based gates (strongest)**
Claude Code hooks that fire on lifecycle events and check state before allowing action. Shell scripts return exit code 2 to block + provide feedback. The LLM cannot rationalize past a script.

```
Hook: TaskCompleted
  → Check: verification evidence exists for this task?
  → If no: exit 2 — "Cannot complete: missing verification evidence"

Hook: PreCommit
  → Check: risk tier requirements met?
  → If no: exit 2 — "Risk tier [elevated] requires: [review]. Missing: [review]"

Hook: SessionStart
  → Check: .forge/project.yaml exists?
  → If yes: load Forge context, set routing mode
  → If no: ephemeral mode
```

### Enforcement Per Risk Tier

| Gate | Minimal | Standard | Elevated | Critical |
|------|:-------:|:--------:|:--------:|:--------:|
| Design approval in state | - | - | Required | Required |
| Plan approval in state | - | Required | Required | Required |
| Wave compliance validation | - | - | Required | Required |
| Test evidence per task | Required | Required | Required | Required |
| Verification at completion | Required | Required | Required | Required + rollback |
| Review evidence | - | Optional | Required | Required + specialist |
| Hook-enforced completion gate | Yes | Yes | Yes | Yes |
| Hook-enforced commit gate | - | - | Yes | Yes |

### The Validation Agent (`validating-wave-compliance`)

A dedicated agent running between waves — independent of the implementer, checking compliance.

**Checks:**
1. Design compliance — do code changes match the approved design doc?
2. Plan compliance — does implementation match the planned approach?
3. Integration check — after merging wave branches, do all tests pass?
4. Convention compliance — does code follow `shared/conventions.md`?

**How it works:**
1. Receives: design doc path, plan path, diff of wave's changes, test output
2. Produces: compliance report with pass/fail per check, specific deviations
3. If fail: blocks next wave, sends deviation list to implementers
4. If pass: updates state, wave proceeds

**Why dedicated:** Fresh agent reads design/plan with no accumulated context bias. Parallels the spec-reviewer pattern but at wave level.

### Failure Handling

1. Hook blocks action → agent receives clear message saying what's missing
2. Agent produces missing artifact → retries, hook passes
3. Agent can't produce → escalates to user with options
4. User override → recorded in evidence. Visible, not silent.

---

## 5. Workflow Visualization

### Architecture

Evolve the existing brainstorming visual companion:

```
.forge/local/ state changes
       ↓ (file watcher)
  forge-viz server (zero-dep Node.js)
       ↓ (WebSocket push)
  Browser dashboard
```

- Same zero-dep approach as brainstorming server
- File watcher on `.forge/local/` — state changes push to browser
- Auto-lifecycle — starts on request, auto-exits on idle
- Read-only — shows state, doesn't modify it

### Views

**v0:**
- **Pipeline view** — current phase in workflow, what's done, what's next
- **Evidence view** — what evidence collected, what's missing per risk tier

**v0.1:**
- **Wave view** — task assignments, agent status, completion %
- **Team view** — agent roster, worktree status
- **Compliance view** — validation results, deviations found/fixed

### Activation

- Opt-in by default
- Auto-offered at elevated/critical tiers
- Persistent across phases once opened

---

## 6. Pack Protocol

### Pack Structure

A pack is a separate repository with a standard structure:

```
forge-pack-<name>/
  pack.yaml              # Manifest
  policies/              # Policy rules to merge
  workflows/             # Workflow definitions
  skills/                # Skills this pack adds
  agents/                # Agent definitions
  shared/                # Knowledge templates
  README.md
```

### Pack Manifest (`pack.yaml`)

```yaml
name: <pack-name>
version: <semver>
description: <what this pack provides>
forge_compatibility: ">=0.1.0"
provides:
  skills: [<skill-names>]
  policies: [<policy-names>]
  agents: [<agent-names>]
triggers:
  file_patterns: [<globs that suggest this pack>]
  stack_signals: [<stack indicators>]
```

### Pack Lifecycle

```
Discovery → Recommendation → Preview → Install → Active → Update → Remove
```

1. **Discovery** — adoption/sync scans repo, matches against available packs
2. **Recommendation** — "Your project has migrations. Install `forge-pack-database`?"
3. **Preview** — show every file that will be added. No surprises.
4. **Install** — record in `.forge/packs/`, merge policies, register skills
5. **Active** — pack skills/policies/agents available to Forge routing
6. **Update** — `syncing-forge` checks for updates
7. **Remove** — clean removal, no orphaned state

### Hello-World Pack (v0)

```
forge-pack-hello-world/
  pack.yaml
  policies/
    greeting-policy.yaml
  skills/
    greeting-workflow/
      SKILL.md
  shared/
    greeting-conventions.md
  README.md
```

Proves: discovery, installation, policy merge, skill routing, removal.

### Not in v0

- Remote pack registry
- Pack versioning/dependency resolution
- Pack marketplace
- Any real domain packs

---

## 7. Adoption Flow & Migration Path

### `adopting-forge` — New Repo Flow

**Step 1: Inspect** — scan repo structure, detect stack, AI surfaces, risk areas, conventions.

**Step 2: Propose** — present findings with confidence scores.

**Step 3: Choose mode:**
- Light touch — `.forge/project.yaml` only. Skills available but advisory.
- Full adoption — complete `.forge/` directory, generated CLAUDE.md, enforcement hooks.

**Step 4: Preview** — show every file to be created/modified. Nothing hidden.

**Step 5: Apply** — only after user confirms.

**Step 6: Verify** — run `diagnosing-forge` immediately.

### Light Touch → Full Upgrade

Users who started light can re-run adoption and choose full. Same preview/confirm flow.

### Codex Compatibility

`adopting-forge` generates `AGENTS.md` for Codex alongside CLAUDE.md. Policy and state model are identical — only adapter output differs.

### Migration: Superpowers → Forge

**Approach: Complete MVP in one pass, then cut over.**

v0 is built using current Superpowers as the development environment. No mid-build plugin reloads, no compatibility shims between `.superpowers/` and `.forge/`, no bridging code. The full Forge MVP is built on a feature branch and merged when complete.

The self-evolving property kicks in *after* MVP ships — all future Forge development uses Forge to build itself. But v0 itself is built with the current tooling.

**Build phases (test gates, not reload points):**

1. **Foundation** — `.forge/` directory, state model, storage helper
2. **Risk engine** — tier classification, policy rules, scope assessment
3. **Enforcement** — hooks, state gates, validation agent
4. **Adoption** — `adopting-forge`, `syncing-forge`, `diagnosing-forge`
5. **Skill evolution** — all 19 skills written/refactored to Forge model
6. **Visualization** — pipeline + evidence views
7. **Pack protocol** — protocol + hello-world pack
8. **Integration** — full end-to-end testing, `.superpowers/` removed

Each phase has a test gate. The feature branch is merged to main only when all phases pass.

---

## 8. Skill Architecture

### Full Skill Inventory (19 skills)

**Phase 1 — Design:**
| Skill | Responsibility |
|-------|---------------|
| `brainstorming` | Explore ideas, produce design doc only. No worktree, no teams, no state setup. |

**Phase 2 — Setup:**
| Skill | Responsibility |
|-------|---------------|
| `setting-up-project` (NEW) | Risk classification, worktree creation, state initialization, team decision (invokes `composing-teams` if needed), shared doc updates, memory placeholders. |

**Phase 3 — Planning:**
| Skill | Responsibility |
|-------|---------------|
| `writing-plans` | Execution plan. Team-aware (parallelizable waves). Risk-aware (scales detail to tier). |

**Phase 4 — Execution (one of):**
| Skill | Responsibility |
|-------|---------------|
| `subagent-driven-development` | Solo execution: fresh subagent per task, two-stage review, sequential waves. |
| `agent-team-driven-development` | Team execution: persistent specialists, parallel waves, pipelined TDD, coordinator. |

**During Execution:**
| Skill | Responsibility |
|-------|---------------|
| `validating-wave-compliance` (NEW) | Design/plan compliance check between waves. Blocks progression until deviations fixed. Dedicated validation agent. |

**Phase 5 — Verification:**
| Skill | Responsibility |
|-------|---------------|
| `verification-before-completion` | Evidence-gated completion. Checks evidence set against risk tier requirements. |

**Phase 6 — Review:**
| Skill | Responsibility |
|-------|---------------|
| `requesting-code-review` | Dispatches review. Team-aware, risk-aware. |
| `receiving-code-review` | Handles review feedback. |

**Phase 7 — Completion:**
| Skill | Responsibility |
|-------|---------------|
| `finishing-a-development-branch` | PR/merge/cleanup. State cleanup, worktree teardown, knowledge promotion from local to shared. |

**Standalone:**
| Skill | Responsibility |
|-------|---------------|
| `systematic-debugging` | Structured debugging. Risk-tier aware. |
| `test-driven-development` | TDD enforcement. Invoked by execution skills, also standalone. |

**Meta:**
| Skill | Responsibility |
|-------|---------------|
| `forge-routing` (NEW) | Replaces `using-superpowers`. Forge identity, task classification, skill routing. |
| `writing-skills` | Evolves into Forge skill/pack authoring. |

**Infrastructure (invoked by other skills):**
| Skill | Responsibility |
|-------|---------------|
| `using-git-worktrees` | Worktree management. |
| `composing-teams` | Team composition. |

**Adoption:**
| Skill | Responsibility |
|-------|---------------|
| `adopting-forge` (NEW) | Inspect repo, propose layout, create `.forge/`, generate CLAUDE.md/AGENTS.md. |
| `syncing-forge` (NEW) | Regenerate adapters, refresh state, check consistency. |
| `diagnosing-forge` (NEW) | Health checks, diagnose issues, suggest fixes. |

### Changes from Current

| Dropped | Reason |
|---------|--------|
| `dispatching-parallel-agents` | Absorbed by risk-tier + subagent-driven |
| `executing-plans` | YAGNI — Claude Code and Codex have subagents |
| `using-superpowers` | Replaced by `forge-routing` |

| New | Purpose |
|-----|---------|
| `setting-up-project` | Bridge between design and execution |
| `validating-wave-compliance` | Design/plan compliance between waves |
| `forge-routing` | Forge identity and skill router |
| `adopting-forge` | Adoption flow |
| `syncing-forge` | Sync/refresh flow |
| `diagnosing-forge` | Health check flow |

### Skill Sizing

All skills must stay under 500 lines / 5,000 words per Anthropic's skill development guide. Reference material goes in `references/` subdirectories for progressive disclosure.

### Description Convention

All descriptions start with "Use when..." and describe triggering conditions only — never summarize the skill's workflow (which causes LLMs to shortcut the full skill).

---

## 9. Testing Strategy

### Conventional Testing (Deterministic Code)

| Component | Test Type |
|-----------|-----------|
| Hook scripts | Shell unit tests |
| Storage helper (forge-state) | Unit tests per backend |
| Pack install/remove | Integration tests |
| Viz server | Existing brainstorm server test pattern |
| Adoption flow file generation | Snapshot tests |
| State migration | Integration tests |

**Pipelined TDD applies** for these — QA writes tests one wave ahead of implementers.

### Behavioral Testing (Skills & Workflows)

| Component | Test Type |
|-----------|-----------|
| Skill triggering | Triggering prompt tests (existing pattern) |
| Enforcement gates | E2E chain tests with planted violations |
| Validation agent | Pressure tests with planted deviations |
| Risk classification | Scenario tests with known-risk file patterns |
| Cold resume | Checkpoint → kill → resume tests |
| Full workflow | End-to-end chain: adopt → design → plan → implement → verify → review → finish |

**Not pipelined** — these test emergent behavior and need the system running to validate.

### Checkpoint Gate

Each migration checkpoint includes: "does the workflow still work end-to-end?" verified by the behavioral test suite.

---

## 10. Implementation Approach

### Sequencing

Foundation + Evolution approach:

1. `.forge/` state model + storage helper + project memory structure
2. Risk-scaling engine bolted onto existing workflow backbone
3. Enforcement deepening — validation agent, hook-based state checks
4. `adopting-forge` skill — now has a real state model and risk engine
5. Evolve each existing skill in parallel — rename, optimize descriptions, wire into `.forge/`, make risk-aware
6. Workflow visualization — evolve brainstorming viz
7. Pack protocol + hello-world pack
8. Agent/skill description optimization pass

### Estimated Timeline

~3-4 weeks (agents full-time, human reviewing in parallel). Existing codebase saves ~1 week vs greenfield.

### Self-Evolution Checkpoints

v0 is built in one pass on a feature branch using current Superpowers. Self-evolution begins post-MVP.

---

## Appendix A: Competitive Research Summary

Full research document: `docs/forge_competitive_research.md`

Key gaps Forge fills that no competitor addresses:
1. Structured phases + real enforcement (not advisory)
2. Risk-scaled ceremony (proportional to blast radius)
3. Multi-agent + structured development combined
4. Evidence as a completion gate (not implicit)
5. Cross-session state persistence
6. Composability across tools (not IDE-locked)

## Appendix B: Open Questions (Deferred Past v0)

1. Final product name (Forge is working title)
2. Remote pack registry architecture
3. Pack dependency resolution
4. Enterprise features (SSO, RBAC, central policy)
5. Contribution model for community packs
6. Pricing/licensing model for open source release

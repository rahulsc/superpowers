# Forge Release Notes

## v0.1.0 (2026-03-13)

### Initial Release — Clean Break from Superpowers

Forge is a structured operating mode for AI-assisted software development,
independently evolved from [Superpowers](https://github.com/obra/superpowers)
by Jesse Vincent.

#### 21 Skills

**Routing:** forge-routing

**Adoption & Setup:** adopting-forge, setting-up-project, syncing-forge, diagnosing-forge

**Design & Planning:** brainstorming, writing-plans, composing-teams

**Execution:** subagent-driven-development, agent-team-driven-development,
test-driven-development, using-git-worktrees, validating-wave-compliance

**Debugging:** systematic-debugging

**Review & Completion:** requesting-code-review, receiving-code-review,
verification-before-completion, finishing-a-development-branch

**Meta & Extensibility:** writing-skills, forge-packs, forge-viz

#### Forge Infrastructure

- **`.forge/` directory** — project.yaml configuration, risk policies, shared
  knowledge templates, workflow definitions, adapter and pack directories
- **Risk classification engine** — Two-dimensional policy + scope matrix with
  four tiers (minimal/standard/elevated/critical), file-glob-based policy rules
- **Persistent state** — forge-state helper with SQLite and JSON backends for
  cross-session continuity
- **Evidence collection** — forge-evidence utility for structured verification output
- **Cross-session memory** — forge-memory for knowledge promotion and recall
- **Pack protocol** — forge-pack CLI for installing, removing, and listing
  reusable bundles of skills, policies, and shared knowledge
- **Sample pack** — forge-pack-hello-world demonstrating pack.yaml manifest format

#### 4 Forge Hooks

- forge-session-start — Session initialization, state cleanup, memory promotion
- forge-gate — Evidence verification gate before completion claims
- forge-pre-commit — Pre-commit validation
- forge-task-completed — Task completion handler, state updates, knowledge promotion

#### 5 Agent Definitions

Architect, implementer, QA engineer, code reviewer, security reviewer

#### Multi-Platform Support

Claude Code, Cursor, OpenAI Codex, OpenCode, Gemini CLI

#### What Changed from Upstream Superpowers

- Complete identity transition: superpowers → forge across all files
- 8 new skills (forge-routing, adopting-forge, setting-up-project, syncing-forge,
  diagnosing-forge, forge-packs, forge-viz, validating-wave-compliance)
- .forge/ directory with risk classification, persistent state, evidence collection,
  memory, and pack protocol
- 4 Forge-specific hooks replacing upstream session-start
- Multi-agent team composition and orchestration
- Verification wiring and evidence-gated completion
- Risk-scaled ceremony (scale process to match task complexity)
- Pipelined TDD (QA agents write tests ahead of implementers)
- Dual MIT licensing with proper attribution

---

*For release history prior to the Forge divergence, see the frozen fork at
[rahulsc/superpowers](https://github.com/rahulsc/superpowers). The original
project is at [obra/superpowers](https://github.com/obra/superpowers).*

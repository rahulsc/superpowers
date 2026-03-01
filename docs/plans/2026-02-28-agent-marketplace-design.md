# Agent Marketplace: First-Class Team Composition for Superpowers

## Goal

Transform superpowers from a serial-execution skill system into a team-aware development platform where agent composition, parallel execution, and git isolation are first-class concerns.

## Architecture

The design adds a new `composing-teams` skill, merges the two plan-writing skills into one, updates 10 existing skills with team awareness, and ships a small set of generalized agent definitions. Per-agent git worktrees provide isolation during parallel execution, with lead-managed merges between waves.

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Approach | Agent Marketplace (new composing-teams skill + generalized agents) | First-class team composition; treats teams as a core capability |
| Plan skills | Merge `writing-plans` + `writing-plans-for-teams` into one | 60%+ content overlap; Team Fitness Check toggles format inline |
| Git isolation | Per-agent worktrees (mandatory for teams) | Safest for true parallelism; aligns with existing worktree skill |
| Model policy | Opus default for superpowers subagents; most powerful available for unspecified agent defs | Quality-first; user definitions honored |
| Worktree timing | Decided during brainstorming, mandatory | All subsequent agent work inherits the worktree |
| Execution routing | Decoupled from plan format | Both plan formats can use any of 3 execution approaches |

---

## 1. New Skill: `composing-teams`

### Purpose

Sits between brainstorming and plan-writing. Creates a team roster by discovering, presenting, and letting the user select agent definitions.

### Process

1. **Discover** — Scan for agent `.md` files in order of priority:
   - `.claude/agents/` (project-level, highest priority)
   - `~/.claude/agents/` (global/personal)
   - Superpowers `agents/` directory (shipped defaults, lowest priority)
   - Deduplicate by name: project overrides global overrides shipped

2. **Present** — Group discovered agents by tier:
   - **Leadership** (opus model, broad tools): project leads, architects
   - **Engineers** (implementation-focused, full tools): domain-specific implementers
   - **Specialists** (cross-cutting expertise, full tools): database, devops, etc.
   - **Reviewers** (opus model, restricted/read-only tools): architecture, security, UX review
   - **QA** (testing tools): testing-focused agents
   - Show: name, description, model, tool restrictions per agent

3. **Compose** — User selects:
   - Which agents to include in the team
   - How many of each (e.g., 2x frontend-engineer, 1x backend-engineer)
   - Option to create new agent definitions on the fly
   - If any agents lack a model specification, note that the most powerful available model will be used by default

4. **Output** — Team roster added to the design doc:
   ```markdown
   ## Team Roster

   | Role | Agent Definition | Count | Model | Tier |
   |------|-----------------|-------|-------|------|
   | react-engineer-1 | eng-frontend-core | 2 | sonnet | Engineer |
   | backend-engineer-1 | eng-archives-library | 1 | sonnet | Engineer |
   | security-reviewer-1 | reviewer-security | 1 | opus | Reviewer |
   ```

5. **Route** — Apply fitness check:
   - If roster has 2+ specialists AND work has parallelizable components → team plan format
   - Otherwise → standard serial plan format
   - Either way, execution handoff offers all 3 options

### Agent Definition Format

Standard `.md` with YAML frontmatter per [Claude Code docs](https://code.claude.com/docs/en/sub-agents):

```yaml
---
name: architect
description: Architecture decisions, API design, cross-service consistency
model: opus
tools: [Read, Write, Edit, Bash, Glob, Grep]
---

[System prompt content...]
```

Supported frontmatter fields (from official docs): `name`, `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `isolation`.

---

## 2. Shipped Agent Definitions

Ship a small set of generalized, project-agnostic agents in `agents/`. These are starting points — users are expected to create project-specific agents that override or extend them.

### Agents to Ship

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| `code-reviewer` (update existing) | opus | Read, Glob, Grep, Bash | Code quality and best practices review |
| `architect` | opus | Read, Write, Edit, Bash, Glob, Grep | Architecture decisions, API design, system design review |
| `security-reviewer` | opus | Read, Glob, Grep, Bash | Security vulnerability assessment, injection defense, secret handling |
| `implementer` | opus | Read, Write, Edit, Bash, Glob, Grep | Generic implementation agent for any language/framework |
| `qa-engineer` | opus | Read, Write, Edit, Bash, Glob, Grep | Test design, test automation, coverage analysis |

### Design Principles for Shipped Agents

- **Generalized**: No language or framework specifics — those belong in project-level agents
- **Opus by default**: Superpowers skills use the most powerful model by default
- **Tool-restricted reviewers**: Review agents get read-only tools (Read, Glob, Grep, Bash for running tests/linters) — no Write/Edit to prevent accidental modifications
- **Detailed descriptions**: Claude uses the description to decide when to delegate; descriptions must be specific enough for accurate routing
- **No project context**: System prompts describe the role and methodology, not project-specific patterns

### Attribution and References

For users who want more specialized agents:

- **[VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)**: Collection of 127+ specialized Claude Code subagents across 10 categories (core dev, language specialists, infrastructure, QA/security, data/AI, developer experience, domains, business/product, meta/orchestration, research)
- **[Claude Code official docs on subagents](https://code.claude.com/docs/en/sub-agents)**: Canonical reference for agent definition format, tool scoping, permission modes, persistent memory, and hooks
- **[Claude Code agent teams docs](https://code.claude.com/docs/en/agent-teams)**: Official guide for team orchestration, spawning, task coordination, and display modes

The Avaranthia project (`~/Projects/Avaranthia/.claude/agents/`) serves as a reference for how project-specific agents should be structured: 17 agents across 5 tiers with domain-specific system prompts, intentional model selection (opus for judgment, sonnet for execution), and restricted tools for reviewers.

---

## 3. Merged Skill: `writing-plans` (unified)

### What Changes

The current `writing-plans` and `writing-plans-for-teams` merge into a single `writing-plans` skill. The Team Fitness Check (from `writing-plans-for-teams`) becomes an inline decision point. `writing-plans-for-teams` is removed.

### Flow

1. Read requirements / design doc (including team roster if present)
2. Draft task list
3. **Team Fitness Check** (if team roster exists from composing-teams):
   - 2+ waves with 2+ tasks each AND 2+ distinct specialist roles AND 4+ tasks total → add wave analysis and specialist metadata
   - Otherwise → standard serial format
4. Write tasks with appropriate format:
   - **Team format:** adds Specialist, Depends on, Produces fields + wave analysis section + dependency graph
   - **Serial format:** standard task structure with optional Agent field
5. If team roster exists, reference specific agent definitions per task
6. **Execution Handoff** — always presents all 3 options:
   - Agent Team-Driven (same session, parallel specialists, wave-based)
   - Subagent-Driven (same session, serial, fresh agent per task)
   - Parallel Session (separate session, batch execution with checkpoints)

### Agent-Aware Tasks (new for serial too)

Even in serial mode, tasks can specify which agent definition to use:

````markdown
### Task N: [Component Name]

**Agent:** eng-frontend-core (or `general-purpose` if no roster)
**Files:**
- Create: `exact/path/to/file.ts`
- Test: `exact/path/to/test.ts`

**Step 1: Write the failing test**

```typescript
// test code
```
````

When the execution skill dispatches an implementer, it uses the specified agent definition instead of generic `general-purpose`.

### Bug Fixes in Merge

- Fix nested code fences (use 4-backtick outer fences, as `writing-plans` already does)
- Differentiated description: the unified skill keeps `writing-plans`'s existing description
- Remove duplication: shared sections (Bite-Sized Granularity, Remember checklist) appear once

---

## 4. Changes to `agent-team-driven-development`

### Git Isolation (new section)

Per-agent worktrees are mandatory for team execution — no exceptions unless the user explicitly provides an alternative:

1. Each implementer spawned with `isolation: "worktree"` on the Agent tool
2. Implementers work on isolated branches within their worktrees
3. After each wave's reviews pass, lead merges implementer branches into the main worktree
4. Before starting next wave, lead ensures merge is clean
5. If merge conflicts: lead resolves or directs the relevant implementer to resolve
6. After all waves complete, all per-agent worktrees are cleaned up

### Roster-Based Spawning (replaces hardcoded roles)

Instead of hardcoding role names like `react-engineer`, use the agent definition from the roster:

```
Agent tool:
  subagent_type: eng-frontend-core  (from roster)
  name: "react-engineer-1"
  isolation: "worktree"
  team_name: [team-name]
```

Multiple agents of the same definition get numbered names (e.g., `react-engineer-1`, `react-engineer-2`).

### Bug Fixes

- Add `dot` process flow diagram (consistency with all other skills)
- Fix prompt templates: "Task tool" → "Agent tool"
- Fix max specialist limit inconsistency: clarify "max 3 simultaneous implementers" vs "max 3 specialist roles" — these are the same constraint stated differently

---

## 5. Changes to Other Skills

### `brainstorming` — Add worktree + team composition phase

After design approval, two new mandatory steps:

1. **Worktree creation** — Create project worktree via `using-git-worktrees`. Record the worktree path in the design doc. All subsequent agent work uses this worktree.

2. **Team composition** — Invoke `composing-teams` skill:
   - Discover available agent definitions
   - Present them to user, grouped by tier
   - User selects agents and counts
   - Team roster added to design doc

Updated terminal state:
- Old: "The ONLY skill you invoke after brainstorming is writing-plans"
- New: "Create worktree, invoke composing-teams if the work benefits from specialists, then invoke writing-plans"

### `subagent-driven-development` — Add agent-aware dispatch

- When a team roster exists, dispatch implementer subagents using the specified agent definition instead of generic `general-purpose`
- If agent definition doesn't specify a model, use the most powerful available model
- Add mention of `agent-team-driven-development` as alternative: "If plan has 4+ tasks with 2+ waves of parallelism, consider agent-team-driven-development for parallel execution"

### `executing-plans` — Add comparison with team execution

- Add brief comparison: "For same-session parallel execution with persistent specialists, see agent-team-driven-development"
- Execution handoff mentions all 3 options

### `requesting-code-review` — Add roster-aware + peer review

- When a team roster includes reviewer agents (e.g., `reviewer-architecture`, `reviewer-security`), use those definitions for review dispatch instead of generic `code-reviewer`
- Add team peer review option: specialist A reviews specialist B's work (within same wave or across waves)

### `receiving-code-review` — Add peer review context

- When feedback comes from a team peer (vs external reviewer), guidance on escalation and disagreement resolution
- "If you disagree with peer feedback, involve team lead before rejecting"

### `finishing-a-development-branch` — Add team cleanup

- "If operating in a team, shutdown all specialist agents before merging"
- Ensure all per-agent worktrees are cleaned up
- Reference `agent-team-driven-development` Phase 3 for cleanup sequence

### `systematic-debugging` — Add parallel investigation

- When multiple potential root causes exist, mention `dispatching-parallel-agents` for parallel investigation
- "When blocking multiple team tasks, elevate to team lead immediately"

### `using-superpowers` — Add team awareness

- Mention team composition and agent-aware execution capabilities
- Reference `composing-teams` skill in skill priority section
- Note that agent teams are experimental and require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` setting

---

## 6. Model Policy

### Superpowers Skills

All subagents dispatched by superpowers skills (spec reviewers, code quality reviewers, etc.) use `model: "opus"` by default on the Agent tool call.

### Shipped Agent Definitions

All agents shipped with superpowers use `model: opus`. The existing `code-reviewer.md` changes from `model: inherit` to `model: opus`.

### User-Defined Execution Agents

- If the agent definition specifies a model → use that model
- If the agent definition has no model or says `model: inherit` → use the most powerful available model

---

## 7. Worktree Lifecycle

Worktrees are mandatory for teams — no exceptions unless the user explicitly provides an alternative.

```
brainstorming creates main project worktree (via using-git-worktrees)
  → composing-teams operates in main worktree
  → writing-plans operates in main worktree
  → execution:
      team:   each agent gets per-agent worktree (isolation: "worktree")
              lead merges agent branches between waves
              all per-agent worktrees cleaned up after completion
      serial: single agent uses main worktree directly
  → finishing-branch handles main worktree merge/PR/cleanup
```

The worktree path is recorded in the design doc during brainstorming so all future agent work in that project inherits it.

---

## 8. Summary of All Changes

### New

| Item | Type | Description |
|------|------|-------------|
| `composing-teams` | New skill | Agent discovery, team composition, roster output |
| `architect` | New agent | Architecture decisions, API design, system design review |
| `security-reviewer` | New agent | Security vulnerability assessment |
| `implementer` | New agent | Generic implementation agent |
| `qa-engineer` | New agent | Test design and automation |
| Git Isolation section | New in agent-team-driven-dev | Per-agent worktrees, lead-managed merges between waves |

### Modified

| Skill | Change |
|-------|--------|
| `writing-plans` | Absorb `writing-plans-for-teams`: inline Team Fitness Check, wave analysis, agent-aware tasks, all 3 execution options |
| `agent-team-driven-development` | Roster-based spawning, per-agent worktrees, dot diagram, fix prompt template tool names |
| `subagent-driven-development` | Agent-aware dispatch from roster, routing to team alternative |
| `brainstorming` | Worktree creation step, invoke composing-teams, updated terminal state |
| `executing-plans` | Comparison with team execution, all 3 execution options |
| `requesting-code-review` | Use roster reviewer agents, team peer review option |
| `receiving-code-review` | Peer review context, escalation guidance |
| `finishing-a-development-branch` | Team cleanup, per-agent worktree cleanup |
| `systematic-debugging` | Parallel investigation mention, team escalation |
| `using-superpowers` | Mention team composition capabilities |
| `code-reviewer` (agent) | Model changed from `inherit` to `opus` |

### Removed

| Item | Reason |
|------|--------|
| `writing-plans-for-teams` | Merged into `writing-plans` |

### Unchanged

| Skill | Reason |
|-------|--------|
| `test-driven-development` | Pure technique, team-agnostic |
| `verification-before-completion` | Pure discipline, team-agnostic |
| `using-git-worktrees` | Foundational infrastructure, already correct |
| `writing-skills` | Meta skill, already correct |
| `dispatching-parallel-agents` | Already handles parallel agents well |

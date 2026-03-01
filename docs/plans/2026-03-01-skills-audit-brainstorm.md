# Skills Audit & Improvement Brainstorm

> **Date:** 2026-03-01
> **Status:** In progress (16 of 16 skills reviewed — audit complete, pending design synthesis)
> **Approach:** Workflow-order review of all 16 skills, cross-referencing 104 open issues and 84 open PRs from upstream (obra/superpowers)

## Upstream References

- **Repository:** https://github.com/obra/superpowers
- **Open issues:** 104 (as of 2026-03-01)
- **Open PRs:** 84 (as of 2026-03-01)

## Review Order

1. using-superpowers (done)
2. brainstorming (done)
3. writing-plans (done)
4. composing-teams (done)
5. agent-team-driven-development (done)
6. subagent-driven-development (done)
7. dispatching-parallel-agents
8. executing-plans
9. test-driven-development
10. using-git-worktrees
11. requesting-code-review
12. receiving-code-review
13. systematic-debugging
14. verification-before-completion
15. finishing-a-development-branch
16. writing-skills

---

## Skill 1: `using-superpowers`

**Relevant upstream:** #446, #472, #237, #54, #260, PR #459, PR #534

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | `TodoWrite` → `TaskCreate`/`TaskUpdate` (stale tool name in dot diagram) | Lines 36, 50-52 | High — causes wrong tool invocation |
| 2 | No user-facing observability — can't tell if superpowers is active | #446 | Medium |
| 3 | `EXTREMELY_IMPORTANT` concealment prevents surfacing stuck states | #472 | High — causes session accumulation |
| 4 | Subagents don't receive discipline framework | #237 (verified with tests) | High — breaks TDD/review in subagents |
| 5 | No quick-bypass for trivial tasks | PR #534 | Medium — friction on simple tasks |
| 6 | Frontmatter description too broad, conflicts with other skills | PR #459 | Medium |
| 7 | Red Flags table over-broad (12 rows) — trim to 5 most effective | PR #459 (eval: 61%→100%) | Medium |

---

## Skill 2: `brainstorming`

**Relevant upstream:** #565, #574, #530, #512, #345, #244, #178, #107, #123, PR #579, #541, #520, #483, #386

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | No user gate between design doc and plan writing — immediately invokes writing-plans without letting user review the written document | #565 (regression from 7f2ee614) | High — design doc gets overwritten |
| 2 | Plan overwrites design doc — writing-plans saves to same file path as design doc, destroying it | #565 | High — data loss |
| 3 | No assumption challenging — accepts user framing uncritically | #530, PR #541 | Medium |
| 4 | "One question at a time" is too rigid — smart batching (up to 4 independent text questions) reduces 6 calls to 3 with 100% consistency | PR #520 (tested, hard data) | Medium |
| 5 | No scale/volume question — expected volume is a critical architectural driver | PR #579 (tested RED→GREEN) | Medium |
| 6 | No existing solutions research — designs from scratch without checking GitHub/web | PR #386 | Medium |
| 7 | Auto-commit without review — sometimes commits design doc/plan without user confirmation | #123 | Medium |
| 8 | After the Design section routinely skipped — design doc writing + worktree steps not followed | #107 | High |
| 9 | `TodoWrite` → `TaskCreate` — same stale tool name issue | Checklist step references | High |
| 10 | Command naming confusion — `/brainstorm` vs `superpowers:brainstorming` vs `superpowers:brainstorm` | #244 | Low |

### Memory Integration

- **Write**: Record design decisions and rejected approaches to `.superpowers/journal/active/`
- **Read**: On session resume, check if there's an in-progress brainstorm (`.superpowers/state.yml` with `phase: brainstorming`)
- **Prune**: When plan is finalized, archive brainstorming-phase journal entries, keeping only decisions that affect implementation

---

## Skill 3: `writing-plans`

**Relevant upstream:** #566, #227, #408, #337, #229, #512, PR #172, #235, #442, #340, #448

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | TDD not enforced — template shown but not validated. Real evidence: 13-task plan where only 2 tasks included tests, written after implementation. | #566, PR #172 | Critical |
| 2 | Plans exceed 32K output token limit — detailed plans with complete code blow through max output | #227 | High |
| 3 | No plan status tracking (`pending`/`executed`) — stale plans accumulate | PR #442 | Medium |
| 4 | No plan review/verification step before execution — wrong file paths, naming conventions slip through | #229, PR #448 | High |
| 5 | Flat `docs/plans/` gets cluttered — no project namespacing | PR #448 | Medium |
| 6 | Configurable save location — some users want plans outside the repo | #337, PR #340 | Low |
| 7 | No phase design principles — all tasks treated as equal, no MVP-first approach | PR #235 | Medium |
| 8 | Plan overwrites design doc — same file path collision with brainstorming's design doc | #565 | High |
| 9 | Intermittent file write failures — "invalid argument passed to tool" | #408 | Low |
| 10 | "Complete code in plan" undermines agent expertise — designed for dumb executors, counterproductive with expert agents | #512, #227 | High |
| 11 | Monolithic plan file is 2.7x more token-wasteful than split-by-task | #512, #87 | Medium |

### Design Decisions

- **Plans should specify:** test expectations, interfaces, constraints, reference patterns
- **Plans should NOT specify:** complete implementation code (let expert agents write it)
- **Original rationale for "complete code":** The skill was written assuming executors had "zero context and questionable taste." With expert agents that can read the codebase, this assumption is outdated.
- **Test phase:** Pipelined — QA writes tests one wave ahead of implementation (see Finding P)
- **Agent needed:** Strong `test-writer` agent definition (evolve from qa-engineer or create new)
- **File structure:** Directory-based `docs/plans/<project-name>/` with design.md, plan.md, per-task files

### Memory Integration

- **Write**: On plan save → update `.superpowers/state.yml` with `active_plan`, `plan_status: pending`
- **Write**: Record tech choices and approach rationale to `journal/active/`
- **Read**: On session resume → detect active plan, offer to continue execution
- **Transition**: On plan `status: executed` → trigger journal compaction for that plan's phase entries

---

## Workflow-Level Findings

These are systemic issues that span multiple skills. Lettered for cross-referencing.

### A. Enforcement model is brittle

The entire compliance mechanism is a strongly-worded prompt. When it fails (subagents, context compaction, custom models), there's no structural fallback. Issue #237 proves subagents don't get discipline context. Issue #147 shows post-compact agents forget reviews.

### B. No tiered workflow

Every task gets the same brainstorm → plan → worktree → execute pipeline regardless of complexity. "Fix this typo" and "rebuild the auth system" enter the same funnel.

Proposed tiers:
- **Quick**: Direct action, no ceremony (typo, one-liner, clarification)
- **Standard**: Brainstorm → plan → execute (features, bug fixes)
- **Complex**: Brainstorm → plan → team composition → parallel execution (multi-component work)

Related: PR #534 (quick mode bypass), #512 (efficiency).

### C. Skill dependency graph is implicit

Skills reference each other by name in prose, but there's no machine-readable dependency graph or lifecycle model. Full workflow is:

```
using-superpowers → brainstorming → writing-plans → [composing-teams] →
[agent-team/subagent/executing-plans] → [TDD per task] → requesting-code-review →
verification-before-completion → finishing-a-development-branch
```

### D. No persistent state across sessions

Root cause of #551, #478, #158. Designed solution below.

### E. `TodoWrite` → `TaskCreate` naming drift

Affects every skill that mentions TodoWrite. Global audit and rename needed.

### F. Static skill list in session-start hook

Users who add custom skills or remove built-in ones still get the full default list injected. No discovery mechanism adapts to what's actually installed.

### G. Brainstorming → writing-plans handoff is the most fragile point

Issues #565, #107, #123 all report it breaking in different ways. The transition is a prose instruction ("invoke writing-plans") rather than a structured handoff with explicit gates.

### H. AI sycophancy undermines brainstorming quality

Issue #530: AI accepts user framing and builds whatever is asked. A brainstorming skill that doesn't challenge assumptions is just a requirements-gathering form. Should act more like a senior PM who pushes back on the premise.

General workflow principle: **skills should resist premature commitment at every phase.**

### I. Token efficiency of plans matters at scale

Issue #512 data: monolithic plan = ~60K tokens across session (3-4 re-reads), split-by-task = ~22K tokens. Directory-based approach helps both brainstorming and writing-plans.

### J. Research before designing should be a workflow principle

PR #386 proposes searching GitHub/web before designing. Applies to: brainstorming (search for existing solutions), systematic-debugging (search for known bugs), writing-plans (search for reference implementations), composing-teams (search for existing agent definitions).

### K. TDD enforcement is the biggest systemic gap

Issues #566, #384, #373, #493 and PRs #172, #498 all report the same problem: TDD is mentioned everywhere but enforced nowhere. Plans routinely omit tests or write tests after implementation. The TDD skill exists but isn't structurally wired into the plan → execution pipeline.

Needs a structural fix — not just stronger wording.

### L. Plans over-specify implementation, undermining agent expertise

The "complete code in plan" guidance was designed for context-blind executors (Oct 2025). With expert agents that can read the codebase and make implementation decisions, plans should specify what/where/why and let agents decide how.

This is a **role clarity** problem: the plan is doing the agent's job. Shifting to interface/constraint/test-expectation specs makes plans lighter AND agents more effective.

### M. Plan lifecycle needs tracking for memory system

Plans transition through written → executing → done, but no field captures this. PR #442's YAML frontmatter (`status: pending/executed`) integrates with `.superpowers/state.yml`.

### N. Plan review is a missing workflow stage

Pipeline is brainstorming → writing-plans → execution with no verification that the plan is correct against the actual codebase. PR #448's reviewing-plans skill addresses this with a "3-Example Rule" — for every convention claim in the plan, find 3+ existing examples.

### O. Directory-based plans solve multiple problems at once

```
docs/plans/<project-name>/
├── design.md          # From brainstorming
├── plan.md            # From writing-plans (or overview.md + task-N.md)
├── review.md          # From reviewing-plans (optional)
└── status.yml         # Plan lifecycle state
```

Solves: plan overwrites design doc (#565), flat directory clutter (PR #448), token efficiency (#512), plan status tracking (PR #442).

### P. Pipelined test-writing: QA agents one wave ahead of implementers

Test-writing and implementation interleave across waves:

```
Wave 0: [QA writes tests for Wave 1 tasks] + [test framework setup]
         ↓ tests ready
Wave 1: [Impl executes Wave 1 tasks] + [QA writes tests for Wave 2 tasks]
         ↓                             ↓ tests ready
Wave 2: [Impl executes Wave 2 tasks] + [QA writes tests for Wave 3 tasks]
         ...
Wave N: [Impl executes Wave N tasks]
```

Adds ~1 wave of latency but structurally enforces TDD with no throughput penalty. Requires: strong `test-writer` agent definition, plan that specifies test expectations per task, agent-team-driven-development support for mixed QA+implementation waves.

### Q. Model tiering should be a first-class concept

PR #547 demonstrates that using Opus for everything is wasteful. Sensible defaults:
- **Planning/review** = opus (deep reasoning needed)
- **Implementation** = sonnet (fast, capable, much cheaper)
- **Quick/simple tasks** = haiku (fastest, cheapest)

Affects: composing-teams (recommendation), writing-plans (agent metadata), agent-team-driven-development (spawn model selection), agent definitions.

### R. Test-writer must be part of team composition vocabulary

Finding P (pipelined TDD) requires a test-writer agent in every team using the pipelined approach. composing-teams should detect if the design suggests a test phase and recommend including test-writer agents. The shipped agent roster needs a strong `test-writer.md` definition alongside `qa-engineer.md`.

### S. Agent creation is a pre-wave composition concern

When no project-specific agents exist, composing-teams should suggest creating them from shipped templates. The lead (or a single agent) writes the agent definitions during composing-teams — this is fast (~30s per agent, just writing .md files) and must complete before any wave starts, since Wave 0 test-writers need to be spawned from those definitions. Agent creation is a planning/composition concern, not an execution concern. This avoids a chicken-and-egg conflict where Wave 0 tries to both create and use the same agents.

### T. Review process should be tiered, not one-size-fits-all

The two-stage review (spec then code quality) adds latency per task. Proposed tiers:
- **Light**: Single combined review (simple/low-risk tasks)
- **Standard**: Two-stage spec + code quality (default)
- **Critical**: Two-stage + security review (auth, payment, data handling)

Connects to Finding B — the entire pipeline should scale to task complexity.

### U. Spawn prompts should be minimal when project agents exist

The implementer prompt template is 100 lines of generic guidance. If the implementer is a project-specific agent that already knows the codebase, most is redundant. Prompt should be: task description, context from previous waves, workflow contract. Role knowledge lives in the agent definition.

### V. Evidence-based review is essential — prose verdicts are unreliable

PR #578's core insight: language models produce convincing text, not verified facts. A reviewer can write "implementation looks correct" without opening a file. File:line citations are a checksum — cheap to produce if you read the code, immediately detectable as fake if you didn't. This should apply to ALL review activities: implementer evidence (test output + diff stat), reviewer citations (file:line per requirement), verification-before-completion.

### W. Post-compact workflow recovery needs the memory system

Issue #147 proves post-compaction agents forget reviews. With `.superpowers/state.yml`, the compact hook injects: "you are mid-execution of [plan], task [N] complete, next step is [spec review]." Agent doesn't need to remember — state file tells it.

---

## Skill 4: `composing-teams`

**Relevant upstream:** #429, #464, PR #547

*Note: This skill was created by us in v4.4.0. No upstream issues about it directly, but #429 (agent teams support), #464 (swarm mode), and PR #547 (model-aware agents) are adjacent.*

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | No cost/model tiering guidance — presents agents by tier but doesn't inform user about cost implications of running multiple opus agents vs sonnet | PR #547 | High |
| 2 | No team sizing guidance — "Max 3" without explaining why or helping right-size based on task count, parallelism, costs | #464 | Medium |
| 3 | Missing test-writer role — pipelined TDD (Finding P) requires test-writer agents in team composition | New (from our analysis) | High |
| 4 | No on-the-fly agent creation workflow — mentioned but no guidance on format, tools, model | — | Medium |
| 5 | Tier classification vague — "opus + broad tools" isn't precise for custom/unspecified models | — | Low |
| 6 | No validation of agent definitions — doesn't check well-formedness or valid tools | — | Low |
| 7 | No detection of existing team on session resume | — | Medium |
| 8 | No model cost estimation for team configuration | PR #547 | Low |

### Design Decisions

**Agent selection hierarchy:**
1. **Project-level agents** (`.claude/agents/`) — user-defined, project-specific
2. **Superpowers shipped agents** (`agents/`) — generic fallbacks AND templates for creating project-specific agents
3. **Raw model tier** (opus/sonnet/haiku) — no agent definition, role conveyed via task prompt

**Agent creation flow:**
- composing-teams discovers project agents
- If none found → suggest creating project-specific agents using shipped templates, customized to the project's stack
- If user accepts → agent creation queued as Wave 0 of execution (alongside test framework setup)
- If user declines → shipped agents used as fallbacks + raw model tiers
- Shipped agents serve dual purpose: runtime fallback AND copy-and-customize templates

**Model tiering is the primary dispatch mechanism:**
- The most important decision is model tier (opus/sonnet/haiku), not agent definition
- Agent definitions add role-specific prompting and tool restrictions, but model tier determines cost and capability
- Default: planning/review = opus, implementation = sonnet, quick tasks = haiku

### Memory Integration

- **Write**: Store team roster in `.superpowers/state.yml` under `team.roster`
- **Read**: On session resume, detect existing roster and offer to reuse or recompose
- **Write**: Record composition decisions (why agents chosen/excluded) to journal

---

## Skill 5: `agent-team-driven-development`

**Relevant upstream:** #429, #464, PR #578

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | No pipelined TDD support — needs mixed QA+implementation waves | Finding P | High |
| 2 | Implementer prompt has vague TDD: "follow TDD where appropriate" | #566 | High |
| 3 | No Wave 0 concept — no support for agent creation, test framework, foundation work | Finding S | High |
| 4 | No model tiering in prompt templates — everything spawns as `general-purpose` | Finding Q | Medium |
| 5 | "FULL TEXT of task from plan" contradicts revised plan philosophy (Finding L) | Finding L | Medium |
| 6 | No progress persistence — session dies mid-wave, no recovery | Finding D | High |
| 7 | No inter-wave test writing — waves are purely implementation | Finding P | High |
| 8 | Max 3 implementers hardcoded without reasoning | — | Low |
| 9 | No review tiering — every task gets two-stage review regardless of complexity | Finding T | Medium |
| 10 | No merge conflict guidance — just "lead resolves or directs" | — | Medium |
| 11 | Implementer prompt too long/generic — with project agents, should be minimal | Finding U | Medium |
| 12 | Spec reviewer has no specialized agent type (code quality uses code-reviewer, spec uses general-purpose) | — | Low |

### Design Decisions

- **Wave 0**: Foundation wave for agent creation + test framework + shared infrastructure
- **Pipelined execution**: QA agents write tests for Wave N+1 while implementers execute Wave N
- **Review tiers**: Light (combined) / Standard (two-stage) / Critical (two-stage + security)
- **Minimal prompts**: Task + context + workflow contract. Role knowledge from agent definition.

### Memory Integration

- **Write**: Track `team.wave`, `team.completed_tasks`, `team.active_implementers` in state.yml
- **Read**: On session resume, detect mid-execution team state, resume from last completed wave
- **Write**: Record merge conflicts and resolutions to journal

---

## Skill 6: `subagent-driven-development`

**Relevant upstream:** #485, #463, #291, #147, #87, PR #578

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Phantom completion — no evidence requirement for implementers or reviewers | PR #578 | Critical |
| 2 | Controller rationalizes skipping reviews — self-confirms "straightforward" tasks | #463 | Critical |
| 3 | `TodoWrite` references (lines 58, 80, 109) | — | High |
| 4 | Post-compact amnesia — forgets to do reviews after context compaction | #147 | High |
| 5 | Model parallelizes despite serial-only instructions using run_in_background | #485 | Medium |
| 6 | Final review scope unclear — should be whole-feature, not just last task | #291 | Medium |
| 7 | No review tiering — two-stage for every task regardless of complexity | Finding T | Medium |
| 8 | Token waste from monolithic plan loading | #87 | Medium |
| 9 | No progress persistence — can't resume mid-plan | Finding D | High |
| 10 | No pipelined TDD for serial execution | Finding P | Medium |
| 11 | No re-review loop bound — no escalation after repeated failures | PR #578 | Medium |
| 12 | No pre-flight context check — can start execution near context limit | PR #578 | Medium |

### Innovations from PR #578 (adopt)

1. **Mandatory evidence**: Implementers paste verbatim test output + `git diff --stat`. Reports without evidence rejected.
2. **Mandatory file:line citations**: Reviewers cite specific `file:line` + code excerpt per requirement. Verdicts without citations invalid.
3. **Re-review loop bound**: Max 3 cycles, then escalate to human with rejection history.
4. **Pre-flight context check**: Below ~50% context → mandatory `/compact` before execution.
5. **Persistent validators** (team mode): Validators accumulate cross-task context, detect gaps via SHA map.

### Memory Integration

- **Write**: After each task/review completion, update state.yml with current task and phase
- **Read**: On compact/resume, inject execution state so agent knows where to continue
- **Write**: Record review rejections and fix patterns to journal

---

## Cross-Pollination: Execution Skills Share Common Failures

The following issues were identified in `subagent-driven-development` but apply equally to `agent-team-driven-development` and `executing-plans`. When implementing fixes, apply them across ALL execution skills:

| Issue | subagent-driven | agent-team-driven | executing-plans |
|-------|:-:|:-:|:-:|
| **Phantom completion** (no evidence requirement) | PR #578 identified | Same risk — implementers report via SendMessage | Same risk — human may not verify |
| **Review skipping** (controller rationalizes "straightforward") | #463 confirmed | Same risk — lead can self-confirm | Less risk — human reviews between batches |
| **Post-compact amnesia** (forgets workflow state) | #147 confirmed | Same risk — lead loses wave/task state | Same risk — loses batch progress |
| **No re-review loop bound** | PR #578 proposes 3 max | Apply same bound | Apply same bound |
| **No pre-flight context check** | PR #578 proposes 50% gate | Even more critical — team overhead consumes more context | Less critical — separate session |
| **TodoWrite → TaskCreate** | Lines 58, 80, 109 | Already uses TaskCreate | Needs audit |
| **No progress persistence** (can't resume) | Finding D | Finding D | Finding D |
| **Evidence-based review** (file:line citations) | PR #578 | Apply same standard | Apply same standard |
| **Final cross-cutting review** (whole-feature scope) | #291 | Already has this step | Needs addition |
| **Token waste from monolithic plan** | #87 | Same issue | Same issue |
| **Native worktree isolation** (Finding X) | Less critical — serial | Critical — parallel agents need per-agent worktrees | Less critical — single session |
| **Canonical evidence format** (Finding Y) | Apply — subagent reports | Apply — SendMessage reports need structure | Apply — human reviews need evidence |

**Principle:** Any fix to one execution skill MUST be evaluated for the other two. They share the same fundamental contract: read plan → dispatch work → review → complete.

---

## New Feature: Persistent Memory System

### Design Decisions

| Aspect | Decision |
|--------|----------|
| Location | `.superpowers/` in project root, gitignored by default |
| Layer 1 | `state.yml` — active plan, progress (task N of M), worktree path, team composition |
| Layer 2 | `journal/active/` + `journal/archive/` — learnings with semantic decay |
| Pruning | Phase-based archival, relevance tagging, size-triggered compaction, explicit prune command |
| Inspiration | [Beads](https://github.com/steveyegge/beads) semantic decay via LLM summarization, no external deps |
| Integration | Skills read/write; session-start hook loads state into context |

### State File Example

```yaml
# .superpowers/state.yml
active_plan: docs/plans/2026-02-28-agent-marketplace-implementation.md
plan_status: executed          # pending | in_progress | executed
current_task: null             # task ID if mid-execution
worktree: null                 # path if active
team:
  roster: null
  wave: null
last_session: 2026-03-01T10:30:00Z
```

### Journal Structure

```
.superpowers/journal/
├── active/                    # Current phase entries
│   ├── 001-auth-design.md     # Decision: chose JWT over sessions
│   └── 002-db-migration.md    # Failed: alembic, switched to raw SQL
└── archive/                   # Compacted past phases
    └── phase-1-summary.md     # LLM-generated summary of N entries
```

### Pruning Mechanisms

1. **Phase-based archival** — When plan status → `executed`, LLM summarizes journal entries and moves to `archive/`
2. **Relevance tagging** — Entries tagged with scope (feature, module, phase). Skills only load entries matching current scope.
3. **Size-triggered compaction** — When `active/` exceeds N entries or K tokens, auto-compact oldest entries
4. **Explicit prune** — User can say "prune memory" to trigger summarization of stale entries

### Research References

- [Beads](https://github.com/steveyegge/beads) — Git-native issue tracker with LLM-powered `bd compact`
- [A-MEM](https://github.com/agiresearch/A-mem) — Zettelkasten-style linked notes with importance recalibration
- [Mem0](https://github.com/mem0ai/mem0) — Universal memory layer with relevance scoring
- [Letta](https://www.letta.com/blog/agent-memory) — RAM/disk memory metaphor, agent manages working memory
- [Claude Code native memory](https://code.claude.com/docs/en/memory) — `~/.claude/projects/<project>/memory/`, session memory, CLAUDE.md
- Upstream proposals: #551, PR #555, PR #508, PR #442, #478, #158

---

## Skill 7: `dispatching-parallel-agents`

**Relevant upstream:** #473, #315, PR #362

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Agents freeze without explicit autonomy — no `mode: "bypassPermissions"` or equivalent guidance for spawned agents | #473 | High |
| 2 | No model tier guidance — all agents implicitly use same model, no cost-aware dispatch | Finding Q | Medium |
| 3 | Hardcoded TypeScript `Task()` example — not how Claude Code Agent tool works | Lines 67-72 | Medium |
| 4 | "3+" threshold too high — 2 independent problems already benefit from parallel dispatch | Line 38 | Low |
| 5 | No merge/conflict detection — "verify fixes don't conflict" with no guidance on how | Lines 78-79 | Medium |
| 6 | No worktree isolation guidance — parallel agents editing same files without isolation | — | High |
| 7 | Redundant with agent-team-driven-development for planned work — no clear boundary | #315 | Medium |
| 8 | No connection to memory system — parallel results not persisted | Finding D | Low |
| 9 | Emoji in "Common Mistakes" section violates project convention | Lines 112-122 | Low |

### Design Decisions

- **Scope boundary**: dispatching-parallel-agents = ad-hoc parallel investigation/fixes; agent-team-driven = planned multi-wave execution
- **Worktree isolation**: Parallel agents need either per-agent worktrees or explicit shared-state risk warnings
- **Autonomy**: Spawned agents must have explicit permission mode to avoid freeze-on-prompt

---

## Skill 8: `executing-plans`

**Relevant upstream:** #566, PR #442, PR #172, #229

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | `TodoWrite` on line 23 — stale tool name | Finding E | High |
| 2 | No evidence requirement for task completion — just "mark as completed" | Finding V, PR #578 | High |
| 3 | No TDD enforcement — plan steps followed but no test-first gate | #566, Finding K | High |
| 4 | No progress persistence — batch progress lost on session death | Finding D | High |
| 5 | Batch size hardcoded at 3 — no guidance for right-sizing based on task complexity | — | Low |
| 6 | No pre-flight context check — can start near context limit | PR #578 | Medium |
| 7 | Human review between batches is good but no structured review template | — | Medium |
| 8 | No final cross-cutting review step before finishing-a-development-branch | #291 | Medium |
| 9 | "Follow each step exactly" contradicts revised plan philosophy — should follow intent, agents decide implementation | Finding L | Medium |
| 10 | No plan loading optimization — reads monolithic plan each time | Finding I | Medium |

**Cross-pollination applied:** Issues 2, 3, 4, 6, 8, 10 shared with subagent-driven and agent-team-driven.

---

## Skill 9: `test-driven-development`

**Relevant upstream:** #566, #437, #384, #373, PR #172

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Not structurally integrated into execution pipeline — mentioned but not enforced | #384, Finding K | Critical |
| 2 | No guidance for test frameworks — "npm test" is the only example, no Python/Rust/Go | #437 | Medium |
| 3 | No refactoring examples — REFACTOR phase is two sentences | #437 | Medium |
| 4 | No guidance for pipelined TDD context — QA writes tests, implementer writes code | Finding P | High |
| 5 | "Delete it. Start over." is unrealistic for multi-hour implementation — needs graduated response | — | Medium |
| 6 | Testing anti-patterns file referenced with relative path (`@testing-anti-patterns.md`) | Line 359 | Low |
| 7 | No integration with plan structure — test expectations in plans don't map to TDD cycles | Finding L | Medium |
| 8 | Mocking guidance too brief — "no mocks unless unavoidable" with no criteria for unavoidable | Line 111 | Low |
| 9 | No guidance on test granularity for AI agents — unit vs integration vs e2e selection | — | Medium |

### Design Decisions

Two TDD modes:
1. **Solo TDD**: Same agent writes test then implements (traditional Red-Green-Refactor)
2. **Pipelined TDD**: QA agent writes test (Red), implementation agent writes code (Green), reviewer verifies

The skill should document both modes and when to use each.

---

## Skill 10: `using-git-worktrees`

**Relevant upstream:** #583, #574, #371, #348, #299, #279, #238, #186, #167, #5, PR #483, PR #391

*Most upstream issues of any skill (12 issues + 2 PRs).*

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Worktree should be optional — many users don't want/need isolation for small changes | #583, #348 | High |
| 2 | Worktree not created after brainstorming despite being REQUIRED | #574, PR #483 | High |
| 3 | Subagents can't find worktree location from previous tasks | #371 | High |
| 4 | Worktree path not propagated to `.superpowers/state.yml` | Finding D | High |
| 5 | `.worktrees/` causes duplicate CLAUDE.md loading (Claude Code treats it as separate project) | #279 | High |
| 6 | Cleanup fails when working directory is inside worktree | #238, PR #391 | High |
| 7 | `finishing-a-development-branch` fails from within worktree | #167 | High |
| 8 | No caching/env setup guidance — npm install in every worktree is slow | #299 | Medium |
| 9 | No guidance on using worktrees for debugging (parallel investigation) | #186 | Low |
| 10 | No connection to dispatching-parallel-agents — per-agent worktrees | — | Medium |
| 11 | "Fix broken things immediately" approach to .gitignore commits without user consent | Line 66-67 | Medium |
| 12 | No native worktree support awareness — Claude Code now has `EnterWorktree` tool | — | High |

### Design Decisions

- Claude Code's `EnterWorktree` tool handles creation and cleanup natively
- Skill should layer safety verification (gitignore check, baseline tests, state tracking) on top of native tool
- Worktree path must be persisted in `.superpowers/state.yml` for cross-session recovery

---

## Skill 11: `requesting-code-review`

**Relevant upstream:** #528, #463, #557, #479, PR #560, PR #480, PR #334

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Reviews get skipped — controller rationalizes "straightforward" and self-confirms | #528, #463 | Critical |
| 2 | No review tiering — same two-stage review for every task | Finding T | Medium |
| 3 | No evidence requirement from reviewers — reviewer can say "looks good" without reading code | Finding V | High |
| 4 | SHA-based review scope can miss uncommitted changes | #436 | Medium |
| 5 | No security review tier — auth/payment/data handling needs specialized review | #479, PR #560 | Medium |
| 6 | `code-reviewer.md` template reference but no inline structure | Line 116 | Low |
| 7 | "Push back if reviewer is wrong" lacks specifics on what constitutes valid pushback | — | Low |
| 8 | No re-review loop bound — reviewer can reject indefinitely | PR #578 | Medium |

---

## Skill 12: `receiving-code-review`

**Relevant upstream:** #221, PR #334

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Spec reviewer pedantry — reviewers flag valid code as issues | #221 | Medium |
| 2 | No structured template for review responses — prose-only | — | Low |
| 3 | "Circle K" escape signal is project-specific, not generalizable | Line 138 | Low |
| 4 | "your human partner" throughout — needs generalization for public library | Multiple lines | Medium |
| 5 | No guidance on review-of-review — when reviewer feedback itself needs review | — | Low |
| 6 | No connection to evidence-based review — receiver should demand file:line citations from reviewer | Finding V | Medium |
| 7 | GitHub thread replies guidance only covers GH — no other platform guidance | Line 214 | Low |

---

## Skill 13: `systematic-debugging`

**Relevant upstream:** #536, #246, PR #334

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Users can't find it — name/description CSO may be poor | #536 | Medium |
| 2 | No fork option for context management in long debugging sessions | #246 | Medium |
| 3 | "your human partner" personalization throughout | Multiple lines | Medium |
| 4 | Phase 4.5 referenced in text but labeled "Phase 4, Step 5" — confusing numbering | Lines 197-213 | Low |
| 5 | No connection to worktrees for parallel hypothesis testing | #186 | Medium |
| 6 | No integration with memory system — debug findings not persisted | Finding D | Medium |
| 7 | `root-cause-tracing.md` referenced with relative path — should use skill cross-reference format | Line 114 | Low |
| 8 | No guidance on debugging in team context | — | Low |
| 9 | "Real-World Impact" stats from single session — unverifiable | Lines 298-302 | Low |

---

## Skill 14: `verification-before-completion`

**Relevant upstream:** #557, PR #334

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Not structurally enforced — depends on agent self-discipline, which is unreliable | Finding A | High |
| 2 | No connection to evidence-based review — should define the canonical evidence format | Finding V | High |
| 3 | "your human partner" personalization | Lines 111-115 | Medium |
| 4 | "Agent completed" row in table is key but easily missed | Line 49 | Medium |
| 5 | No structured evidence format — "run command" but no output template | — | Medium |
| 6 | No connection to memory system — verification results not persisted | Finding D | Low |
| 7 | "24 failure memories" reference is project-specific (Jesse's sessions) | Line 111 | Low |

### Design Decisions

- This skill should define the canonical evidence format: `{verification_command, verbatim_output, exit_code, timestamp}`
- All other evidence requirements (subagent completion, reviewer citations, TDD proof) reference this format

---

## Skill 15: `finishing-a-development-branch`

**Relevant upstream:** #167, PR #391

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Fails when run from inside worktree — cd to repo root needed | #167, PR #391 | High |
| 2 | Worktree cleanup ordering wrong — tries to remove worktree while cwd is inside it | PR #391 | High |
| 3 | Option 2 worktree cleanup contradicts quick reference table | — | Medium |
| 4 | No connection to memory system — should update state.yml on completion | Finding D | Medium |
| 5 | "Type 'discard' to confirm" — CLI can't do typed confirmation, needs AskUserQuestion | — | Medium |
| 6 | No squash vs merge guidance for PR creation | — | Low |
| 7 | Team shutdown in Team Context section but not in main flow — easy to miss | Lines 206-209 | Medium |
| 8 | Native `EnterWorktree` cleanup path differs from manual worktree | Finding X | Medium |

---

## Skill 16: `writing-skills`

**Relevant upstream:** #526, #451, #280, #233, PR #517, PR #471

### Skill-Specific Fixes

| # | Issue | Source | Priority |
|---|-------|--------|----------|
| 1 | Needs alignment with Anthropic's official "Building Skills" guide | #526, PR #471, PR #517 | High |
| 2 | `TodoWrite` on line 598 — stale tool name | Finding E | High |
| 3 | Exclamation marks in inline code spans cause rendering issues | #451 | Low |
| 4 | Inconsistent file reference syntax — `@` vs markdown links | #280 | Medium |
| 5 | TDD-for-skills testing methodology requires subagents — high overhead for simple skills | #233 | Medium |
| 6 | Personal skill paths (`~/.claude/skills`, `~/.agents/skills/`) are fragile | Line 12 | Low |
| 7 | Token efficiency targets (<150, <200, <500 words) not validated | Lines 217-219 | Low |
| 8 | No skill versioning or changelog tracking | — | Medium |
| 9 | persuasion-principles.md reference may be too academic | Line 463 | Low |
| 10 | No guidance on when to split vs combine skills — composability rules | — | Medium |

---

## Additional Workflow-Level Findings (from skills 7-16)

### X. Native worktree support changes the game

Claude Code's built-in `EnterWorktree` tool handles creation and cleanup natively. The using-git-worktrees skill should layer safety verification (gitignore check, baseline tests, state tracking) on top of the native tool rather than reimplementing worktree management. Also affects: dispatching-parallel-agents (per-agent worktrees), finishing-a-development-branch (cleanup path).

### Y. verification-before-completion should define the canonical evidence format

Instead of just "run the command," define a structured evidence format: `{verification_command, verbatim_output, exit_code, timestamp}`. All other evidence requirements (subagent completion proof, reviewer file:line citations, TDD red-green verification) reference this one standard. This makes evidence requirements concrete and auditable.

### Z. "your human partner" personalization must be generalized

Multiple skills contain Jesse-specific language ("your human partner's rule", "Circle K" signal, "24 failure memories"). These should be generalized for the public skill library while preserving the principles behind them. Affected skills: receiving-code-review, systematic-debugging, verification-before-completion, test-driven-development.

---

---

## Backwards Dependency Audit: Handoff Gaps

Every skill assumes its predecessor set up certain requirements. This audit traces each handoff and identifies where requirements are NOT met.

### Full Workflow Chain

```
brainstorming → [composing-teams] → writing-plans → [executor] → finishing-a-development-branch
     ↓               ↓                    ↓              ↓               ↓
  design doc    team roster           plan file     implementation    merge/PR/cleanup
  + worktree    (in design doc)       + waves       + reviews         + worktree removal
```

### Gap Summary

| # | Handoff | Gap | Severity | Root Cause |
|---|---------|-----|----------|------------|
| H1 | brainstorming → composing-teams | Worktree creation often skipped (#574) | High | Step 6 is unreliable, no verification gate |
| H2 | composing-teams → writing-plans | Team roster location ambiguous — in design doc, but plan can overwrite it (#565) | High | No separate roster artifact |
| H3 | writing-plans → agent-team-driven | Per-agent worktree branch names not tracked — needed for between-wave merges | High | `isolation: "worktree"` auto-creates but lead can't find branch names after compact |
| H4 | writing-plans → agent-team-driven | Team roster not findable — agent-team says "from composing-teams" but doesn't say WHERE | High | No standard location for roster |
| H5 | writing-plans → subagent-driven | Subagents can't find worktree path (#371) | High | Worktree path not persisted |
| H6 | writing-plans → executing-plans | Separate session has zero state — no worktree, no roster, no progress | Critical | No state.yml, no handoff mechanism |
| H7 | [any executor] → finishing | CWD inside worktree prevents removal (#167, PR #391) | High | No "cd out of worktree" step |
| H8 | [any executor] → finishing | Worktree path not stored anywhere | High | No state persistence |
| H9 | brainstorming step 7 | "If work benefits from specialist agents" is vibes-based — no structured criteria for when to compose teams | Medium | Missing decision framework |
| H10 | agent-team between waves | Wave N+1 implementers may not branch from merged result — unclear if `isolation: "worktree"` branches from HEAD or from main | High | Worktree branching semantics undocumented |
| H11 | agent-team between waves | Persistent implementer worktrees — does the worktree persist when team member is idle between waves? | Medium | `isolation: "worktree"` lifecycle tied to agent lifecycle, not wave lifecycle |
| H12 | pipelined TDD (Finding P) | QA agents writing tests have NO worktree guidance — where do test files go? | High | Finding P designed but not integrated into worktree strategy |
| H13 | any executor → requesting-code-review (team mode) | Per-implementer git SHAs need to come from implementer's worktree branch, not main | Medium | Review template assumes single branch |

### The Root Cause

**Nearly all handoff gaps trace back to one missing piece: persistent state.** If `.superpowers/state.yml` tracked:

```yaml
worktree:
  main: /path/to/lead/worktree
  branch: feature/my-feature
  implementers:
    react-engineer: { path: /path/to/wt1, branch: wt-react-123 }
    backend-engineer: { path: /path/to/wt2, branch: wt-backend-456 }
team:
  roster_path: docs/plans/2026-03-01-my-feature-design.md#team-roster
  roster: [{ role: react-engineer, agent: react-engineer, model: sonnet }]
plan:
  path: docs/plans/2026-03-01-my-feature.md
  status: in_progress
  current_wave: 2
  completed_tasks: [1, 2, 3]
```

Then every downstream skill could read this file to find what it needs, regardless of session boundaries or context compaction.

### Fix Coverage Analysis

**Fully solved by `.superpowers/state.yml` (6 of 13):**

| Gap | How state.yml solves it |
|---|---|
| H3 | Stores per-implementer `{ path, branch }` — lead can find branches for merge |
| H4 | Stores `team.roster_path` or inline roster — agent-team knows where to look |
| H5 | Stores `worktree.main` — subagents read it to find worktree |
| H6 | Entire file IS the cross-session handoff — executing-plans reads it cold |
| H8 | Stores worktree path directly |
| H13 | Stores per-implementer latest commit SHA for review dispatch |

**Partially helped by state.yml — additional fix needed (5 of 13):**

| Gap | State helps with | Additional fix needed |
|---|---|---|
| H1 | Detect missing worktree (field empty) | **Verification gate** in brainstorming — refuse to proceed without worktree |
| H2 | Stores `roster_path` pointer | **Directory-based plans** (Finding O) — separate `design.md` and `plan.md` |
| H7 | Stores repo root path | **Procedural fix** — finishing needs explicit "cd to repo root" step |
| H10 | Tracks merged state per wave | **Skill documentation** — agent-team must document branching from merged result |
| H11 | Tracks worktree existence/status | **Platform clarification** — `isolation: "worktree"` lifecycle when agent is idle |

**Not solved by state.yml (2 of 13):**

| Gap | What's actually needed |
|---|---|
| H9 | **Decision framework** — structured criteria for when to invoke composing-teams (reuse writing-plans' Team Fitness Check earlier) |
| H12 | **Design decision** — QA agents in pipelined TDD need explicit worktree strategy (proposed: write tests in lead's worktree, no conflict with implementation in separate worktrees) |

### Fix Strategy

Six complementary fixes cover all 13 gaps:

1. **State file** (H3, H4, H5, H6, H8, H13 + partial H1, H2, H7, H10, H11): Store worktree paths, roster, plan path, wave progress in `.superpowers/state.yml`
2. **Verification gates** (H1): brainstorming must verify worktree exists before proceeding to composing-teams/writing-plans
3. **Directory-based plans** (H2): Finding O — separate `design.md` and `plan.md` files prevent overwrites
4. **CWD management** (H7): finishing-a-development-branch must cd to repo root before worktree removal
5. **Decision framework** (H9): brainstorming needs structured criteria for composing-teams trigger — reuse writing-plans' Team Fitness Check earlier in the pipeline
6. **Worktree strategy for QA** (H12): QA agents write tests in lead's worktree (test files don't conflict with implementation in separate worktrees)
7. **Skill documentation** (H10, H11): Document worktree branching semantics for between-wave operations
7. **Per-agent SHA tracking solves H13**: State file tracks per-implementer latest commit SHA for review dispatch

---

---

## Implementation Approach

**Chosen: Foundation First** — Build infrastructure that unblocks everything else, then fix skills top-down.

### Phase 1: Foundation (state + structure)
- Implement `.superpowers/state.yml` + journal system
- Implement directory-based plans (`design.md` / `plan.md` separation)
- Add verification gates at every handoff
- Fix `TodoWrite` → `TaskCreate` globally

### Phase 2: Critical path (execution pipeline)
- Structural TDD enforcement (Finding K, pipelined TDD)
- Evidence-based review (Finding V, canonical format from Finding Y)
- Phantom completion fix across all 3 executors
- Worktree rework (leverage native `EnterWorktree`, fix all 12 upstream issues)

### Phase 3: Per-skill fixes
- Work through each skill's issue table, prioritized by severity
- Generalize "your human partner" language (Finding Z)
- Align writing-skills with Anthropic guide

### Phase 4: New capabilities
- Review tiering (Finding T)
- Model tiering (Finding Q)
- Workflow tiering (Finding B)

---

## Audit Summary

### By Priority

**Critical (5):**
- TDD not structurally integrated into execution pipeline (K, affects writing-plans, all executors, TDD skill)
- Phantom completion / no evidence requirement (V, affects all execution skills)
- Review skipping via rationalization (#528, #463, affects requesting-code-review, all executors)
- TDD not enforced in writing-plans (#566)
- TDD not structurally enforced in execution (#384)

**High (33):**
- TodoWrite → TaskCreate naming drift (E, affects 6+ skills)
- Progress persistence / memory system (D, affects all execution skills)
- Brainstorming → writing-plans handoff fragility (G)
- Plans over-specify implementation (L)
- Plan overwrites design doc (#565)
- Worktree issues (12 upstream issues, Finding X)
- Agent autonomy in parallel dispatch (#473)
- Evidence format standardization (Y)
- Post-compact amnesia (W, #147)
- Anthropic guide alignment for writing-skills (#526)
- And 23 more High-priority skill-specific issues

**Medium (48):** Various per-skill improvements

**Low (24):** Minor fixes, conventions, documentation

### Cross-Cutting Themes

1. **Structural enforcement over prompting** (Findings A, K, V) — The biggest improvements come from making compliance structural rather than relying on strongly-worded instructions
2. **Persistent state** (Finding D) — Nearly every skill benefits from `.superpowers/` state tracking
3. **Evidence-based workflow** (Findings V, Y) — Standardized evidence format eliminates phantom completions
4. **Pipelined TDD** (Finding P) — Structural TDD enforcement with near-zero throughput penalty
5. **Native tool integration** (Finding X) — Leverage Claude Code's built-in capabilities
6. **Agent hierarchy** (Findings Q, R, S) — Project agents > shipped fallbacks > raw model tiers
7. **Worktree pain** (12 issues) — Most reported issue area, needs fundamental rethink
8. **Tiering everywhere** (Findings B, T) — Workflow, review, and model selection all need complexity-appropriate scaling

# Forge Ideation Document v1

## Status

Draft for review and rapid iteration.

## Executive summary

The current repository already contains the right *primitives* for the direction we discussed, but not yet the right *product layer*.

Today, the fork is strongest in five areas:

1. A structured software-development workflow rather than a loose bag of prompts.
2. Strong enforcement around design-before-implementation, TDD, verification, and review.
3. Early multi-agent and team-composition support.
4. Multi-harness ambition: Claude Code, Codex, Cursor, OpenCode, Gemini.
5. A real behavior-oriented test suite rather than only smoke tests.

What is missing is the thing that would make this feel like **Forge** instead of “Superpowers with extra features”:

- a first-class project adoption flow
- a canonical project model and local state model
- generated harness adapters and concise memory files
- risk-scaled policy and evidence artifacts
- outcome-first workflows and capability packs
- public messaging that matches the actual direction

The recommendation from this pass is:

**Evolve the repo into a structured operating mode for AI-assisted software development, with an opinionated adoption flow and risk-scaled ceremony.**

Not an infra autopilot. Not a generic marketplace of ever more skills. Not a markdown-heavy spec framework.

The product thesis should be:

> Forge is a structured operating mode for engineers who want AI help without surrendering direction, memory, or reviewability.

## Why this direction fits the current repo

The repo is already ahead of upstream in ways that align with Forge:

- the fork is only 5 commits ahead, but those 5 commits span 159 files and add agent-team support, team composition, evidence gates, cold-resume/progress work, docs restructuring, and broad test infrastructure
- the repo contains multi-platform surfaces (`.claude-plugin`, `.codex`, `.cursor-plugin`, `.opencode`, `GEMINI.md`, `gemini-extension.json`) plus `agents/`, `commands/`, `docs/`, `hooks/`, `skills/`, `tests/`, and a hidden `.superpowers` directory
- the current workflow already enforces design -> worktree -> plan -> execution -> TDD -> review -> finish
- the fork adds `composing-teams` and `agent-team-driven-development`, which are stronger hints toward an orchestrator than toward a generic skill pack
- the test runner is already tiered into trigger tests, pressure/behavior tests, and E2E workflow chains

Those are not patch-carrier signals. Those are product-foundation signals.

## Current-state assessment

### What already exists and should be preserved

#### 1. Strong workflow backbone

The current repo has a coherent execution backbone:

- `brainstorming` enforces design before code
- `using-git-worktrees` creates isolated workspaces
- `writing-plans` creates execution plans
- `subagent-driven-development` and `agent-team-driven-development` execute those plans
- `test-driven-development`, `verification-before-completion`, and review skills add quality gates
- `finishing-a-development-branch` closes the loop

This is the single most valuable asset in the project. Forge should keep this backbone.

#### 2. Team orchestration primitives

The fork now has explicit team composition and team execution:

- `composing-teams` discovers available agents, lets the user choose a team, and routes that roster into planning
- `agent-team-driven-development` adds persistent specialist implementers, wave-based execution, pipelined TDD, and reviewer separation

This is an excellent base for a richer orchestrator. The important next move is to make team mode *one execution strategy*, not the product identity.

#### 3. Evidence-first direction

Your compare commits show clear movement toward evidence gates, canonical evidence formats, citation requirements, and progress persistence. That is exactly the right instinct. Forge should formalize this into machine-readable artifacts rather than more prose.

#### 4. Cross-harness ambition

The repo structure and release notes show intentional support for Claude Code, Codex, Cursor, OpenCode, and Gemini. That is useful, but the implementation should evolve toward thin harness adapters around a stable orchestration core.

#### 5. Real test infrastructure

The repo already has the beginnings of a serious evaluation harness. That is rare, and worth doubling down on.

### What is weak or misleading today

#### 1. The public surface still looks like upstream

This is the largest immediate issue.

Right now the repo still markets itself almost exactly like upstream:

- same product name
- same one-line positioning
- upstream sponsorship language
- Codex/OpenCode install docs that still clone or fetch from `obra/superpowers`
- overall framing as a plugin/skills library rather than a new operating model

This is not just branding debt. It actively hides the repo’s real direction.

#### 2. There is no first-class project adoption flow

The repo has great execution behavior *after* the agent is already in the workflow, but there is no coherent “bring Forge into a real repo and let it learn/setup/project-ize itself” experience.

This is the biggest missing feature for the future product.

#### 3. Skills are still too exposed as the product

Internally, skills are a good implementation model.
Externally, users will adopt **verbs and outcomes**, not a catalog of 16+ named skills.

The current repo still largely explains itself as a skill system. Forge should explain itself as:

- adopt repo
- start feature
- fix bug
- review change
- resume work
- prepare release
- investigate incident

#### 4. Structure is not yet risk-scaled

Today the repo is strongly process-driven, which is good, but it still risks feeling too mandatory in low-risk situations.

Forge needs a crisp answer to:

- when can this be light?
- when must this be structured?
- what artifacts are required for each level of risk?

#### 5. State exists implicitly, not as a product concept

The hidden `.superpowers` state directory is a clue that the product already wants local state. But the state model is not yet an explicit product abstraction.

Forge needs:

- shared project state
- local-only working state
- generated adapters
- resumable checkpoints
- evidence ledger
- sync/refresh mechanisms

## What does not make sense for Forge going forward

### 1. “Mandatory workflow for everything” as a user-facing message

Internally, strict skills are fine. But the product should not *feel* like every action requires ceremony.

Forge should be strict where risk is high, and light where risk is low.

That means moving from:

- always-heavy structure

to:

- **risk-scaled structure**

### 2. Treating infra automation as the main wedge

Your own instinct here is right.

Forge can be strong at infra/security/compliance *without* becoming a system that autonomously mutates production. The better angle is:

- better plans
- stronger policy
- safer reviews
- stronger rollback evidence
- better design prompts
- safer human-supervised execution

So infra should be a pack or domain specialization, not the central brand promise.

### 3. Adding more low-level skills as the default growth strategy

More skills alone will not make the product better.

The next step is not “20 more skills.”
The next step is:

- a product layer
- an adoption flow
- a policy model
- a compact artifact model
- better workflow packaging

### 4. Large checked-in markdown as the main state model

Forge should not become document sprawl.

Markdown remains useful for:

- human-readable summaries
- reviewed designs
- release notes
- selected rationale

But the canonical state should increasingly become machine-readable and selectively rendered.

## Product thesis for Forge

### Core statement

Forge is an adoptable operating mode for AI-assisted software development.

It gives teams:

- a structured workflow
- durable project memory
- generated harness guidance
- explicit policy and evidence gates
- lightweight or full-depth execution modes
- outcome-first commands instead of a skill catalog

### Intended user

Primary user:

- software engineers who want more structure than vibe coding
- senior or staff engineers who care about consistency, reviewability, and quality
- teams who want agents to help, but not to operate without guardrails

Secondary user:

- infra/security/compliance-heavy teams that want better planning/review artifacts, not autonomous production action

### What Forge is **not**

- not an autonomous prod operator
- not a generic bag of prompts
- not a heavyweight spec bureaucracy
- not a dashboard-first management product
- not a vendor-specific harness wrapper

## Proposed product model

## Operating modes

Forge should support three operating modes, not just two:

### 1. Ephemeral mode

Purpose:

- quick work
- little or no repo mutation from Forge itself
- minimal overhead

Behavior:

- no project adoption required
- uses existing repo context opportunistically
- creates temporary plan/evidence structures only when risk requires it

Use cases:

- small bug fixes
- quick analysis
- exploratory code reading
- low-risk refactors

### 2. Project mode

Purpose:

- shared project setup with minimal checked-in structure

Behavior:

- creates concise shared config
- generates harness-facing instruction files
- supports reusable workflows and packs
- keeps richer working memory local

Use cases:

- teams adopting Forge without wanting full local state machinery yet

### 3. Adopted mode

Purpose:

- full Forge experience

Behavior:

- full repo scan / project understanding
- local index, checkpoints, and memory
- generated concise adapter files for supported harnesses
- enabled packs
- richer workflow/policy/evidence model

Use cases:

- active teams using Forge as the default operating mode for the repo

## The critical new feature: `forge adopt`

This should be the first major product-level addition.

### What it should do

`forge adopt` should:

1. inspect the repo
2. infer commands, stack, layout, CI, tests, conventions, and risk areas
3. discover existing AI-agent surfaces (`CLAUDE.md`, `AGENTS.md`, Kiro steering, hooks, etc.)
4. propose a Forge layout and pack set
5. preview all changes
6. apply only after confirmation

### Output model

Adoption should create a small shared surface and a richer local surface.

Proposed shape:

```text
.forge/
  project.yaml
  workflows/
  policies/
  packs/
  adapters/
  generated/
  local/            # gitignored
    index/
    memory/
    checkpoints/
    evidence/
    cache/

AGENTS.md                # generated / concise
.claude/CLAUDE.md        # generated / concise
.kiro/steering/*.md      # generated when enabled
```

### Design rules for adoption

- must be explicit, never magical
- must be previewable
- must be reversible
- must attach confidence to inferred facts
- must allow users to reject parts of the proposal
- must never silently enable risky shell/environment behavior

### Related commands

- `forge adopt`
- `forge sync`
- `forge doctor`
- `forge explain`
- `forge reset-local`

## Canonical state model

Forge should treat project state as a first-class product concept.

### Shared state (checked in)

Keep this compact and intentional:

- `project.yaml` — project identity, stack, commands, repo traits
- `packs/*.yaml` — enabled capability packs
- `policies/*.yaml` — workflow and risk rules
- `workflows/*.yaml` — outcome-level verbs and routing
- selected reviewed docs under `docs/` if desired

### Local-only state (gitignored)

This is where the richer intelligence should live:

- repo index / architecture map
- recent learnings
- task checkpoints
- evidence artifacts
- plan execution progress
- generated working summaries

### Rendered state

Harness-facing files should be generated from the canonical model:

- `AGENTS.md`
- `CLAUDE.md`
- Kiro steering files
- optional hook configs

The repo should not require humans to hand-maintain multiple instruction systems in parallel.

## Evidence and policy model

This is where Forge can differentiate without becoming overbearing.

### Principle

Policy should require **artifacts**, not walls of prose.

### Artifact types

Potential minimal artifacts:

- `task.yaml`
- `evidence.jsonl`
- `review.yaml`
- `risk.yaml`
- `rollout.yaml`
- `rollback.yaml`

Human-readable markdown can be generated from these when needed.

### Risk-scaled ceremony

Example policy classes:

#### Low risk

Examples:

- docs edits
- trivial refactors
- isolated tests

Required:

- concise plan or direct execution
- verification evidence

#### Medium risk

Examples:

- feature changes
- cross-module refactors
- moderate bug fixes

Required:

- plan
- test evidence
- review evidence
- checkpoint/resume support

#### High risk

Examples:

- database migrations
- auth/authz changes
- API contract changes
- infra or release-affecting changes

Required:

- explicit design note
- risk register
- compatibility/rollback evidence
- reviewer role requirements
- stricter completion gates

#### Restricted risk

Examples:

- production infra apply
- destructive operations
- secrets handling

Required:

- plan-only mode or explicit user approval paths
- clear hard-stop behavior

### Policy examples

```yaml
rules:
  - match: ["db/migrations/**"]
    require: ["rollback-plan", "compat-check", "migration-test"]

  - match: ["auth/**", "permissions/**"]
    require: ["security-review", "threat-note", "test-evidence"]

  - match: ["infra/**"]
    mode: "plan-only"
    require: ["blast-radius", "rollback", "human-approval"]
```

## Public surface: from skills to workflows

Users should not need to think in terms of skill names.

### Proposed flagship workflows

Start with 6–8 outcome-first workflows:

- adopt repo
- start feature
- fix bug
- refactor safely
- review change
- resume work
- prepare release
- investigate incident

### Mapping to existing repo primitives

This is important because the current repo already has the right internals.

- `brainstorming` -> design/specify phase
- `writing-plans` -> planning phase
- `subagent-driven-development` -> serial implementation engine
- `agent-team-driven-development` -> parallel implementation engine
- `test-driven-development` -> implementation discipline
- `verification-before-completion` -> completion gate
- `requesting-code-review` / `receiving-code-review` -> review loop
- `finishing-a-development-branch` -> closeout / PR / cleanup
- `composing-teams` -> optional execution-strategy setup
- `using-superpowers` -> transitional compatibility layer only

Forge should keep these internals while changing the user-facing model.

## Packs: the right way to broaden beyond infra

Packs are the best way to reach a larger software-dev audience without becoming a shapeless kitchen sink.

### Recommended initial packs

#### 1. Core software pack

Default for all projects.

Includes:

- design
- plan
- implement
- review
- verify
- finish
- resume

#### 2. Backend/service pack

Includes:

- API design prompts
- service boundaries
- contract checks
- idempotency / retry prompts
- observability prompts

#### 3. Database/migrations pack

Includes:

- migration sequencing
- rollback requirements
- compatibility checks
- data backfill planning

#### 4. Security review pack

Includes:

- auth/authz review
- secrets handling checks
- dependency/supply-chain review
- data flow / trust boundary prompts

#### 5. Release/ops pack

Includes:

- rollout plans
- rollback plans
- release notes
- smoke validation
- incident readiness

#### 6. Frontend/UI pack

Optional but useful for broader reach.

#### 7. Large-repo / monorepo pack

Includes:

- path-specific rules
- bounded context summaries
- repo-map generation
- ownership-aware routing

### What to avoid

Do not start by shipping too many packs. The first wave should be opinionated and curated.

## Proposed artifact strategy

### What should be checked in

Check in:

- compact project guidance
- pack selection
- policy rules
- reviewed design/plan artifacts when useful
- generated concise adapter files only if team wants them versioned

### What should stay local

Keep local:

- working memory
- checkpoints
- raw evidence logs
- indexes and caches
- large generated summaries

### Why this matters

This addresses the failure mode other structured systems hit when they spill too much tool state into the repo root and burden normal development.

## Harness strategy

The current repo already spans multiple harnesses. Forge should continue that, but with a clearer architecture.

### Recommendation

Build a stable orchestration core and thin adapters for:

- Claude Code
- Codex
- Cursor
- OpenCode
- Gemini (best-effort where capabilities differ)
- future adapters as needed

### Adapter responsibilities

An adapter should know how to:

- expose instructions to the harness
- map tools / capabilities
- install hooks or equivalent deterministic controls
- manage worktree patterns if supported
- degrade gracefully when a harness lacks subagents or teams

### Important principle

Harness capability should shape execution strategy, not change the product identity.

## Immediate repo changes that make sense now

### 1. Reframe the repo surface

Change immediately:

- README title and opening
- repo description
- About text
- install docs
- remove or rewrite upstream sponsorship/support copy

Add immediately:

- why this exists
- relationship to upstream
- what is different
- whether the project tracks upstream selectively
- project status and direction

### 2. Introduce Forge compatibility layer without breaking current repo

Near-term transitional approach:

- keep current internal skill names working
- add a `forge` concept layer in docs and structure
- introduce `.forge/` while keeping `.superpowers/` compatibility where necessary
- mark `using-superpowers` as a compatibility/internal skill, not the product front door

### 3. Start outcome-first documentation

Add a new top-level doc set such as:

- `docs/forge/overview.md`
- `docs/forge/adopt.md`
- `docs/forge/workflows.md`
- `docs/forge/policies.md`
- `docs/forge/packs.md`

### 4. Build the state schema before expanding skills

Do next:

- define `project.yaml`
- define policy schema
- define task/evidence schema
- define generated adapter strategy

This will give structure to the next wave of implementation.

### 5. Re-target tests around the future product

Keep existing skill tests, but add product-level tests for:

- adopt flow
- sync flow
- mode routing (ephemeral/project/adopted)
- risk-scaled ceremony decisions
- workflow routing
- adapter generation
- checkpoint/resume integrity

## What to keep, what to reframe, what to cut

### Keep

- workflow backbone
- evidence mindset
- worktree discipline
- review loops
- team execution primitives
- multi-harness ambition
- behavior-oriented tests

### Reframe

- skills -> workflows
- team mode -> optional execution strategy
- docs/specs -> risk-scaled artifacts
- hidden state -> explicit local-state model
- plugin identity -> adopted operating mode

### Cut or de-emphasize

- upstream-identity residue in README/docs
- more skill-count inflation as the main roadmap
- overly broad “mandatory for everything” messaging
- long verbose checked-in markdown as the default state format
- any implication that Forge should autonomously operate production infrastructure

## Suggested first implementation sequence

### Phase 1: product framing

- rewrite README and harness docs
- define product thesis
- add Forge docs section
- introduce repo description and status messaging

### Phase 2: core schemas

- `project.yaml`
- `packs/*.yaml`
- `policies/*.yaml`
- `tasks/evidence/review` schema

### Phase 3: adoption flow

- `forge adopt`
- `forge sync`
- `forge doctor`
- generated adapter outputs

### Phase 4: workflow surface

- start feature
- fix bug
- review change
- resume work
- prepare release

### Phase 5: initial packs

- core software
- backend/service
- database/migrations
- security review
- release/ops

### Phase 6: evaluation

- benchmark scenarios
- cold resume tests
- risk-gate tests
- side-by-side workflows on representative repos

## 30-day target

A realistic first compelling version would have:

- new public messaging
- minimal Forge layout
- adopt + sync + doctor
- generated `CLAUDE.md` / `AGENTS.md`
- three operating modes
- five flagship workflows
- core + backend + migrations packs
- product-level tests for adoption, routing, and resume

That would already be a coherent v0.

## Open questions for the next review

1. Should `.forge/` be the canonical directory immediately, or should the repo keep `.superpowers/` compatibility for one major transition?
2. How much of the generated adapter output should be checked in versus regenerated locally?
3. Should team mode be opt-in by workflow decision, or user-selectable at the start of each major task?
4. What is the exact minimum artifact set for low-risk, medium-risk, and high-risk work?
5. Should packs ship in-repo first, or as installable add-ons after the core lands?
6. How opinionated should the default backend pack be about testing, architecture boundaries, and release behavior?
7. What is the final public product name if Forge remains only a working title?

## Bottom line

The fork already has enough substance to stop thinking of it as “a better Superpowers fork.”

The right next move is to turn it into a product with:

- an adoption flow
- a state model
- generated adapters
- risk-scaled policy
- workflow-first UX
- curated packs

The repo already contains the implementation primitives.
What it needs now is a visible product architecture.

---

## Evidence basis and references

### Current repo and upstream

1. Fork repo root and README: https://github.com/rahulsc/superpowers
2. Upstream repo root: https://github.com/obra/superpowers
3. Compare view: https://github.com/obra/superpowers/compare/main...rahulsc:superpowers:main
4. Fork Codex docs: https://github.com/rahulsc/superpowers/blob/main/docs/README.codex.md
5. Fork OpenCode docs: https://raw.githubusercontent.com/rahulsc/superpowers/main/docs/README.opencode.md
6. Fork release notes: https://raw.githubusercontent.com/rahulsc/superpowers/main/RELEASE-NOTES.md
7. Fork composing-teams skill: https://github.com/rahulsc/superpowers/blob/main/skills/composing-teams/SKILL.md
8. Fork agent-team-driven-development skill: https://github.com/rahulsc/superpowers/blob/main/skills/agent-team-driven-development/SKILL.md
9. Fork brainstorming skill: https://raw.githubusercontent.com/rahulsc/superpowers/main/skills/brainstorming/SKILL.md
10. Fork top-level test runner: https://raw.githubusercontent.com/rahulsc/superpowers/main/tests/run-all-tests.sh

### External reference points

11. Claude Code memory / CLAUDE.md / rules / `/init`: https://code.claude.com/docs/en/memory
12. Claude Code hooks: https://code.claude.com/docs/en/hooks-guide
13. Claude Code agent teams: https://code.claude.com/docs/en/agent-teams
14. OpenAI Codex introduction (AGENTS.md, evidence, parallel tasks): https://openai.com/index/introducing-codex/
15. OpenAI Codex app (worktrees, skills, configurable permissions): https://openai.com/index/introducing-the-codex-app/
16. OpenAI Codex product page (skills, automations, multi-agent framing): https://openai.com/codex/
17. Kiro steering docs: https://kiro.dev/docs/steering/
18. Kiro specs docs: https://kiro.dev/docs/specs/
19. GitHub Spec Kit repo: https://github.com/github/spec-kit
20. GitHub Spec Kit issue on repo-root clutter: https://github.com/github/spec-kit/issues/139

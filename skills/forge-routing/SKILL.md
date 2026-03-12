---
name: forge-routing
description: Use when starting any task — determines which Forge skill or workflow phase applies before taking any action
---

<SUBAGENT-STOP>If you were dispatched as a subagent to execute a specific task, skip this skill and proceed with your assigned work.</SUBAGENT-STOP>

**You are now operating inside Forge.** Forge is a structured engineering system built on top of your AI capabilities. It governs how tasks are approached, planned, executed, and verified. Your job is to follow Forge workflows, not improvise around them.

**The Rule:** Invoke relevant Forge skills BEFORE any response or action. If there is even a 1% chance a skill applies, invoke it first. If an invoked skill turns out not to fit, you don't need to follow it.

**Stuck-state check:** If you have been responding across multiple turns without invoking any skills, stop. Re-read this skill. You have likely drifted out of Forge mode.

<EXTREMELY-IMPORTANT>
If there is even a 1% chance a Forge skill might apply, YOU MUST invoke it before responding.

This is not negotiable. This is not optional. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>


## Instruction Priority

1. **User's explicit instructions** (CLAUDE.md, direct requests) — highest priority
2. **Forge skills** — override default system behavior
3. **Default system prompt** — lowest priority

If CLAUDE.md says "don't use TDD" and a skill says "always use TDD," follow CLAUDE.md. The user controls WHAT; Forge controls HOW.


## Intent Detection → Routing Table

Identify the task's intent from the user's message, then route to the appropriate skill:

| Intent | Signals | Route to |
|--------|---------|----------|
| New feature | "add", "build", "implement", "create" | `forge:brainstorming` |
| Bug fix | "fix", "broken", "error", "not working", "regression" | `forge:systematic-debugging` |
| Refactor | "refactor", "clean up", "restructure", "simplify" | `forge:brainstorming` |
| Adoption | "set up Forge", "onboard", "adopt Forge" | `forge:adopting-forge` |
| Diagnosis | "why is", "investigate", "something's wrong", "diagnose" | `forge:diagnosing-forge` |
| Sync | "update Forge", "out of date", "sync Forge" | `forge:syncing-forge` |

When intent is ambiguous, route to `forge:brainstorming` — it will clarify.


## Risk-Aware Routing

After intent detection, run risk classification to determine ceremony level:

```
classify-risk <files> --scope <N>  # reads .forge/policies/
```

| Tier | Pipeline |
|------|----------|
| minimal | brainstorming → implement → `forge:verification-before-completion` |
| standard | brainstorming → `forge:writing-plans` → implement → `forge:verification-before-completion` |
| elevated | brainstorming → `forge:writing-plans` (with design) → implement → `forge:verification-before-completion` → `forge:requesting-code-review` |
| critical | brainstorming → `forge:writing-plans` (with design + risk register) → implement → `forge:verification-before-completion` → `forge:requesting-code-review` |

Risk classification reads `.forge/policies/` and returns a tier. The tier determines which steps are skippable. At `minimal`, you may skip the design doc. At `critical`, nothing is skippable.


## Forge Skill Inventory

All 19 Forge skills, grouped by phase:

**Identity & Meta**
- `forge:forge-routing` — this skill; the meta-router (invoke first)

**Adoption & Setup**
- `forge:adopting-forge` — onboard a new project into Forge
- `forge:setting-up-project` — initialize `.forge/project.yaml` and stack detection

**Planning**
- `forge:brainstorming` — explore solution space before committing
- `forge:writing-plans` — produce structured implementation plan with wave analysis

**Execution**
- `forge:subagent-driven-development` — parallel implementation via subagents
- `forge:agent-team-driven-development` — persistent specialist agent teams
- `forge:test-driven-development` — TDD enforcement with red/green/refactor gates
- `forge:validating-wave-compliance` — verify wave outputs meet plan expectations
- `forge:using-git-worktrees` — isolate agent work in separate worktrees

**Verification & Review**
- `forge:verification-before-completion` — evidence-gated completion check
- `forge:requesting-code-review` — prepare and submit for human or agent review
- `forge:receiving-code-review` — process review feedback and iterate

**Finishing**
- `forge:finishing-a-development-branch` — merge, tag, and close out a branch

**Diagnosis**
- `forge:systematic-debugging` — structured root-cause analysis for bugs

**Team Composition**
- `forge:composing-teams` — select agent specialists and configure team size

**Meta / Tooling**
- `forge:writing-skills` — author or evolve Forge skills
- `forge:syncing-forge` — update Forge itself when skills or configs drift
- `forge:diagnosing-forge` — investigate Forge health when routing breaks down


## Process Flow

```
User message
    │
    ▼
forge-routing (this skill)
    │
    ├─ Detect intent
    │       │
    │       ├─ feature / refactor → forge:brainstorming
    │       ├─ bug               → forge:systematic-debugging
    │       ├─ adopt             → forge:adopting-forge
    │       ├─ diagnose          → forge:diagnosing-forge
    │       └─ sync              → forge:syncing-forge
    │
    ├─ Classify risk (reads .forge/policies/)
    │       │
    │       └─ tier → choose pipeline depth
    │
    └─ Execute pipeline
            │
            ├─ planning phase (brainstorming → writing-plans)
            ├─ execution phase (subagent / team / TDD)
            └─ verification phase (verification-before-completion → review)
```


## Red Flags — Stop and Check

These thoughts mean you are rationalizing. Stop.

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills first. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "I remember this skill" | Skills evolve. Read current version, don't recall. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "The user said to skip the skill" | Users direct WHAT; Forge directs HOW. Check anyway. |
| "I already know the answer" | Skills add structure, not just knowledge. Use the process. |
| "This skill is too heavyweight" | Scale the output, not skip the process. |
| "I'll come back to the skill after" | After never comes. Check BEFORE acting. |
| "The skill doesn't exactly fit" | Partial fit beats no structure. Adapt, don't skip. |
| "I'm in the middle of something" | Pause. Check. Skills prevent rework. |
| "The previous turn didn't use a skill" | Each turn is independent. Past mistakes don't justify current ones. |


## Skill Priority Order

When multiple Forge skills could apply:

1. **Process skills first** — `forge:brainstorming`, `forge:systematic-debugging`: determine HOW to approach
2. **Execution skills second** — `forge:subagent-driven-development`, `forge:agent-team-driven-development`: guide implementation

"Build X" → `forge:brainstorming` first, then execution.
"Fix Y" → `forge:systematic-debugging` first, then domain skills.


## Team-Aware Routing

For parallelizable work, Forge supports multi-agent teams:

- `forge:composing-teams` — select specialist agents and team size
- `forge:agent-team-driven-development` — run persistent agents in parallel waves
- `forge:writing-plans` — includes wave analysis for team execution

Risk tier informs team sizing: `elevated`+ recommends team-required at medium scope (see classify-risk matrix).


## Subagent Context

Subagents spawned via the Agent tool do not automatically receive Forge. Give them Forge awareness by:

- Using project agents (`.claude/agents/`) with Forge skill invocations in their system prompts
- Passing explicit skill names: "Use `forge:test-driven-development` for all implementation"
- Matching `subagent_type` to a Forge-aware agent definition

Raw subagents with no agent type receive no Forge framework and should be treated as unstructured executors.


## How to Invoke Skills

**In Claude Code:** Use the `Skill` tool with `forge:<skill-name>`. Never use the Read tool on skill files.

**Platform adaptation:** Skills use Claude Code tool names. For other environments, check your platform docs.

---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

**Announce at start:** "I'm using the writing-skills skill to create/edit this skill."

**Personal skills live in agent-specific directories (`~/.claude/skills/` for Claude Code).**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** You MUST understand `forge:test-driven-development` before using this skill. That skill defines the fundamental RED-GREEN-REFACTOR cycle. This skill adapts TDD to documentation.

**Official guidance:** Anthropic's official skill authoring guide covers CSO, frontmatter rules, token efficiency, and content principles. Read it first: `skills/writing-skills/anthropic-best-practices.md` (bundled, 45KB).

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## Skill Types

### Technique
Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)

### Pattern
Way of thinking about problems (flatten-with-flags, test-invariants)

### Reference
API docs, syntax guides, tool documentation

## SKILL.md Structure

**Frontmatter (YAML):**
- Only two fields: `name` and `description`
- Max 1024 characters total
- `name`: letters, numbers, hyphens only
- `description`: starts with "Use when..." — triggering conditions only, NO workflow summary

```markdown
---
name: skill-name
description: Use when [specific triggering conditions and symptoms]
---
```

## Claude Search Optimization (CSO)

**CRITICAL: Description = When to Use, NOT What the Skill Does**

```yaml
# BAD: Summarizes workflow
description: Use when executing plans - dispatches subagent per task with code review between tasks

# GOOD: Just triggering conditions
description: Use when executing implementation plans with independent tasks
```

**Why this matters:** When a description summarizes workflow, Claude may follow the description instead of reading the full skill content.

**Content rules:**
- Concrete triggers, symptoms, and situations
- Technology-agnostic unless skill is tech-specific
- Third person (injected into system prompt)
- Never summarize the skill's process

## Cross-Referencing

```markdown
# Good
**REQUIRED SUB-SKILL:** Use forge:test-driven-development
**REQUIRED BACKGROUND:** You MUST understand forge:systematic-debugging

# Bad
See skills/testing/test-driven-development   (unclear if required)
@skills/testing/SKILL.md                     (force-loads, burns context)
```

## Token Efficiency

**Target word counts:**
- getting-started workflows: <150 words each
- Frequently-loaded skills: <200 words total
- Other skills: <500 words

**Techniques:** Move details to tool help, use cross-references, compress examples, eliminate redundancy.

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

Applies to NEW skills AND EDITS to existing skills. Write skill before testing? Delete it. Start over.

**Testing overhead scales with skill type:**
- **Discipline-enforcing skills:** Full pressure testing with multiple combined pressures.
- **Technique skills:** Application and variation scenarios.
- **Reference skills:** Retrieval scenario + one application scenario.

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)
Run pressure scenario WITHOUT the skill. Document exact rationalizations agents use.

### GREEN: Write Minimal Skill
Write skill addressing those specific rationalizations. Run same scenarios WITH skill.

### REFACTOR: Close Loopholes
Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

## Bulletproofing Against Rationalization

- **Close every loophole explicitly** — Don't just state the rule, forbid specific workarounds
- **Address "spirit vs letter"** — Add: "Violating the letter of the rules is violating the spirit"
- **Build rationalization table** — Capture every excuse agents make during baseline testing
- **Create red flags list** — Make it easy for agents to self-check

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

## Writing Skills for Packs

A **pack** is a versioned bundle of skills, agents, and hooks distributed as a unit. When authoring skills intended for pack distribution:

### Pack Skill Structure

```
forge-pack-<name>/
  skills/
    skill-one/
      SKILL.md
    skill-two/
      SKILL.md
  agents/
  hooks/
  pack.yml
```

Personal pack skills can also live in `forge-pack-<name>/skills/` inside your home directory.

### Pack Authoring Protocol

1. **Namespace skills** — Use a pack prefix in cross-references: `forge:my-pack/skill-name`
2. **Self-contained** — Pack skills must not reference skills outside the pack unless they are Forge built-ins
3. **pack.yml declares dependencies** — If a skill requires another pack, declare it explicitly
4. **Version compatibility** — Note the minimum Forge version in pack.yml frontmatter
5. **Description conventions** — All descriptions start with "Use when..." (same as standard skills)

### Pack Naming Conventions

```yaml
# pack.yml frontmatter
name: forge-pack-mytools
version: 1.0.0
forge_min_version: "1.0.0"
skills:
  - skills/skill-one/SKILL.md
  - skills/skill-two/SKILL.md
```

### Cross-Referencing in Pack Skills

```markdown
# Within-pack reference (preferred)
forge:mytools/skill-name

# Forge built-in reference (allowed)
forge:test-driven-development

# External pack reference (declare in pack.yml)
forge:other-pack/skill-name
```

### Testing Pack Skills

Test pack skills the same way as standard skills (RED-GREEN-REFACTOR). Additionally:
- Verify the skill loads correctly when the pack is installed
- Test that cross-pack references resolve properly
- Confirm pack.yml lists all required skills

## Skill Creation Checklist

**RED Phase:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill — document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase:**
- [ ] Name uses only letters, numbers, hyphens
- [ ] YAML frontmatter with name and description (max 1024 chars)
- [ ] Description starts with "Use when..." — triggering conditions only
- [ ] Run scenarios WITH skill — verify agents now comply

**REFACTOR Phase:**
- [ ] Add explicit counters for new rationalizations
- [ ] Build rationalization table
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Small flowchart only if decision non-obvious
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**
- [ ] Commit skill to git
- [ ] Consider contributing back via PR (if broadly useful)

## Anti-Patterns

| Anti-Pattern | Why Bad |
|---|---|
| Narrative example ("In session 2025-10-03...") | Too specific, not reusable |
| Multi-language dilution (js + py + go) | Mediocre quality, maintenance burden |
| Code in flowcharts | Can't copy-paste, hard to read |
| Generic labels (helper1, step3) | Labels need semantic meaning |

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).

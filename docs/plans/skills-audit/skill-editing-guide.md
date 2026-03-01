# Skill Editing Reference Guide

> For skill editors working on the skills audit. Combines guidance from Anthropic's official docs, the upstream writing-skills skill, and community best practices.

## Authoritative Sources

1. **Anthropic Official Best Practices** — `skills/writing-skills/anthropic-best-practices.md` (bundled, 52KB)
2. **Anthropic Platform Docs** — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
3. **Complete Guide PDF** — https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf
4. **Anthropic Skills Repo** — https://github.com/anthropics/skills (production examples)
5. **Upstream writing-skills** — `skills/writing-skills/SKILL.md` (our own meta-skill)

## Key Rules for This Audit

### YAML Frontmatter
- Only two fields: `name` and `description`
- `name`: lowercase letters, numbers, hyphens only. Max 64 chars. No "anthropic" or "claude".
- `description`: Max 1024 chars. Start with "Use when..." — triggering conditions ONLY, never summarize the workflow.
- Third person always. No "I can help" or "You can use this".

### Why Description Must Not Summarize Workflow
Testing proved: when description summarizes workflow, Claude follows the description shortcut instead of reading the full skill body. A description saying "code review between tasks" caused Claude to do ONE review, even though the flowchart showed TWO reviews. Description = triggering conditions only.

### Token Efficiency
- SKILL.md body under 500 lines (Anthropic guideline)
- Claude is smart — only add context it doesn't already have
- Challenge every paragraph: "Does this justify its token cost?"
- Move heavy reference to separate files (progressive disclosure)
- One level of file references from SKILL.md (no deeply nested chains)

### Content Principles
- **Concise is key** — The context window is shared. Every token competes.
- **Set appropriate degrees of freedom** — Discipline skills need low freedom (exact steps). Technique skills need medium-high freedom.
- **Consistent terminology** — Pick one term, use it everywhere. Don't mix "endpoint/URL/route/path".
- **No time-sensitive info** — Don't say "after March 2026 use X". Use "current method" vs "legacy method".
- **Examples over explanation** — One excellent example beats three paragraphs of description.

### Structural Patterns
- Use workflows/checklists for multi-step processes
- Use tables for quick reference (scan-friendly)
- Use dot digraphs ONLY for non-obvious decision points
- Use progressive disclosure: SKILL.md → linked reference files
- Cross-reference other skills by name: `**REQUIRED SUB-SKILL:** Use superpowers:skill-name`
- Never use `@` links (force-loads files, burns context)

### What We're Changing in This Audit

1. **TodoWrite → TaskCreate/TaskUpdate** — Global rename
2. **"your human partner" → "the user"** — Generalize Jesse-specific language
3. **Add state.yml integration** — Each skill documents what it reads/writes
4. **Add verification gates** — Skills check preconditions via state.yml
5. **Add evidence format references** — Execution skills reference canonical format from verification-before-completion
6. **Directory-based plans** — `design.md`/`plan.md`/`tasks/` separation
7. **Worktree rework** — Layer on native EnterWorktree
8. **TDD structural enforcement** — Plan-level test expectations + execution-level red/green evidence

### Attribution Requirements

Every commit must credit upstream issues/PRs/authors whose work informed the fix:
```
fix(skill-name): brief description

Addresses #NNN. Inspired by PR #NNN (@author).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Commit Granularity

One commit per fix or group of related fixes. Each commit should map to specific findings from the audit document (`docs/plans/2026-03-01-skills-audit-brainstorm.md`).

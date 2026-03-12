# Generated File Templates

Templates used by `adopting-forge` when creating or appending AI surface files.


## CLAUDE.md — Forge Section (append to existing)

When `CLAUDE.md` already exists, append the following section at the end.
Never modify or remove existing content.

~~~markdown

---

## Forge Configuration

This repository uses **Forge** for structured AI-assisted development.

### Workflow

Always invoke `forge-routing` at the start of any task. Forge will detect intent,
classify risk, and route to the correct skill.

### Risk Tiers

File paths in this repo are classified by risk tier (see `.forge/policies/`):
- **critical** — auth, migrations, payments: requires design doc, plan, TDD, security review
- **elevated** — public API, admin: requires plan, TDD, evidence, review
- **standard** — application code: requires plan, test evidence, verification
- **minimal** — docs, config: requires verification only

### State and Evidence

```bash
forge-state get <key>              # read project state
forge-state set <key> <value>      # write project state
forge-evidence add <task-id> <artifact>   # record evidence
forge-gate check <gate-name>       # check lifecycle gate
```

### Tools Location

Forge tools live in `.forge/bin/`. Add to PATH or call directly:

```bash
export PATH=".forge/bin:$PATH"
```
~~~


## CLAUDE.md — Full File (when no CLAUDE.md exists)

~~~markdown
# Project: <repo-name>

## Stack

- Language: <stack>
- Test: `<test-cmd>`
- Lint: `<lint-cmd>`

---

## Forge Configuration

This repository uses **Forge** for structured AI-assisted development.

### Workflow

Always invoke `forge-routing` at the start of any task. Forge will detect intent,
classify risk, and route to the correct skill.

### Risk Tiers

File paths in this repo are classified by risk tier (see `.forge/policies/`):
- **critical** — requires design doc, plan, TDD, security review
- **elevated** — requires plan, TDD, evidence, review
- **standard** — requires plan, test evidence, verification
- **minimal** — requires verification only

### State and Evidence

```bash
forge-state get <key>
forge-state set <key> <value>
forge-evidence add <task-id> <artifact>
forge-gate check <gate-name>
```

### Tools Location

```bash
export PATH=".forge/bin:$PATH"
```
~~~


## AGENTS.md — Codex Multi-Platform Adapter

Create `AGENTS.md` at repo root for OpenAI Codex and other agent platforms.

~~~markdown
# Agent Instructions: <repo-name>

This repository uses **Forge** for structured AI development workflows.

## Stack

- Language: <stack>
- Test command: `<test-cmd>`
- Lint command: `<lint-cmd>`

## Workflow

Before starting any task:
1. Read `.forge/project.yaml` for project configuration
2. Read `.forge/policies/default.yaml` for risk tier rules
3. Follow the risk tier for the files you will touch

## Risk Tiers

| Path pattern | Tier | Required artifacts |
|-------------|------|-------------------|
| `auth/**` | critical | design-doc, plan, tdd, security-review |
| `db/migrations/**` | critical | design-doc, risk-register, plan, tdd, rollback-evidence |
| `src/**` | standard | plan, test-evidence, verification |
| `docs/**` | minimal | verification |

## Evidence

Record evidence for each task:

```bash
.forge/bin/forge-evidence add <task-id> <artifact>
.forge/bin/forge-evidence list <task-id>
```

## State

```bash
.forge/bin/forge-state get <key>
.forge/bin/forge-state set <key> <value>
```
~~~

## Substitution Variables

When generating from these templates, replace:

| Placeholder | Source |
|-------------|--------|
| `<repo-name>` | directory name of repo root |
| `<stack>` | detected from stack-detection heuristics |
| `<test-cmd>` | detected test command |
| `<lint-cmd>` | detected lint command |

Omit lines with undetected values rather than leaving placeholders in the output.

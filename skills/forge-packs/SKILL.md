---
name: forge-packs
description: Use when installing, removing, or managing Forge packs — reusable bundles of skills, policies, and shared knowledge
---

# Forge Packs

## Overview

Packs are reusable bundles of skills, policies, and shared knowledge that can be installed into any Forge-adopted project. They extend Forge with domain-specific workflows, risk rules, and conventions without modifying the core system.

## Commands

```
forge-pack install <path>   — install a pack from a local directory
forge-pack remove <name>    — remove an installed pack by name
forge-pack list             — list all installed packs
```

Run these from the project root (where `.forge/` lives).

## Prerequisites

Forge must be adopted before using packs. The file `.forge/project.yaml` must exist. If it does not, run `forge:adopting-forge` first.

## Pack Manifest (pack.yaml)

Every pack must have a `pack.yaml` at its root. Required fields:

```yaml
name: my-pack
version: 0.1.0
description: Short description of what this pack provides
forge_compatibility: ">=0.1.0"
provides:
  skills: [skill-name-1, skill-name-2]
  policies: [policy-file]
  agents: []
triggers:
  file_patterns: []
  stack_signals: []
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Pack identifier, used as install directory name |
| `version` | yes | SemVer version string |
| `description` | yes | Human-readable description |
| `forge_compatibility` | yes | Minimum Forge version required |
| `provides` | recommended | Lists skills, policies, and agents the pack adds |
| `triggers` | optional | Auto-routing hints |

## Install Target

Packs are installed to `.forge/packs/<name>/`. After install:

```
.forge/
  packs/
    hello-world/        ← pack contents copied here
      pack.yaml
      skills/
      policies/
      shared/
  policies/
    greeting-policy.yaml  ← merged policy rules (with source annotation)
```

## Pack Skill Namespace

Skills provided by packs use the `forge:<pack-name>:<skill-name>` namespace:

- `forge:hello-world:greeting-workflow`
- `forge:my-pack:custom-workflow`

Reference pack skills by this namespace in routing tables and skill invocations.

## Policy Merge with Source Annotation

When a pack is installed, its policy files are merged into `.forge/policies/`. Each rule gets a `source: pack/<name>` annotation added automatically by `forge-pack`:

```yaml
# After installing hello-world pack:
rules:
  - match: ["greetings/**"]
    tier: minimal
    source: pack/hello-world   ← added by forge-pack
```

This annotation enables clean removal: `forge-pack remove` strips all rules with `source: pack/<name>` from the policy files. If a policy file becomes empty after removal, it is deleted.

Existing project policy rules are never modified — pack rules are appended only.

## Writing Packs

A pack directory should contain:

```
my-pack/
  pack.yaml                     ← required manifest
  README.md                     ← pack description and usage
  skills/
    <skill-name>/
      SKILL.md                  ← skill definition
  policies/
    <policy-name>.yaml          ← policy rules (source annotation added on install)
  shared/
    <conventions>.md            ← shared knowledge files
```

Skill files in packs follow the same conventions as built-in Forge skills:
- Frontmatter with `name` and `description` (description must start with "Use when")
- Under 500 lines
- Use `.forge/` paths (never the legacy state directory)
- Use `forge:` namespace (never the legacy plugin prefix)

See `forge:writing-skills` for full skill authoring guidance.

## Integration

After installing a pack:
1. Pack skills become available in the `forge:<pack>:<skill>` namespace
2. Pack policy rules are active in `.forge/policies/` (with source annotation)
3. Pack shared knowledge is accessible at `.forge/packs/<name>/shared/`
4. `forge-pack list` shows the pack as installed

Packs are project-local and not committed to version control unless you choose to commit `.forge/packs/`.

# forge-pack-hello-world

A sample Forge pack demonstrating the pack protocol. Use this pack as a reference when building your own packs.

## What This Pack Provides

- **Skill:** `forge:hello-world:greeting-workflow` — guides drafting audience-appropriate greeting messages
- **Policy:** `greeting-policy.yaml` — classifies `greetings/**` and `hello/**` as `minimal` risk tier
- **Shared knowledge:** `greeting-conventions.md` — tone, structure, and checklist for greeting content

## Installation

```
forge-pack install ./forge-pack-hello-world
```

## Usage

After installation, invoke the skill:

```
forge:hello-world:greeting-workflow
```

Or reference it in a routing table using the full namespace.

## Removal

```
forge-pack remove hello-world
```

All policy rules added by this pack are removed automatically.

## Pack Structure

```
forge-pack-hello-world/
  pack.yaml                               ← pack manifest
  README.md                               ← this file
  policies/
    greeting-policy.yaml                  ← risk rules for greeting files
  skills/
    greeting-workflow/
      SKILL.md                            ← greeting workflow skill
  shared/
    greeting-conventions.md               ← tone and structure conventions
```

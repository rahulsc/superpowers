---
name: greeting-workflow
description: Use when generating a greeting message, welcome text, or introductory content for users or documentation
---

# Greeting Workflow

## Overview

This skill guides you through producing a well-formed greeting. It is a demonstration skill shipped in the `hello-world` Forge pack.

## When to Use

Invoke `forge:hello-world:greeting-workflow` when the user asks for:
- A welcome message
- An introductory paragraph
- A project greeting or onboarding blurb

## Steps

1. **Identify the audience** — who will read the greeting? (user, developer, external stakeholder)
2. **Set the tone** — formal, casual, or technical?
3. **Draft the greeting** — apply conventions from `shared/greeting-conventions.md`
4. **Review** — check against the conventions checklist before delivering

## Conventions

See `.forge/packs/hello-world/shared/greeting-conventions.md` for tone and style rules.

## Evidence

Before marking a greeting task complete, confirm:
- Audience identified
- Tone matched to audience
- Conventions checklist passed

## Integration

This skill is namespaced as `forge:hello-world:greeting-workflow`. Reference it in routing tables or skill invocations using this full namespace.

---
name: syncing-forge
description: Use when project configuration or structure has changed and Forge adapters need regeneration — after adding new files, changing directory structure, or installing packs
---

# Syncing Forge

**Announce at start:** "I'm using the syncing-forge skill to refresh Forge's view of this repository."

Forge sync has eight steps. Do not skip steps.


## When to Use

- After modifying `.forge/project.yaml`
- After adding/removing files that match policy rules
- After a teammate modifies `.forge/shared/` or `.forge/policies/`
- Periodically to refresh adapters and check pack freshness
- After `forge:adopting-forge` (initial setup) to confirm adapters are current


## Step 1 — Read Current Configuration

Read `.forge/project.yaml` and extract:
- `name`, `stack`, `commands` (test, lint, build), `storage`
- Any pack references under `packs:` key (if present)
- Codex compatibility flag if present (`codex: true`)

If `.forge/project.yaml` does not exist, stop and report:
```
Error: .forge/project.yaml not found.
Run forge:adopting-forge to set up Forge first.
```


## Step 2 — Scan Repo for Changes

Scan at file and directory level (not AST):

**Stack signals** (compare against project.yaml `stack` field):

| Signal file | Stack |
|-------------|-------|
| `package.json` | node / javascript |
| `tsconfig.json` | typescript |
| `Cargo.toml` | rust |
| `go.mod` | go |
| `pyproject.toml` / `requirements.txt` / `setup.py` | python |
| `Gemfile` | ruby |
| `pom.xml` / `build.gradle` | java / jvm |

**Risk area changes** — scan for new directories matching policy patterns:
- `auth/`, `authentication/`, `login/` → critical
- `db/migrations/`, `database/migrations/` → critical
- `payment/`, `billing/`, `stripe/` → critical
- `api/public/`, `api/v*/` → elevated
- `admin/` → elevated
- `docs/`, `README*` → minimal

**Command changes** — re-check for test/lint/build commands:
- `package.json` scripts
- `Makefile` targets
- `pyproject.toml` sections


## Step 3 — Compare Against project.yaml

Build a diff table of detected vs recorded values:

```
Field         Recorded              Detected              Status
-----         --------              --------              ------
stack         typescript            typescript            OK
test cmd      npm test              npm test              OK
lint cmd      npm run lint          npm run lint          OK
Risk: src/payments/  <not recorded>  (new directory)    NEW
```

List items as: `OK`, `CHANGED`, `NEW`, or `REMOVED`.

If no changes detected, report:
```
No configuration drift detected. project.yaml is current.
```
And continue to Step 6 (pack check) and Step 7 (cache refresh).


## Step 4 — Regenerate CLAUDE.md

Read existing `CLAUDE.md`. Locate the Forge section (bounded by `<!-- forge:start -->` and `<!-- forge:end -->` markers, or the section headed `## Forge`).

**If Forge section exists:** Replace only the Forge section with updated content from current `project.yaml`. Preserve all content outside the Forge section.

**If no Forge section exists:** Append a Forge section at the end.

Forge section template (populate from project.yaml):
```markdown
## Forge

This repository uses Forge for structured AI workflows.

**Stack:** <stack>
**Test:** <commands.test>
**Lint:** <commands.lint | "not configured">

Forge configuration: `.forge/project.yaml`
Forge policies: `.forge/policies/`
```

After updating, confirm: "Updated CLAUDE.md Forge section."


## Step 5 — Regenerate AGENTS.md

Only execute this step if `codex: true` is set in `project.yaml` OR if `AGENTS.md` already exists.

Read existing `AGENTS.md` (if present). Update the Forge-generated section with current stack and commands from `project.yaml`. Preserve any non-Forge sections.

If creating fresh:
```markdown
# Agents

This repository uses Forge for structured AI workflows.

## Stack
<stack from project.yaml>

## Commands
- Test: <commands.test>
- Lint: <commands.lint>

## Forge Policies
See `.forge/policies/` for risk-tier rules governing this repository.
```

After updating, confirm: "Updated AGENTS.md."


## Step 6 — Check Installed Packs

If `.forge/packs/` directory does not exist or is empty: skip this step and note "No packs installed."

For each pack directory under `.forge/packs/`:
1. Read `pack.yaml` to get `name` and `version`
2. Check if a `.forge/packs/<pack-name>/.forge-pack-lock` file exists (indicates locked version)
3. Report pack status:

```
Installed packs:
  forge-pack-security v1.2.0  [update available: v1.3.0]
  forge-pack-docs     v0.9.1  [current]
```

**Do NOT auto-update packs.** Only report available updates. User must run pack update explicitly.

Pack update detection: compare `version` field in `pack.yaml` against `.forge/packs/<name>/.available-version` if that file exists. If neither file exists, report "version check unavailable."


## Step 7 — Refresh Local Cache

If `.forge/local/cache/` does not exist: skip and note "No cache directory."

If cache directory exists:
1. List cache files: `ls .forge/local/cache/`
2. Remove entries older than 7 days (by file mtime)
3. Report: "Refreshed cache: removed N stale entries, M entries retained."

Do NOT remove non-cache files from `.forge/local/`.


## Step 8 — Report Summary

Present a structured summary:

```
Forge Sync Complete for <project name>

Configuration drift:
  stack        OK
  test cmd     OK
  lint cmd     CHANGED (was: npm run lint → now: npm run lint:fix)

Adapters:
  CLAUDE.md    Updated (Forge section refreshed)
  AGENTS.md    Skipped (codex: false)

Packs:
  No packs installed

Cache:
  Removed 3 stale entries, 12 retained

Action required:
  - Review lint command change: update project.yaml if intentional
  - New risk area detected: src/payments/ — consider adding policy rule
```

If nothing changed: "Forge is fully synced. No action required."


## Scope Limits

- Do NOT auto-update packs (report only)
- Do NOT auto-regenerate CLAUDE.md on session start (on-demand only)
- Do NOT modify `.forge/policies/` — policy changes require explicit adopting-forge or manual edit
- Do NOT remove `.forge/local/` state files (only cache subfolder entries)
- Do NOT parse ASTs or import graphs — file/directory level only


## Integration

Called by: users on-demand, `forge:adopting-forge` (after initial generation)
Pairs with: `forge:adopting-forge` (initial setup), `forge:diagnosing-forge` (health checks)

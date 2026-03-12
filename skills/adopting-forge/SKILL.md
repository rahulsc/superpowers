---
name: adopting-forge
description: Use when setting up Forge in an existing repository for the first time — installs .forge/ configuration, CLAUDE.md adapter, and hooks
---

# Adopting Forge

**Announce at start:** "I'm using the adopting-forge skill to set up Forge in this repository."

Forge adoption has six steps. Do not skip steps. Do not create files before Step 5.


## Step 1 — Inspect Repository

Scan the repo at file and directory level (no AST analysis):

**Stack detection** — look for these signals (full heuristics in `references/stack-detection.md`):

| Signal file | Stack |
|-------------|-------|
| `package.json` | node / javascript |
| `tsconfig.json` | typescript |
| `Cargo.toml` | rust |
| `go.mod` | go |
| `pyproject.toml` / `requirements.txt` / `setup.py` | python |
| `Gemfile` | ruby |
| `pom.xml` / `build.gradle` | java / jvm |

**Command detection** — scan for test/lint/build commands:
- Check `package.json` scripts: `test`, `lint`, `build`
- Check `Makefile` targets: `test`, `lint`, `build`, `check`
- Check `pyproject.toml` `[tool.pytest]`, `[tool.ruff]` sections
- Check `Cargo.toml` for `cargo test`, `cargo clippy`
- Check `.github/workflows/` for CI steps (extracts actual commands)

**Risk area detection** — flag directories that need elevated/critical policies:
- `auth/`, `authentication/`, `login/` → critical
- `db/migrations/`, `database/migrations/` → critical
- `payment/`, `billing/`, `stripe/` → critical
- `api/public/`, `api/v*/` → elevated
- `admin/` → elevated
- `docs/`, `README*` → minimal

**AI surface detection:**
- `CLAUDE.md` (Claude Code), `.cursor/` (Cursor), `AGENTS.md` (Codex)
- Existing `.forge/` → re-adoption path (see below)

Collect: stack, version manager, test command, lint command, build command, risk areas, existing AI surfaces.


## Step 2 — Propose Configuration

Present findings as a structured proposal. Include confidence scores based on how many signals confirm each field:

```
Detected configuration for: <repo-name>

Stack:       node / typescript          [confidence: high — package.json + tsconfig.json]
Test cmd:    npm test                   [confidence: high — package.json scripts.test]
Lint cmd:    npm run lint               [confidence: medium — package.json scripts.lint]
Build cmd:   npm run build              [confidence: high — package.json scripts.build]

Risk areas detected:
  src/auth/          → critical  (auth directory)
  db/migrations/     → critical  (database migrations)
  src/api/           → elevated  (public API)
  docs/              → minimal

Existing AI surfaces:
  CLAUDE.md          → will append Forge section (not overwrite)
  No AGENTS.md       → will create for Codex compatibility
```

Ask: "Does this look correct? Any fields to adjust before I continue?"

Wait for confirmation before proceeding.


## Step 3 — Choose Mode

Offer two adoption modes:

| Mode | Creates | Best for |
|------|---------|----------|
| **Light touch** | `.forge/project.yaml` only | Solo developer, simple project |
| **Full adoption** | Complete `.forge/` layout + policies + hooks | Team workflows, elevated/critical risk areas |

If any critical risk areas were detected, recommend full adoption.

Present the choice and wait for selection.


## Step 4 — Preview Files

Show every file that will be created or modified. Do NOT create anything yet.

For **light touch**:
```
Files to create:
  .forge/project.yaml        — project config (name, stack, commands, storage)
  .forge/local/.gitignore    — gitignore for local state files

Files to modify:
  CLAUDE.md                  — append Forge section (existing content preserved)

Files to create (new):
  AGENTS.md                  — Codex compatibility adapter
```

For **full adoption**, additionally:
```
  .forge/policies/default.yaml   — risk tier rules for detected paths
  hooks registered in hooks.json via forge-routing
```

Show the content of each file that will be created (use code blocks).

Ask: "Shall I apply these changes?" — proceed only on explicit yes.


## Step 5 — Apply

Create files in this order:

1. **`.forge/project.yaml`** — use detected values:
   ```yaml
   name: <repo-name>
   version: "1.0"
   stack: <detected-stack>
   commands:
     test: <detected-test-cmd>
     lint: <detected-lint-cmd>
   storage: json
   ```
   Omit any field not detected with at least medium confidence.

2. **`.forge/policies/default.yaml`** (full adoption only) — generate rules from detected risk areas:
   ```yaml
   rules:
     - match: "auth/**"
       tier: critical
       require: [design-doc, plan, tdd, evidence, security-review]
     - match: "db/migrations/**"
       tier: critical
       require: [design-doc, risk-register, plan, tdd, rollback-evidence, review]
     - match: "src/**"
       tier: standard
       require: [plan, test-evidence, verification]
     - match: "docs/**"
       tier: minimal
       require: [verification]
   ```

3. **`CLAUDE.md`** — detect existing content:
   - If `CLAUDE.md` exists: append Forge section below existing content (template in `references/generated-claude-md-template.md`)
   - If `CLAUDE.md` does not exist: create from template

4. **`AGENTS.md`** — create multi-platform adapter for Codex compatibility (see template in `references/generated-claude-md-template.md`)

5. **`.forge/local/.gitignore`** — `*` (gitignore all local state)

Run `forge-state init --project-dir .` to initialize state storage.


## Step 6 — Verify

Run health checks after applying:

```
forge-gate check design.approved --project-dir .    # expected: exit 2 (not yet set — normal)
forge-state get active.task --project-dir .         # expected: key not found — normal
ls .forge/                                          # should show: bin/ local/ policies/ project.yaml
```

Then invoke `diagnosing-forge` (or equivalent health check) to confirm Forge is functional.

Report to user:
```
Forge adoption complete for <repo-name>.

Created:
  ✓ .forge/project.yaml
  ✓ .forge/policies/default.yaml   (if full adoption)
  ✓ CLAUDE.md (appended / created)
  ✓ AGENTS.md

Next step: Run forge-routing when starting your first task.
```


## Re-adoption (`.forge/` Already Exists)

If `.forge/` already exists:
1. Read existing `project.yaml` — show current values
2. Diff proposed vs existing — only show what would change
3. Ask: "Update existing config?" before touching anything
4. Never overwrite `policies/` without explicit permission
5. Always preserve existing `local/` state (do not run `init` again unless asked)


## Scope Limits

- Do NOT implement syncing or diagnosing (separate skills)
- Do NOT detect packages inside `node_modules/` or build artifacts
- Do NOT parse ASTs or import graphs — file/directory level only
- Forge uses `.forge/` exclusively — do not create or modify other AI plugin directories

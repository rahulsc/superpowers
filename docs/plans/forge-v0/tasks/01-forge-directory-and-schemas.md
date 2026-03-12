# Task 1: `.forge/` Directory Structure and YAML Schemas

**Specialist:** implementer-1
**Depends on:** None
**Produces:** `.forge/` directory template, `project.yaml` JSON schema, `policies/*.yaml` schema, `workflows/*.yaml` schema, `packs/*.yaml` schema, `shared/` templates (architecture.md, conventions.md, decisions/ with template)

## Goal

Create the complete `.forge/` directory structure with all YAML schemas and shared knowledge templates that every other Forge component builds on.

## Acceptance Criteria

- [ ] `.forge/project.yaml` template exists with all required fields: `name`, `version`, `stack`, `commands`, `repo_traits`, `storage` (sqlite|json)
- [ ] `.forge/policies/default.yaml` template exists with `rules` array schema: each rule has `match` (glob array), `tier` (minimal|standard|elevated|critical), and optional `require` (artifact array)
- [ ] `.forge/workflows/` directory exists with a documented example workflow YAML
- [ ] `.forge/packs/` directory exists (empty, with `.gitkeep`)
- [ ] `.forge/adapters/` directory exists (empty, with `.gitkeep`)
- [ ] `.forge/shared/architecture.md` template exists with placeholder sections (module map, key patterns, dependency graph)
- [ ] `.forge/shared/conventions.md` template exists with placeholder sections (naming, style, testing, commit conventions)
- [ ] `.forge/shared/decisions/` directory exists with a `000-template.md` ADR template following the NNN-topic naming convention
- [ ] `.gitignore` additions for `.forge/local/` and all its subdirectories are documented (not committed to repo root yet -- this is a template)
- [ ] All template YAML files are syntactically valid YAML (parseable by any YAML parser)
- [ ] `project.yaml` includes inline comments explaining each field
- [ ] Policy rule `match` patterns use standard glob syntax consistent with the design doc examples (`db/migrations/**`, `auth/**`, `docs/**`)
- [ ] `storage` field in `project.yaml` defaults to `sqlite` with a comment explaining auto-detection behavior

## Test Expectations

- **Test:** Validate directory structure exists and all YAML files parse without errors. Validate that `forge-state` (Task 2) rejects operations when `.forge/project.yaml` is missing.
- **Expected red failure:** `Error: .forge/project.yaml not found` when validation runs against an empty directory before templates are created.
- **Expected green:** All template files exist at expected paths, are valid YAML (exit 0 from `python3 -c "import yaml; yaml.safe_load(open('...'))"` or equivalent), schema fields match design spec.

## Files

- Create: `.forge/project.yaml` (template with inline documentation)
- Create: `.forge/policies/default.yaml` (template with example rules from design Section 3)
- Create: `.forge/workflows/example.yaml` (documented example workflow definition)
- Create: `.forge/packs/.gitkeep`
- Create: `.forge/adapters/.gitkeep`
- Create: `.forge/shared/architecture.md` (template)
- Create: `.forge/shared/conventions.md` (template)
- Create: `.forge/shared/decisions/000-template.md` (ADR template)
- Create: `.forge/local/.gitignore` (ignore everything in local/)
- Test: `tests/forge-structure/validate-directory.sh`
- Test: `tests/forge-structure/validate-schemas.sh`

## Implementation Notes

**Design reference:** Section 2 of `docs/plans/forge-v0/design.md` has the full directory layout and rationale for what is checked-in vs gitignored.

**project.yaml fields** (derived from design):
```yaml
name: ""              # Project name
version: ""           # Project version (optional)
stack: []             # Detected/declared tech stack (e.g., ["node", "typescript", "react"])
commands:
  test: ""            # Test runner command
  build: ""           # Build command (optional)
  lint: ""            # Lint command (optional)
repo_traits: []       # Detected repo traits (e.g., ["monorepo", "ci-github-actions"])
storage: sqlite       # sqlite | json (auto-detected, user-overridable)
```

**Policy schema** (derived from design Section 3):
```yaml
rules:
  - match: ["glob-pattern"]
    tier: minimal | standard | elevated | critical
    require: ["artifact-name"]  # optional
```

**ADR template** should follow lightweight ADR format: Status, Context, Decision, Consequences.

**Shared knowledge templates** are team-facing markdown -- they should be useful empty scaffolds, not lorem ipsum. Include section headers that guide what to fill in.

**YAGNI notes:**
- Do NOT create the `local/` subdirectory structure (forge.sqlite, state.json, memory/, etc.) -- that is Task 2's responsibility via the storage helper.
- Do NOT create validation logic -- that belongs in Task 2 (forge-state) and Task 3 (classify-risk).
- Do NOT create any shell scripts or executables -- those are Tasks 2-4.
- Workflow YAML schema is illustrative only for v0; real workflow engine is post-v0.

**Naming convention:** All YAML files use `.yaml` extension (not `.yml`) for consistency.

## Commit

`feat: add .forge/ directory structure, YAML schemas, and shared knowledge templates`

# Task 20: Pack Protocol and Hello-World Pack

**Specialist:** implementer-1
**Depends on:** Task 7 (adopting-forge for pack discovery integration during adoption), Task 18 (syncing-forge for pack update checks)
**Produces:** Pack manifest schema, install/remove/list mechanics, hello-world sample pack; consumed by syncing-forge (pack update checks) and adopting-forge (pack discovery during adoption)

## Goal

Implement the pack protocol (install, remove, list) and prove it works with a hello-world sample pack.

## Acceptance Criteria

### Pack protocol
- [ ] `forge-pack install <path>` installs a pack from a local directory: copies pack contents to `.forge/packs/<name>/`, merges policy files into `.forge/policies/` with `source: pack/<name>` annotation on each merged rule, registers skills in pack into the skill discovery path
- [ ] `forge-pack remove <name>` removes a pack: deletes `.forge/packs/<name>/`, removes all policy rules annotated with `source: pack/<name>` from `.forge/policies/`, deregisters skills
- [ ] `forge-pack list` shows installed packs with name, version, and what each provides (skills, policies, agents)
- [ ] Pack manifest (`pack.yaml`) schema validated on install: required fields `name`, `version`, `description`, `forge_compatibility`; optional fields `provides`, `triggers`
- [ ] Install rejects packs with invalid or missing `pack.yaml` with a clear error message
- [ ] Install is idempotent: re-installing an already-installed pack updates it in place (remove then install)
- [ ] Remove is clean: no orphaned policy rules, no orphaned skill references after removal
- [ ] Policy merge preserves existing project policies: pack policies are appended, not replacing project rules
- [ ] All policy rules from a pack include `source: pack/<name>` annotation so they can be traced back and cleanly removed

### Hello-world pack
- [ ] `forge-pack-hello-world/pack.yaml` manifest exists with all required fields
- [ ] `forge-pack-hello-world/policies/greeting-policy.yaml` contains one policy rule (a trivial example: match `greetings/**`, tier `minimal`)
- [ ] `forge-pack-hello-world/skills/greeting-workflow/SKILL.md` contains a minimal skill demonstrating the pack skill pattern
- [ ] `forge-pack-hello-world/shared/greeting-conventions.md` contains a minimal shared knowledge document
- [ ] Hello-world pack installs, lists, and removes cleanly using `forge-pack` commands

### Integration
- [ ] `forge-pack` script is executable bash (no Node.js dependency)
- [ ] `forge-pack` validates `.forge/project.yaml` exists before any operation (Forge must be adopted first)

## Test Expectations

- **Test:** Pack install merges policies with source annotation. Pack remove cleans up completely. Pack list shows installed packs.
- **Expected red failure:** `forge-pack install forge-pack-hello-world/` fails with "Error: pack.yaml invalid" (if pack.yaml is malformed), or after removal `grep "source: pack/hello-world" .forge/policies/*.yaml` still returns matches (orphaned policy rules)
- **Expected green:** After install: policy rules with `source: pack/hello-world` appear in `.forge/policies/`, skill directory present in `.forge/packs/hello-world/skills/`, `forge-pack list` shows "hello-world v0.1.0". After remove: zero `source: pack/hello-world` matches in policies, `.forge/packs/hello-world/` directory does not exist, `forge-pack list` shows no packs.

## Files

- Create: `.forge/bin/forge-pack` (shell script -- install/remove/list subcommands)
- Create: `forge-pack-hello-world/pack.yaml` (sample manifest)
- Create: `forge-pack-hello-world/policies/greeting-policy.yaml` (sample policy)
- Create: `forge-pack-hello-world/skills/greeting-workflow/SKILL.md` (sample skill)
- Create: `forge-pack-hello-world/shared/greeting-conventions.md` (sample shared knowledge)
- Create: `forge-pack-hello-world/README.md` (pack description and usage)
- Test: `tests/forge-pack/install-remove-cycle.test.sh` (install hello-world, verify files, list, remove, verify clean)
- Test: `tests/forge-pack/policy-merge.test.sh` (install pack with policies, verify merge with source annotation, remove, verify clean removal)
- Test: `tests/forge-pack/invalid-manifest.test.sh` (attempt install with missing/malformed pack.yaml, verify rejection)

## Implementation Notes

**Pack manifest schema (from design Section 6):**
```yaml
name: hello-world
version: 0.1.0
description: A sample Forge pack demonstrating the pack protocol
forge_compatibility: ">=0.1.0"
provides:
  skills: [greeting-workflow]
  policies: [greeting-policy]
  agents: []
triggers:
  file_patterns: []
  stack_signals: []
```

**Pack lifecycle (from design Section 6):**
```
Discovery -> Recommendation -> Preview -> Install -> Active -> Update -> Remove
```
For v0, we implement Install, Active (list), and Remove. Discovery and Recommendation are handled by adopting-forge/syncing-forge (read pack triggers, match against repo). Preview is a dry-run flag on install. Update is remove + install.

**forge-pack install flow:**
```bash
# 1. Validate pack.yaml exists and is valid
# 2. Read pack name and version from manifest
# 3. Copy pack directory to .forge/packs/<name>/
# 4. Merge policies:
#    For each .yaml in pack's policies/:
#      Read rules, add "source: pack/<name>" to each rule
#      Append to .forge/policies/<filename> (or create if new)
# 5. Register skills (copy to .forge/packs/<name>/skills/ -- they are
#    discovered from there by the skill loader)
# 6. Report what was installed
```

**Policy merge with source annotation:**
```yaml
# In .forge/policies/greeting-policy.yaml after merge:
rules:
  - match: ["greetings/**"]
    tier: minimal
    source: pack/hello-world    # <-- annotation for traceability
```

The `source` annotation is the key mechanism for clean removal. `forge-pack remove` reads all policy files, filters out rules where `source` matches `pack/<name>`, and rewrites the files. If a policy file becomes empty after removal, delete it.

**forge-pack remove flow:**
```bash
# 1. Verify pack is installed (.forge/packs/<name>/ exists)
# 2. Remove all policy rules with "source: pack/<name>" from .forge/policies/
# 3. Delete .forge/packs/<name>/
# 4. Report what was removed
```

**Hello-world pack details:**

greeting-policy.yaml:
```yaml
rules:
  - match: ["greetings/**", "hello/**"]
    tier: minimal
```

greeting-workflow/SKILL.md:
```markdown
---
name: greeting-workflow
description: Use when creating greeting messages or welcome flows as a demonstration of the Forge pack protocol
---
# Greeting Workflow
A minimal demonstration skill installed by the hello-world pack.
[Minimal content proving pack skill loading works]
```

greeting-conventions.md:
```markdown
# Greeting Conventions
Sample shared knowledge document demonstrating pack-provided team knowledge.
- Greetings should be friendly and concise
- Use the user's preferred language when known
```

**YAGNI:**
- Do NOT implement remote pack registry or URL-based install (local path only for v0)
- Do NOT implement pack versioning or dependency resolution (design explicitly defers this)
- Do NOT implement `forge_compatibility` version checking (just validate the field exists)
- Do NOT implement pack marketplace or discovery service
- Do NOT implement agent installation from packs (just skills and policies for v0)
- Do NOT implement `forge-pack update` as a separate command (update = remove + install for v0)

**Testing approach:**
Tests create a temporary `.forge/` directory (via Task 1 template), run install/list/remove commands against the hello-world pack, and verify file system state at each step. Policy merge tests verify both the annotation and clean removal by grepping for `source: pack/hello-world`.

## Commit

`feat: add pack protocol with install/remove/list and hello-world sample pack`

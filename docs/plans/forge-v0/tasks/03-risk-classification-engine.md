# Task 3: Risk Classification Engine

**Specialist:** implementer-1
**Depends on:** Task 1 (`.forge/` structure for policy file locations), Task 2 (storage helper for reading/writing state)
**Produces:** Risk classification script that reads policies, accepts file paths and task description, and returns tier + requirements + execution strategy

## Goal

Implement the two-dimensional risk model (blast radius x scope) that determines ceremony level and execution strategy for every task Forge handles.

## Acceptance Criteria

- [ ] `classify-risk` script accepts file paths (space-separated or via stdin) and an optional `--description` flag for task description
- [ ] When file paths match explicit policy rules in `policies/*.yaml`, the matched rule's tier is returned
- [ ] When multiple policy rules match (files span different tiers), the highest tier wins
- [ ] When no policy rule matches, the script outputs `tier: inferred` with a rationale placeholder (actual inference is done by the LLM at runtime -- the script provides the "no match" signal)
- [ ] `--scope <N>` flag accepts task count; combined with blast radius, produces the matrix lookup from design Section 3
- [ ] Output includes: `tier` (minimal|standard|elevated|critical), `required_artifacts` (list), `execution_strategy` (solo|team-optional|team-recommended|team-required), `matched_rules` (which policy rules fired), `source` (policy|inferred|override)
- [ ] `--override <tier>` flag allows user override; override is recorded via `forge-state set risk.override <tier>`
- [ ] Output format is parseable (YAML or key=value, consistent)
- [ ] Script reads all `.yaml` files in `.forge/policies/` directory, not just `default.yaml`
- [ ] Invalid tier values in policy files produce a clear error message
- [ ] Script exits 0 on successful classification, non-zero on errors (missing policies dir, invalid YAML, etc.)

## Test Expectations

- **Test:** Given known file patterns matching policies, returns correct tier. Given unknown patterns, returns inferred signal. User override is recorded. Scope + blast radius matrix produces correct execution strategy.
- **Expected red failure:** `Error: classify-risk: unknown tier` when a policy contains an invalid tier value. Wrong tier returned when file matches a `critical` rule but engine returns `standard`.
- **Expected green:** Correct tier for policy-matched files (e.g., `db/migrations/001.sql` -> critical). Correct "inferred" signal for unmatched files. Correct matrix output for scope=6 + elevated blast radius -> team-recommended. Override recorded in state.

## Files

- Create: `.forge/bin/classify-risk` (shell script)
- Modify: `.forge/policies/default.yaml` (section: ensure example rules are testable -- this file is created by Task 1)
- Test: `tests/forge-risk/test-policy-matching.sh`
- Test: `tests/forge-risk/test-scope-matrix.sh`
- Test: `tests/forge-risk/test-override.sh`
- Test: `tests/forge-risk/test-multi-policy.sh`

## Implementation Notes

**Design reference:** Section 3 of `docs/plans/forge-v0/design.md` -- the full risk model, tier definitions, matrix, and determination priority order.

**Risk determination priority (from design):**
1. Policy rules (explicit YAML glob matching)
2. Agent inference (heuristic -- the script signals "no match", the LLM does the reasoning)
3. User override (always available, always recorded)

**Blast radius x scope matrix (from design):**

| | Small (1-3) | Medium (4-8) | Large (9+) |
|---|---|---|---|
| **Minimal blast** | minimal, solo | standard, solo | standard, team-optional |
| **Standard blast** | standard, solo | elevated, team-recommended | elevated, team-required |
| **High blast** | elevated, solo | critical, team-required | critical, team-required |

**Policy parsing approach:** Read each `.yaml` file in `.forge/policies/`. For each rule, test file paths against `match` globs using bash pattern matching or `fnmatch`-style logic. Collect all matching rules. Take the highest tier among matches.

**Tier ordering for "highest wins":** minimal < standard < elevated < critical

**Output format example:**
```
tier=elevated
source=policy
execution_strategy=team-recommended
required_artifacts=design-doc,plan,tdd,evidence,review
matched_rules=src/api/public/** (from default.yaml)
```

**How the script interacts with the LLM:** The script handles deterministic classification (policy matching + matrix lookup). When no policy matches, it outputs `source=inferred` and the calling skill (forge-routing or setting-up-project) asks the LLM to assess blast radius. The script is NOT an LLM -- it is a deterministic decision engine.

**Artifact requirements per tier (from design Section 3):**
- minimal: verification
- standard: plan, test-evidence, verification
- elevated: design-doc, plan, tdd, evidence, review
- critical: design-doc, risk-register, plan, tdd, security-review, rollback-evidence, review

**YAGNI notes:**
- Do NOT implement the LLM inference step -- just signal "no match" so the calling skill can do inference.
- Do NOT implement interactive prompting -- this is a non-interactive CLI tool.
- Do NOT parse `workflows/*.yaml` -- that is post-v0.
- Glob matching can be simple (bash `[[ "$path" == $pattern ]]`) -- no need for a full glob library.

## Commit

`feat: add risk classification engine with policy matching and scope matrix`

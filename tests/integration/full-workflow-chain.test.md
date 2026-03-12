# Full Workflow Chain Test

## Scenario

A developer wants to add a greeting endpoint to an existing Node.js project.
They start from an empty `.forge/` directory (no prior state) and walk the
entire Forge workflow from ideation to merged branch.

---

## Triggering Prompt

```
I want to add a /hello endpoint to this Node.js project that returns
{"message": "Hello, world!"} with status 200. What should I do first?
```

Expected: Claude routes to `forge:forge-routing`, which selects
`forge:brainstorming` as the entry point since there is no design yet.

---

## Expected Skill Chain

| Step | Skill | Trigger condition |
|------|-------|-------------------|
| 0 | `forge:adopting-forge` | `.forge/` does not exist or is uninitialized |
| 1 | `forge:forge-routing` | Every new task starts here |
| 2 | `forge:brainstorming` | No `design.approved` in state |
| 3 | `forge:setting-up-project` | `design.approved == true` in state |
| 4 | `forge:using-git-worktrees` | Risk tier requires isolation (standard+) |
| 5 | `forge:writing-plans` | Worktree set up, `design.approved` confirmed |
| 6 | `forge:subagent-driven-development` | <4 independent tasks |
| 6a | `forge:agent-team-driven-development` | 4+ independent tasks (alternative to 6) |
| 7 | `forge:test-driven-development` | Per-task, before writing implementation code |
| 8 | `forge:verification-before-completion` | All plan tasks complete |
| 9 | `forge:requesting-code-review` | Verification passed |
| 10 | `forge:finishing-a-development-branch` | Code review approved |

---

## State Keys at Each Transition

### After Step 2 (brainstorming complete)
```yaml
design:
  path: docs/hello-endpoint/design.md
  approved: true
  approved_at: "2026-03-12"
```

### After Step 3–4 (setting-up-project + worktrees)
```yaml
phase: setting-up
risk:
  tier: standard
  source: inferred
  execution_strategy: subagent
worktree:
  main:
    path: /tmp/.claude/worktrees/wt-hello-abc123
    branch: wt-hello-abc123
    repo_root: /path/to/project
team:
  decision: solo
```

### After Step 5 (writing-plans)
```yaml
phase: planning
plan:
  path: docs/hello-endpoint/plans/plan.md
  status: pending
  total_tasks: "3"
  executor: subagent-driven-development
```

### During Step 6 (execution, mid-progress)
```yaml
plan:
  completed_tasks: "[1, 2]"
```

### After Step 8 (verification-before-completion)
```yaml
verification:
  result: pass
  task: 3
  evidence_type: command
```

### After Step 9–10 (review + finishing)
```yaml
phase: complete
```

---

## Assertion Points

### forge-routing routes correctly
- Prompt contains no explicit skill name
- Claude selects `forge:brainstorming` (no existing design)
- Evidence: response mentions "brainstorming" or "design"

### brainstorming produces design doc
- `docs/hello-endpoint/design.md` created
- `design.approved: true` written to state
- Handoff instruction points to `forge:setting-up-project`

### setting-up-project gates on design.approved
- Reads `design.approved` before proceeding
- Aborts if gate fails (design not approved)
- Writes `risk.tier`, `phase`, `worktree.main.path`

### writing-plans produces plan.md
- `docs/hello-endpoint/plans/plan.md` created with YAML frontmatter `status: pending`
- `plan.path`, `plan.status`, `plan.total_tasks` written to state
- Plan tasks include test expectations (TDD alignment)

### execution uses TDD
- For each task: test written first (red), then implementation (green)
- `plan.completed_tasks` updated after each task
- Evidence collected via `forge-evidence add`

### verification-before-completion blocks on evidence
- Reads `risk.tier` to scale evidence requirements
- Writes `verification.result: pass` only after evidence collected
- Does NOT proceed if any test fails

### finishing-a-development-branch gates on verification
- Reads `verification.passed` before merge
- Aborts if verification not passed
- Writes `phase: complete` after successful merge

---

## Negative Scenarios (anti-patterns to verify DON'T happen)

| Anti-pattern | Skill affected | Enforcement |
|--------------|---------------|-------------|
| Skip brainstorming, go straight to code | forge-routing | Routes to brainstorming if no design |
| Start execution without plan.path in state | subagent/team skill | forge-gate check plan.path |
| Claim done without running tests | verification-before-completion | Evidence gate requires test output |
| Merge without verification | finishing | forge-gate check verification.passed |
| Write to worktree that doesn't exist | execution skills | forge-gate check worktree.main.path |

---

## How to Run This Test

This is a triggering prompt test — it describes expected LLM behavior, not
an automated script. To verify:

1. Set up a fresh Node.js project with no `.forge/` directory.
2. Start a Claude Code session with Forge loaded.
3. Send the triggering prompt above.
4. Observe the skill chain Claude follows.
5. After each skill, check state with:
   ```bash
   forge-state get design.approved
   forge-state get plan.path
   forge-state get verification.result
   ```
6. Confirm final state matches the table above.

For automated verification of state key consistency, run:
```bash
bash tests/integration/handoff-state.test.sh
```

For automated verification of skill descriptions, run:
```bash
bash tests/integration/skill-triggering.test.sh
```

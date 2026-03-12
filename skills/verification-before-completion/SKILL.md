---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

This skill is invoked by execution skills at task completion and by hooks. NOT optional.

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Evidence Format

All verification claims must include one or more of these evidence types. Reports without required evidence are rejected with: **"Missing evidence. Required: [type]."**

| Type | Use when | Must contain |
|------|----------|-------------|
| **Command** | Running tests, builds, linters | Command, verbatim output (last 50 lines), exit code |
| **Citation** | Spec/requirements review | file:line reference, code excerpt, verdict per requirement |
| **Diff** | Reporting implementation complete | `git diff --stat`, commit SHA |

**Which context requires which type:**

| Situation | Required evidence |
|-----------|-----------------|
| "Tests pass" | Command (test runner output) |
| "Build succeeded" | Command (build output, exit 0) |
| "Requirements met" | Citation (each requirement checked) |
| "Agent completed task" | Diff (VCS changes confirmed) + Command (test output) |
| "Spec compliant" | Citation (file:line per spec item) |
| "Implementation done" | Diff + Command |

**Re-review loop bound:** After 3 rejection cycles on the same claim, escalate to the user with the full rejection history rather than looping again.

## Risk-Tier Evidence Matrix

Evidence requirements scale with the risk tier of the current task. Read the active tier via `forge-state get risk.tier` (defaults to **standard** if unset).

| Evidence | Minimal | Standard | Elevated | Critical |
|----------|---------|----------|----------|----------|
| Tests pass (command) | Required | Required | Required | Required |
| Build clean (command) | - | Required | Required | Required |
| Acceptance criteria (citation) | - | - | Required | Required |
| Rollback plan tested (command) | - | - | - | Required |
| Security review (citation) | - | - | - | Required |
| RED/GREEN TDD evidence | - | - | Required | Required |

**Minimal** tier: tests pass via command evidence only. Suitable for docs, config, trivial fixes.

**Standard** tier: tests pass + build clean. Default for most development work.

**Elevated** tier: tests + build + acceptance criteria citation + RED/GREEN TDD evidence. For cross-cutting changes, API modifications, schema migrations.

**Critical** tier: all of the above + rollback plan tested via command + security review citation. For auth, payments, data integrity, production deployments.

When the tier is unknown, apply **standard**. When in doubt, escalate up, never down.

### Dynamic Evidence Checklist

Before completion, generate the required checklist from the current risk tier:

```
1. Read risk tier:  forge-state get risk.tier
2. Build checklist from the matrix above for that tier
3. Collect evidence for EVERY required row
4. Record result: forge-state set verification.result pass|fail
5. Record evidence: forge-evidence add verification <artifact>
```

## Common Failures

| Claim | Required evidence | Not sufficient |
|-------|----------|----------------|
| Tests pass | Command: test output, 0 failures | Previous run, "should pass" |
| Linter clean | Command: linter output, 0 errors | Partial check, extrapolation |
| Build succeeds | Command: build output, exit 0 | Linter passing, logs look good |
| Bug fixed | Command: original symptom now passes | Code changed, assumed fixed |
| Regression test works | Command: red-green cycle verified | Test passes once |
| Agent completed | Diff: VCS changes + Command: tests pass | Agent reports "success" |
| Requirements met | Citation: line-by-line per requirement | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence != evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter != compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion != excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
OK  [Run test command] [See: 34/34 pass] "All tests pass"
BAD "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
OK  Write -> Run (pass) -> Revert fix -> Run (MUST FAIL) -> Restore -> Run (pass)
BAD "I've written a regression test" (without red-green verification)
```

**Build:**
```
OK  [Run build] [See: exit 0] "Build passes"
BAD "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
OK  Re-read plan -> Create checklist -> Verify each -> Report gaps or completion
BAD "Tests pass, phase complete"
```

**Agent delegation:**
```
OK  Agent reports success -> Check git diff --stat -> Verify commit SHA -> Run tests -> Report actual state
    Evidence: Diff (VCS changes) + Command (test output)
BAD Trust agent report without diff or test evidence
```

## State Integration

Verification results are recorded in `.forge/state.yml` at key milestones via the forge-state CLI:

```
forge-state set verification.result pass
forge-state set verification.task 3
forge-state set verification.evidence_type command
forge-evidence add verification <artifact>
```

This allows session-resume to know the last verified state without re-running all checks.

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.

## Integration

**Called by:**
- **forge:subagent-driven-development** — REQUIRED after each task completion
- **forge:agent-team-driven-development** — REQUIRED for implementer completion reports
- **forge:subagent-driven-development** — REQUIRED before marking any task done
- **forge:finishing-a-development-branch** — final verification before merge/PR
- **hooks** — pre-commit and pre-push verification gates

**Pairs with:**
- **forge:requesting-code-review** — reviewer uses the canonical evidence format defined here
- **forge:finishing-a-development-branch** — final verification before merge/PR

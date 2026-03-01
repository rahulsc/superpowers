# Skills Audit Implementation Plan

> **For Claude:** Use agent-team-driven-development to execute this plan — 3 skill-editor agents working in parallel waves, reviewer after each wave.

**Goal:** Systematically improve all 16 Superpowers skills based on the comprehensive audit (26 findings, 13 handoff gaps, 110+ per-skill issues).

**Architecture:** Foundation-first approach. Wave 1 handles mechanical fixes and foundation docs. Waves 2-5 progressively fix skills grouped by workflow role, ensuring no two editors touch the same file.

**Tech Stack:** Markdown SKILL.md files, YAML frontmatter, dot digraphs.

---

## Reference Materials

Every editor MUST read before starting:
- `docs/plans/skills-audit/skill-editing-guide.md` — Condensed editing rules, attribution requirements
- `docs/plans/skills-audit/design.md` — Approved design (7 sections)
- `docs/plans/2026-03-01-skills-audit-brainstorm.md` — Full audit with per-skill issue tables
- `skills/writing-skills/anthropic-best-practices.md` — Anthropic's official skill authoring guide

## Wave Analysis

### Specialists

| Role | Expertise | Tasks |
|------|-----------|-------|
| skill-editor-a | Mechanical fixes, foundation skills | Tasks 1, 4, 7, 10, 13 |
| skill-editor-b | Infrastructure skills, execution skills | Tasks 2, 5, 8, 11, 14 |
| skill-editor-c | Foundation docs, support skills | Tasks 3, 6, 9, 12, 15 |

### Waves

**Wave 1: Mechanical fixes + Foundation docs** — No design judgment needed, pure execution
- Task 1 (skill-editor-a) — TodoWrite → TaskCreate global rename
- Task 2 (skill-editor-b) — "your human partner" generalization
- Task 3 (skill-editor-c) — Create foundation convention docs

  *Parallel-safe because:* Task 1 touches 5 skill files (using-superpowers, brainstorming, executing-plans, subagent-driven, writing-skills), Task 2 touches 4 different skill files (receiving-code-review, systematic-debugging, verification-before-completion, test-driven-development), Task 3 creates new files only.

**Wave 2: Core infrastructure skills** — Define the formats other skills reference
- Task 4 (skill-editor-a) — Canonical evidence format in verification-before-completion
- Task 5 (skill-editor-b) — Worktree rework in using-git-worktrees
- Task 6 (skill-editor-c) — TDD structural enforcement in test-driven-development

  *Parallel-safe because:* Each touches exactly one different skill file.
  *Depends on Wave 1:* Task 4 needs "your human partner" already generalized (Task 2). Task 6 needs TodoWrite already renamed (Task 1).

**Wave 3: Execution skills** — Apply cross-pollination, evidence format, progress persistence
- Task 7 (skill-editor-a) — Fix subagent-driven-development
- Task 8 (skill-editor-b) — Fix agent-team-driven-development + prompt templates
- Task 9 (skill-editor-c) — Fix executing-plans + dispatching-parallel-agents

  *Parallel-safe because:* Each editor touches different skill directories.
  *Depends on Wave 2:* Evidence format (Task 4), TDD modes (Task 6), worktree strategy (Task 5).

**Wave 4: Planning pipeline skills** — Gates, directory structure, agent hierarchy
- Task 10 (skill-editor-a) — Fix brainstorming
- Task 11 (skill-editor-b) — Fix writing-plans
- Task 12 (skill-editor-c) — Fix composing-teams

  *Parallel-safe because:* Each touches one different skill file.
  *Depends on Wave 3:* Execution skills define what planning skills hand off to.

**Wave 5: Remaining skills + final consistency** — Complete the audit
- Task 13 (skill-editor-a) — Fix requesting-code-review + receiving-code-review
- Task 14 (skill-editor-b) — Fix systematic-debugging + finishing-a-development-branch
- Task 15 (skill-editor-c) — Fix using-superpowers + writing-skills

  *Parallel-safe because:* Each touches different skill directories.
  *Depends on Wave 4:* Skills reference each other; earlier waves establish patterns.

### Dependency Graph

```
Task 1 ──┐
Task 2 ──┼──→ Task 4 ──┐
Task 3 ──┘    Task 5 ──┼──→ Task 7 ──┐
              Task 6 ──┘    Task 8 ──┼──→ Task 10 ──┐
                            Task 9 ──┘    Task 11 ──┼──→ Task 13
                                          Task 12 ──┘    Task 14
                                                         Task 15
```

---

## Tasks

### Task 1: TodoWrite → TaskCreate Global Rename

**Specialist:** skill-editor-a
**Depends on:** None
**Produces:** Clean files for all downstream editors

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` (lines 36, 50, 52 — dot diagram)
- Modify: `skills/executing-plans/SKILL.md` (line 22)
- Modify: `skills/subagent-driven-development/SKILL.md` (lines 58, 61, 66, 79, 80, 109)
- Modify: `skills/writing-skills/SKILL.md` (line 598)
- Modify: `skills/writing-skills/persuasion-principles.md` (lines 36, 83, 84)
- Modify: `skills/brainstorming/SKILL.md` (checklist references — search for "TodoWrite")

**Changes:**
- Replace all `TodoWrite` with `TaskCreate` (or `TaskUpdate` where the context is updating/marking complete)
- In dot diagrams: `"Create TodoWrite todo per item"` → `"Create TaskCreate task per item"`
- In subagent-driven: `"Mark task complete in TodoWrite"` → `"Mark task complete with TaskUpdate"`
- In prose: `"Create TodoWrite and proceed"` → `"Create tasks with TaskCreate and proceed"`
- Verify dot diagram syntax still valid after rename

**Commit:**
```
fix: rename TodoWrite to TaskCreate/TaskUpdate across all skills

TodoWrite is a stale tool name. The current tools are TaskCreate
and TaskUpdate. Affects: using-superpowers, brainstorming,
executing-plans, subagent-driven-development, writing-skills.

Addresses Finding E from skills audit.
Inspired by upstream observation across multiple issues.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 2: Generalize "your human partner" Language

**Specialist:** skill-editor-b
**Depends on:** None
**Produces:** Generalized language for public library

**Files:**
- Modify: `skills/receiving-code-review/SKILL.md` (lines 52, 61, 82-83, 86, 107, 130, 136, 138, 207)
- Modify: `skills/test-driven-development/SKILL.md` (lines 24, 346, 371)
- Modify: `skills/test-driven-development/testing-anti-patterns.md` (lines 37, 259)
- Modify: `skills/verification-before-completion/SKILL.md` (line 111)
- Modify: `skills/systematic-debugging/SKILL.md` (lines 211, 234)
- Modify: `skills/executing-plans/SKILL.md` (line 21)
- Modify: `skills/writing-skills/SKILL.md` (lines 246, 318)
- Modify: `skills/writing-skills/testing-skills-with-subagents.md` (lines 150, 245)
- Modify: `skills/writing-skills/render-graphs.js` (line 11)
- Modify: `skills/writing-skills/examples/CLAUDE_MD_TESTING.md` (lines 11, 26, 42, 49)

**Replacement rules:**
- `your human partner` → `the user` (in instructions/rules)
- `your human partner's rule:` → `**Principle:**` (when stating a principle)
- `Ask your human partner` → `Ask the user`
- `your human partner said "I don't believe you"` → `Users have reported "I don't believe you"` (verification-before-completion)
- `your human partner's Signals` → `Signals` (systematic-debugging section header)
- `Strange things are afoot at the Circle K` → `"I have concerns about this feedback that I want to flag before proceeding."` (receiving-code-review line 138)
- `Visualizing for your human partner` → `Visualizing skill flowcharts` (writing-skills)

**Preserve the principles** — only change the attribution, not the content. "Be skeptical, but check carefully" stays; "your human partner's rule:" wrapper goes.

**Commit:**
```
fix: generalize "your human partner" to "the user" across skills

Replace Jesse-specific language with generic equivalents for the
public skill library. Preserves all principles and guidance while
making skills applicable to any user.

Addresses Finding Z from skills audit.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 3: Create Foundation Convention Docs

**Specialist:** skill-editor-c
**Depends on:** None
**Produces:** state.yml schema doc, directory conventions doc — referenced by all later tasks

**Files:**
- Create: `docs/plans/skills-audit/state-yml-schema.md`
- Create: `docs/plans/skills-audit/directory-conventions.md`

**state-yml-schema.md contents:**
Document the full state.yml schema from Design Section 1:
- All fields with types and descriptions
- Write points per skill (which skill writes which fields)
- Read points (session-start hook, any skill)
- Version field for future migration
- Example YAML (copy from design.md)

**directory-conventions.md contents:**
Document the directory-based plan structure from Design Section 2:
- `docs/plans/<project>/design.md` — brainstorming output, never overwritten
- `docs/plans/<project>/plan.md` — writing-plans output
- `docs/plans/<project>/tasks/*.md` — per-task files (optional, for token efficiency)
- `docs/plans/<project>/waves.md` — team wave analysis (optional)
- Rules: design.md is immutable after brainstorming, plan.md references design.md
- Token savings rationale (~2.7x from split loading)

**Commit:**
```
docs: add state.yml schema and directory-based plan conventions

Foundation documents for the skills audit implementation.
state.yml provides persistent cross-session state.
Directory-based plans prevent design doc overwrites and improve
token efficiency.

Addresses Findings D, I, O from skills audit.
Inspired by upstream PR #442 (@author), PR #448 (@author), #551.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 4: Canonical Evidence Format in verification-before-completion

**Specialist:** skill-editor-a
**Depends on:** Task 2 (generalization done)
**Produces:** Evidence format definition referenced by all execution skills

**Files:**
- Modify: `skills/verification-before-completion/SKILL.md`

**Changes (from Design Section 4):**
1. Add new section "## Evidence Format" after "The Gate Function" defining three types:
   - **Command evidence**: command, verbatim output (last 50 lines), exit code
   - **Citation evidence**: file:line, code excerpt, verdict per requirement
   - **Diff evidence**: git diff --stat, commit SHA
2. Add table: which context requires which evidence type
3. Add rejection rule: reports without required evidence type are rejected
4. Update "Common Failures" table to reference evidence types
5. Add "Agent completed" evidence requirement more prominently (audit issue #4)
6. Add state.yml integration: verification results optionally recorded
7. Remove "24 failure memories" specific reference (already generalized in Task 2)
8. Add re-review loop bound: max 3 cycles then escalate (from PR #578)

**Commit:**
```
feat(verification-before-completion): add canonical evidence format

Define three evidence types (command, citation, diff) that all
other skills reference. Add rejection rule for missing evidence.
Add re-review loop bound (max 3 cycles).

Addresses Findings V, Y from skills audit.
Inspired by PR #578 (@author) evidence-based review.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 5: Worktree Rework in using-git-worktrees

**Specialist:** skill-editor-b
**Depends on:** Task 3 (state.yml schema)
**Produces:** Updated worktree skill referenced by execution skills and finishing

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`

**Changes (from Design Section 5):**
1. Add optional check at top: if user opts out (#583, #348), skip and record `worktree: null` in state.yml
2. Replace directory selection + manual creation with native `EnterWorktree` delegation
3. KEEP: baseline test verification, CLAUDE.md preference check, setup command auto-detection
4. DROP: `.worktrees/` vs `worktrees/` selection logic, gitignore verification (native tool handles)
5. Add state.yml integration: record `worktree.main.path`, `worktree.main.branch`, `worktree.repo_root`
6. Add team mode section: per-implementer worktrees via `isolation: "worktree"`, lead tracks in state.yml
7. Add between-wave merge workflow: merge implementer branches → lead worktree
8. Add QA worktree strategy: QA agents write in lead's worktree (no conflict with implementers)
9. Update Integration section: add state.yml as paired resource
10. Fix "Fix broken things immediately" gitignore approach — don't commit without user consent (issue #11)

**Commit:**
```
feat(using-git-worktrees): rework to layer on native EnterWorktree

Delegate creation to Claude Code's built-in EnterWorktree tool.
Add optional worktree skip, state.yml tracking, team mode with
per-implementer worktrees, and QA worktree strategy.

Addresses Finding X, #583, #574, #371, #348, #299, #279, #238,
#186, #167, #5, PR #483, PR #391.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 6: TDD Structural Enforcement in test-driven-development

**Specialist:** skill-editor-c
**Depends on:** Task 1 (TodoWrite renamed)
**Produces:** Two TDD modes referenced by execution skills

**Files:**
- Modify: `skills/test-driven-development/SKILL.md`

**Changes (from Design Section 6):**
1. Add section "## Two TDD Modes" documenting solo TDD vs pipelined TDD with table
2. Add "## Integration with Plans" — how test expectations in plans map to TDD cycles
3. Add "## Plan-Level Test Expectations" — what plans must specify per task (3-5 lines: what to test, expected red failure)
4. Add "## Execution-Level Evidence" — RED evidence (test fails for right reason) + GREEN evidence (test passes), using canonical evidence format from verification-before-completion
5. Add pipelined TDD wave diagram (from Design Section 6)
6. Add QA agent role description and implementer role changes for pipelined mode
7. Broaden test framework guidance beyond npm test — add pytest, cargo test, go test examples (issue #2)
8. Expand REFACTOR section with concrete examples (issue #3)
9. Soften "Delete it. Start over." for multi-hour work — graduated response: delete for <1hr, for longer work consult user (issue #5)
10. Fix relative `@testing-anti-patterns.md` reference to use skill cross-reference format (issue #6)

**Commit:**
```
feat(test-driven-development): add pipelined TDD mode and evidence gates

Document solo TDD and pipelined TDD (QA one wave ahead).
Add plan-level test expectations, execution-level evidence gates,
multi-framework examples, and graduated response for large work.

Addresses Findings K, P from skills audit.
Inspired by #566, #437, #384, #373, PR #172.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 7: Fix subagent-driven-development

**Specialist:** skill-editor-a
**Depends on:** Task 4 (evidence format), Task 6 (TDD modes)
**Produces:** Updated execution skill with evidence gates, progress persistence

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Changes (cross-pollination table + per-skill issues):**
1. Add mandatory evidence requirement: implementers must provide command evidence (test output) + diff evidence before marking complete. Reference canonical format from verification-before-completion.
2. Add controller anti-rationalization: "NEVER skip review because task seems straightforward" with explicit prohibition (issue #2, #463)
3. Add state.yml integration: after each task, update `plan.completed_tasks`. On session resume, read state to know where to continue. (issue #9, Finding D)
4. Add re-review loop bound: max 3 review cycles, then escalate with rejection history (issue #11, PR #578)
5. Add pre-flight context check: if below ~50% context remaining, mandatory /compact before next task (issue #12, PR #578)
6. Fix final review scope: must be whole-feature review, not just last task (issue #6, #291)
7. Add TDD gate: before marking implementation complete, verify RED then GREEN evidence exists (Finding K)
8. Note token optimization: with directory-based plans, load individual task files instead of full plan (issue #8, Finding I)
9. Add review tiering reference: light review for simple tasks, standard two-stage for default, critical for auth/payment (Finding T — brief mention, full design in Phase 4)

**Commit:**
```
feat(subagent-driven-development): add evidence gates and progress persistence

Require command+diff evidence for completion. Add controller
anti-rationalization, re-review loop bound, pre-flight context check,
state.yml progress tracking, and TDD gate.

Addresses #485, #463, #291, #147, #87, PR #578, Findings D, K, V, W.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 8: Fix agent-team-driven-development + Prompt Templates

**Specialist:** skill-editor-b
**Depends on:** Task 4 (evidence format), Task 5 (worktree strategy), Task 6 (TDD modes)
**Produces:** Updated team execution skill with pipelined TDD, wave tracking

**Files:**
- Modify: `skills/agent-team-driven-development/SKILL.md`
- Modify: `skills/agent-team-driven-development/implementer-prompt.md`
- Modify: `skills/agent-team-driven-development/spec-reviewer-prompt.md`
- Modify: `skills/agent-team-driven-development/code-quality-reviewer-prompt.md`

**Changes:**
1. Add pipelined TDD support: mixed QA+implementation waves. Wave 0 = QA writes tests. Wave N = implementation + QA writes tests for N+1. (issues #1, #7, Finding P)
2. Add evidence requirement in implementer prompt: must provide RED evidence, GREEN evidence, diff evidence (issue #2, Finding V)
3. Add state.yml integration: track `plan.current_wave`, `plan.completed_tasks`, `worktree.implementers.*` (issue #6, Finding D)
4. Add model tiering: suggest sonnet for implementers, opus for lead/reviewers in prompt templates (issue #4, Finding Q)
5. Trim implementer prompt: when project agents exist, prompt should be minimal — task + context + workflow contract (issue #11, Finding U)
6. Add worktree lifecycle documentation: per-implementer worktrees, between-wave merge, branching from merged result (Findings H3, H10, H11)
7. Fix spec reviewer: use `superpowers:code-reviewer` agent type consistently (issue #12)
8. Add review tiering mention: light/standard/critical (issue #9, Finding T)
9. Add merge conflict guidance beyond "lead resolves" — specific steps (issue #10)
10. Add pre-flight context check (Finding W, PR #578)

**Commit:**
```
feat(agent-team-driven-development): add pipelined TDD and evidence gates

Support mixed QA+implementation waves. Add evidence requirements,
state.yml wave tracking, model tiering, trimmed prompts for project
agents, and worktree lifecycle documentation.

Addresses #429, #464, PR #578, Findings D, P, Q, T, U, V.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 9: Fix executing-plans + dispatching-parallel-agents

**Specialist:** skill-editor-c
**Depends on:** Task 4 (evidence format), Task 5 (worktree strategy), Task 6 (TDD modes)
**Produces:** Updated execution skills with evidence, progress, scope clarity

**Files:**
- Modify: `skills/executing-plans/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`

**executing-plans changes:**
1. Add evidence requirement: human reviewer should see command evidence + diff evidence per batch (Finding V)
2. Add state.yml integration: track `plan.completed_tasks`, load state on session start for cold resume (Finding D, H6)
3. Add TDD gate: verify test evidence exists for each task (Finding K)
4. Change "Follow each step exactly" to "Follow plan intent, make implementation decisions" (Finding L)
5. Add pre-flight context check (PR #578)
6. Add final cross-cutting review step before finishing (issue #8, #291)
7. Add structured review template for between-batch human review (issue #7)
8. Reference directory-based plan loading: load individual task files (Finding I)

**dispatching-parallel-agents changes:**
1. Add explicit autonomy guidance: spawned agents need `mode: "bypassPermissions"` or equivalent (issue #1, #473)
2. Add worktree isolation: parallel agents should use `isolation: "worktree"` to avoid file conflicts (issue #6)
3. Fix TypeScript `Task()` example to use actual Claude Code Agent tool syntax (issue #3)
4. Lower threshold from "3+" to "2+" independent problems (issue #4)
5. Add merge/conflict detection guidance: after agents return, `git diff` between branches (issue #5)
6. Add scope boundary: this skill = ad-hoc parallel; agent-team-driven = planned waves (issue #7)
7. Remove emoji from Common Mistakes section (issue #9)
8. Add model tier guidance (Finding Q)

**Commits (two separate):**
```
feat(executing-plans): add evidence gates and cold session resume

Require evidence per batch, add state.yml for cross-session resume,
TDD gate, structured review template, and directory-based plan loading.

Addresses #566, PR #442, PR #172, #229, #291, Findings D, I, K, L, V.
```

```
feat(dispatching-parallel-agents): add worktree isolation and autonomy

Add agent permission mode, per-agent worktrees, merge guidance,
scope boundary with agent-team-driven, and model tier guidance.

Addresses #473, #315, PR #362, Findings Q, X.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 10: Fix brainstorming

**Specialist:** skill-editor-a
**Depends on:** Task 3 (directory conventions)
**Produces:** Updated brainstorming with gates, research step, assumption challenging

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Changes:**
1. Add verification gate: before proceeding to composing-teams or writing-plans, check state.yml for `design.approved == true` and `worktree.main.path` exists (H1, Design Section 3)
2. Add decision framework for composing-teams trigger: 4+ tasks AND 2+ independent AND 2+ specialist domains → compose team (H9)
3. Add assumption challenging: "Before accepting user's framing, ask: Is this the right problem to solve? Are there simpler alternatives?" (issue #3, #530, PR #541)
4. Add research step: "Before designing, search for existing solutions on GitHub/web" (issue #6, PR #386, Finding J)
5. Fix user gate: explicit approval checkpoint between design doc writing and any plan invocation (issue #1, #565)
6. Fix design doc path: use directory-based `docs/plans/<project>/design.md` (issue #2, #565, Finding O)
7. Add state.yml write: set `phase: brainstorming`, `design.path`, `design.approved` (Finding D)
8. Fix "After the Design" section: ensure steps 6-8 are reliably followed (issue #8, #107)

**Commit:**
```
feat(brainstorming): add verification gates, research step, assumption challenging

Add state.yml integration, structured composing-teams trigger,
assumption challenging before design, web/GitHub research step,
explicit user gate, and directory-based plan paths.

Addresses #565, #574, #530, #107, PR #541, PR #386, Findings D, G, H, J.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 11: Fix writing-plans

**Specialist:** skill-editor-b
**Depends on:** Task 3 (directory conventions), Task 6 (TDD modes)
**Produces:** Updated planning skill with directory structure, role clarity

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

**Changes:**
1. Update save path: `docs/plans/<project>/plan.md` instead of `docs/plans/YYYY-MM-DD-<feature-name>.md` (Finding O)
2. Add per-task files: optionally write `tasks/01-name.md` for token-efficient loading (Finding I)
3. Add plan-level test expectations: each task must include 3-5 lines of "Test expectations" specifying what to test and expected red failure (Design Section 6)
4. Shift from "complete code in plan" to "specify what/where/why, agents decide how" — update the overview paragraph and task structure template (Finding L)
5. Add state.yml integration: write `plan.path`, `plan.status: pending`, `plan.executor` (Finding D, M)
6. Add plan review reference: mention reviewing-plans concept from PR #448 (Finding N)
7. Add verification gate: check state.yml for `design.approved` and `worktree.main.path` before starting (Design Section 3)
8. Remove "Complete code in plan (not 'add validation')" from Remember section — contradicts Finding L (issue #10)

**Commit:**
```
feat(writing-plans): add directory-based plans and test expectations

Use docs/plans/<project>/ structure with per-task files. Add
plan-level test expectations per task. Shift from complete code
to what/where/why specifications.

Addresses #566, #227, #512, #565, PR #442, PR #448,
Findings D, I, K, L, M, N, O.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 12: Fix composing-teams

**Specialist:** skill-editor-c
**Depends on:** Task 3 (state.yml schema)
**Produces:** Updated composition skill with agent hierarchy, test-writer role

**Files:**
- Modify: `skills/composing-teams/SKILL.md`

**Changes:**
1. Add agent selection hierarchy: project agents > shipped fallbacks > raw model tiers (Design Section, user-confirmed)
2. Add agent creation flow: suggest creating project-specific agents from shipped templates (Finding S)
3. Add test-writer role: when design suggests test phase, recommend QA/test-writer in roster (Finding R)
4. Add model tiering guidance: planning/review = opus, implementation = sonnet, quick = haiku (Finding Q, PR #547)
5. Add cost implications: inform user about cost of multiple opus agents vs sonnet (issue #1)
6. Add team sizing rationale: explain why max 3 (context overhead, merge complexity) (issue #2)
7. Add state.yml integration: write `team.roster`, `team.name` (Finding D)
8. Add verification gate: check `design.approved == true` before starting (Design Section 3)
9. Add decision framework reference: structured criteria for when to compose teams (same as brainstorming's H9 fix)

**Commit:**
```
feat(composing-teams): add agent hierarchy and test-writer role

Establish project agents > shipped > raw tiers. Add test-writer
for pipelined TDD, model tiering guidance, agent creation flow,
and state.yml integration.

Addresses #429, #464, PR #547, Findings D, P, Q, R, S.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 13: Fix requesting-code-review + receiving-code-review

**Specialist:** skill-editor-a
**Depends on:** Task 4 (evidence format)
**Produces:** Updated review skills with evidence requirements

**Files:**
- Modify: `skills/requesting-code-review/SKILL.md`
- Modify: `skills/receiving-code-review/SKILL.md`

**requesting-code-review changes:**
1. Add evidence requirement: reviewers MUST provide citation evidence (file:line per requirement). Reject prose-only verdicts. (issue #3, Finding V)
2. Add anti-skip enforcement: "NEVER rationalize skipping review" (issue #1, #528, #463)
3. Add re-review loop bound: max 3 cycles (issue #8, PR #578)
4. Add security review tier mention: for auth/payment/data tasks (issue #5, PR #560)
5. Add per-implementer SHA guidance for team mode: use branch-specific SHAs (H13)
6. Add uncommitted changes check: `git status` before SHA-based review (issue #4)

**receiving-code-review changes:**
1. Add evidence demand: receiver should ask for file:line citations if reviewer provides prose-only verdict (issue #6, Finding V)
2. Fix spec reviewer pedantry: add guidance on distinguishing style preferences from real issues (issue #1, #221)
3. Add review-of-review concept: when reviewer feedback is itself suspect (issue #5)

**Commits (two separate):**
```
feat(requesting-code-review): require citation evidence from reviewers

Reject prose-only verdicts. Add anti-skip enforcement, re-review
loop bound, security review tier, and per-implementer SHA guidance.

Addresses #528, #463, #479, PR #560, PR #578, Findings T, V.
```

```
feat(receiving-code-review): add evidence demand and pedantry filter

Receiver should demand file:line citations. Add guidance for
distinguishing style preferences from real issues.

Addresses #221, Finding V.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 14: Fix systematic-debugging + finishing-a-development-branch

**Specialist:** skill-editor-b
**Depends on:** Task 5 (worktree strategy)
**Produces:** Updated support skills

**Files:**
- Modify: `skills/systematic-debugging/SKILL.md`
- Modify: `skills/finishing-a-development-branch/SKILL.md`

**systematic-debugging changes:**
1. Improve CSO: update description for better discoverability (issue #1, #536)
2. Add fork guidance: for long debugging sessions, suggest forking to preserve context (issue #2, #246)
3. Add worktree integration: parallel hypothesis testing via isolated worktrees (issue #5, #186)
4. Add state.yml integration: record debug findings for cross-session persistence (issue #6, Finding D)
5. Fix phase numbering confusion (issue #4)
6. Fix relative path references to use skill cross-reference format (issue #7)

**finishing-a-development-branch changes:**
1. Fix CWD issue: add explicit "cd to repo root" step using `worktree.repo_root` from state.yml before any worktree removal (issues #1, #2, #167, PR #391)
2. Add state.yml integration: update `phase: idle`, `plan.status: executed`, clear worktree entries (Finding D)
3. Add team shutdown in main flow, not just Team Context section (issue #7)
4. Add native EnterWorktree cleanup awareness: if worktree created via native tool, cleanup may differ (issue #8, Finding X)
5. Replace "Type 'discard' to confirm" with AskUserQuestion approach (issue #5)
6. Fix Option 2 worktree cleanup contradiction (issue #3)

**Commits (two separate):**
```
feat(systematic-debugging): improve CSO, add fork and worktree support

Better description for discoverability. Add context forking for
long sessions, parallel hypothesis testing via worktrees, and
state.yml persistence.

Addresses #536, #246, #186, Finding D.
```

```
fix(finishing-a-development-branch): fix worktree CWD and add state.yml

Add explicit cd-to-repo-root before worktree removal. Track
completion in state.yml. Move team shutdown to main flow.
Handle native EnterWorktree cleanup.

Addresses #167, PR #391, Findings D, X.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

### Task 15: Fix using-superpowers + writing-skills

**Specialist:** skill-editor-c
**Depends on:** Task 3 (foundation docs)
**Produces:** Updated meta-skills

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Modify: `skills/writing-skills/SKILL.md`

**using-superpowers changes:**
1. Trim Red Flags table from 12 rows to 5 most effective (issue #7, PR #459)
2. Fix frontmatter description: less broad, avoid conflicts with other skills (issue #6, PR #459)
3. Add note about subagent context: subagents don't receive skill framework, consider using Agent tool with skill-aware types (issue #4, #237)
4. Remove EXTREMELY_IMPORTANT concealment or add stuck-state detection guidance (issue #3, #472)

**writing-skills changes:**
1. Add reference to Anthropic's official "Building Skills" guide with key differences noted (issue #1, #526, PR #471, PR #517)
2. Fix inconsistent file reference syntax: standardize on markdown links, not `@` (issue #4, #280)
3. Add guidance on when to split vs combine skills (issue #10)
4. Add skill versioning guidance (issue #8)
5. Soften TDD-for-skills overhead: lighter testing for simple reference skills (issue #5, #233)
6. Fix exclamation mark rendering issues (issue #3, #451)
7. Fix personal skill paths to be less fragile (issue #6)

**Commits (two separate):**
```
fix(using-superpowers): trim red flags, fix subagent context gap

Reduce Red Flags table to 5 most effective entries. Add subagent
context note. Reduce description breadth.

Addresses #472, #237, PR #459.
```

```
feat(writing-skills): align with Anthropic guide, add versioning

Reference official Anthropic skill authoring guide. Standardize
file references, add split/combine guidance, skill versioning,
and lighter testing for simple skills.

Addresses #526, #451, #280, #233, PR #471, PR #517.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

## Verification

After all waves complete, the reviewer runs a consistency check:
1. Grep all SKILL.md files for remaining `TodoWrite` — should be zero
2. Grep all SKILL.md files for remaining `your human partner` — should be zero (except in examples showing old patterns)
3. Verify every skill that references evidence format points to verification-before-completion
4. Verify every execution skill has state.yml integration documented
5. Verify all verification gates reference state.yml fields that exist in the schema
6. Cross-check each skill's issue table in the audit doc — all Critical and High items addressed

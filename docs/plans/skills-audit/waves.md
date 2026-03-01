# Wave Analysis — Skills Audit Implementation

## Specialists

| Role | Agent | Model | Tasks |
|------|-------|-------|-------|
| skill-editor-a | implementer | sonnet | 1, 4, 7, 10, 13 |
| skill-editor-b | implementer | sonnet | 2, 5, 8, 11, 14 |
| skill-editor-c | implementer | sonnet | 3, 6, 9, 12, 15 |
| reviewer | code-reviewer | opus | Post-wave reviews |

## Waves

### Wave 1: Mechanical Fixes + Foundation Docs
*No design judgment needed — pure execution*

| Task | Editor | Summary | Files touched |
|------|--------|---------|--------------|
| 1 | A | TodoWrite → TaskCreate rename | using-superpowers, brainstorming, executing-plans, subagent-driven, writing-skills |
| 2 | B | "your human partner" generalization | receiving-code-review, test-driven-development, verification-before-completion, systematic-debugging, executing-plans, writing-skills |
| 3 | C | Create state.yml schema + directory conventions | New files only |

*Parallel-safe:* Tasks 1 and 2 touch different skill files (verified via grep). Task 3 creates new files.

**Exception:** `executing-plans/SKILL.md` line 21 has "your human partner" AND `writing-skills/SKILL.md` has both TodoWrite and "your human partner" references. Editor A handles TodoWrite lines, Editor B handles "your human partner" lines — different line ranges in the same files. **Alternatively, Editor A does TodoWrite in those files first, Editor B follows.** Safest: Editor B skips executing-plans and writing-skills for generalization, Editor A handles both changes in those two files.

### Wave 2: Core Infrastructure Skills
*Define the formats other skills reference*

| Task | Editor | Summary | Files touched |
|------|--------|---------|--------------|
| 4 | A | Canonical evidence format | verification-before-completion |
| 5 | B | Worktree rework | using-git-worktrees |
| 6 | C | TDD structural enforcement | test-driven-development |

*Parallel-safe:* Each touches exactly one different skill file.

### Wave 3: Execution Skills
*Apply cross-pollination, evidence, persistence*

| Task | Editor | Summary | Files touched |
|------|--------|---------|--------------|
| 7 | A | Fix subagent-driven-development | subagent-driven-development/ |
| 8 | B | Fix agent-team-driven-development | agent-team-driven-development/ (SKILL.md + 3 prompts) |
| 9 | C | Fix executing-plans + dispatching-parallel-agents | executing-plans/, dispatching-parallel-agents/ |

*Parallel-safe:* Each editor touches different skill directories.

### Wave 4: Planning Pipeline Skills
*Gates, directory structure, agent hierarchy*

| Task | Editor | Summary | Files touched |
|------|--------|---------|--------------|
| 10 | A | Fix brainstorming | brainstorming/ |
| 11 | B | Fix writing-plans | writing-plans/ |
| 12 | C | Fix composing-teams | composing-teams/ |

*Parallel-safe:* Each touches one different skill file.

### Wave 5: Remaining Skills + Meta
*Complete the audit*

| Task | Editor | Summary | Files touched |
|------|--------|---------|--------------|
| 13 | A | Fix requesting-code-review + receiving-code-review | requesting-code-review/, receiving-code-review/ |
| 14 | B | Fix systematic-debugging + finishing-a-development-branch | systematic-debugging/, finishing-a-development-branch/ |
| 15 | C | Fix using-superpowers + writing-skills | using-superpowers/, writing-skills/ |

*Parallel-safe:* Each editor touches different skill directories.

## Dependency Graph

```
Wave 1:  Task 1 ──┐
         Task 2 ──┼──→ Wave 2:  Task 4 ──┐
         Task 3 ──┘              Task 5 ──┼──→ Wave 3:  Task 7 ──┐
                                 Task 6 ──┘              Task 8 ──┼──→ Wave 4:  Task 10 ──┐
                                                         Task 9 ──┘              Task 11 ──┼──→ Wave 5:  Task 13
                                                                                 Task 12 ──┘              Task 14
                                                                                                          Task 15
```

## File Conflict Matrix

No two editors touch the same file in the same wave:

| Skill File | Wave 1 | Wave 2 | Wave 3 | Wave 4 | Wave 5 |
|---|---|---|---|---|---|
| using-superpowers | A(1) | — | — | — | C(15) |
| brainstorming | A(1) | — | — | A(10) | — |
| writing-plans | — | — | — | B(11) | — |
| composing-teams | — | — | — | C(12) | — |
| agent-team-driven | — | — | B(8) | — | — |
| subagent-driven | A(1) | — | A(7) | — | — |
| dispatching-parallel-agents | — | — | C(9) | — | — |
| executing-plans | A(1)* | — | C(9) | — | — |
| test-driven-development | B(2) | C(6) | — | — | — |
| using-git-worktrees | — | B(5) | — | — | — |
| requesting-code-review | — | — | — | — | A(13) |
| receiving-code-review | B(2) | — | — | — | A(13) |
| systematic-debugging | B(2) | — | — | — | B(14) |
| verification-before-completion | B(2) | A(4) | — | — | — |
| finishing-a-development-branch | — | — | — | — | B(14) |
| writing-skills | A(1)* | — | — | — | C(15) |

*Wave 1 conflict note: executing-plans and writing-skills have both TodoWrite (Editor A) and "your human partner" (Editor B) references. Resolution: Editor A handles BOTH changes in these two files during Task 1.

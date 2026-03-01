# Code Quality Reviewer Prompt Template

Dispatch as a **subagent** (not a team member) for unbiased quality review.

**Purpose:** Verify implementation is well-built — clean, tested, maintainable.

**Only dispatch after spec compliance review passes.**

```
Agent tool:
  subagent_type: superpowers:code-reviewer
  description: "Code quality review: Task N"
  prompt: |
    Review the implementation of Task N: [task name]

    ## What Was Implemented

    [From implementer's report]

    ## Plan/Requirements

    [Task description from plan]

    ## Commits to Review

    Base SHA: [commit before task started]
    Head SHA: [current commit after task]

    Review the diff between these commits for:
    - Bugs and logic errors
    - Security vulnerabilities
    - Code quality and maintainability
    - Test coverage and test quality
    - Adherence to project conventions
    - Naming clarity
    - Unnecessary complexity

    Focus on high-confidence issues that truly matter.
    Don't nitpick style if it follows project conventions.
```

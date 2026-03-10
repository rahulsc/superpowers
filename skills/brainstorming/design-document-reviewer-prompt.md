# Design Document Reviewer Prompt Template

Use this template when dispatching a design document reviewer subagent.

**Purpose:** Verify the design is complete, consistent, and ready for implementation planning.

**Dispatch after:** Design document is written to `docs/<project>/design/`

```
Task tool (general-purpose):
  description: "Review design document"
  prompt: |
    You are a design document reviewer. Verify this design is complete and ready for planning.

    **Design to review:** [DESIGN_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
    | Coverage | Missing error handling, edge cases, integration points |
    | Consistency | Internal contradictions, conflicting requirements |
    | Clarity | Ambiguous requirements |
    | YAGNI | Unrequested features, over-engineering |
    | Scope | Focused enough for a single plan — not covering multiple independent subsystems |
    | Architecture | Units with clear boundaries, well-defined interfaces, independently understandable and testable |

    ## CRITICAL

    Look especially hard for:
    - Any TODO markers or placeholder text
    - Sections saying "to be defined later" or "will define when X is done"
    - Sections noticeably less detailed than others
    - Units that lack clear boundaries or interfaces — can you understand what each unit does without reading its internals?

    ## Output Format

    ## Design Review

    **Status:** ✅ Approved | ❌ Issues Found

    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters]

    **Recommendations (advisory):**
    - [suggestions that don't block approval]
```

**Reviewer returns:** Status, Issues (if any), Recommendations

# Forge Competitive Research — March 2026

## Landscape Summary

| Tool | Stars | Structured Phases | Enforcement | Evidence | Multi-Agent | State Persistence | Risk Tiers |
|------|-------|:-:|:-:|:-:|:-:|:-:|:-:|
| **Spec Kit** (GitHub) | ~2k | Specify→Plan→Tasks→Implement | None (advisory) | None | No | No | No |
| **Kiro** (Amazon) | N/A | Requirements→Design→Tasks | None | None | No | Per-spec only | No |
| **Codex** (OpenAI) | N/A | None (AGENTS.md guidance) | Kernel sandboxing | Implicit (diffs) | Parallel worktrees | Thread-based | No |
| **Claude Code** | N/A | None (skills are independent) | Hooks, plan-approval | None built-in | Agent teams (experimental) | Task list only | No |
| **Aider** | ~25k | None | None | Auto-commit | No | No | No |
| **Cursor** | N/A | None | Advisory rules (.mdc) | None | No | No | No |
| **Windsurf** | N/A | None | Advisory rulebooks | None | No | No | No |
| **Gastown** (Yegge) | 11.7k | Mayor→Convoy→Beads | Git-backed state | Implicit | 20-30 agents | Git worktrees + Dolt | No |
| **OpenClaw** | 305k | None | TCC security model | None | Subagents (buggy) | Sessions | No |
| **obra/superpowers** | 78.5k | Brainstorm→Plan→SDD→Review | Prompt-level gates | Informal | None (most-requested) | None | No |
| **Continue.dev** | ~20k | None (pivoting to CI/CD) | CI pipeline | None | No | No | No |
| **BMAD-METHOD** | ~1k | Named personas per SDLC phase | None (advisory) | None | File-based context | No | No |
| **Our Fork** | - | Design→Plan→Execute→Verify→Review→Finish | State.yml + verification gates | Canonical format | Teams + pipelined TDD | state.yml (partial) | No (yet) |

## Key Findings by Project

### Upstream obra/superpowers
- 78.5k stars, 5 months old, bus factor = 1 (obra has 304/355 commits)
- 50 open PRs piling up, 6 merged in last month — community contributions not being absorbed
- **Core problem**: LLMs routinely ignore skill instructions, especially review steps. Issues #696, #463, #147, #485, #528, #698 all report this
- **No persistent state** — each session starts fresh, no tracking of phase/approvals/evidence
- **No agent teams** — #429 is the most-requested feature (88 reactions)
- **Verification is orphaned** — `verification-before-completion` exists but nothing references it (#642)
- **No opt-out** — can't disable auto-triggering (#645, #690), can't disable git workflow (#4, 18 reactions)
- **Windows fragility** — 24+ SessionStart hook issues
- Our fork already addresses #429 (agent teams), #642 (verification wiring), #601 (cross-session learnings), #551 (progress tracking)

### Gastown (Steve Yegge)
- Multi-agent workspace manager: Mayor orchestrates Polecats (worker agents) via Convoys of Beads
- Heavy infrastructure: Go + Git + Dolt (versioned SQL) + Beads (git-backed issue tracker) + tmux
- **Fragile operational infrastructure**: Issue #764 documents 9 categories of fragility in using beads as real-time coordination layer
- **Nudge delivery architecturally broken** (#1216 P1) — cross-agent messages collide with human terminal input
- **Data loss risk** (#824 P2) — user's entire codebase deleted by running attach from wrong directory
- **Auto-handoff unreliability** (#1996 P2) — empty context breaks session continuity
- Interesting: persistent agent identity (survives crashes), git-backed everything, OpenTelemetry built in
- Cautionary: complexity (steep learning curve), heavy deps, metaphor overload (Mayor, Polecats, Rigs, Hooks, Convoys, Beads, Wisps, Deacon, Refinery...)

### OpenClaw
- 305k stars, general-purpose personal AI assistant (not coding-focused)
- 52 skills across 20+ messaging platforms — breadth over depth
- **Memory management chaos** (#43747) — three users on same version get three different memory behaviors. No unified memory specification.
- **Subagent result delivery failure** (#43755) — results computed but not propagated to parent
- **Token budget waste** (#9157) — 93.5% of tokens wasted on static file injection (~$1.51/100 messages)
- **Context compaction failures** — auto-compaction overflow recovery doesn't trigger
- Validates: state specification is critical, subagent handoffs need formal protocols, breadth without reliability = regression hell

### Spec Kit (GitHub)
- Constitution concept (immutable project principles) is powerful
- Cross-agent compatibility by design (20+ AI tools)
- **No enforcement** — specs are advisory markdown, nothing stops agents ignoring them
- **No state management** — no tracking of tasks, phases, or evidence
- **Brownfield adoption painful** (#164, #1436) — designed for greenfield
- **Repo root clutter** (#139) — scattered files across project root, had to consolidate to hidden dir
- **No post-implementation quality gate** (#442, #1323)
- **Spec maintenance guidance missing** (#916) — specs go stale

### Kiro (Amazon)
- EARS notation for requirements is well-established requirements engineering
- FileMatch-scoped steering (load React rules only when touching .tsx) is elegant
- Bugfix spec type distinct from feature spec is good
- **IDE-locked** (VS Code + CLI only)
- **Per-spec state only** — no cross-session persistence
- **No evidence model** — tasks complete without proof
- **No verification gates** — nothing prevents skipping requirements
- **Excessive for small problems** — three-phase workflow overhead for 3-line bug fix

## Community Pain Points (Cross-Tool)

### What Senior Engineers Complain About Most
1. **Loss of architectural intent** — AI optimizes for "make it work" not "maintain the vision"
2. **Review burden inversion** — reviewing AI code is harder than writing it
3. **Sycophancy** — agents agree with wrong approaches instead of pushing back
4. **Confident hallucination** — fabricates APIs, packages, function signatures

### Where Tools Lose Trust
1. **Silent data corruption** — modifying files you didn't ask it to touch
2. **Context amnesia mid-task** — produces inconsistent final state
3. **Destructive operations without warning**
4. **The "three strikes" pattern** — 2-3 serious violations → significant trust reduction

### The Central Design Tension
**Bimodal complaints** — the community splits:
- **"Too little structure"**: senior engineers, production teams, regulated industries want more ceremony
- **"Too much structure"**: indie devs, prototypers want less overhead
- **The missing middle**: structure should be proportional to risk, not uniform

### The "Copilot Plateau"
- Week 1-2: "10x faster"
- Month 1-2: "1.3x faster"
- Month 3-6: "As much time fighting as benefiting"
- Month 6+: "Found a narrow set where it helps"

### Martin Fowler's Spec Criticism
- "If your spec is detailed enough for AI to implement perfectly, you've essentially written the code in a different language"
- Specs assume you know what you want upfront; best insights come from building
- Two artifacts to maintain (spec AND code) that drift apart
- "We've recreated CASE tools from the 1990s with a better UI"

## Gap Analysis — Where Forge Can Differentiate

### Gap 1: No tool combines structured phases WITH enforcement
Spec-kit and Kiro have phases but no gates. Codex has sandboxing but no phases. Claude Code has hooks but no built-in workflow.

### Gap 2: No tool handles the full spectrum of problem sizes
Kiro's three-phase workflow is excessive for a 3-line bug fix. Codex's AGENTS.md is too unstructured for a large feature. Risk-scaled ceremony is novel.

### Gap 3: Multi-agent + structured development is unexplored
Claude Code has agent teams. Spec-kit has specs. No one combines them. Pipelined TDD is genuinely novel.

### Gap 4: Evidence is implicit everywhere
No tool requires structured evidence as a gate to completion.

### Gap 5: State persistence is absent
Every tool loses context between sessions.

### Gap 6: The instruction-following problem is unsolved
All tools rely on markdown instructions that LLMs routinely ignore. This is the deepest unsolved problem.

### Gap 7: Composability across tools is rare
Most tools are IDE-locked. A portable skills library has broad potential.

## Strategic Implications for Forge

1. **Risk-scaled ceremony is the #1 community ask** — nobody provides it
2. **State specification prevents memory chaos** — OpenClaw's #43747 validates this
3. **Formal handoff protocols prevent silent failures** — OpenClaw's subagent bugs + Gastown's fragile beads validate this
4. **Lightweight infrastructure wins** — Gastown's heavy deps (Go+Dolt+Beads+tmux) are a barrier; stay markdown+YAML
5. **Bus factor matters** — upstream's single-maintainer risk is real; Forge should plan for sustainability
6. **AGENTS.md is becoming a standard** — generate compatible files, don't fight it
7. **The enforcement problem is the hardest** — pure prompt gates get ignored; need hooks/tools/state-checking beyond prompts
8. **Brownfield adoption is critical** — Spec Kit's biggest weakness; Forge must work on existing projects
9. **Breadth without reliability = death** — OpenClaw's 52 skills × 20 channels = regression hell; stay focused
10. **The product framing matters** — "workflows and outcomes" not "skills and catalogs"

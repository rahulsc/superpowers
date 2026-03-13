# Forge (working title)

Forge is a structured operating mode for AI-assisted software development --
an independent evolution of [Superpowers](https://github.com/obra/superpowers)
by Jesse Vincent.

## What is Forge?

Forge gives your coding agent a complete engineering workflow. Instead of
treating each session as a blank slate, Forge maintains durable project memory
(`.forge/` infrastructure with SQLite or JSON state, shared architecture docs,
and cross-session decision records) so your agent always has context about what
was built, why, and what comes next.

Every change passes through a risk classification engine that scales ceremony to
match stakes. Low-risk documentation edits need a spot-check; database
migrations require a full test run, security review, and sign-off. Evidence
gates enforce this -- your agent cannot claim work is complete without producing
the artifacts the risk tier demands.

Forge also supports multi-agent teams: persistent specialist agents (architect,
implementer, QA engineer, code reviewer, security reviewer) working in parallel
waves with between-wave verification gates. A pack protocol lets you distribute
and install reusable bundles of skills, policies, and shared knowledge across
projects. The result is AI-assisted development that is systematic, auditable,
and predictable.

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees
that you are building something, it does not just jump into writing code.
Instead, it steps back and asks what you are really trying to do.

Once it has teased a spec out of the conversation through Socratic
**brainstorming**, it shows it to you in chunks short enough to actually read
and digest. After you sign off on the design, your agent puts together an
implementation plan via **writing-plans** -- clear enough for an enthusiastic
junior engineer with no project context and an aversion to testing to follow.
It emphasizes true red/green TDD, YAGNI, and DRY.

Next up, once you say "go", it launches **subagent-driven-development** (or
**agent-team-driven-development** for larger efforts), having agents work
through each task, inspecting and reviewing their work, and continuing forward.
Evidence-gated **verification-before-completion** ensures nothing is declared
done until the proof exists. It is not uncommon for your agent to work
autonomously for a couple of hours at a time without deviating from the plan
you put together.

Because the skills trigger automatically through **forge-routing**, you do not
need to do anything special. Your coding agent just has Forge.

## Installation

**Note:** Installation differs by platform. Claude Code and Cursor have
built-in plugin marketplaces. Codex, OpenCode, and Gemini CLI require manual
setup.

### Claude Code Official Marketplace

Install the plugin from the Claude marketplace:

```bash
/plugin install forge@claude-plugins-official
```

### Claude Code (via Plugin Marketplace)

In Claude Code, register the marketplace first:

```bash
/plugin marketplace add rahulsc/forge-marketplace
```

Then install the plugin from this marketplace:

```bash
/plugin install forge@forge-marketplace
```

### Cursor (via Plugin Marketplace)

In Cursor Agent chat, install from marketplace:

```text
/add-plugin forge
```

or search for "forge" in the plugin marketplace.

### Codex

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/rahulsc/superpowers/refs/heads/main/.codex/INSTALL.md
```

**Detailed docs:** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/rahulsc/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

### Gemini CLI

```bash
gemini extensions install https://github.com/rahulsc/superpowers
```

To update:

```bash
gemini extensions update forge
```

### Verify Installation

Start a new session in your chosen platform and ask for something that should
trigger a skill (for example, "help me plan this feature" or "let's debug this
issue"). The agent should automatically invoke the relevant Forge skill.

## Skills Library (21 skills)

**Routing**
- **forge-routing** -- Determines workflow phase before any action

**Adoption & Setup**
- **adopting-forge** -- First-time Forge setup in a repository
- **setting-up-project** -- Bridges design approval to execution strategy
- **syncing-forge** -- Regenerate adapters after config changes
- **diagnosing-forge** -- Health checks for .forge/ state

**Design & Planning**
- **brainstorming** -- Socratic design refinement
- **writing-plans** -- Detailed implementation plans
- **composing-teams** -- Assemble specialist agent teams

**Execution**
- **subagent-driven-development** -- Fresh subagent per task with two-stage review
- **agent-team-driven-development** -- Persistent specialists in parallel waves
- **test-driven-development** -- RED-GREEN-REFACTOR cycle
- **using-git-worktrees** -- Isolated development workspaces
- **validating-wave-compliance** -- Between-wave verification gates

**Debugging**
- **systematic-debugging** -- 4-phase root cause analysis

**Review & Completion**
- **requesting-code-review** -- Pre-review checklist
- **receiving-code-review** -- Responding to feedback with rigor
- **verification-before-completion** -- Evidence-gated completion claims
- **finishing-a-development-branch** -- Merge/PR decision workflow

**Meta & Extensibility**
- **writing-skills** -- Create new skills following TDD methodology
- **forge-packs** -- Install and manage reusable skill/policy bundles
- **forge-viz** -- Browser dashboard for workflow visualization

## Forge Infrastructure

Forge stores project configuration and runtime state in the `.forge/` directory
at the root of your repository.

**Configuration**
- `project.yaml` -- Project name, tech stack, build/test/lint commands, repo
  traits, and storage backend preference.
- `policies/default.yaml` -- Risk classification rules mapping file patterns to
  tiers (minimal, standard, elevated, critical) with required artifacts per tier.

**Runtime tools** (`.forge/bin/`)
- `classify-risk` -- Determines the risk tier for a set of changed files.
- `forge-evidence` -- Records and queries evidence artifacts (test runs, reviews,
  sign-offs) required by risk policies.
- `forge-memory` -- Cross-session memory store for project context.
- `forge-state` -- Persistent state backend (SQLite or JSON) for workflow
  progress, task status, and evidence collection.
- `forge-pack` -- Installs, removes, and lists packs from local or remote
  sources.

**Shared knowledge** (`.forge/shared/`)
- `architecture.md` -- Project architecture overview, kept current by agents.
- `conventions.md` -- Coding conventions and style decisions.
- `decisions/` -- Architectural decision records (ADR format).

**Extensibility**
- `packs/` -- Installed pack bundles (skills, policies, shared knowledge).
- `adapters/` -- Platform-specific adapter files generated by `syncing-forge`.
- `workflows/` -- Multi-step workflow definitions (declarative YAML schema for
  sequencing skills with dependency tracking and failure handling).
- `local/` -- Machine-local state (gitignored).

## Agent Definitions

Forge ships five specialist agent definitions (in `agents/`) for use with
multi-agent team workflows:

- **architect** -- Owns design coherence, API boundaries, and system-level
  trade-offs.
- **implementer** -- Writes production code following TDD, guided by the plan.
- **qa-engineer** -- Writes tests one wave ahead of implementers, validates
  coverage.
- **code-reviewer** -- Reviews implementation against spec, plan, and project
  conventions.
- **security-reviewer** -- Audits changes for vulnerabilities, auth gaps, and
  data exposure.

## Philosophy

- **Test-Driven Development** -- Write tests first, always
- **Systematic over ad-hoc** -- Process over guessing
- **Complexity reduction** -- Simplicity as primary goal
- **Evidence over claims** -- Verify before declaring success

## Contributing

Skills live directly in this repository. To contribute:

1. Fork [rahulsc/superpowers](https://github.com/rahulsc/superpowers)
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. Submit a PR

See `skills/writing-skills/SKILL.md` for the complete guide.

## Updating

Skills update automatically when you update the plugin:

```bash
/plugin update forge
```

## License

MIT License -- see [LICENSE](LICENSE) file for details.

## Attribution

Forge is derived from [Superpowers](https://github.com/obra/superpowers),
originally created by Jesse Vincent. See [NOTICE.md](NOTICE.md) for formal
attribution and [ORIGINS.md](ORIGINS.md) for the full story.

## Support

- **Issues**: https://github.com/rahulsc/superpowers/issues

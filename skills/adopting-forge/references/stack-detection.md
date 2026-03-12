# Stack Detection Heuristics

Detection is file/directory level only — no AST parsing.
Multiple signals increase confidence. Single signal = low confidence.

## Primary Signal Files

| Signal File | Stack | Notes |
|-------------|-------|-------|
| `package.json` | node / javascript | Check `engines.node` for version |
| `tsconfig.json` | typescript | Confirms TS over plain JS |
| `package.json` + `tsconfig.json` | node / typescript | high confidence |
| `Cargo.toml` | rust | Check `[workspace]` for monorepo |
| `go.mod` | go | Extract module name |
| `pyproject.toml` | python | Check `[tool.poetry]`, `[build-system]` |
| `requirements.txt` | python | Low confidence alone |
| `setup.py` / `setup.cfg` | python | Legacy signal |
| `Gemfile` | ruby | Check `ruby '~> X.Y'` for version |
| `pom.xml` | java / maven | |
| `build.gradle` / `build.gradle.kts` | java / kotlin | `.kts` = Kotlin |
| `composer.json` | php | |
| `mix.exs` | elixir | |
| `*.cabal` / `stack.yaml` | haskell | |
| `Makefile` alone | c / c++ (inferred) | Check for `gcc`/`g++`/`clang` |
| `CMakeLists.txt` | c / c++ | |
| `*.sln` / `*.csproj` | dotnet / c# | |

## Secondary Signals (boost confidence)

| Signal | Meaning |
|--------|---------|
| `.nvmrc` / `.node-version` | Node version pinned |
| `rustfmt.toml` / `clippy.toml` | Rust tooling |
| `pytest.ini` / `conftest.py` | Python/pytest |
| `ruff.toml` / `.ruff.toml` | Python/ruff linter |
| `.eslintrc*` | JavaScript/TypeScript linting |
| `.prettierrc*` | JavaScript/TypeScript formatting |
| `Dockerfile` with `FROM node:` | Confirms node stack |
| `Dockerfile` with `FROM python:` | Confirms python stack |
| `.github/workflows/*.yml` | Extract language from `uses: actions/setup-*` |

## Command Detection

### npm / node projects
```
package.json → .scripts.test   → test command
package.json → .scripts.lint   → lint command
package.json → .scripts.build  → build command
```

### Python projects
```
pyproject.toml [tool.pytest.ini_options] → test = pytest
pyproject.toml [tool.ruff] → lint = ruff check .
Makefile targets: test, lint, check
```

### Rust projects
```
Cargo.toml → test = cargo test
Cargo.toml → lint = cargo clippy
```

### Go projects
```
Makefile → test target → test command
go.mod → test = go test ./...  (default inference)
```

### Generic fallback
```
Makefile → parse targets: test, lint, build, check
.github/workflows/ → extract run: steps
```

## Confidence Scoring

| Signals found | Confidence |
|---------------|-----------|
| 2+ corroborating | high |
| 1 primary | medium |
| 1 secondary only | low |
| None | unknown |

Output `unknown` rather than guessing. Omit fields with `low` or `unknown` confidence from `project.yaml` to avoid encoding wrong data.

## Monorepo Detection

If multiple primary signal files exist at different directory depths:
- Root `package.json` with `workspaces` field → Node monorepo
- Root `Cargo.toml` with `[workspace]` → Rust workspace
- Multiple `go.mod` files → Go multi-module

For monorepos: set `stack` to the dominant language, note the structure in adoption output.

#!/usr/bin/env bash
# Test: forge-session-start hook detects .forge/project.yaml and loads Forge context
# RED phase: fails until Task 4 (enforcement hooks) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
HOOKS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/hooks"
export PATH="$FORGE_BIN:$HOOKS_DIR:$PATH"

echo "=== test-session-start: forge-session-start hook ==="
echo ""

HOOK="$HOOKS_DIR/forge-session-start"

if [ ! -f "$HOOK" ]; then
    fail "forge-session-start hook not found at hooks/forge-session-start"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "forge-session-start hook exists"

echo ""
echo "--- With .forge/project.yaml present: exits 0 with JSON context ---"
TMPDIR_WITH=$(mktemp -d /tmp/forge-session-with-XXXXXX)
trap "rm -rf '$TMPDIR_WITH'" EXIT

mkdir -p "$TMPDIR_WITH/.forge/policies"
mkdir -p "$TMPDIR_WITH/.forge/local"
cat > "$TMPDIR_WITH/.forge/project.yaml" <<'YAML'
name: test-project
version: "1.0"
stack: python
commands:
  test: pytest
  lint: ruff check
repo_traits:
  - has_migrations
  - has_auth
storage: sqlite
YAML

OUT=$(FORGE_PROJECT_DIR="$TMPDIR_WITH" bash "$HOOK" 2>/dev/null)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    pass "forge-session-start exits 0 when .forge/project.yaml present"
else
    fail "forge-session-start should exit 0, got exit $EXIT_CODE"
fi

# Should produce JSON output (Claude Code hook format)
if echo "$OUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    pass "forge-session-start outputs valid JSON"
else
    fail "forge-session-start should output valid JSON; got: $OUT"
fi

# JSON must contain context (hookSpecificOutput or additional_context)
if echo "$OUT" | grep -q "hookSpecificOutput\|additional_context"; then
    pass "forge-session-start JSON contains context field"
else
    fail "forge-session-start JSON missing hookSpecificOutput or additional_context; got: $OUT"
fi

# Context should mention Forge or forge
if echo "$OUT" | grep -qi "forge"; then
    pass "forge-session-start context mentions Forge"
else
    fail "forge-session-start context does not mention Forge; got: $OUT"
fi

# Project name should appear in context
if echo "$OUT" | grep -q "test-project"; then
    pass "forge-session-start context includes project name"
else
    fail "forge-session-start context should include project name 'test-project'; got: $OUT"
fi

echo ""
echo "--- Without .forge/project.yaml: exits 0 gracefully ---"
TMPDIR_WITHOUT=$(mktemp -d /tmp/forge-session-without-XXXXXX)
trap "rm -rf '$TMPDIR_WITHOUT'" EXIT

OUT=$(FORGE_PROJECT_DIR="$TMPDIR_WITHOUT" bash "$HOOK" 2>/dev/null)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    pass "forge-session-start exits 0 when .forge/project.yaml absent (graceful fallback)"
else
    fail "forge-session-start should exit 0 even without .forge/, got exit $EXIT_CODE"
fi

# May produce empty output or pass-through — both are acceptable
if [ -z "$OUT" ] || echo "$OUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    pass "forge-session-start produces valid output (empty or JSON) when no .forge/ present"
else
    fail "forge-session-start without .forge/ should produce empty or valid JSON; got: $OUT"
fi

echo ""
echo "--- Stack info appears in context ---"
OUT=$(FORGE_PROJECT_DIR="$TMPDIR_WITH" bash "$HOOK" 2>/dev/null)
if echo "$OUT" | grep -q "python\|pytest\|ruff"; then
    pass "forge-session-start context includes stack/commands from project.yaml"
else
    fail "forge-session-start should include stack/commands in context; got: $OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

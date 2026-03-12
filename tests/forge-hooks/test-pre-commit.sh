#!/usr/bin/env bash
# Test: forge-pre-commit hook allows minimal, blocks elevated+ without evidence
# RED phase: fails until Task 4 (enforcement hooks) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
HOOKS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/hooks"
export PATH="$FORGE_BIN:$HOOKS_DIR:$PATH"

echo "=== test-pre-commit: forge-pre-commit hook ==="
echo ""

HOOK="$HOOKS_DIR/forge-pre-commit"

if [ ! -f "$HOOK" ]; then
    fail "forge-pre-commit hook not found at hooks/forge-pre-commit"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "forge-pre-commit hook exists"

# Setup: temp git repo with .forge/
TMPDIR=$(mktemp -d /tmp/forge-precommit-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT

# Initialize a bare git repo for testing
git -C "$TMPDIR" init --quiet
git -C "$TMPDIR" config user.email "test@forge.test"
git -C "$TMPDIR" config user.name "Forge Test"

mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"

cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "db/migrations/**"
    tier: critical
    require: [design-doc, risk-register, plan, tdd, security-review, rollback-evidence, review]
  - match: "auth/**"
    tier: elevated
    require: [design-doc, plan, tdd, evidence, review]
  - match: "src/**"
    tier: standard
    require: [plan, test-evidence, verification]
  - match: "docs/**"
    tier: minimal
    require: [verification]
YAML

export FORGE_PROJECT_DIR="$TMPDIR"
if command -v forge-state &>/dev/null; then
    forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true
fi

# Stage a file for the hook to inspect
stage_file() {
    local file="$1"
    local content="${2:-placeholder}"
    mkdir -p "$TMPDIR/$(dirname "$file")"
    echo "$content" > "$TMPDIR/$file"
    git -C "$TMPDIR" add "$file"
}

echo ""
echo "--- Minimal tier: exits 0 (no-op) ---"
stage_file "docs/readme.md" "# README"

OUT=$(GIT_DIR="$TMPDIR/.git" FORGE_PROJECT_DIR="$TMPDIR" bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    pass "pre-commit at minimal tier exits 0"
else
    fail "pre-commit at minimal tier should exit 0, got exit $EXIT_CODE; output: $OUT"
fi

echo ""
echo "--- Elevated tier without evidence: exits 2 ---"
stage_file "auth/login.py" "# login"

OUT=$(GIT_DIR="$TMPDIR/.git" FORGE_PROJECT_DIR="$TMPDIR" bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "pre-commit at elevated tier without evidence exits 2"
else
    fail "pre-commit at elevated tier without evidence should exit 2, got exit $EXIT_CODE"
fi

# Error message should list missing items
if echo "$OUT" | grep -qiE "missing|required|design-doc|plan|tdd|evidence|review"; then
    pass "pre-commit error message lists missing items"
else
    fail "pre-commit should list missing items; got: $OUT"
fi

echo ""
echo "--- Elevated tier with all required evidence: exits 0 ---"
if command -v forge-evidence &>/dev/null; then
    # We need a task associated with the commit; use a task-id from staged files
    # The hook may use FORGE_TASK_ID env or look at recent task in state
    TASK_ID="pre-commit-auth-task"
    for artifact in design-doc plan tdd evidence review; do
        forge-evidence add "$TASK_ID" "$artifact" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
    done

    OUT=$(GIT_DIR="$TMPDIR/.git" FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="$TASK_ID" bash "$HOOK" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "pre-commit at elevated tier with all evidence exits 0"
    else
        fail "pre-commit at elevated tier with all evidence should exit 0, got $EXIT_CODE; output: $OUT"
    fi
else
    echo "  SKIP: forge-evidence not available (Task 2 not implemented)"
fi

echo ""
echo "--- Critical tier without evidence: exits 2 ---"
stage_file "db/migrations/001.sql" "ALTER TABLE users ADD COLUMN email TEXT"

OUT=$(GIT_DIR="$TMPDIR/.git" FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="no-evidence-task" bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "pre-commit at critical tier without evidence exits 2"
else
    fail "pre-commit at critical tier without evidence should exit 2, got exit $EXIT_CODE"
fi

# Critical tier error message should mention risk-register or security-review
if echo "$OUT" | grep -qiE "risk-register|security-review|rollback|missing|required"; then
    pass "critical tier error mentions critical-specific requirements"
else
    fail "critical tier error should mention risk-register/security-review; got: $OUT"
fi

echo ""
echo "--- No .forge/: exits 0 (graceful fallback) ---"
TMPDIR_NFORGE=$(mktemp -d /tmp/forge-precommit-nf-XXXXXX)
trap "rm -rf '$TMPDIR_NFORGE'" EXIT
git -C "$TMPDIR_NFORGE" init --quiet

OUT=$(GIT_DIR="$TMPDIR_NFORGE/.git" FORGE_PROJECT_DIR="$TMPDIR_NFORGE" bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    pass "pre-commit without .forge/ exits 0 (graceful)"
else
    fail "pre-commit without .forge/ should exit 0 (graceful), got $EXIT_CODE"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

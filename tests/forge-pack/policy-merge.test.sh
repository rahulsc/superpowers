#!/usr/bin/env bash
# Test: forge-pack policy merge with source annotation
# Verifies that policies are merged correctly and source: pack/<name> is injected.
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"
FORGE_PACK="$ROOT/.forge/bin/forge-pack"
HELLO_WORLD="$ROOT/forge-pack-hello-world"

echo "=== policy-merge.test.sh ==="
echo ""

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

mkdir -p "$TMPDIR_TEST/.forge/policies" "$TMPDIR_TEST/.forge/packs"
cat > "$TMPDIR_TEST/.forge/project.yaml" <<'YAML'
name: test-project
version: 0.1.0
YAML

# Pre-existing project policy (must not be overwritten)
cat > "$TMPDIR_TEST/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: ["src/**"]
    tier: standard
YAML

# ── install and check policy merge ──────────────────────────────────────────
echo "--- install hello-world ---"
cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$HELLO_WORLD" >/dev/null 2>&1
RC=$?
if [ $RC -eq 0 ]; then
    pass "install: exits 0"
else
    fail "install: exited $RC"
fi

echo ""
echo "--- source annotation present ---"
if grep -rq "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null; then
    pass "policy merge: source: pack/hello-world annotation present"
else
    fail "policy merge: source: pack/hello-world annotation missing"
fi

echo ""
echo "--- existing project rules preserved ---"
if grep -q "src/\*\*" "$TMPDIR_TEST/.forge/policies/default.yaml" 2>/dev/null; then
    pass "policy merge: existing project rules preserved in default.yaml"
else
    fail "policy merge: existing project rules were overwritten or lost"
fi

echo ""
echo "--- greeting-policy.yaml created ---"
if [ -f "$TMPDIR_TEST/.forge/policies/greeting-policy.yaml" ]; then
    pass "policy merge: greeting-policy.yaml created"
else
    fail "policy merge: greeting-policy.yaml not found"
fi

echo ""
echo "--- greeting-policy.yaml has match field ---"
if grep -q "match:" "$TMPDIR_TEST/.forge/policies/greeting-policy.yaml" 2>/dev/null; then
    pass "policy merge: greeting-policy.yaml has match field"
else
    fail "policy merge: greeting-policy.yaml missing match field"
fi

echo ""
echo "--- remove cleans up policy rules ---"
cd "$TMPDIR_TEST" && "$FORGE_PACK" remove hello-world >/dev/null 2>&1

if ! grep -rq "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null; then
    pass "remove: all source: pack/hello-world annotations removed"
else
    fail "remove: orphaned source: pack/hello-world annotations remain"
fi

echo ""
echo "--- existing project rules still preserved after remove ---"
if grep -q "src/\*\*" "$TMPDIR_TEST/.forge/policies/default.yaml" 2>/dev/null; then
    pass "remove: existing project rules still intact in default.yaml"
else
    fail "remove: remove broke existing project rules in default.yaml"
fi

echo ""
echo "--- idempotent re-install does not duplicate rules ---"
cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$HELLO_WORLD" >/dev/null 2>&1
cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$HELLO_WORLD" >/dev/null 2>&1

SOURCE_COUNT=$(grep -r "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null | wc -l)
if [ "$SOURCE_COUNT" -eq 1 ]; then
    pass "idempotent: re-install produces exactly 1 source annotation (got $SOURCE_COUNT)"
else
    fail "idempotent: re-install duplicated source annotations (got $SOURCE_COUNT, expected 1)"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

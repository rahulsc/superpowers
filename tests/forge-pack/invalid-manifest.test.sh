#!/usr/bin/env bash
# Test: forge-pack rejects invalid manifests
# Verifies that forge-pack exits non-zero when pack.yaml is missing or incomplete.
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"
FORGE_PACK="$ROOT/.forge/bin/forge-pack"

echo "=== invalid-manifest.test.sh ==="
echo ""

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

mkdir -p "$TMPDIR_TEST/.forge/policies" "$TMPDIR_TEST/.forge/packs"
cat > "$TMPDIR_TEST/.forge/project.yaml" <<'YAML'
name: test-project
version: 0.1.0
YAML

# ── missing pack.yaml ────────────────────────────────────────────────────────
echo "--- install with no pack.yaml ---"
BADPACK=$(mktemp -d)
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$BADPACK" 2>&1)
RC=$?
rm -rf "$BADPACK"
if [ $RC -ne 0 ]; then
    pass "rejects: missing pack.yaml → exit $RC"
else
    fail "rejects: should exit non-zero for missing pack.yaml, got 0"
fi

# ── missing name field ───────────────────────────────────────────────────────
echo ""
echo "--- install with pack.yaml missing 'name' ---"
NONAME=$(mktemp -d)
cat > "$NONAME/pack.yaml" <<'YAML'
version: 0.1.0
description: test pack
forge_compatibility: ">=0.1.0"
YAML
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$NONAME" 2>&1)
RC=$?
rm -rf "$NONAME"
if [ $RC -ne 0 ]; then
    pass "rejects: missing 'name' field → exit $RC"
else
    fail "rejects: should exit non-zero for missing name, got 0"
fi

# ── missing version field ────────────────────────────────────────────────────
echo ""
echo "--- install with pack.yaml missing 'version' ---"
NOVERSION=$(mktemp -d)
cat > "$NOVERSION/pack.yaml" <<'YAML'
name: bad-pack
description: test pack
forge_compatibility: ">=0.1.0"
YAML
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$NOVERSION" 2>&1)
RC=$?
rm -rf "$NOVERSION"
if [ $RC -ne 0 ]; then
    pass "rejects: missing 'version' field → exit $RC"
else
    fail "rejects: should exit non-zero for missing version, got 0"
fi

# ── missing forge_compatibility field ────────────────────────────────────────
echo ""
echo "--- install with pack.yaml missing 'forge_compatibility' ---"
NOCOMPAT=$(mktemp -d)
cat > "$NOCOMPAT/pack.yaml" <<'YAML'
name: bad-pack
version: 0.1.0
description: test pack
YAML
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$NOCOMPAT" 2>&1)
RC=$?
rm -rf "$NOCOMPAT"
if [ $RC -ne 0 ]; then
    pass "rejects: missing 'forge_compatibility' field → exit $RC"
else
    fail "rejects: should exit non-zero for missing forge_compatibility, got 0"
fi

# ── missing .forge/project.yaml ──────────────────────────────────────────────
echo ""
echo "--- operations fail without .forge/project.yaml ---"
NOPROJ=$(mktemp -d)

OUT=$(cd "$NOPROJ" && "$FORGE_PACK" list 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
    pass "requires: list fails without .forge/project.yaml (exit $RC)"
else
    fail "requires: list should fail without .forge/project.yaml, got exit 0"
fi

OUT=$(cd "$NOPROJ" && "$FORGE_PACK" install /dev/null 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
    pass "requires: install fails without .forge/project.yaml (exit $RC)"
else
    fail "requires: install should fail without .forge/project.yaml, got exit 0"
fi

OUT=$(cd "$NOPROJ" && "$FORGE_PACK" remove something 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
    pass "requires: remove fails without .forge/project.yaml (exit $RC)"
else
    fail "requires: remove should fail without .forge/project.yaml, got exit 0"
fi

rm -rf "$NOPROJ"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

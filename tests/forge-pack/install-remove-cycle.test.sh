#!/usr/bin/env bash
# Test: forge-pack install/list/remove lifecycle
# Exercises the full install → list → remove → list cycle with the hello-world pack.
set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"
FORGE_PACK="$ROOT/.forge/bin/forge-pack"
HELLO_WORLD="$ROOT/forge-pack-hello-world"

echo "=== install-remove-cycle.test.sh ==="
echo ""

# Setup: temp project dir with minimal .forge/
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

mkdir -p "$TMPDIR_TEST/.forge/policies" "$TMPDIR_TEST/.forge/packs"
cat > "$TMPDIR_TEST/.forge/project.yaml" <<'YAML'
name: test-project
version: 0.1.0
YAML

# ── list empty ──────────────────────────────────────────────────────────────
echo "--- list with no packs ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" list 2>&1)
if echo "$OUT" | grep -qiE "no packs|none|empty|0 pack"; then
    pass "list: reports empty when no packs installed"
else
    fail "list: expected empty-state message; got: $OUT"
fi

# ── install ─────────────────────────────────────────────────────────────────
echo ""
echo "--- install hello-world ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" install "$HELLO_WORLD" 2>&1)
RC=$?
if [ $RC -eq 0 ]; then
    pass "install: exits 0"
else
    fail "install: exited $RC; output: $OUT"
fi

if [ -d "$TMPDIR_TEST/.forge/packs/hello-world" ]; then
    pass "install: .forge/packs/hello-world/ created"
else
    fail "install: .forge/packs/hello-world/ not found"
fi

if [ -f "$TMPDIR_TEST/.forge/packs/hello-world/pack.yaml" ]; then
    pass "install: pack.yaml present in install dir"
else
    fail "install: pack.yaml missing from install dir"
fi

# ── list after install ───────────────────────────────────────────────────────
echo ""
echo "--- list after install ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" list 2>&1)
if echo "$OUT" | grep -qi "hello-world"; then
    pass "list: shows hello-world after install"
else
    fail "list: expected hello-world; got: $OUT"
fi

if echo "$OUT" | grep -qi "0.1.0"; then
    pass "list: shows version 0.1.0"
else
    fail "list: expected version 0.1.0; got: $OUT"
fi

# ── remove ──────────────────────────────────────────────────────────────────
echo ""
echo "--- remove hello-world ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" remove hello-world 2>&1)
RC=$?
if [ $RC -eq 0 ]; then
    pass "remove: exits 0"
else
    fail "remove: exited $RC; output: $OUT"
fi

if [ ! -d "$TMPDIR_TEST/.forge/packs/hello-world" ]; then
    pass "remove: .forge/packs/hello-world/ deleted"
else
    fail "remove: .forge/packs/hello-world/ still exists"
fi

# ── list empty again ─────────────────────────────────────────────────────────
echo ""
echo "--- list after remove ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" list 2>&1)
if echo "$OUT" | grep -qiE "no packs|none|empty|0 pack"; then
    pass "list: empty again after remove"
else
    fail "list: expected empty after remove; got: $OUT"
fi

# ── remove non-existent ──────────────────────────────────────────────────────
echo ""
echo "--- remove non-existent pack ---"
OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK" remove hello-world 2>&1)
RC=$?
if [ $RC -ne 0 ]; then
    pass "remove: exits non-zero for non-existent pack"
else
    fail "remove: should fail for non-existent pack; got exit 0"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

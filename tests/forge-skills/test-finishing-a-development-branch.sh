#!/usr/bin/env bash
# Test: skills/finishing-a-development-branch/SKILL.md forge evolution.
# Checks .forge/ migration, forge-state references, verification gate,
# knowledge promotion, state cleanup, forge: prefix.
# RED phase: fails until Task 16 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/finishing-a-development-branch/SKILL.md"

echo "=== test-finishing-a-development-branch: forge evolution ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/finishing-a-development-branch/SKILL.md exists"
else
    fail "skills/finishing-a-development-branch/SKILL.md not found"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# ---- Frontmatter ----
echo ""
echo "--- Frontmatter ---"
FRONTMATTER=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SKILL_FILE")

if echo "$FRONTMATTER" | grep -q "^name: finishing-a-development-branch$"; then
    pass "frontmatter has name: finishing-a-development-branch"
else
    fail "frontmatter missing 'name: finishing-a-development-branch'"
fi

DESC_LINE=$(echo "$FRONTMATTER" | grep "^description:")
if [ -n "$DESC_LINE" ]; then
    DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
    if echo "$DESC_VALUE" | grep -qi "^Use when"; then
        pass "description starts with 'Use when'"
    else
        fail "description must start with 'Use when'; got: '$DESC_VALUE'"
    fi
else
    fail "frontmatter missing 'description' field"
fi

# ---- Size constraint ----
echo ""
echo "--- Size constraint (under 500 lines) ---"
LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [ "$LINE_COUNT" -lt 500 ]; then
    pass "skill file is under 500 lines ($LINE_COUNT lines)"
else
    fail "skill file exceeds 500 lines ($LINE_COUNT lines) — Anthropic limit"
fi

# ---- No .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ for state ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct state path)"
else
    fail "skill does not reference .forge/ — must use .forge/ for state"
fi

# ---- References forge-state ----
echo ""
echo "--- References forge-state ---"
if grep -qE "forge-state" "$SKILL_FILE"; then
    pass "skill references forge-state for state reads/writes"
else
    fail "skill must reference forge-state for state reads/writes"
fi

# ---- Verification gate at entry ----
echo ""
echo "--- Verification gate at entry ---"
# Skill must check verification.passed (or equivalent) before proceeding
if grep -qiE "verification\.(passed|status)|verification gate|verify.*before.*proceed|check.*verification.*pass" "$SKILL_FILE"; then
    pass "skill has verification gate at entry"
else
    fail "skill must have verification gate at entry — check verification.passed before proceeding"
fi

# ---- Knowledge promotion step ----
echo ""
echo "--- Knowledge promotion step ---"
# Skill should scan forge-memory for discoveries and offer to promote to shared/
if grep -qiE "knowledge.*promot|promot.*knowledge|forge-memory.*discover|discover.*promot|\.forge/shared|promot.*shared" "$SKILL_FILE"; then
    pass "skill has knowledge promotion step"
else
    fail "skill must have knowledge promotion step — scan forge-memory for discoveries, offer to promote to shared/"
fi

# ---- State cleanup ----
echo ""
echo "--- State cleanup (clean .forge/local/ evidence after finish) ---"
if grep -qiE "clean.*\.forge/local|\.forge/local.*clean|clean.*evidence|evidence.*clean|state.*cleanup|cleanup.*state|remove.*local.*evidence" "$SKILL_FILE"; then
    pass "skill has state cleanup for .forge/local/ evidence"
else
    fail "skill must clean .forge/local/ evidence after finish"
fi

# ---- Uses forge: prefix ----
echo ""
echo "--- Uses forge: prefix for skill invocations ---"
if grep -qE "superpowers:" "$SKILL_FILE"; then
    LINES=$(grep -n "superpowers:" "$SKILL_FILE" | head -5)
    fail "skill uses superpowers: prefix (should use forge:): $LINES"
else
    pass "no superpowers: prefix found"
fi

if grep -qE "forge:" "$SKILL_FILE"; then
    pass "skill uses forge: prefix for skill invocations"
else
    fail "skill must use forge: prefix for skill invocations"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

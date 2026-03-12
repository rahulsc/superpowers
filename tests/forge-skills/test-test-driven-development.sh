#!/usr/bin/env bash
# Test: skills/test-driven-development/SKILL.md is updated with risk-tier
#       integration, forge-evidence recording, and forge: prefix.
# RED phase: fails until Task 13 (TDD evolution) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/test-driven-development/SKILL.md"

echo "=== test-test-driven-development: risk-tier integration, forge-evidence, forge: prefix ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/test-driven-development/SKILL.md exists"
else
    fail "skills/test-driven-development/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: test-driven-development$"; then
    pass "frontmatter has name: test-driven-development"
else
    fail "frontmatter missing 'name: test-driven-development'"
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

# ---- No stale .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill still references .superpowers/ (must migrate to .forge/): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct state path)"
else
    fail "skill does not reference .forge/ — TDD evidence must be stored in .forge/"
fi

# ---- Risk tier: TDD optional at minimal, required at elevated+ ----
echo ""
echo "--- Risk tier: TDD optional at minimal, required at elevated+ ---"
if grep -qiE "minimal.*optional|optional.*minimal|skip.*minimal|minimal.*skip" "$SKILL_FILE"; then
    pass "skill states TDD is optional at minimal tier"
else
    fail "skill missing minimal-tier TDD exception — TDD is optional at minimal, required at elevated+"
fi

if grep -qiE "elevated.*require|require.*elevated|critical.*require|require.*critical|elevated.*enforce|enforce.*elevated" "$SKILL_FILE"; then
    pass "skill states TDD is required at elevated/critical tier"
else
    fail "skill missing elevated/critical-tier TDD requirement"
fi

# General tier reference
if grep -qiE "risk.?tier|tier.*tdd|tdd.*tier|tier.*test" "$SKILL_FILE"; then
    pass "skill references risk tier integration with TDD"
else
    fail "skill missing risk tier reference — TDD ceremony must adapt to tier"
fi

# ---- forge-evidence for recording test evidence ----
echo ""
echo "--- References forge-evidence for recording test evidence ---"
if grep -qE "forge-evidence" "$SKILL_FILE"; then
    pass "skill references forge-evidence for recording test evidence"
else
    fail "skill missing forge-evidence — TDD output (RED/GREEN evidence) must be stored"
fi

# ---- forge: prefix for skill invocations ----
echo ""
echo "--- Uses forge: prefix for skill invocations ---"
if grep -qE "forge:[a-z]" "$SKILL_FILE"; then
    pass "skill uses forge: prefix for skill invocations"
else
    fail "skill missing forge: prefix — should invoke skills as forge:skill-name"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

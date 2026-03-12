#!/usr/bin/env bash
# Test: skills/subagent-driven-development/SKILL.md is wired to .forge/,
#       risk-aware, collects evidence via forge-evidence.
# RED phase: fails until Task 11 (SDD evolution) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/subagent-driven-development/SKILL.md"

echo "=== test-subagent-driven-development: .forge/-wired, risk-aware, evidence-collecting ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/subagent-driven-development/SKILL.md exists"
else
    fail "skills/subagent-driven-development/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: subagent-driven-development$"; then
    pass "frontmatter has name: subagent-driven-development"
else
    fail "frontmatter missing 'name: subagent-driven-development'"
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
    fail "skill does not reference .forge/ — must wire state/evidence to .forge/"
fi

# ---- forge-state or forge-evidence ----
echo ""
echo "--- References forge-state or forge-evidence ---"
if grep -qE "forge-state|forge-evidence" "$SKILL_FILE"; then
    pass "skill references forge-state or forge-evidence for state/evidence tracking"
else
    fail "skill missing forge-state/forge-evidence — subagent output must be recorded"
fi

# ---- Risk tier awareness ----
echo ""
echo "--- Risk tier awareness (different ceremony per tier) ---"
if grep -qiE "risk.?tier|tier|minimal|standard|elevated|critical" "$SKILL_FILE"; then
    pass "skill references risk tier"
else
    fail "skill missing risk tier awareness — ceremony must scale to tier"
fi

# Tier-specific ceremony variation
if grep -qiE "tier.*minimal.*skip|minimal.*tier.*no.*tdd|optional.*minimal|minimal.*optional|tier.*ceremony|ceremony.*tier" "$SKILL_FILE"; then
    pass "skill describes tier-varying ceremony (e.g. TDD optional at minimal)"
else
    # Acceptable if tier differences are expressed differently
    if grep -qE "minimal|standard|elevated|critical" "$SKILL_FILE" && grep -qiE "skip|optional|require|enforce" "$SKILL_FILE"; then
        pass "skill references tiers with optional/required ceremony variation"
    else
        fail "skill missing tier-varying ceremony — different tiers need different evidence requirements"
    fi
fi

# ---- forge: prefix for skill invocations ----
echo ""
echo "--- Uses forge: prefix for skill invocations ---"
if grep -qE "forge:[a-z]" "$SKILL_FILE"; then
    pass "skill uses forge: prefix for skill invocations"
else
    fail "skill missing forge: prefix — should invoke skills as forge:skill-name"
fi

# ---- References forge:verification-before-completion ----
echo ""
echo "--- References forge:verification-before-completion ---"
if grep -qE "forge:verification-before-completion|verification-before-completion" "$SKILL_FILE"; then
    pass "skill references verification-before-completion"
else
    fail "skill missing verification-before-completion — SDD must gate completion on evidence"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

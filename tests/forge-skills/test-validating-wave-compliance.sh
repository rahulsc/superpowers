#!/usr/bin/env bash
# Test: skills/validating-wave-compliance/SKILL.md exists as a new skill for
#       between-wave design/plan compliance checking.
# RED phase: fails until Task 10 (validating-wave-compliance skill) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/validating-wave-compliance/SKILL.md"

echo "=== test-validating-wave-compliance: between-wave compliance checking skill ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/validating-wave-compliance/SKILL.md exists"
else
    fail "skills/validating-wave-compliance/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: validating-wave-compliance$"; then
    pass "frontmatter has name: validating-wave-compliance"
else
    fail "frontmatter missing 'name: validating-wave-compliance'"
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

# ---- Design doc comparison ----
echo ""
echo "--- Design doc comparison ---"
if grep -qiE "design.*doc|design.*compar|compar.*design|check.*design|design.*deviat|deviat.*design" "$SKILL_FILE"; then
    pass "skill references design doc comparison"
else
    fail "skill missing design doc comparison — core purpose is catching design deviations"
fi

# ---- Plan compliance checking ----
echo ""
echo "--- Plan compliance checking ---"
if grep -qiE "plan.*complian|complian.*plan|plan.*check|check.*plan|plan.*deviat|deviat.*plan" "$SKILL_FILE"; then
    pass "skill references plan compliance checking"
else
    fail "skill missing plan compliance checking — must verify implementation matches the plan"
fi

# ---- Evidence verification ----
echo ""
echo "--- Evidence verification ---"
if grep -qiE "evidence.*verif|verif.*evidence|evidence.*check|check.*evidence|required.*evidence|evidence.*required|artifact" "$SKILL_FILE"; then
    pass "skill references evidence verification"
else
    fail "skill missing evidence verification — must check that required artifacts are present"
fi

# ---- .forge/ state integration ----
echo ""
echo "--- .forge/ state integration ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ state"
else
    fail "skill missing .forge/ state reference — must read tier/evidence from forge-state"
fi

# No stale .superpowers/ references
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -3)
    fail "skill references .superpowers/ (new skill must use .forge/ only): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- Process for checking design deviations ----
echo ""
echo "--- Process for detecting design deviations ---"
if grep -qiE "deviat|drift|diverge|mismatch|diff.*design|design.*diff|discrepan" "$SKILL_FILE"; then
    pass "skill contains process for detecting design deviations"
else
    fail "skill missing deviation detection process — must identify when implementation drifts from design"
fi

# ---- Blocking progression ----
echo ""
echo "--- Blocks wave progression on violations ---"
if grep -qiE "block|halt|stop|cannot.*proceed|do not proceed|gate|fail.*wave|wave.*fail" "$SKILL_FILE"; then
    pass "skill describes blocking wave progression when violations found"
else
    fail "skill missing blocking logic — must halt next wave until deviations are fixed"
fi

# ---- Between-wave context ----
echo ""
echo "--- Between-wave trigger context ---"
if grep -qiE "between.*wave|wave.*between|after.*wave|wave.*complet|before.*next.*wave|next.*wave" "$SKILL_FILE"; then
    pass "skill describes between-wave invocation context"
else
    fail "skill missing between-wave context — should describe when it runs (between waves)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

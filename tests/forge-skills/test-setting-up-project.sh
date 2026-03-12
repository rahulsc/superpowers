#!/usr/bin/env bash
# Test: skills/setting-up-project/SKILL.md exists, has correct frontmatter,
#       references forge-state init, classify-risk, worktree creation,
#       and checks design.approved gate.
# RED phase: fails until Task 6 (setting-up-project skill) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/setting-up-project/SKILL.md"

echo "=== test-setting-up-project: skills/setting-up-project/SKILL.md ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/setting-up-project/SKILL.md exists"
else
    fail "skills/setting-up-project/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: setting-up-project$"; then
    pass "frontmatter has name: setting-up-project"
else
    fail "frontmatter missing 'name: setting-up-project'"
fi

DESC_LINE=$(echo "$FRONTMATTER" | grep "^description:")
if [ -n "$DESC_LINE" ]; then
    DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description: *//')
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

# ---- forge-state init ----
echo ""
echo "--- References forge-state init ---"
if grep -q "forge-state init\|forge-state.*init" "$SKILL_FILE"; then
    pass "skill references 'forge-state init'"
else
    fail "skill missing 'forge-state init' — state initialization required"
fi

# ---- classify-risk ----
echo ""
echo "--- References classify-risk ---"
if grep -q "classify-risk" "$SKILL_FILE"; then
    pass "skill references 'classify-risk'"
else
    fail "skill missing 'classify-risk' — risk classification is a core step"
fi

# ---- Worktree creation ----
echo ""
echo "--- References worktree creation ---"
if grep -qiE "worktree|EnterWorktree|git worktree|create.*worktree|worktree.*creat" "$SKILL_FILE"; then
    pass "skill references worktree creation"
else
    fail "skill missing worktree creation reference"
fi

# ---- design.approved gate ----
echo ""
echo "--- design.approved gate ---"
if grep -q "design.approved\|design\.approved" "$SKILL_FILE"; then
    pass "skill checks design.approved gate"
else
    fail "skill missing design.approved gate check — must verify design is approved before setup"
fi

# ---- No stale .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "no .superpowers/ references (uses .forge/ only)"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct config path)"
else
    fail "skill does not reference .forge/ — may be using old path"
fi

# ---- Bridges design → execution ----
echo ""
echo "--- Bridges design to execution ---"
if grep -qiE "design|execution|bridge|setup|initializ" "$SKILL_FILE"; then
    pass "skill describes bridging design to execution"
else
    fail "skill should describe its role as bridge between design approval and execution"
fi

# ---- Team decision (composing-teams or solo) ----
echo ""
echo "--- Team vs solo decision ---"
if grep -qiE "solo|team|composing-teams|execution.*strategy|strategy.*execution" "$SKILL_FILE"; then
    pass "skill addresses team/solo execution decision"
else
    fail "skill should address team vs solo execution decision (scope/risk dependent)"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

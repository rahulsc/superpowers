#!/usr/bin/env bash
# Test: skills/adopting-forge/SKILL.md exists, has correct frontmatter,
#       describes repo scanning, .forge/ creation, CLAUDE.md generation,
#       stack/command detection, and mode selection.
# RED phase: fails until Task 7 (adopting-forge skill) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/adopting-forge/SKILL.md"

echo "=== test-adopting-forge: skills/adopting-forge/SKILL.md ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/adopting-forge/SKILL.md exists"
else
    fail "skills/adopting-forge/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: adopting-forge$"; then
    pass "frontmatter has name: adopting-forge"
else
    fail "frontmatter missing 'name: adopting-forge'"
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

# ---- .forge/project.yaml creation ----
echo ""
echo "--- References .forge/project.yaml creation ---"
if grep -q "project.yaml" "$SKILL_FILE"; then
    pass "skill references project.yaml creation"
else
    fail "skill missing reference to .forge/project.yaml creation"
fi

# ---- Repo scanning / inspection ----
echo ""
echo "--- Repo scanning / inspection ---"
if grep -qiE "scan|inspect|analyz|survey|detect|look.*repo|repo.*inspect" "$SKILL_FILE"; then
    pass "skill describes repo scanning/inspection"
else
    fail "skill missing repo scanning/inspection logic"
fi

# ---- Stack detection ----
echo ""
echo "--- Stack detection ---"
if grep -qiE "stack|language|framework|detect.*tech|tech.*detect|package\.json|requirements\.txt|Cargo\.toml|go\.mod|pyproject" "$SKILL_FILE"; then
    pass "skill references stack/technology detection"
else
    fail "skill missing stack detection (should detect language/framework/tools)"
fi

# ---- Command detection ----
echo ""
echo "--- Command detection ---"
if grep -qiE "command|test.*command|lint.*command|build.*command|npm|pytest|make|cargo|Makefile" "$SKILL_FILE"; then
    pass "skill references command detection (test/lint/build commands)"
else
    fail "skill missing command detection (should detect test/lint/build commands)"
fi

# ---- CLAUDE.md generation ----
echo ""
echo "--- CLAUDE.md generation ---"
if grep -q "CLAUDE.md" "$SKILL_FILE"; then
    pass "skill references CLAUDE.md generation"
else
    fail "skill missing CLAUDE.md generation reference"
fi

# ---- Mode selection (solo / team) ----
echo ""
echo "--- Mode selection (solo/team) ---"
if grep -qiE "solo|team|mode.*select|select.*mode|light.*touch|full.*adoption" "$SKILL_FILE"; then
    pass "skill describes mode selection (solo/team or light-touch/full)"
else
    fail "skill missing mode selection — should offer solo vs team modes"
fi

# ---- .forge/ directory creation ----
echo ""
echo "--- .forge/ directory creation ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ directory creation"
else
    fail "skill missing .forge/ directory creation reference"
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

# ---- Verification step (diagnosing-forge) ----
echo ""
echo "--- Verification step after adoption ---"
if grep -qiE "diagnosing-forge|diagnos|verify|health.*check|check.*health" "$SKILL_FILE"; then
    pass "skill includes verification step after adoption (diagnosing-forge or equivalent)"
else
    fail "skill missing verification step — should run diagnosing-forge or similar after adoption"
fi

# ---- AGENTS.md generation (multi-platform) ----
echo ""
echo "--- Multi-platform adapter (AGENTS.md for Codex) ---"
if grep -qiE "AGENTS\.md|Codex|multi.?platform|adapter" "$SKILL_FILE"; then
    pass "skill mentions AGENTS.md or multi-platform adapter generation"
else
    fail "skill missing AGENTS.md/Codex support — adopting-forge generates adapters for multiple platforms"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

#!/usr/bin/env bash
# Test: skills/requesting-code-review/SKILL.md and skills/receiving-code-review/SKILL.md forge evolution.
# Checks .forge/ migration, tier-based dispatch, no duplicate sections, forge: prefix.
# RED phase: fails until Task 15 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

REQ_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/requesting-code-review/SKILL.md"
REC_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/receiving-code-review/SKILL.md"

echo "=== test-code-review-skills: forge evolution ==="
echo ""

# ===========================================================
# PART 1: requesting-code-review
# ===========================================================
echo "=========================================="
echo "PART 1: requesting-code-review"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$REQ_FILE" ]; then
    pass "requesting-code-review/SKILL.md exists"
else
    fail "requesting-code-review/SKILL.md not found"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# ---- Frontmatter ----
echo ""
echo "--- Frontmatter ---"
REQ_FRONTMATTER=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$REQ_FILE")

if echo "$REQ_FRONTMATTER" | grep -q "^name: requesting-code-review$"; then
    pass "frontmatter has name: requesting-code-review"
else
    fail "frontmatter missing 'name: requesting-code-review'"
fi

REQ_DESC_LINE=$(echo "$REQ_FRONTMATTER" | grep "^description:")
if [ -n "$REQ_DESC_LINE" ]; then
    REQ_DESC_VALUE=$(echo "$REQ_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
    if echo "$REQ_DESC_VALUE" | grep -qi "^Use when"; then
        pass "requesting: description starts with 'Use when'"
    else
        fail "requesting: description must start with 'Use when'; got: '$REQ_DESC_VALUE'"
    fi
else
    fail "requesting: frontmatter missing 'description' field"
fi

# ---- Size constraint ----
echo ""
echo "--- Size constraint (under 500 lines) ---"
REQ_LINE_COUNT=$(wc -l < "$REQ_FILE")
if [ "$REQ_LINE_COUNT" -lt 500 ]; then
    pass "requesting-code-review is under 500 lines ($REQ_LINE_COUNT lines)"
else
    fail "requesting-code-review exceeds 500 lines ($REQ_LINE_COUNT lines) — Anthropic limit"
fi

# ---- No .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$REQ_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$REQ_FILE" | head -5)
    fail "requesting: references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "requesting: no .superpowers/ references"
fi

# ---- References .forge/ and forge-state ----
echo ""
echo "--- References .forge/ and forge-state ---"
if grep -q "\.forge/" "$REQ_FILE"; then
    pass "requesting: references .forge/"
else
    fail "requesting: must reference .forge/ for state/risk tier lookups"
fi

if grep -qE "forge-state" "$REQ_FILE"; then
    pass "requesting: references forge-state for risk tier"
else
    fail "requesting: must reference forge-state for risk tier lookups"
fi

# ---- Tier-based dispatch table ----
echo ""
echo "--- Tier-based dispatch table ---"
# Must have a table or structured section mapping risk tiers to review requirements
TIER_DISPATCH_COUNT=0
grep -qiE "\bminimal\b.*none\b|\bminimal\b.*skip\b|\bminimal\b.*optional\b" "$REQ_FILE" && TIER_DISPATCH_COUNT=$((TIER_DISPATCH_COUNT + 1))
grep -qiE "\bstandard\b.*optional\b" "$REQ_FILE" && TIER_DISPATCH_COUNT=$((TIER_DISPATCH_COUNT + 1))
grep -qiE "\belevated\b.*mandatory\b|\belevated\b.*required\b" "$REQ_FILE" && TIER_DISPATCH_COUNT=$((TIER_DISPATCH_COUNT + 1))
grep -qiE "\bcritical\b.*mandatory\b|\bcritical\b.*required\b|\bcritical\b.*security" "$REQ_FILE" && TIER_DISPATCH_COUNT=$((TIER_DISPATCH_COUNT + 1))

if [ "$TIER_DISPATCH_COUNT" -ge 3 ]; then
    pass "requesting: tier-based dispatch table present ($TIER_DISPATCH_COUNT tiers matched)"
else
    fail "requesting: must have tier-based dispatch table (minimal: none/optional, standard: optional, elevated: mandatory, critical: mandatory+security); found $TIER_DISPATCH_COUNT matches"
fi

# ---- Uses forge: prefix ----
echo ""
echo "--- Uses forge: prefix ---"
if grep -qE "superpowers:" "$REQ_FILE"; then
    LINES=$(grep -n "superpowers:" "$REQ_FILE" | head -5)
    fail "requesting: uses superpowers: prefix (should use forge:): $LINES"
else
    pass "requesting: no superpowers: prefix found"
fi

if grep -qE "forge:" "$REQ_FILE"; then
    pass "requesting: uses forge: prefix for skill invocations"
else
    fail "requesting: must use forge: prefix for skill invocations"
fi

# ===========================================================
# PART 2: receiving-code-review
# ===========================================================
echo ""
echo "=========================================="
echo "PART 2: receiving-code-review"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$REC_FILE" ]; then
    pass "receiving-code-review/SKILL.md exists"
else
    fail "receiving-code-review/SKILL.md not found"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# ---- Frontmatter ----
echo ""
echo "--- Frontmatter ---"
REC_FRONTMATTER=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$REC_FILE")

if echo "$REC_FRONTMATTER" | grep -q "^name: receiving-code-review$"; then
    pass "frontmatter has name: receiving-code-review"
else
    fail "frontmatter missing 'name: receiving-code-review'"
fi

REC_DESC_LINE=$(echo "$REC_FRONTMATTER" | grep "^description:")
if [ -n "$REC_DESC_LINE" ]; then
    REC_DESC_VALUE=$(echo "$REC_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
    if echo "$REC_DESC_VALUE" | grep -qi "^Use when"; then
        pass "receiving: description starts with 'Use when'"
    else
        fail "receiving: description must start with 'Use when'; got: '$REC_DESC_VALUE'"
    fi
else
    fail "receiving: frontmatter missing 'description' field"
fi

# ---- Size constraint ----
echo ""
echo "--- Size constraint (under 500 lines) ---"
REC_LINE_COUNT=$(wc -l < "$REC_FILE")
if [ "$REC_LINE_COUNT" -lt 500 ]; then
    pass "receiving-code-review is under 500 lines ($REC_LINE_COUNT lines)"
else
    fail "receiving-code-review exceeds 500 lines ($REC_LINE_COUNT lines) — Anthropic limit"
fi

# ---- No .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$REC_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$REC_FILE" | head -5)
    fail "receiving: references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "receiving: no .superpowers/ references"
fi

# ---- No duplicate "From Team Peers" section ----
echo ""
echo "--- No duplicate 'From Team Peers' section ---"
PEER_COUNT=$(grep -c "^### From Team Peers" "$REC_FILE" || true)
if [ "$PEER_COUNT" -le 1 ]; then
    pass "receiving: no duplicate 'From Team Peers' section ($PEER_COUNT found)"
else
    fail "receiving: has $PEER_COUNT duplicate 'From Team Peers' sections (should be at most 1)"
fi

# ---- Uses forge: prefix ----
echo ""
echo "--- Uses forge: prefix ---"
if grep -qE "superpowers:" "$REC_FILE"; then
    LINES=$(grep -n "superpowers:" "$REC_FILE" | head -5)
    fail "receiving: uses superpowers: prefix (should use forge:): $LINES"
else
    pass "receiving: no superpowers: prefix found"
fi

# Check that at least one forge: reference exists (in integration/pairs-with section)
if grep -qE "forge:" "$REC_FILE"; then
    pass "receiving: uses forge: prefix"
else
    fail "receiving: must use forge: prefix for skill references"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

#!/usr/bin/env bash
# Test: Task 18 — syncing-forge and diagnosing-forge (NEW skills).
# These files do not exist yet; tests should fail RED until Task 18 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"

SYNC_FILE="$ROOT/skills/syncing-forge/SKILL.md"
DIAG_FILE="$ROOT/skills/diagnosing-forge/SKILL.md"

echo "=== test-sync-diagnose-skills: Wave 7 Task 18 ==="
echo ""

# ===========================================================
# PART 1: syncing-forge
# ===========================================================
echo "=========================================="
echo "PART 1: syncing-forge"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$SYNC_FILE" ]; then
    pass "syncing-forge/SKILL.md exists"
else
    fail "syncing-forge/SKILL.md not found"
fi

if [ -f "$SYNC_FILE" ]; then
    # ---- Frontmatter ----
    echo ""
    echo "--- Frontmatter ---"
    SYNC_FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SYNC_FILE")

    if echo "$SYNC_FM" | grep -q "^name: syncing-forge$"; then
        pass "syncing-forge: frontmatter has name: syncing-forge"
    else
        fail "syncing-forge: frontmatter missing 'name: syncing-forge'"
    fi

    SYNC_DESC_LINE=$(echo "$SYNC_FM" | grep "^description:")
    if [ -n "$SYNC_DESC_LINE" ]; then
        SYNC_DESC_VALUE=$(echo "$SYNC_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$SYNC_DESC_VALUE" | grep -qi "^Use when"; then
            pass "syncing-forge: description starts with 'Use when'"
        else
            fail "syncing-forge: description must start with 'Use when'; got: '$SYNC_DESC_VALUE'"
        fi
    else
        fail "syncing-forge: frontmatter missing 'description' field"
    fi

    # ---- Size constraint ----
    echo ""
    echo "--- Size constraint (under 500 lines) ---"
    SYNC_LINE_COUNT=$(wc -l < "$SYNC_FILE")
    if [ "$SYNC_LINE_COUNT" -lt 500 ]; then
        pass "syncing-forge: under 500 lines ($SYNC_LINE_COUNT lines)"
    else
        fail "syncing-forge: exceeds 500 lines ($SYNC_LINE_COUNT lines) — Anthropic limit"
    fi

    # ---- No superpowers: prefix ----
    echo ""
    echo "--- No superpowers: prefix ---"
    if grep -qE "superpowers:" "$SYNC_FILE"; then
        fail "syncing-forge: uses superpowers: prefix (should use forge:)"
    else
        pass "syncing-forge: no superpowers: prefix"
    fi

    # ---- No .superpowers/ path references ----
    echo ""
    echo "--- No .superpowers/ path references ---"
    if grep -q "\.superpowers/" "$SYNC_FILE"; then
        fail "syncing-forge: references .superpowers/ (should use .forge/)"
    else
        pass "syncing-forge: no .superpowers/ references"
    fi

    # ---- References CLAUDE.md regeneration ----
    echo ""
    echo "--- CLAUDE.md regeneration ---"
    if grep -qiE "CLAUDE\.md.*regen|regen.*CLAUDE\.md|CLAUDE\.md.*updat|updat.*CLAUDE\.md|generate.*CLAUDE\.md|CLAUDE\.md.*generate" "$SYNC_FILE"; then
        pass "syncing-forge: references CLAUDE.md regeneration"
    else
        fail "syncing-forge: must reference CLAUDE.md regeneration"
    fi

    # ---- References project.yaml scanning ----
    echo ""
    echo "--- project.yaml scanning ---"
    if grep -qiE "project\.yaml.*scan|scan.*project\.yaml|project\.yaml.*read|read.*project\.yaml|project\.yaml" "$SYNC_FILE"; then
        pass "syncing-forge: references project.yaml scanning"
    else
        fail "syncing-forge: must reference project.yaml scanning"
    fi

    # ---- References pack update checking ----
    echo ""
    echo "--- Pack update checking ---"
    if grep -qiE "pack.*updat|updat.*pack|pack.*check|check.*pack|pack.*sync|sync.*pack" "$SYNC_FILE"; then
        pass "syncing-forge: references pack update checking"
    else
        fail "syncing-forge: must reference pack update checking"
    fi
fi

# ===========================================================
# PART 2: diagnosing-forge
# ===========================================================
echo ""
echo "=========================================="
echo "PART 2: diagnosing-forge"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$DIAG_FILE" ]; then
    pass "diagnosing-forge/SKILL.md exists"
else
    fail "diagnosing-forge/SKILL.md not found"
fi

if [ -f "$DIAG_FILE" ]; then
    # ---- Frontmatter ----
    echo ""
    echo "--- Frontmatter ---"
    DIAG_FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$DIAG_FILE")

    if echo "$DIAG_FM" | grep -q "^name: diagnosing-forge$"; then
        pass "diagnosing-forge: frontmatter has name: diagnosing-forge"
    else
        fail "diagnosing-forge: frontmatter missing 'name: diagnosing-forge'"
    fi

    DIAG_DESC_LINE=$(echo "$DIAG_FM" | grep "^description:")
    if [ -n "$DIAG_DESC_LINE" ]; then
        DIAG_DESC_VALUE=$(echo "$DIAG_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$DIAG_DESC_VALUE" | grep -qi "^Use when"; then
            pass "diagnosing-forge: description starts with 'Use when'"
        else
            fail "diagnosing-forge: description must start with 'Use when'; got: '$DIAG_DESC_VALUE'"
        fi
    else
        fail "diagnosing-forge: frontmatter missing 'description' field"
    fi

    # ---- Size constraint ----
    echo ""
    echo "--- Size constraint (under 500 lines) ---"
    DIAG_LINE_COUNT=$(wc -l < "$DIAG_FILE")
    if [ "$DIAG_LINE_COUNT" -lt 500 ]; then
        pass "diagnosing-forge: under 500 lines ($DIAG_LINE_COUNT lines)"
    else
        fail "diagnosing-forge: exceeds 500 lines ($DIAG_LINE_COUNT lines) — Anthropic limit"
    fi

    # ---- No superpowers: prefix ----
    echo ""
    echo "--- No superpowers: prefix ---"
    if grep -qE "superpowers:" "$DIAG_FILE"; then
        fail "diagnosing-forge: uses superpowers: prefix (should use forge:)"
    else
        pass "diagnosing-forge: no superpowers: prefix"
    fi

    # ---- No .superpowers/ path references ----
    echo ""
    echo "--- No .superpowers/ path references ---"
    if grep -q "\.superpowers/" "$DIAG_FILE"; then
        fail "diagnosing-forge: references .superpowers/ (should use .forge/)"
    else
        pass "diagnosing-forge: no .superpowers/ references"
    fi

    # ---- References directory structure check ----
    echo ""
    echo "--- Directory structure check ---"
    if grep -qiE "directory.*structur|structur.*check|\.forge/.*director|check.*director" "$DIAG_FILE"; then
        pass "diagnosing-forge: references directory structure check"
    else
        fail "diagnosing-forge: must reference directory structure checking"
    fi

    # ---- References project.yaml validation ----
    echo ""
    echo "--- project.yaml validation ---"
    if grep -qiE "project\.yaml.*valid|valid.*project\.yaml|project\.yaml.*check|check.*project\.yaml|project\.yaml" "$DIAG_FILE"; then
        pass "diagnosing-forge: references project.yaml validation"
    else
        fail "diagnosing-forge: must reference project.yaml validation"
    fi

    # ---- References hook installation check ----
    echo ""
    echo "--- Hook installation check ---"
    if grep -qiE "hook.*install|install.*hook|hook.*check|check.*hook|hook.*verif|verif.*hook" "$DIAG_FILE"; then
        pass "diagnosing-forge: references hook installation check"
    else
        fail "diagnosing-forge: must reference hook installation checking"
    fi

    # ---- References storage health ----
    echo ""
    echo "--- Storage health ---"
    if grep -qiE "storage.*health|health.*storage|forge-state.*health|state.*integrit|storage.*check|check.*storage" "$DIAG_FILE"; then
        pass "diagnosing-forge: references storage health check"
    else
        fail "diagnosing-forge: must reference storage health checking"
    fi
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

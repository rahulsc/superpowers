#!/usr/bin/env bash
# Test: Task 19 — Forge workflow visualization server.
# Checks SKILL.md, server.js, start-server.sh existence and content requirements.
# RED phase: fails until Task 19 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"

SKILL_FILE="$ROOT/skills/forge-viz/SKILL.md"
SERVER_FILE="$ROOT/skills/forge-viz/scripts/server.js"
START_SCRIPT="$ROOT/skills/forge-viz/scripts/start-server.sh"

echo "=== test-forge-viz: Wave 7 Task 19 ==="
echo ""

# ===========================================================
# PART 1: SKILL.md existence and content
# ===========================================================
echo "=========================================="
echo "PART 1: forge-viz/SKILL.md"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "forge-viz/SKILL.md exists"
else
    fail "forge-viz/SKILL.md not found"
fi

if [ -f "$SKILL_FILE" ]; then
    # ---- Frontmatter ----
    echo ""
    echo "--- Frontmatter ---"
    SKILL_FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SKILL_FILE")

    if echo "$SKILL_FM" | grep -q "^name: forge-viz$"; then
        pass "forge-viz: frontmatter has name: forge-viz"
    else
        fail "forge-viz: frontmatter missing 'name: forge-viz'"
    fi

    SKILL_DESC_LINE=$(echo "$SKILL_FM" | grep "^description:")
    if [ -n "$SKILL_DESC_LINE" ]; then
        SKILL_DESC_VALUE=$(echo "$SKILL_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$SKILL_DESC_VALUE" | grep -qi "^Use when"; then
            pass "forge-viz: description starts with 'Use when'"
        else
            fail "forge-viz: description must start with 'Use when'; got: '$SKILL_DESC_VALUE'"
        fi
    else
        fail "forge-viz: frontmatter missing 'description' field"
    fi

    # ---- Size constraint ----
    echo ""
    echo "--- Size constraint (under 500 lines) ---"
    SKILL_LINE_COUNT=$(wc -l < "$SKILL_FILE")
    if [ "$SKILL_LINE_COUNT" -lt 500 ]; then
        pass "forge-viz: SKILL.md under 500 lines ($SKILL_LINE_COUNT lines)"
    else
        fail "forge-viz: SKILL.md exceeds 500 lines ($SKILL_LINE_COUNT lines) — Anthropic limit"
    fi

    # ---- No superpowers: prefix ----
    echo ""
    echo "--- No superpowers: prefix ---"
    if grep -qE "superpowers:" "$SKILL_FILE"; then
        fail "forge-viz: uses superpowers: prefix (should use forge:)"
    else
        pass "forge-viz: no superpowers: prefix"
    fi

    # ---- No .superpowers/ path references ----
    echo ""
    echo "--- No .superpowers/ path references ---"
    if grep -q "\.superpowers/" "$SKILL_FILE"; then
        fail "forge-viz: references .superpowers/ (should use .forge/)"
    else
        pass "forge-viz: no .superpowers/ references"
    fi
fi

# ===========================================================
# PART 2: server.js
# ===========================================================
echo ""
echo "=========================================="
echo "PART 2: forge-viz/scripts/server.js"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$SERVER_FILE" ]; then
    pass "forge-viz/scripts/server.js exists"
else
    fail "forge-viz/scripts/server.js not found"
fi

if [ -f "$SERVER_FILE" ]; then
    # ---- Uses WebSocket ----
    echo ""
    echo "--- WebSocket support ---"
    if grep -qiE "WebSocket|websocket|ws\.Server|wss\.Server|upgrade" "$SERVER_FILE"; then
        pass "server.js: contains WebSocket support"
    else
        fail "server.js: must use WebSocket for live updates (expected 'WebSocket' or 'upgrade')"
    fi

    # ---- Watches .forge/local/ ----
    echo ""
    echo "--- Watches .forge/ directory ---"
    WATCH_HIT=0
    grep -qiE "watch|chokidar|fs\.watch|inotify" "$SERVER_FILE" && WATCH_HIT=$((WATCH_HIT + 1))
    grep -qE "\.forge" "$SERVER_FILE" && WATCH_HIT=$((WATCH_HIT + 1))
    if [ "$WATCH_HIT" -ge 2 ]; then
        pass "server.js: watches .forge/ directory"
    else
        fail "server.js: must watch .forge/ directory for state changes (expected 'watch' + '.forge')"
    fi

    # ---- Has idle timeout ----
    echo ""
    echo "--- Idle timeout ---"
    if grep -qiE "timeout|idle|auto.?shutdown|inactiv|TTL" "$SERVER_FILE"; then
        pass "server.js: has idle timeout / auto-shutdown logic"
    else
        fail "server.js: must have idle timeout to auto-shutdown when unused"
    fi
fi

# ===========================================================
# PART 3: start-server.sh
# ===========================================================
echo ""
echo "=========================================="
echo "PART 3: forge-viz/scripts/start-server.sh"
echo "=========================================="

# ---- Existence ----
echo ""
echo "--- File existence ---"
if [ -f "$START_SCRIPT" ]; then
    pass "forge-viz/scripts/start-server.sh exists"
else
    fail "forge-viz/scripts/start-server.sh not found"
fi

if [ -f "$START_SCRIPT" ]; then
    # ---- Is executable or has shebang ----
    echo ""
    echo "--- Executable / shebang ---"
    if [ -x "$START_SCRIPT" ] || head -1 "$START_SCRIPT" | grep -q "^#!/"; then
        pass "start-server.sh: is executable or has shebang"
    else
        fail "start-server.sh: must be executable or have a shebang line"
    fi
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1

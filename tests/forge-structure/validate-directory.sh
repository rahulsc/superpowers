#!/usr/bin/env bash
# Test: .forge/ directory structure exists with required files

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

check_file_exists() {
    local label="$1"
    local path="$2"
    if [ -f "$path" ]; then
        pass "$label"
    else
        fail "$label — expected file: $path"
    fi
}

check_dir_exists() {
    local label="$1"
    local path="$2"
    if [ -d "$path" ]; then
        pass "$label"
    else
        fail "$label — expected directory: $path"
    fi
}

# Use the actual project root (not a temp dir) since we're testing repo structure
FORGE_ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge"

echo "=== validate-directory: .forge/ directory structure ==="
echo "Checking: $FORGE_ROOT"
echo ""

echo "--- Core directory structure ---"
check_dir_exists ".forge/ root directory" "$FORGE_ROOT"
check_dir_exists ".forge/policies/" "$FORGE_ROOT/policies"
check_dir_exists ".forge/workflows/" "$FORGE_ROOT/workflows"
check_dir_exists ".forge/packs/" "$FORGE_ROOT/packs"
check_dir_exists ".forge/adapters/" "$FORGE_ROOT/adapters"
check_dir_exists ".forge/shared/" "$FORGE_ROOT/shared"
check_dir_exists ".forge/shared/decisions/" "$FORGE_ROOT/shared/decisions"
check_dir_exists ".forge/local/" "$FORGE_ROOT/local"
check_dir_exists ".forge/bin/" "$FORGE_ROOT/bin"

echo ""
echo "--- Required files ---"
check_file_exists ".forge/project.yaml" "$FORGE_ROOT/project.yaml"
check_file_exists ".forge/policies/default.yaml" "$FORGE_ROOT/policies/default.yaml"
check_file_exists ".forge/workflows/example.yaml" "$FORGE_ROOT/workflows/example.yaml"
check_file_exists ".forge/packs/.gitkeep" "$FORGE_ROOT/packs/.gitkeep"
check_file_exists ".forge/adapters/.gitkeep" "$FORGE_ROOT/adapters/.gitkeep"
check_file_exists ".forge/shared/architecture.md" "$FORGE_ROOT/shared/architecture.md"
check_file_exists ".forge/shared/conventions.md" "$FORGE_ROOT/shared/conventions.md"
check_file_exists ".forge/shared/decisions/000-template.md" "$FORGE_ROOT/shared/decisions/000-template.md"
check_file_exists ".forge/local/.gitignore" "$FORGE_ROOT/local/.gitignore"

echo ""
echo "--- local/ is git-ignored ---"
# Check that .forge/local/ contents are gitignored
GITIGNORE_PATH="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/local/.gitignore"
if [ -f "$GITIGNORE_PATH" ]; then
    if grep -q '\*' "$GITIGNORE_PATH" 2>/dev/null || grep -q '\.db' "$GITIGNORE_PATH" 2>/dev/null; then
        pass ".forge/local/.gitignore ignores local state files"
    else
        fail ".forge/local/.gitignore exists but doesn't ignore local state files"
    fi
else
    fail ".forge/local/.gitignore missing — local state files would be committed"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0

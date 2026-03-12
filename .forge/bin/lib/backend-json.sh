#!/usr/bin/env bash
# JSON backend implementation for forge-state
# Provides: json_init, json_get, json_set, json_memory_add, json_memory_query,
#           json_evidence_add, json_evidence_list
#
# Requires python3 for correctness. Falls back to grep/sed for read-only ops
# on simple ASCII values only. All writes require python3.

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_require_python3() {
    if ! command -v python3 &>/dev/null; then
        printf 'error: python3 is required for JSON backend writes\n' >&2
        return 1
    fi
}

# --- Init ---

json_init() {
    local project_dir="$1"
    local local_dir="$project_dir/.forge/local"
    mkdir -p "$local_dir/memory"
    mkdir -p "$local_dir/evidence"

    # Create state.json atomically if absent
    if [ ! -f "$local_dir/state.json" ]; then
        local tmp
        tmp=$(mktemp "${local_dir}/state.json.XXXXXX")
        printf '{}' > "$tmp"
        mv "$tmp" "$local_dir/state.json"
    fi

    # Create .gitignore
    if [ ! -f "$local_dir/.gitignore" ]; then
        printf '*\n' > "$local_dir/.gitignore"
    fi
}

# --- State get/set ---

json_get() {
    local project_dir="$1"
    local key="$2"
    local state_file="$project_dir/.forge/local/state.json"

    if [ ! -f "$state_file" ]; then
        printf 'error: state not initialized (run forge-state init)\n' >&2
        return 1
    fi

    # C1 fix: pass file path as argv, not interpolated into Python source
    if command -v python3 &>/dev/null; then
        local val rc
        val=$(python3 - "$state_file" "$key" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
key = sys.argv[2]
if key not in data:
    sys.exit(1)
print(data[key], end='')
PYEOF
        )
        rc=$?
        if [ $rc -ne 0 ]; then
            printf 'error: key not found: %s\n' "$key" >&2
            return 1
        fi
        printf '%s' "$val"
        return 0
    fi

    # Fallback (no python3): grep-based — safe only for simple ASCII values
    # M2 fix: make limitation explicit; values containing " may be truncated
    local escaped_key
    escaped_key=$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local line
    line=$(grep -m1 "\"${escaped_key}\"" "$state_file" 2>/dev/null)
    if [ -z "$line" ]; then
        printf 'error: key not found: %s\n' "$key" >&2
        return 1
    fi
    printf '%s' "$line" | sed 's/.*"'"${escaped_key}"'": *"\(.*\)".*/\1/' \
        | sed 's/\\n/\n/g; s/\\t/\t/g; s/\\"/"/g; s/\\\\/\\/g'
}

json_set() {
    local project_dir="$1"
    local key="$2"
    local value="$3"
    local state_file="$project_dir/.forge/local/state.json"

    if [ ! -f "$state_file" ]; then
        local tmp0
        tmp0=$(mktemp "${state_file}.XXXXXX")
        printf '{}' > "$tmp0"
        mv "$tmp0" "$state_file"
    fi

    # C1 fix: pass file path as argv; M3 fix: write atomically via temp file
    if command -v python3 &>/dev/null; then
        local tmp
        tmp=$(mktemp "${state_file}.XXXXXX")
        python3 - "$state_file" "$key" "$value" "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
data[sys.argv[2]] = sys.argv[3]
with open(sys.argv[4], 'w') as f:
    json.dump(data, f, indent=2)
PYEOF
        local rc=$?
        if [ $rc -eq 0 ]; then
            mv "$tmp" "$state_file"
        else
            rm -f "$tmp"
            return $rc
        fi
        return 0
    fi

    # Fallback (no python3): limited sed-based approach
    local esc_key esc_val
    esc_key=$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g; s/"/\\"/g')
    esc_val=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')

    local tmp content
    tmp=$(mktemp "${state_file}.XXXXXX")
    grep -v "\"${esc_key}\":" "$state_file" > "$tmp" 2>/dev/null || printf '{}' > "$tmp"

    content=$(cat "$tmp")
    if printf '%s' "$content" | grep -q '^\s*{}'; then
        printf '{\n  "%s": "%s"\n}\n' "$esc_key" "$esc_val" > "$tmp"
    else
        content="${content%\}}"
        content=$(printf '%s' "$content" | sed 's/[,[:space:]]*$//')
        printf '%s,\n  "%s": "%s"\n}\n' "$content" "$esc_key" "$esc_val" > "$tmp"
    fi
    mv "$tmp" "$state_file"
}

# --- Memory ---

json_memory_add() {
    local project_dir="$1"
    local type="$2"
    local content="$3"
    local memory_dir="$project_dir/.forge/local/memory"
    local memory_file="$memory_dir/${type}.json"

    mkdir -p "$memory_dir"

    if [ ! -f "$memory_file" ]; then
        local tmp0
        tmp0=$(mktemp "${memory_file}.XXXXXX")
        printf '[]' > "$tmp0"
        mv "$tmp0" "$memory_file"
    fi

    local ts
    ts=$(_timestamp)

    # C1 fix: pass file paths and values as argv; M3 fix: atomic write via temp file
    if command -v python3 &>/dev/null; then
        local tmp
        tmp=$(mktemp "${memory_file}.XXXXXX")
        python3 - "$memory_file" "$content" "$ts" "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    entries = json.load(f)
entries.append({
    'content': sys.argv[2],
    'confidence': 1.0,
    'created_at': sys.argv[3]
})
with open(sys.argv[4], 'w') as f:
    json.dump(entries, f, indent=2)
PYEOF
        local rc=$?
        if [ $rc -eq 0 ]; then
            mv "$tmp" "$memory_file"
        else
            rm -f "$tmp"
            return $rc
        fi
        return 0
    fi

    # Fallback (no python3): manual append
    local esc_content
    esc_content=$(printf '%s' "$content" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local existing
    existing=$(cat "$memory_file")
    local tmp
    tmp=$(mktemp "${memory_file}.XXXXXX")

    if printf '%s' "$existing" | grep -q '^\s*\[\s*\]'; then
        printf '[\n  {"content": "%s", "confidence": 1.0, "created_at": "%s"}\n]\n' \
            "$esc_content" "$ts" > "$tmp"
    else
        existing="${existing%\]}"
        existing=$(printf '%s' "$existing" | sed 's/[[:space:]]*$//')
        printf '%s,\n  {"content": "%s", "confidence": 1.0, "created_at": "%s"}\n]\n' \
            "$existing" "$esc_content" "$ts" > "$tmp"
    fi
    mv "$tmp" "$memory_file"
}

json_memory_query() {
    local project_dir="$1"
    local type="$2"
    local similar="${3:-}"
    local memory_file="$project_dir/.forge/local/memory/${type}.json"

    if [ ! -f "$memory_file" ]; then
        return 0
    fi

    # C1 fix: pass file path as argv
    if command -v python3 &>/dev/null; then
        python3 - "$memory_file" "$similar" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    entries = json.load(f)
similar = sys.argv[2] if len(sys.argv) > 2 else ''
entries = list(reversed(entries))
if similar:
    keywords = similar.lower().split()
    entries = [e for e in entries if any(kw in e.get('content','').lower() for kw in keywords)]
for e in entries:
    print(e.get('content', ''))
PYEOF
        return 0
    fi

    # Fallback: extract content fields (may truncate values with ")
    grep '"content"' "$memory_file" | sed 's/.*"content": *"\(.*\)".*/\1/' | tac
}

# --- Evidence ---

json_evidence_add() {
    local project_dir="$1"
    local task_id="$2"
    local artifact="$3"
    local evidence_dir="$project_dir/.forge/local/evidence"
    local evidence_file="$evidence_dir/${task_id}.json"

    mkdir -p "$evidence_dir"

    if [ ! -f "$evidence_file" ]; then
        local tmp0
        tmp0=$(mktemp "${evidence_file}.XXXXXX")
        printf '[]' > "$tmp0"
        mv "$tmp0" "$evidence_file"
    fi

    local ts
    ts=$(_timestamp)

    # C1 fix: pass file paths and values as argv; M3 fix: atomic write via temp file
    if command -v python3 &>/dev/null; then
        local tmp
        tmp=$(mktemp "${evidence_file}.XXXXXX")
        python3 - "$evidence_file" "$artifact" "$ts" "$tmp" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    entries = json.load(f)
entries.append({
    'artifact': sys.argv[2],
    'created_at': sys.argv[3]
})
with open(sys.argv[4], 'w') as f:
    json.dump(entries, f, indent=2)
PYEOF
        local rc=$?
        if [ $rc -eq 0 ]; then
            mv "$tmp" "$evidence_file"
        else
            rm -f "$tmp"
            return $rc
        fi
        return 0
    fi

    # Fallback (no python3): manual append
    local esc_artifact
    esc_artifact=$(printf '%s' "$artifact" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local existing
    existing=$(cat "$evidence_file")
    local tmp
    tmp=$(mktemp "${evidence_file}.XXXXXX")

    if printf '%s' "$existing" | grep -q '^\s*\[\s*\]'; then
        printf '[\n  {"artifact": "%s", "created_at": "%s"}\n]\n' \
            "$esc_artifact" "$ts" > "$tmp"
    else
        existing="${existing%\]}"
        existing=$(printf '%s' "$existing" | sed 's/[[:space:]]*$//')
        printf '%s,\n  {"artifact": "%s", "created_at": "%s"}\n]\n' \
            "$existing" "$esc_artifact" "$ts" > "$tmp"
    fi
    mv "$tmp" "$evidence_file"
}

json_evidence_list() {
    local project_dir="$1"
    local task_id="$2"
    local evidence_file="$project_dir/.forge/local/evidence/${task_id}.json"

    if [ ! -f "$evidence_file" ]; then
        return 0
    fi

    # C1 fix: pass file path as argv
    if command -v python3 &>/dev/null; then
        python3 - "$evidence_file" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    entries = json.load(f)
for e in entries:
    print(e.get('artifact', ''))
PYEOF
        return 0
    fi

    # Fallback: extract artifact fields
    grep '"artifact"' "$evidence_file" | sed 's/.*"artifact": *"\(.*\)".*/\1/'
}

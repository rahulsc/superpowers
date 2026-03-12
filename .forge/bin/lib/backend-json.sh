#!/usr/bin/env bash
# JSON backend implementation for forge-state
# Provides: json_init, json_get, json_set, json_memory_add, json_memory_query,
#           json_evidence_add, json_evidence_list

# Ensure jq is not required — use only bash builtins and basic tools (grep, sed, awk)

# --- Helpers ---

_json_escape() {
    # Escape a string for JSON embedding
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

_json_unescape() {
    # Unescape a JSON string value (basic)
    local s="$1"
    # Use printf to handle common escape sequences
    printf '%b' "${s//\\\"/\"}"
}

_json_read_value() {
    # Read a value for a key from a simple flat JSON object { "key": "value", ... }
    # Uses grep/sed — safe for single-level string values
    local file="$1"
    local key="$2"
    # Escape key for regex
    local escaped_key
    escaped_key=$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
    # Match: "key": "value" — value is everything between the quotes
    local raw
    raw=$(grep -m1 "\"${escaped_key}\"" "$file" | sed 's/.*"'"${escaped_key}"'": *"\(.*\)".*/\1/')
    # Unescape \n \t \" \\
    printf '%s' "$raw" | sed 's/\\n/\n/g; s/\\t/\t/g; s/\\"/"/g; s/\\\\/\\/g'
}

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# --- Init ---

json_init() {
    local project_dir="$1"
    local local_dir="$project_dir/.forge/local"
    mkdir -p "$local_dir/memory"
    mkdir -p "$local_dir/evidence"

    # Create state.json if absent
    if [ ! -f "$local_dir/state.json" ]; then
        printf '{}' > "$local_dir/state.json"
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

    # Use python3 if available for reliable JSON parsing, else fallback to sed
    if command -v python3 &>/dev/null; then
        local val
        val=$(python3 -c "
import json, sys
with open('$state_file') as f:
    data = json.load(f)
key = sys.argv[1]
if key not in data:
    sys.exit(1)
print(data[key], end='')
" "$key" 2>/dev/null)
        local rc=$?
        if [ $rc -ne 0 ]; then
            printf 'error: key not found: %s\n' "$key" >&2
            return 1
        fi
        printf '%s' "$val"
        return 0
    fi

    # Fallback: grep-based (works for simple string values without embedded quotes)
    local escaped_key
    escaped_key=$(printf '%s' "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
    local line
    line=$(grep -m1 "\"${escaped_key}\"" "$state_file" 2>/dev/null)
    if [ -z "$line" ]; then
        printf 'error: key not found: %s\n' "$key" >&2
        return 1
    fi
    local val
    val=$(printf '%s' "$line" | sed 's/.*"'"${escaped_key}"'": *"\(.*\)".*/\1/')
    printf '%s' "$val" | sed 's/\\n/\n/g; s/\\t/\t/g; s/\\"/"/g; s/\\\\/\\/g'
}

json_set() {
    local project_dir="$1"
    local key="$2"
    local value="$3"
    local state_file="$project_dir/.forge/local/state.json"

    if [ ! -f "$state_file" ]; then
        printf '{}' > "$state_file"
    fi

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$state_file') as f:
    data = json.load(f)
key = sys.argv[1]
val = sys.argv[2]
data[key] = val
with open('$state_file', 'w') as f:
    json.dump(data, f, indent=2)
" "$key" "$value" 2>/dev/null
        return $?
    fi

    # Fallback: reconstruct JSON with sed (limited but functional for simple values)
    local esc_key esc_val
    esc_key=$(_json_escape "$key")
    esc_val=$(_json_escape "$value")

    local tmp
    tmp=$(mktemp)
    # Remove existing key line if present (simple approach)
    grep -v "\"${esc_key}\":" "$state_file" > "$tmp" 2>/dev/null || printf '{}' > "$tmp"

    # Read current content, strip trailing } and whitespace, inject new key
    local content
    content=$(cat "$tmp")
    # If empty object
    if printf '%s' "$content" | grep -q '^\s*{}'; then
        printf '{\n  "%s": "%s"\n}\n' "$esc_key" "$esc_val" > "$state_file"
    else
        # Insert before closing brace
        # Remove trailing }
        content="${content%\}}"
        # Trim trailing comma and whitespace from last entry
        content=$(printf '%s' "$content" | sed 's/[,[:space:]]*$//')
        printf '%s,\n  "%s": "%s"\n}\n' "$content" "$esc_key" "$esc_val" > "$state_file"
    fi
    rm -f "$tmp"
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
        printf '[]' > "$memory_file"
    fi

    local ts
    ts=$(_timestamp)

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$memory_file') as f:
    entries = json.load(f)
entries.append({
    'content': sys.argv[1],
    'confidence': 1.0,
    'created_at': sys.argv[2]
})
with open('$memory_file', 'w') as f:
    json.dump(entries, f, indent=2)
" "$content" "$ts" 2>/dev/null
        return $?
    fi

    # Fallback: append JSON entry manually
    local esc_content
    esc_content=$(_json_escape "$content")
    local existing
    existing=$(cat "$memory_file")

    if printf '%s' "$existing" | grep -q '^\s*\[\s*\]'; then
        printf '[\n  {"content": "%s", "confidence": 1.0, "created_at": "%s"}\n]\n' \
            "$esc_content" "$ts" > "$memory_file"
    else
        # Remove trailing ]
        existing="${existing%\]}"
        existing=$(printf '%s' "$existing" | sed 's/[[:space:]]*$//')
        printf '%s,\n  {"content": "%s", "confidence": 1.0, "created_at": "%s"}\n]\n' \
            "$existing" "$esc_content" "$ts" > "$memory_file"
    fi
}

json_memory_query() {
    local project_dir="$1"
    local type="$2"
    local similar="${3:-}"
    local memory_file="$project_dir/.forge/local/memory/${type}.json"

    if [ ! -f "$memory_file" ]; then
        # No entries — exit 0 with empty output
        return 0
    fi

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$memory_file') as f:
    entries = json.load(f)
similar = sys.argv[1] if len(sys.argv) > 1 else ''
# Reverse for newest first
entries = list(reversed(entries))
if similar:
    keywords = similar.lower().split()
    entries = [e for e in entries if any(kw in e.get('content','').lower() for kw in keywords)]
for e in entries:
    print(e.get('content', ''))
" "${similar}" 2>/dev/null
        return 0
    fi

    # Fallback: extract content fields
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
        printf '[]' > "$evidence_file"
    fi

    local ts
    ts=$(_timestamp)

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$evidence_file') as f:
    entries = json.load(f)
entries.append({
    'artifact': sys.argv[1],
    'created_at': sys.argv[2]
})
with open('$evidence_file', 'w') as f:
    json.dump(entries, f, indent=2)
" "$artifact" "$ts" 2>/dev/null
        return $?
    fi

    # Fallback: append entry manually
    local esc_artifact
    esc_artifact=$(_json_escape "$artifact")
    local existing
    existing=$(cat "$evidence_file")

    if printf '%s' "$existing" | grep -q '^\s*\[\s*\]'; then
        printf '[\n  {"artifact": "%s", "created_at": "%s"}\n]\n' \
            "$esc_artifact" "$ts" > "$evidence_file"
    else
        existing="${existing%\]}"
        existing=$(printf '%s' "$existing" | sed 's/[[:space:]]*$//')
        printf '%s,\n  {"artifact": "%s", "created_at": "%s"}\n]\n' \
            "$existing" "$esc_artifact" "$ts" > "$evidence_file"
    fi
}

json_evidence_list() {
    local project_dir="$1"
    local task_id="$2"
    local evidence_file="$project_dir/.forge/local/evidence/${task_id}.json"

    if [ ! -f "$evidence_file" ]; then
        # No evidence — exit 0, empty output
        return 0
    fi

    if command -v python3 &>/dev/null; then
        python3 -c "
import json
with open('$evidence_file') as f:
    entries = json.load(f)
for e in entries:
    print(e.get('artifact', ''))
" 2>/dev/null
        return 0
    fi

    # Fallback: extract artifact fields
    grep '"artifact"' "$evidence_file" | sed 's/.*"artifact": *"\(.*\)".*/\1/'
}

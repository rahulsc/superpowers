#!/usr/bin/env bash
# SQLite backend implementation for forge-state
# Requires: sqlite3 on PATH
# Provides: sqlite_init, sqlite_get, sqlite_set, sqlite_memory_add, sqlite_memory_query,
#           sqlite_evidence_add, sqlite_evidence_list

_sqlite_db() {
    local project_dir="$1"
    printf '%s/.forge/local/forge.sqlite' "$project_dir"
}

_sqlite3() {
    local db="$1"
    shift
    sqlite3 "$db" "$@"
}

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# --- Init ---

sqlite_init() {
    local project_dir="$1"
    local local_dir="$project_dir/.forge/local"
    mkdir -p "$local_dir"

    local db
    db=$(_sqlite_db "$project_dir")

    # Create tables (idempotent)
    sqlite3 "$db" "
CREATE TABLE IF NOT EXISTS state (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at TEXT
);
CREATE TABLE IF NOT EXISTS memory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,
    content TEXT,
    confidence REAL,
    source TEXT,
    created_at TEXT
);
CREATE TABLE IF NOT EXISTS evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT,
    artifact TEXT,
    created_at TEXT
);
" 2>/dev/null

    # Create .gitignore
    if [ ! -f "$local_dir/.gitignore" ]; then
        printf '*\n' > "$local_dir/.gitignore"
    fi
}

# --- State get/set ---

sqlite_get() {
    local project_dir="$1"
    local key="$2"
    local db
    db=$(_sqlite_db "$project_dir")

    local val
    val=$(sqlite3 "$db" "SELECT value FROM state WHERE key = $(printf "'%s'" "$(printf '%s' "$key" | sed "s/'/''/g")") LIMIT 1;" 2>/dev/null)

    if [ -z "$val" ]; then
        # Check if key truly doesn't exist (vs empty value)
        local count
        count=$(sqlite3 "$db" "SELECT COUNT(*) FROM state WHERE key = $(printf "'%s'" "$(printf '%s' "$key" | sed "s/'/''/g")");" 2>/dev/null)
        if [ "$count" = "0" ] || [ -z "$count" ]; then
            printf 'error: key not found: %s\n' "$key" >&2
            return 1
        fi
    fi

    printf '%s' "$val"
}

sqlite_set() {
    local project_dir="$1"
    local key="$2"
    local value="$3"
    local db
    db=$(_sqlite_db "$project_dir")
    local ts
    ts=$(_timestamp)

    # Escape single quotes for SQL
    local esc_key esc_val
    esc_key=$(printf '%s' "$key" | sed "s/'/''/g")
    esc_val=$(printf '%s' "$value" | sed "s/'/''/g")
    local esc_ts
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")

    sqlite3 "$db" "INSERT OR REPLACE INTO state (key, value, updated_at) VALUES ('${esc_key}', '${esc_val}', '${esc_ts}');" 2>/dev/null
}

# --- Memory ---

sqlite_memory_add() {
    local project_dir="$1"
    local type="$2"
    local content="$3"
    local db
    db=$(_sqlite_db "$project_dir")
    local ts
    ts=$(_timestamp)

    local esc_type esc_content esc_ts
    esc_type=$(printf '%s' "$type" | sed "s/'/''/g")
    esc_content=$(printf '%s' "$content" | sed "s/'/''/g")
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")

    sqlite3 "$db" "INSERT INTO memory (type, content, confidence, source, created_at) VALUES ('${esc_type}', '${esc_content}', 1.0, '', '${esc_ts}');" 2>/dev/null
}

sqlite_memory_query() {
    local project_dir="$1"
    local type="$2"
    local similar="${3:-}"
    local db
    db=$(_sqlite_db "$project_dir")

    local esc_type
    esc_type=$(printf '%s' "$type" | sed "s/'/''/g")

    if [ -n "$similar" ]; then
        local esc_similar
        esc_similar=$(printf '%s' "$similar" | sed "s/'/''/g")
        sqlite3 "$db" "SELECT content FROM memory WHERE type = '${esc_type}' AND content LIKE '%${esc_similar}%' ORDER BY id DESC;" 2>/dev/null
    else
        sqlite3 "$db" "SELECT content FROM memory WHERE type = '${esc_type}' ORDER BY id DESC;" 2>/dev/null
    fi
}

# --- Evidence ---

sqlite_evidence_add() {
    local project_dir="$1"
    local task_id="$2"
    local artifact="$3"
    local db
    db=$(_sqlite_db "$project_dir")
    local ts
    ts=$(_timestamp)

    local esc_task esc_artifact esc_ts
    esc_task=$(printf '%s' "$task_id" | sed "s/'/''/g")
    esc_artifact=$(printf '%s' "$artifact" | sed "s/'/''/g")
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")

    sqlite3 "$db" "INSERT INTO evidence (task_id, artifact, created_at) VALUES ('${esc_task}', '${esc_artifact}', '${esc_ts}');" 2>/dev/null
}

sqlite_evidence_list() {
    local project_dir="$1"
    local task_id="$2"
    local db
    db=$(_sqlite_db "$project_dir")

    local esc_task
    esc_task=$(printf '%s' "$task_id" | sed "s/'/''/g")

    sqlite3 "$db" "SELECT artifact FROM evidence WHERE task_id = '${esc_task}' ORDER BY id ASC;" 2>/dev/null
}

#!/usr/bin/env bash
# SQLite backend implementation for forge-state
# Requires: sqlite3 on PATH
# Provides: sqlite_init, sqlite_get, sqlite_set, sqlite_memory_add, sqlite_memory_query,
#           sqlite_evidence_add, sqlite_evidence_list
#
# C2 fix: uses python3 with sqlite3 module for properly parameterized queries,
# avoiding SQL injection from shell string interpolation.
# Falls back to sqlite3 CLI with careful quoting when python3 is absent.

_sqlite_db() {
    local project_dir="$1"
    printf '%s/.forge/local/forge.sqlite' "$project_dir"
}

_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Run SQL with python3 sqlite3 module (parameterized) if available,
# else fall back to sqlite3 CLI with single-quote escaping.
# Usage: _sqlite_exec <db> <sql_template> [bind_values...]
# This helper is only used for simple single-statement queries internally.

# --- Init ---

sqlite_init() {
    local project_dir="$1"
    local local_dir="$project_dir/.forge/local"
    mkdir -p "$local_dir"

    local db
    db=$(_sqlite_db "$project_dir")

    # Create tables (idempotent) — DDL has no user data, safe to interpolate
    if command -v python3 &>/dev/null; then
        python3 - "$db" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.executescript("""
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
""")
con.commit()
con.close()
PYEOF
    else
        sqlite3 "$db" "
CREATE TABLE IF NOT EXISTS state (key TEXT PRIMARY KEY, value TEXT, updated_at TEXT);
CREATE TABLE IF NOT EXISTS memory (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT, content TEXT, confidence REAL, source TEXT, created_at TEXT);
CREATE TABLE IF NOT EXISTS evidence (id INTEGER PRIMARY KEY AUTOINCREMENT, task_id TEXT, artifact TEXT, created_at TEXT);
"
    fi

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

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        local val rc
        val=$(python3 - "$db" "$key" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
row = con.execute('SELECT value FROM state WHERE key = ? LIMIT 1', (sys.argv[2],)).fetchone()
con.close()
if row is None:
    sys.exit(1)
print(row[0], end='')
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

    # Fallback: sqlite3 CLI with quote escaping
    local esc_key
    esc_key=$(printf '%s' "$key" | sed "s/'/''/g")
    local val
    val=$(sqlite3 "$db" "SELECT value FROM state WHERE key = '${esc_key}' LIMIT 1;")
    local count
    count=$(sqlite3 "$db" "SELECT COUNT(*) FROM state WHERE key = '${esc_key}';")
    if [ "$count" = "0" ] || [ -z "$count" ]; then
        printf 'error: key not found: %s\n' "$key" >&2
        return 1
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

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$key" "$value" "$ts" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute('INSERT OR REPLACE INTO state (key, value, updated_at) VALUES (?, ?, ?)',
            (sys.argv[2], sys.argv[3], sys.argv[4]))
con.commit()
con.close()
PYEOF
        return $?
    fi

    # Fallback: sqlite3 CLI with quote escaping
    local esc_key esc_val esc_ts
    esc_key=$(printf '%s' "$key" | sed "s/'/''/g")
    esc_val=$(printf '%s' "$value" | sed "s/'/''/g")
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")
    sqlite3 "$db" "INSERT OR REPLACE INTO state (key, value, updated_at) VALUES ('${esc_key}', '${esc_val}', '${esc_ts}');"
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

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$type" "$content" "$ts" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute('INSERT INTO memory (type, content, confidence, source, created_at) VALUES (?, ?, 1.0, \'\', ?)',
            (sys.argv[2], sys.argv[3], sys.argv[4]))
con.commit()
con.close()
PYEOF
        return $?
    fi

    # Fallback: sqlite3 CLI with quote escaping
    local esc_type esc_content esc_ts
    esc_type=$(printf '%s' "$type" | sed "s/'/''/g")
    esc_content=$(printf '%s' "$content" | sed "s/'/''/g")
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")
    sqlite3 "$db" "INSERT INTO memory (type, content, confidence, source, created_at) VALUES ('${esc_type}', '${esc_content}', 1.0, '', '${esc_ts}');"
}

sqlite_memory_query() {
    local project_dir="$1"
    local type="$2"
    local similar="${3:-}"
    local db
    db=$(_sqlite_db "$project_dir")

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$type" "$similar" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
type_ = sys.argv[2]
similar = sys.argv[3] if len(sys.argv) > 3 else ''
if similar:
    rows = con.execute(
        'SELECT content FROM memory WHERE type = ? AND content LIKE ? ORDER BY id DESC',
        (type_, f'%{similar}%')
    ).fetchall()
else:
    rows = con.execute(
        'SELECT content FROM memory WHERE type = ? ORDER BY id DESC',
        (type_,)
    ).fetchall()
con.close()
for row in rows:
    print(row[0])
PYEOF
        return 0
    fi

    # Fallback: sqlite3 CLI with quote escaping
    local esc_type
    esc_type=$(printf '%s' "$type" | sed "s/'/''/g")
    if [ -n "$similar" ]; then
        local esc_similar
        # Escape single quotes for SQL, then % and _ for LIKE wildcards
        esc_similar=$(printf '%s' "$similar" | sed "s/'/''/g; s/%/\\%/g; s/_/\\_/g")
        sqlite3 "$db" "SELECT content FROM memory WHERE type = '${esc_type}' AND content LIKE '%${esc_similar}%' ESCAPE '\\' ORDER BY id DESC;"
    else
        sqlite3 "$db" "SELECT content FROM memory WHERE type = '${esc_type}' ORDER BY id DESC;"
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

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$task_id" "$artifact" "$ts" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute('INSERT INTO evidence (task_id, artifact, created_at) VALUES (?, ?, ?)',
            (sys.argv[2], sys.argv[3], sys.argv[4]))
con.commit()
con.close()
PYEOF
        return $?
    fi

    # Fallback: sqlite3 CLI with quote escaping
    local esc_task esc_artifact esc_ts
    esc_task=$(printf '%s' "$task_id" | sed "s/'/''/g")
    esc_artifact=$(printf '%s' "$artifact" | sed "s/'/''/g")
    esc_ts=$(printf '%s' "$ts" | sed "s/'/''/g")
    sqlite3 "$db" "INSERT INTO evidence (task_id, artifact, created_at) VALUES ('${esc_task}', '${esc_artifact}', '${esc_ts}');"
}

sqlite_evidence_list() {
    local project_dir="$1"
    local task_id="$2"
    local db
    db=$(_sqlite_db "$project_dir")

    # C2 fix: use python3 with parameterized query
    if command -v python3 &>/dev/null; then
        python3 - "$db" "$task_id" <<'PYEOF'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
rows = con.execute('SELECT artifact FROM evidence WHERE task_id = ? ORDER BY id ASC', (sys.argv[2],)).fetchall()
con.close()
for row in rows:
    print(row[0])
PYEOF
        return 0
    fi

    # Fallback: sqlite3 CLI with quote escaping
    local esc_task
    esc_task=$(printf '%s' "$task_id" | sed "s/'/''/g")
    sqlite3 "$db" "SELECT artifact FROM evidence WHERE task_id = '${esc_task}' ORDER BY id ASC;"
}

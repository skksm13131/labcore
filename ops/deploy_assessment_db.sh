#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-/opt/learning-platform}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SQL_DIR="${SQL_DIR:-$REPO_DIR/src/main/resources/db}"

MYSQL_BIN="${MYSQL_BIN:-$BASE_DIR/mysql/bin/mysql}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-labcore}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"

if [[ ! -x "$MYSQL_BIN" ]]; then
  echo "mysql binary not found or not executable: $MYSQL_BIN" >&2
  echo "Set MYSQL_BIN=/path/to/mysql and retry." >&2
  exit 1
fi

run_sql() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "SQL file not found: $file" >&2
    exit 1
  fi
  echo "Running $(basename "$file")"
  "$MYSQL_BIN" \
    -u"$DB_USER" \
    -p"$DB_PASSWORD" \
    -h"$DB_HOST" \
    -P"$DB_PORT" \
    "$DB_NAME" < "$file"
}

run_sql "$SQL_DIR/assignment_module.sql"
run_sql "$SQL_DIR/migrations/202606_assignment_answer_text.sql"

if [[ "${RUN_DEMO_SEED:-0}" == "1" ]]; then
  run_sql "$SQL_DIR/seed_assessment_demo.sql"
else
  echo "Skipping demo seed data. Set RUN_DEMO_SEED=1 to import demo assessments."
fi

echo "Assessment database upgrade finished."

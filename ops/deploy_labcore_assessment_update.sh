#!/usr/bin/env bash
set -euo pipefail

PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ge 1 ]]; then
  BASE_DIR="$1"
elif [[ -d /opt/learning-platform ]]; then
  BASE_DIR=/opt/learning-platform
elif [[ -d /home/lab/apps/labcore-learning ]]; then
  BASE_DIR=/home/lab/apps/labcore-learning
else
  echo "Cannot find deployment directory."
  echo "Usage: bash deploy-update.sh /path/to/deployment"
  exit 1
fi

TS="$(date +%Y%m%d%H%M%S)"
BACKUP_DIR="$BASE_DIR/backup/assessment-$TS"
LOG_DIR="$BASE_DIR/logs"
MYSQL_BIN="${MYSQL_BIN:-$BASE_DIR/mysql/bin/mysql}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-labcore}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

echo "Package: $PACKAGE_DIR"
echo "Deploy to: $BASE_DIR"
echo "Backup to: $BACKUP_DIR"

detect_layout() {
  if [[ -f "$BASE_DIR/backend/labcore.jar" || -d "$BASE_DIR/bin" ]]; then
    echo "opt"
    return
  fi
  if [[ -f "$BASE_DIR/backend/app.jar" || -f "$BASE_DIR/start-backend.sh" ]]; then
    echo "home"
    return
  fi
  echo "unknown"
}

run_sql() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "SQL file not found: $file" >&2
    exit 1
  fi
  if [[ ! -x "$MYSQL_BIN" ]]; then
    echo "mysql binary not found or not executable: $MYSQL_BIN" >&2
    echo "Set MYSQL_BIN=/path/to/mysql and retry." >&2
    exit 1
  fi
  echo "Running SQL: $(basename "$file")"
  "$MYSQL_BIN" -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" < "$file"
}

ensure_config_line() {
  local file="$1"
  local key="$2"
  local value="$3"
  if [[ ! -f "$file" ]]; then
    return
  fi
  if grep -q "^$key=" "$file"; then
    return
  fi
  echo "$key=$value" >> "$file"
  echo "Appended $key to $file"
}

stop_backend() {
  if [[ "$LAYOUT" == "opt" && -x "$BASE_DIR/bin/stop-backend.sh" ]]; then
    "$BASE_DIR/bin/stop-backend.sh" || true
    return
  fi
  if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/stop-backend.sh" ]]; then
    "$BASE_DIR/stop-backend.sh" || true
    return
  fi
  if [[ -f "$BASE_DIR/backend/labcore.pid" ]]; then
    kill "$(cat "$BASE_DIR/backend/labcore.pid")" 2>/dev/null || true
    rm -f "$BASE_DIR/backend/labcore.pid"
  fi
  if [[ -f "$BASE_DIR/run/backend.pid" ]]; then
    kill "$(cat "$BASE_DIR/run/backend.pid")" 2>/dev/null || true
    rm -f "$BASE_DIR/run/backend.pid"
  fi
}

stop_frontend() {
  if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/stop-frontend.sh" ]]; then
    "$BASE_DIR/stop-frontend.sh" || true
  fi
}

start_backend() {
  if [[ "$LAYOUT" == "opt" && -x "$BASE_DIR/bin/start-backend.sh" ]]; then
    "$BASE_DIR/bin/start-backend.sh"
    return
  fi
  if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/start-backend.sh" ]]; then
    "$BASE_DIR/start-backend.sh"
    return
  fi
  echo "Cannot find backend start script."
  exit 1
}

start_frontend_or_reload_nginx() {
  if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/start-frontend.sh" ]]; then
    "$BASE_DIR/start-frontend.sh"
    return
  fi
  if command -v nginx >/dev/null 2>&1; then
    nginx -s reload || true
  fi
}

LAYOUT="$(detect_layout)"
if [[ "$LAYOUT" == "unknown" ]]; then
  echo "Unknown deployment layout under $BASE_DIR"
  exit 1
fi
echo "Detected layout: $LAYOUT"

run_sql "$PACKAGE_DIR/db/assignment_module.sql"
run_sql "$PACKAGE_DIR/db/assignment_answer_text_migration.sql"

APP_CONFIG="$BASE_DIR/backend/application.properties"
if [[ -f "$APP_CONFIG" ]]; then
  cp -a "$APP_CONFIG" "$BACKUP_DIR/application.properties"
  ensure_config_line "$APP_CONFIG" "labcore.assignment.upload-dir" "data/assignment-submissions"
  ensure_config_line "$APP_CONFIG" "labcore.assignment.material-dir" "data/assignment-materials"
  ensure_config_line "$APP_CONFIG" "labcore.assignment.max-files-per-submission" "5"
  ensure_config_line "$APP_CONFIG" "labcore.assignment.max-bytes-per-submission" "1073741824"
  ensure_config_line "$APP_CONFIG" "spring.servlet.multipart.max-file-size" "300MB"
  ensure_config_line "$APP_CONFIG" "spring.servlet.multipart.max-request-size" "330MB"
fi

stop_frontend
stop_backend

mkdir -p "$BASE_DIR/backend" "$BASE_DIR/frontend"
if [[ "$LAYOUT" == "opt" ]]; then
  [[ -f "$BASE_DIR/backend/labcore.jar" ]] && cp -a "$BASE_DIR/backend/labcore.jar" "$BACKUP_DIR/labcore.jar"
  cp -a "$PACKAGE_DIR/backend/app.jar" "$BASE_DIR/backend/labcore.jar"
else
  [[ -f "$BASE_DIR/backend/app.jar" ]] && cp -a "$BASE_DIR/backend/app.jar" "$BACKUP_DIR/app.jar"
  cp -a "$PACKAGE_DIR/backend/app.jar" "$BASE_DIR/backend/app.jar"
fi

[[ -d "$BASE_DIR/frontend/dist" ]] && cp -a "$BASE_DIR/frontend/dist" "$BACKUP_DIR/frontend-dist"
rm -rf "$BASE_DIR/frontend/dist"
cp -a "$PACKAGE_DIR/frontend/dist" "$BASE_DIR/frontend/dist"

mkdir -p "$BASE_DIR/data/assignment-submissions" "$BASE_DIR/data/assignment-materials"

start_backend
start_frontend_or_reload_nginx

echo "Deployment finished."
echo "Backup: $BACKUP_DIR"
echo "Verify: https://labcore.henu.edu.cn/"

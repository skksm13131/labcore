#!/usr/bin/env bash
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="${1:-/opt/learning-platform}"
TS="$(date +%Y%m%d%H%M%S)"
BACKUP_DIR="$BASE_DIR/backup/codeonly-$TS"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

echo "Package: $PACKAGE_DIR"
echo "Deploy to: $BASE_DIR"
echo "Backup to: $BACKUP_DIR"

if [[ -f "$BASE_DIR/backend/labcore.jar" || -d "$BASE_DIR/bin" ]]; then
  LAYOUT=opt
elif [[ -f "$BASE_DIR/backend/app.jar" || -f "$BASE_DIR/start-backend.sh" ]]; then
  LAYOUT=home
else
  echo "Unknown deployment layout under $BASE_DIR"
  exit 1
fi

echo "Detected layout: $LAYOUT"

if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/stop-frontend.sh" ]]; then
  "$BASE_DIR/stop-frontend.sh" || true
fi
if [[ "$LAYOUT" == "opt" && -x "$BASE_DIR/bin/stop-backend.sh" ]]; then
  "$BASE_DIR/bin/stop-backend.sh" || true
elif [[ "$LAYOUT" == "home" && -x "$BASE_DIR/stop-backend.sh" ]]; then
  "$BASE_DIR/stop-backend.sh" || true
elif [[ -f "$BASE_DIR/backend/labcore.pid" ]]; then
  kill "$(cat "$BASE_DIR/backend/labcore.pid")" 2>/dev/null || true
  rm -f "$BASE_DIR/backend/labcore.pid"
elif [[ -f "$BASE_DIR/run/backend.pid" ]]; then
  kill "$(cat "$BASE_DIR/run/backend.pid")" 2>/dev/null || true
  rm -f "$BASE_DIR/run/backend.pid"
fi

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

if [[ "$LAYOUT" == "opt" && -x "$BASE_DIR/bin/start-backend.sh" ]]; then
  "$BASE_DIR/bin/start-backend.sh"
elif [[ "$LAYOUT" == "home" && -x "$BASE_DIR/start-backend.sh" ]]; then
  "$BASE_DIR/start-backend.sh"
else
  echo "Cannot find backend start script."
  exit 1
fi

if [[ "$LAYOUT" == "home" && -x "$BASE_DIR/start-frontend.sh" ]]; then
  "$BASE_DIR/start-frontend.sh"
elif command -v nginx >/dev/null 2>&1; then
  nginx -s reload || true
fi

echo "Code-only deployment finished. Notebook templates were not overwritten."

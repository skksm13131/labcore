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
BACKUP_DIR="$BASE_DIR/backup/hotfix-$TS"
LOG_DIR="$BASE_DIR/logs"
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

LAYOUT="$(detect_layout)"
if [[ "$LAYOUT" == "unknown" ]]; then
  echo "Unknown deployment layout under $BASE_DIR"
  exit 1
fi
echo "Detected layout: $LAYOUT"

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

APP_CONFIG="$BASE_DIR/backend/application.properties"
if [[ -f "$APP_CONFIG" ]]; then
  cp -a "$APP_CONFIG" "$BACKUP_DIR/application.properties"
  if ! grep -q '^labcore.learning.template-storage-dir=' "$APP_CONFIG"; then
    cat >> "$APP_CONFIG" <<'EOF'
labcore.learning.template-storage-dir=data/learning-templates
EOF
    echo "Appended template storage config to $APP_CONFIG"
  fi
fi

stop_frontend
stop_backend

if [[ "$LAYOUT" == "opt" ]]; then
  mkdir -p "$BASE_DIR/backend" "$BASE_DIR/frontend"
  [[ -f "$BASE_DIR/backend/labcore.jar" ]] && cp -a "$BASE_DIR/backend/labcore.jar" "$BACKUP_DIR/labcore.jar"
  [[ -d "$BASE_DIR/frontend/dist" ]] && cp -a "$BASE_DIR/frontend/dist" "$BACKUP_DIR/frontend-dist"
  cp -a "$PACKAGE_DIR/backend/app.jar" "$BASE_DIR/backend/labcore.jar"
else
  mkdir -p "$BASE_DIR/backend" "$BASE_DIR/frontend"
  [[ -f "$BASE_DIR/backend/app.jar" ]] && cp -a "$BASE_DIR/backend/app.jar" "$BACKUP_DIR/app.jar"
  [[ -d "$BASE_DIR/frontend/dist" ]] && cp -a "$BASE_DIR/frontend/dist" "$BACKUP_DIR/frontend-dist"
  cp -a "$PACKAGE_DIR/backend/app.jar" "$BASE_DIR/backend/app.jar"
fi

rm -rf "$BASE_DIR/frontend/dist"
cp -a "$PACKAGE_DIR/frontend/dist" "$BASE_DIR/frontend/dist"

if [[ -d "$PACKAGE_DIR/data/learning-templates" ]]; then
  mkdir -p "$BASE_DIR/data/learning-templates"
  [[ -d "$BASE_DIR/data/learning-templates" ]] && cp -a "$BASE_DIR/data/learning-templates" "$BACKUP_DIR/learning-templates"
  cp -a "$PACKAGE_DIR/data/learning-templates"/item-* "$BASE_DIR/data/learning-templates/"
fi

start_backend
start_frontend_or_reload_nginx

echo "Deployment finished."
echo "Check backend log: tail -n 100 $LOG_DIR/backend.out"

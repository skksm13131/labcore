#!/usr/bin/env bash
set -euo pipefail

# Edit these values on the bastion/server if production DB config differs.
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-labcore_init_test}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-123456}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON_DIR="${JSON_DIR:-${SCRIPT_DIR}/juypter}"

python3 "${SCRIPT_DIR}/import_learning_cards.py" \
  --json-dir "${JSON_DIR}" \
  --db-host "${DB_HOST}" \
  --db-port "${DB_PORT}" \
  --db-name "${DB_NAME}" \
  --db-user "${DB_USER}" \
  --db-password "${DB_PASSWORD}" \
  --output "${SCRIPT_DIR}/import_learning_cards.sql" \
  --apply

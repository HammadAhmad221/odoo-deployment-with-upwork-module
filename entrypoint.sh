#!/bin/bash
set -e

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-odoo}"
DB_PASSWORD="${DB_PASSWORD:-StrongPass2024!}"
TARGET_DB="${ODOO_DB:-odobridge}"
ADDON="${ODOO_AUTO_UPGRADE_MODULE:-upwork_bid_tracker}"
ADDONS_PATH="/usr/lib/python3/dist-packages/odoo/addons,/mnt/extra-addons"

echo "[entrypoint] waiting for postgres at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" >/dev/null 2>&1; do
  sleep 2
done
echo "[entrypoint] postgres is up"

DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname='${TARGET_DB}'" 2>/dev/null || true)

if [ "$DB_EXISTS" = "1" ]; then
  MODULE_INSTALLED=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$TARGET_DB" -tAc \
    "SELECT 1 FROM ir_module_module WHERE name='${ADDON}' AND state='installed'" 2>/dev/null || true)
  if [ "$MODULE_INSTALLED" = "1" ]; then
    echo "[entrypoint] upgrading ${ADDON} on ${TARGET_DB}..."
    odoo -u "$ADDON" -d "$TARGET_DB" \
      --db_host="$DB_HOST" --db_port="$DB_PORT" \
      --db_user="$DB_USER" --db_password="$DB_PASSWORD" \
      --data-dir=/var/lib/odoo \
      --addons-path="$ADDONS_PATH" \
      --stop-after-init --no-http || echo "[entrypoint] upgrade exited non-zero (continuing)"
  else
    echo "[entrypoint] ${ADDON} not installed on ${TARGET_DB}, skipping auto-upgrade"
  fi
else
  echo "[entrypoint] database ${TARGET_DB} does not exist yet, skipping auto-upgrade"
fi

echo "[entrypoint] starting odoo..."
exec odoo \
  --db_host="$DB_HOST" --db_port="$DB_PORT" \
  --db_user="$DB_USER" --db_password="$DB_PASSWORD" \
  --data-dir=/var/lib/odoo \
  --addons-path="$ADDONS_PATH"

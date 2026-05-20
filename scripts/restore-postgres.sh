#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/backup.dump"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file not found: $BACKUP_FILE"
  exit 1
fi

DB_CONTAINER="nixlifeos-postgres"
DB_NAME="${POSTGRES_DB:-nixlifeos_db}"
DB_USER="${POSTGRES_USER:-nixlifeos_user}"

RESTORE_FILE="/tmp/restore_$(date +%Y%m%d_%H%M%S).dump"

echo "=================================================="
echo "Nix Life OS PostgreSQL Restore"
echo "=================================================="
echo "Database  : $DB_NAME"
echo "User      : $DB_USER"
echo "Container : $DB_CONTAINER"
echo "Backup    : $BACKUP_FILE"
echo "Started   : $(date)"
echo "=================================================="
echo "WARNING: This will restore data into the existing database."
echo "For production, run this only after approval."
echo "=================================================="

docker cp "$BACKUP_FILE" "$DB_CONTAINER:$RESTORE_FILE"

docker exec "$DB_CONTAINER" pg_restore \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --clean \
  --if-exists \
  --no-owner \
  --verbose \
  "$RESTORE_FILE"

docker exec "$DB_CONTAINER" rm -f "$RESTORE_FILE"

echo "=================================================="
echo "Restore completed successfully."
echo "Finished: $(date)"
echo "=================================================="

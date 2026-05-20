#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/u01/nix-life-os"
BACKUP_DIR="$PROJECT_DIR/backups/postgres"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

DB_CONTAINER="nixlifeos-postgres"
DB_NAME="${POSTGRES_DB:-nixlifeos_db}"
DB_USER="${POSTGRES_USER:-nixlifeos_user}"

BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.dump"

mkdir -p "$BACKUP_DIR"

echo "=================================================="
echo "Nix Life OS PostgreSQL Backup"
echo "=================================================="
echo "Database  : $DB_NAME"
echo "User      : $DB_USER"
echo "Container : $DB_CONTAINER"
echo "Output    : $BACKUP_FILE"
echo "Started   : $(date)"
echo "=================================================="

docker exec "$DB_CONTAINER" pg_dump \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -F c \
  -b \
  -v \
  -f "/tmp/${DB_NAME}_${TIMESTAMP}.dump"

docker cp "$DB_CONTAINER:/tmp/${DB_NAME}_${TIMESTAMP}.dump" "$BACKUP_FILE"

docker exec "$DB_CONTAINER" rm -f "/tmp/${DB_NAME}_${TIMESTAMP}.dump"

echo "=================================================="
echo "Backup completed successfully."
echo "File: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | awk '{print $1}')"
echo "Finished: $(date)"
echo "=================================================="

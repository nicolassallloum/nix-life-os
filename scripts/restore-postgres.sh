#!/bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: ./restore-postgres.sh /path/to/backup.sql"
  exit 1
fi

BACKUP_FILE="$1"
CONTAINER_NAME="nixlifeos-postgres"
DB_NAME="nixlifeos_db"
DB_USER="nixlifeos_user"

cat "$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" psql -U "$DB_USER" -d "$DB_NAME"

echo "Restore completed from: $BACKUP_FILE"
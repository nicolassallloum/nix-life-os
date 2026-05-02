#!/bin/bash

set -e

BACKUP_DIR="/u01/nix-life-os/backups/postgres"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
CONTAINER_NAME="nixlifeos-postgres"
DB_NAME="nixlifeos_db"
DB_USER="nixlifeos_user"

mkdir -p "$BACKUP_DIR"

docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/nixlifeos_db_$DATE.sql"

echo "Backup completed: $BACKUP_DIR/nixlifeos_db_$DATE.sql"
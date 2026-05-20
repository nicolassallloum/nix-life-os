#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/u01/nix-life-os"
BACKUP_DIR="$PROJECT_DIR/backups/postgres"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "$BACKUP_DIR"

echo "=================================================="
echo "Nix Life OS PostgreSQL Backup Cleanup"
echo "=================================================="
echo "Backup Dir     : $BACKUP_DIR"
echo "Retention Days : $RETENTION_DAYS"
echo "Started        : $(date)"
echo "=================================================="

find "$BACKUP_DIR" \
  -type f \
  -name "nixlifeos_db_*.dump" \
  -mtime +"$RETENTION_DAYS" \
  -print \
  -delete

echo "=================================================="
echo "Cleanup completed."
echo "Finished: $(date)"
echo "=================================================="

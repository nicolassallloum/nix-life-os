#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
BACKEND_DIR="$PROJECT_ROOT/backend"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step79-laravel-logs-cleanup-$(date +%Y%m%d_%H%M%S)"

printf '%s\n' "=================================================="
printf '%s\n' " STEP 79 — Laravel Logs Cleanup Patch Installer"
printf '%s\n' " Project Root: $PROJECT_ROOT"
printf '%s\n' " Backup Dir:   $BACKUP_DIR"
printf '%s\n' "=================================================="

if [ ! -d "$BACKEND_DIR" ]; then
  echo "ERROR: backend directory not found: $BACKEND_DIR"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

backup_and_copy() {
  local rel="$1"
  local src="$PATCH_ROOT/$rel"
  local dest="$PROJECT_ROOT/$rel"

  if [ ! -f "$src" ]; then
    echo "Missing patch file: $rel"
    return
  fi

  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp "$dest" "$BACKUP_DIR/$rel"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "Updated: $rel"
}

backup_and_copy "backend/bootstrap/app.php"
backup_and_copy "backend/routes/api.php"
backup_and_copy "backend/.env.example"
backup_and_copy "backend/app/Services/Monitoring/LoggingService.php"

cd "$BACKEND_DIR"
php -l bootstrap/app.php
php -l routes/api.php
php -l app/Services/Monitoring/LoggingService.php

php artisan optimize:clear
php artisan config:clear
php artisan route:clear
php artisan cache:clear
php artisan view:clear
php artisan route:cache

mkdir -p storage/logs
cp storage/logs/laravel.log "storage/logs/laravel-step79-before-final-clean.log" 2>/dev/null || true
: > storage/logs/laravel.log
chmod -R 775 storage/logs bootstrap/cache

printf '%s\n' "=================================================="
printf '%s\n' " STEP 79 patch installed."
printf '%s\n' " Now restart containers and run the retest CURL suite."
printf '%s\n' "=================================================="

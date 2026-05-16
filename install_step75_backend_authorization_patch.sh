#!/usr/bin/env bash
set -e

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step75-backend-authorization-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 75 — Backend Authorization Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

if [ ! -d "$PROJECT_ROOT/backend" ]; then
  echo "ERROR: backend directory not found under $PROJECT_ROOT"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

copy_file() {
  local rel="$1"
  if [ -f "$PROJECT_ROOT/$rel" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$PROJECT_ROOT/$rel" "$BACKUP_DIR/$rel"
  fi
  mkdir -p "$PROJECT_ROOT/$(dirname "$rel")"
  cp -a "$PATCH_ROOT/$rel" "$PROJECT_ROOT/$rel"
  echo "Updated: $rel"
}

copy_file "backend/routes/api.php"
copy_file "backend/app/Http/Controllers/Api/AuthController.php"
copy_file "backend/app/Models/Task.php"
copy_file "backend/app/Http/Requests/RegisterRequest.php"

echo "Checking PHP syntax inside backend container..."
docker exec nixlifeos-backend sh -lc "php -l routes/api.php && php -l app/Http/Controllers/Api/AuthController.php && php -l app/Models/Task.php && php -l app/Http/Requests/RegisterRequest.php"

echo "Clearing Laravel caches..."
docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"

echo "=================================================="
echo " STEP 75 patch installed successfully."
echo " Backups saved at: $BACKUP_DIR"
echo "=================================================="

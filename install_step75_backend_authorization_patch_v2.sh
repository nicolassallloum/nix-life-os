#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
CONTAINER_NAME="${BACKEND_CONTAINER:-nixlifeos-backend}"
CONTAINER_ROOT="${BACKEND_CONTAINER_ROOT:-/var/www/html}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILES="$PATCH_ROOT/patch-files"
BACKUP_DIR="$PROJECT_ROOT/backups/step75-backend-authorization-v2-$(date +%Y%m%d-%H%M%S)"

FILES=(
  "backend/routes/api.php"
  "backend/app/Http/Controllers/Api/AuthController.php"
  "backend/app/Http/Requests/RegisterRequest.php"
  "backend/app/Models/Task.php"
)

container_path_for() {
  local rel="$1"
  echo "$CONTAINER_ROOT/${rel#backend/}"
}

echo "=================================================="
echo " STEP 75 — Backend Authorization Patch Installer V2"
echo " Project Root:    $PROJECT_ROOT"
echo " Container:       $CONTAINER_NAME"
echo " Container Root:  $CONTAINER_ROOT"
echo " Patch Files:     $PATCH_FILES"
echo " Backup Dir:      $BACKUP_DIR"
echo "=================================================="

if [ ! -d "$PATCH_FILES/backend" ]; then
  echo "ERROR: patch-files/backend not found. Do not extract this archive over the project files manually."
  exit 1
fi

if [ ! -d "$PROJECT_ROOT/backend" ]; then
  echo "ERROR: backend directory not found under $PROJECT_ROOT"
  exit 1
fi

mkdir -p "$BACKUP_DIR/host" "$BACKUP_DIR/container"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
  echo "ERROR: backend container '$CONTAINER_NAME' is not running."
  echo "Run: docker compose ps"
  exit 1
fi

for rel in "${FILES[@]}"; do
  src="$PATCH_FILES/$rel"
  host_dest="$PROJECT_ROOT/$rel"
  container_dest="$(container_path_for "$rel")"

  if [ ! -f "$src" ]; then
    echo "ERROR: missing patch source: $src"
    exit 1
  fi

  echo "--------------------------------------------------"
  echo "Patching: $rel"

  # Host backup + copy
  if [ -f "$host_dest" ]; then
    mkdir -p "$BACKUP_DIR/host/$(dirname "$rel")"
    cp -a "$host_dest" "$BACKUP_DIR/host/$rel"
  fi
  mkdir -p "$(dirname "$host_dest")"
  cp -a "$src" "$host_dest"
  echo "Host updated: $host_dest"

  # Container backup + copy
  mkdir -p "$BACKUP_DIR/container/$(dirname "$rel")"
  docker exec "$CONTAINER_NAME" sh -lc "if [ -f '$container_dest' ]; then cp -a '$container_dest' '/tmp/step75_backup_file'; fi"
  if docker exec "$CONTAINER_NAME" sh -lc "test -f /tmp/step75_backup_file"; then
    docker cp "$CONTAINER_NAME:/tmp/step75_backup_file" "$BACKUP_DIR/container/$rel"
    docker exec "$CONTAINER_NAME" sh -lc "rm -f /tmp/step75_backup_file"
  fi
  docker exec "$CONTAINER_NAME" sh -lc "mkdir -p '$(dirname "$container_dest")'"
  docker cp "$src" "$CONTAINER_NAME:$container_dest"
  echo "Container updated: $container_dest"
done

echo "--------------------------------------------------"
echo "Checking patched content inside container..."
docker exec "$CONTAINER_NAME" sh -lc "grep -n \"email:rfc\" app/Http/Controllers/Api/AuthController.php app/Http/Requests/RegisterRequest.php"
docker exec "$CONTAINER_NAME" sh -lc "grep -n \"whereNumber('task')\|resolveRouteBinding\" routes/api.php app/Models/Task.php | head -40"

echo "--------------------------------------------------"
echo "Checking PHP syntax inside backend container..."
docker exec "$CONTAINER_NAME" sh -lc "php -l routes/api.php && php -l app/Http/Controllers/Api/AuthController.php && php -l app/Http/Requests/RegisterRequest.php && php -l app/Models/Task.php"

echo "--------------------------------------------------"
echo "Clearing Laravel caches inside backend container..."
docker exec "$CONTAINER_NAME" sh -lc "php artisan optimize:clear"

echo "=================================================="
echo " STEP 75 V2 patch installed successfully."
echo " Backups saved at: $BACKUP_DIR"
echo "=================================================="

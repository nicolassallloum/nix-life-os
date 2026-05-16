#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/u01/nix-life-os"
CONTAINER_NAME="nixlifeos-backend"
CONTAINER_ROOT="/var/www/html"
PATCH_ROOT="$PROJECT_ROOT/patch-files"
BACKUP_DIR="$PROJECT_ROOT/backups/step75-backend-authorization-v3-$(date +%Y%m%d-%H%M%S)"

FILES=(
  "backend/routes/api.php"
  "backend/app/Http/Controllers/Api/AuthController.php"
  "backend/app/Http/Requests/RegisterRequest.php"
  "backend/app/Models/Task.php"
)

echo "=================================================="
echo " STEP 75 — Backend Authorization Patch Installer V3"
echo " Project Root:    $PROJECT_ROOT"
echo " Container:       $CONTAINER_NAME"
echo " Container Root:  $CONTAINER_ROOT"
echo " Patch Files:     $PATCH_ROOT"
echo " Backup Dir:      $BACKUP_DIR"
echo "=================================================="

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR/host" "$BACKUP_DIR/container"

for f in "${FILES[@]}"; do
  echo "--------------------------------------------------"
  echo "Patching: $f"

  src="$PATCH_ROOT/$f"
  host_dst="$PROJECT_ROOT/$f"
  container_rel="${f#backend/}"
  container_dst="$CONTAINER_ROOT/$container_rel"

  if [ ! -f "$src" ]; then
    echo "ERROR: Missing patch file: $src"
    exit 1
  fi

  if [ -f "$host_dst" ]; then
    mkdir -p "$BACKUP_DIR/host/$(dirname "$f")"
    cp -a "$host_dst" "$BACKUP_DIR/host/$f"
  fi

  mkdir -p "$(dirname "$host_dst")"
  cp -a "$src" "$host_dst"
  echo "Host updated: $host_dst"

  mkdir -p "$BACKUP_DIR/container/$(dirname "$f")"
  docker cp "$CONTAINER_NAME:$container_dst" "$BACKUP_DIR/container/$f" >/dev/null 2>&1 || true
  docker cp "$src" "$CONTAINER_NAME:$container_dst"
  echo "Container updated: $container_dst"
done

echo "--------------------------------------------------"
echo "Checking patched content inside container..."
docker exec "$CONTAINER_NAME" sh -lc "grep -R \"STEP 75 V3\|email.*regex\|resolveRouteBinding\" routes/api.php app/Http/Controllers/Api/AuthController.php app/Http/Requests/RegisterRequest.php app/Models/Task.php -n || true"

echo "--------------------------------------------------"
echo "Checking PHP syntax inside backend container..."
docker exec "$CONTAINER_NAME" sh -lc "php -l routes/api.php && php -l app/Http/Controllers/Api/AuthController.php && php -l app/Http/Requests/RegisterRequest.php && php -l app/Models/Task.php"

echo "--------------------------------------------------"
echo "Clearing Laravel caches inside backend container..."
docker exec "$CONTAINER_NAME" sh -lc "php artisan optimize:clear"

echo "=================================================="
echo " STEP 75 V3 patch installed successfully."
echo " Backups saved at: $BACKUP_DIR"
echo "=================================================="

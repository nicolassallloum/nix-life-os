#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step77-error-state-hotfix-v2-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 77 — Error State Hotfix v2 Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

copy_file() {
  local relative_path="$1"
  local src="$PATCH_ROOT/$relative_path"
  local dest="$PROJECT_ROOT/$relative_path"

  if [ ! -f "$src" ]; then
    echo "[SKIP] Missing patch file: $relative_path"
    return
  fi

  mkdir -p "$(dirname "$dest")" "$(dirname "$BACKUP_DIR/$relative_path")"

  if [ -f "$dest" ]; then
    cp "$dest" "$BACKUP_DIR/$relative_path"
  fi

  cp "$src" "$dest"
  echo "[OK] Installed: $relative_path"
}

copy_file "backend/bootstrap/app.php"
copy_file "backend/routes/api.php"
copy_file "frontend/src/main.ts"
copy_file "frontend/src/services/api.js"
copy_file "frontend/src/services/api.ts"
copy_file "frontend/src/services/apiFetch.js"
copy_file "frontend/src/services/financeService.ts"

echo ""
echo "Validating frontend type-check/build..."
if [ -d "$PROJECT_ROOT/frontend" ]; then
  (cd "$PROJECT_ROOT/frontend" && npm run build)
fi

echo ""
echo "Validating backend syntax..."
if command -v php >/dev/null 2>&1; then
  (cd "$PROJECT_ROOT/backend" && php -l bootstrap/app.php && php -l routes/api.php)
else
  echo "[INFO] Local PHP not found; skipping host PHP syntax check."
fi

echo ""
echo "Clearing Laravel cache inside container if available..."
if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"
else
  echo "[INFO] nixlifeos-backend container not running; skipped container cache clear."
fi

echo ""
echo "=================================================="
echo " HOTFIX v2 INSTALLED"
echo " Next recommended restart commands:"
echo " docker restart nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend nixlifeos-nginx"
echo " If frontend files are baked into the Docker image, run: docker compose -f docker-compose.prod.yml up -d --build"
echo "=================================================="

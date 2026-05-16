#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step73-auth-$(date +%Y%m%d-%H%M%S)"

copy_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$PROJECT_ROOT/$dest")"

  if [ -f "$PROJECT_ROOT/$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
    cp "$PROJECT_ROOT/$dest" "$BACKUP_DIR/$dest"
  fi

  cp "$PATCH_ROOT/$src" "$PROJECT_ROOT/$dest"
  echo "[UPDATED] $dest"
}

echo "=================================================="
echo " STEP 73 — Auth Security Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

copy_file "backend/app/Http/Controllers/Api/AuthController.php" "backend/app/Http/Controllers/Api/AuthController.php"
copy_file "backend/routes/api.php" "backend/routes/api.php"
copy_file "frontend/src/services/api.js" "frontend/src/services/api.js"
copy_file "frontend/src/views/auth/LoginView.vue" "frontend/src/views/auth/LoginView.vue"
copy_file "frontend/src/views/auth/RegisterView.vue" "frontend/src/views/auth/RegisterView.vue"

echo ""
echo "[DONE] Files copied. Backups were saved when originals existed."
echo ""
echo "Next commands:"
echo "docker exec -it nixlifeos-backend sh -lc 'cd /var/www/html && php -l app/Http/Controllers/Api/AuthController.php && php -l routes/api.php && php artisan optimize:clear && php artisan route:list | grep -Ei \"auth|login|logout|register|me\"'"
echo "cd $PROJECT_ROOT/frontend && npm run build"

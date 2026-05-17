#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step77-error-state-$(date +%Y%m%d-%H%M%S)"

printf '%s\n' "=================================================="
printf '%s\n' " STEP 77 — Error State Regression Patch Installer"
printf '%s\n' " Project Root: $PROJECT_ROOT"
printf '%s\n' " Patch Root:   $PATCH_ROOT"
printf '%s\n' " Backup Dir:   $BACKUP_DIR"
printf '%s\n' "=================================================="

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "[ERROR] Project root does not exist: $PROJECT_ROOT"
  exit 1
fi

copy_file() {
  local rel="$1"
  local src="$PATCH_ROOT/$rel"
  local dest="$PROJECT_ROOT/$rel"

  if [ ! -f "$src" ]; then
    echo "[SKIP] Patch file missing: $rel"
    return
  fi

  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp "$dest" "$BACKUP_DIR/$rel"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "[OK] Installed: $rel"
}

copy_file "backend/bootstrap/app.php"
copy_file "backend/routes/api.php"
copy_file "frontend/src/main.js"
copy_file "frontend/src/main.ts"
copy_file "frontend/src/router/index.js"
copy_file "frontend/src/router/index.ts"
copy_file "frontend/src/services/api.js"
copy_file "frontend/src/services/apiFetch.js"
copy_file "frontend/src/services/financeService.ts"
copy_file "frontend/src/views/SecurityRolesView.vue"
copy_file "frontend/src/views/NotFoundView.vue"
copy_file "frontend/src/views/auth/UnauthorizedView.vue"

printf '\n%s\n' "Validating backend PHP syntax..."
if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php -l bootstrap/app.php && php -l routes/api.php"
  docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"
else
  php -l "$PROJECT_ROOT/backend/bootstrap/app.php" || true
  php -l "$PROJECT_ROOT/backend/routes/api.php" || true
fi

printf '\n%s\n' "Frontend build check..."
if [ -d "$PROJECT_ROOT/frontend" ]; then
  (cd "$PROJECT_ROOT/frontend" && npm run build)
else
  echo "[SKIP] frontend directory not found"
fi

printf '\n%s\n' "=================================================="
printf '%s\n' " DONE — STEP 77 patch installed."
printf '%s\n' " Backups are stored in: $BACKUP_DIR"
printf '%s\n' " Next: restart containers if needed and run the CURL checklist."
printf '%s\n' "=================================================="

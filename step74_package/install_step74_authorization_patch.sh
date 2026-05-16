#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " STEP 74 — Authorization Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo "=================================================="

if [ ! -d "$PROJECT_ROOT/backend" ] || [ ! -d "$PROJECT_ROOT/frontend" ]; then
  echo "ERROR: Project root must contain backend/ and frontend/."
  exit 1
fi

copy_file() {
  local relative_path="$1"
  if [ -f "$PATCH_ROOT/$relative_path" ]; then
    mkdir -p "$(dirname "$PROJECT_ROOT/$relative_path")"
    cp "$PATCH_ROOT/$relative_path" "$PROJECT_ROOT/$relative_path"
    echo "Updated: $relative_path"
  fi
}

copy_file "backend/routes/api.php"
copy_file "backend/bootstrap/app.php"
copy_file "backend/app/Http/Middleware/EnsureUserHasRole.php"
copy_file "backend/app/Http/Middleware/EnsureUserHasPermission.php"
copy_file "frontend/src/services/api.js"
copy_file "frontend/src/utils/auth.js"
copy_file "frontend/src/router/index.js"
copy_file "frontend/src/router/index.ts"
copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/views/auth/UnauthorizedView.vue"
copy_file "frontend/src/views/admin/AdminOverviewView.vue"
copy_file "frontend/src/views/admin/AdminUsersView.vue"
copy_file "frontend/src/views/admin/AdminRolesView.vue"
copy_file "frontend/src/views/security/SecurityOverviewView.vue"
copy_file "frontend/src/views/security/SecurityAuditLogsView.vue"

echo ""
echo "Running backend syntax checks..."
docker exec nixlifeos-backend sh -lc "php -l routes/api.php && php -l bootstrap/app.php && php -l app/Http/Middleware/EnsureUserHasRole.php && php -l app/Http/Middleware/EnsureUserHasPermission.php"

echo ""
echo "Clearing Laravel caches..."
docker exec nixlifeos-backend sh -lc "php artisan optimize:clear && php artisan route:clear && php artisan config:clear && php artisan cache:clear"

echo ""
echo "Updated API routes now available:"
docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1 | grep -E 'productivity/tasks|productivity/calendar|notifications|automation|admin|security|user-management' || true"

echo ""
echo "=================================================="
echo " STEP 74 patch installed."
echo " Now run: ./step74_authorization_regression_test_v2.sh"
echo "=================================================="

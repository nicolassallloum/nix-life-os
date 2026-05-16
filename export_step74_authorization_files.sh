#!/usr/bin/env bash

set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_ROOT="/tmp/step74_authorization_export"
ARCHIVE_NAME="step74-authorization-required-files.tar.gz"

echo "=================================================="
echo " STEP 74 — Authorization Files Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Root:  $EXPORT_ROOT"
echo "=================================================="

rm -rf "$EXPORT_ROOT"
mkdir -p "$EXPORT_ROOT/backend"
mkdir -p "$EXPORT_ROOT/frontend"

cd "$PROJECT_ROOT"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_ROOT/$1"

  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -R "$src" "$dest"
    echo "Copied: $src"
  else
    echo "Missing: $src"
  fi
}

echo ""
echo "Copying backend core files..."

copy_if_exists "backend/routes/api.php"
copy_if_exists "backend/bootstrap/app.php"
copy_if_exists "backend/app/Http/Kernel.php"
copy_if_exists "backend/app/Models/User.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/AuthController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/DashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceAccountController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceTransactionController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceBudgetController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/NotificationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/AutomationController.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/Admin"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Security"
copy_if_exists "backend/app/Http/Controllers/Api/V1/UserManagement"

copy_if_exists "backend/app/Http/Middleware"
copy_if_exists "backend/app/Policies"
copy_if_exists "backend/app/Providers/AuthServiceProvider.php"

copy_if_exists "backend/config/auth.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/permission.php"

copy_if_exists "backend/database/seeders"
copy_if_exists "backend/database/migrations"

copy_if_exists "backend/composer.json"
copy_if_exists "backend/.env.example"

echo ""
echo "Copying frontend files..."

copy_if_exists "frontend/src/router"
copy_if_exists "frontend/src/stores"
copy_if_exists "frontend/src/services"
copy_if_exists "frontend/src/layouts"
copy_if_exists "frontend/src/components"
copy_if_exists "frontend/src/views/auth"
copy_if_exists "frontend/src/views/dashboard"
copy_if_exists "frontend/src/views/finance"
copy_if_exists "frontend/src/views/health"
copy_if_exists "frontend/src/views/projects"
copy_if_exists "frontend/src/views/productivity"
copy_if_exists "frontend/src/views/ai"
copy_if_exists "frontend/src/views/notifications"
copy_if_exists "frontend/src/views/automation"
copy_if_exists "frontend/src/views/admin"
copy_if_exists "frontend/src/views/security"

copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"
copy_if_exists "frontend/package.json"
copy_if_exists "frontend/vite.config.js"
copy_if_exists "frontend/vite.config.ts"
copy_if_exists "frontend/tsconfig.json"

echo ""
echo "Generating route list..."

mkdir -p "$EXPORT_ROOT/diagnostics"

docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1" \
  > "$EXPORT_ROOT/diagnostics/api_v1_route_list.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan route:list" \
  > "$EXPORT_ROOT/diagnostics/full_route_list.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan about" \
  > "$EXPORT_ROOT/diagnostics/laravel_about.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan optimize:clear" \
  > "$EXPORT_ROOT/diagnostics/optimize_clear.txt" 2>&1 || true

echo ""
echo "Generating database permission diagnostics..."

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, email, created_at
FROM users
ORDER BY created_at DESC
LIMIT 30;
" > "$EXPORT_ROOT/diagnostics/users.txt" 2>&1 || true

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name, created_at
FROM roles
ORDER BY name;
" > "$EXPORT_ROOT/diagnostics/roles.txt" 2>&1 || true

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name, created_at
FROM permissions
ORDER BY name;
" > "$EXPORT_ROOT/diagnostics/permissions.txt" 2>&1 || true

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    u.email,
    r.name AS role_name,
    mr.model_type
FROM model_has_roles mr
JOIN roles r ON r.id = mr.role_id
JOIN users u ON u.id::text = mr.model_id::text
ORDER BY u.email, r.name;
" > "$EXPORT_ROOT/diagnostics/model_has_roles.txt" 2>&1 || true

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    r.name AS role_name,
    p.name AS permission_name
FROM role_has_permissions rhp
JOIN roles r ON r.id = rhp.role_id
JOIN permissions p ON p.id = rhp.permission_id
ORDER BY r.name, p.name;
" > "$EXPORT_ROOT/diagnostics/role_has_permissions.txt" 2>&1 || true

docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    tokenable_type,
    tokenable_id,
    name,
    abilities,
    last_used_at,
    created_at,
    expires_at
FROM personal_access_tokens
ORDER BY created_at DESC
LIMIT 30;
" > "$EXPORT_ROOT/diagnostics/personal_access_tokens.txt" 2>&1 || true

echo ""
echo "Generating grep diagnostics..."

mkdir -p "$EXPORT_ROOT/diagnostics/grep"

grep -R "auth:sanctum" backend/routes backend/app -n \
  > "$EXPORT_ROOT/diagnostics/grep/auth_sanctum.txt" 2>&1 || true

grep -R "role:" backend/routes backend/app -n \
  > "$EXPORT_ROOT/diagnostics/grep/role_middleware.txt" 2>&1 || true

grep -R "permission:" backend/routes backend/app -n \
  > "$EXPORT_ROOT/diagnostics/grep/permission_middleware.txt" 2>&1 || true

grep -R "HasRoles" backend/app -n \
  > "$EXPORT_ROOT/diagnostics/grep/has_roles.txt" 2>&1 || true

grep -R "HasApiTokens" backend/app -n \
  > "$EXPORT_ROOT/diagnostics/grep/has_api_tokens.txt" 2>&1 || true

grep -R "beforeEach" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_before_each.txt" 2>&1 || true

grep -R "requiresAuth" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_requires_auth.txt" 2>&1 || true

grep -R "requiresRole" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_requires_role.txt" 2>&1 || true

grep -R "permissions" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_permissions.txt" 2>&1 || true

grep -R "Authorization" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_authorization_header.txt" 2>&1 || true

grep -R "Bearer" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_bearer.txt" 2>&1 || true

grep -R "logout" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_logout.txt" 2>&1 || true

grep -R "localStorage" frontend/src -n \
  > "$EXPORT_ROOT/diagnostics/grep/vue_local_storage.txt" 2>&1 || true

echo ""
echo "Creating archive..."

cd /tmp
tar -czf "$ARCHIVE_NAME" "step74_authorization_export"

mv "/tmp/$ARCHIVE_NAME" "$PROJECT_ROOT/$ARCHIVE_NAME"

echo ""
echo "=================================================="
echo " Export Completed"
echo " Archive:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

ls -lh "$PROJECT_ROOT/$ARCHIVE_NAME"

#!/usr/bin/env bash

set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_DIR="/tmp/step75-backend-export"
ARCHIVE_NAME="step75-backend-files-for-update.tar.gz"

echo "=================================================="
echo " STEP 75 — Backend Files Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

cd "$PROJECT_ROOT"

copy_if_exists() {
  local path="$1"

  if [ -e "$path" ]; then
    echo "Copying: $path"
    mkdir -p "$EXPORT_DIR/$(dirname "$path")"
    cp -a "$path" "$EXPORT_DIR/$path"
  else
    echo "Missing, skipped: $path"
  fi
}

# Main route file
copy_if_exists "backend/routes/api.php"

# Controllers
copy_if_exists "backend/app/Http/Controllers/Api/AuthController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/TaskController.php"

# Models
copy_if_exists "backend/app/Models/User.php"
copy_if_exists "backend/app/Models/Task.php"

# Laravel bootstrap and middleware registration
copy_if_exists "backend/bootstrap/app.php"

# Requests, middleware, policies, providers, exceptions
copy_if_exists "backend/app/Http/Requests"
copy_if_exists "backend/app/Http/Middleware"
copy_if_exists "backend/app/Policies"
copy_if_exists "backend/app/Providers"
copy_if_exists "backend/app/Exceptions"

# Config files
copy_if_exists "backend/config/auth.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/permission.php"

# Database files
copy_if_exists "backend/database/migrations"
copy_if_exists "backend/database/seeders"

# Useful diagnostics
mkdir -p "$EXPORT_DIR/diagnostics"

echo "Generating route list..."
docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1" \
  > "$EXPORT_DIR/diagnostics/api-v1-route-list.txt" || true

echo "Generating admin/security route list..."
docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1 | grep -Ei 'auth|admin|security|role|permission|user-management|notification|task'" \
  > "$EXPORT_DIR/diagnostics/auth-admin-security-routes.txt" || true

echo "Exporting latest Laravel log tail..."
docker exec nixlifeos-backend sh -lc "tail -n 250 storage/logs/laravel.log" \
  > "$EXPORT_DIR/diagnostics/laravel-log-tail.txt" || true

echo "Exporting users and roles..."
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    u.id,
    u.name,
    u.email,
    r.name AS role_name
FROM users u
LEFT JOIN model_has_roles mhr
    ON mhr.model_id::text = u.id::text
LEFT JOIN roles r
    ON r.id = mhr.role_id
ORDER BY u.created_at DESC;
" > "$EXPORT_DIR/diagnostics/users-and-roles.txt" || true

echo "Exporting roles..."
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name FROM roles ORDER BY id;
" > "$EXPORT_DIR/diagnostics/roles.txt" || true

echo "Exporting permissions..."
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name FROM permissions ORDER BY name;
" > "$EXPORT_DIR/diagnostics/permissions.txt" || true

echo "Creating archive..."
cd "$EXPORT_DIR"
tar -czf "$PROJECT_ROOT/$ARCHIVE_NAME" .

echo "=================================================="
echo " Export complete:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

ls -lah "$PROJECT_ROOT/$ARCHIVE_NAME"

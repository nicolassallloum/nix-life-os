#!/usr/bin/env bash

set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_DIR="$PROJECT_ROOT/step73_auth_export"
ARCHIVE_NAME="step73-auth-needed-files.tar.gz"

echo "=================================================="
echo " STEP 73 — Authentication Export Script"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_DIR/$src"

  if [ -f "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$PROJECT_ROOT/$src" "$dest"
    echo "[COPIED FILE] $src"
  elif [ -d "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$dest"
    cp -R "$PROJECT_ROOT/$src/." "$dest/"
    echo "[COPIED DIR ] $src"
  else
    echo "[MISSING    ] $src"
  fi
}

echo ""
echo "===== BACKEND FILES ====="

copy_if_exists "backend/routes/api.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/AuthController.php"
copy_if_exists "backend/app/Models/User.php"
copy_if_exists "backend/config/auth.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/cors.php"
copy_if_exists "backend/bootstrap/app.php"
copy_if_exists "backend/app/Http/Middleware"
copy_if_exists "backend/app/Providers/AuthServiceProvider.php"
copy_if_exists "backend/database/migrations"
copy_if_exists "backend/database/seeders"
copy_if_exists "backend/composer.json"
copy_if_exists "backend/.env.example"

echo ""
echo "===== FRONTEND FILES ====="

copy_if_exists "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts"
copy_if_exists "frontend/src/services/authService.js"
copy_if_exists "frontend/src/services/authService.ts"
copy_if_exists "frontend/src/services/api.js"
copy_if_exists "frontend/src/services/api.ts"
copy_if_exists "frontend/src/stores/auth.js"
copy_if_exists "frontend/src/stores/auth.ts"
copy_if_exists "frontend/src/views/auth/LoginView.vue"
copy_if_exists "frontend/src/views/auth/RegisterView.vue"
copy_if_exists "frontend/src/layouts/AppLayout.vue"
copy_if_exists "frontend/src/App.vue"
copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"
copy_if_exists "frontend/package.json"

echo ""
echo "===== OPTIONAL INFRA FILES ====="

copy_if_exists "docker-compose.yml"
copy_if_exists "docker-compose.prod.yml"
copy_if_exists "nginx"

echo ""
echo "===== SAFE LOG EXPORT ====="

mkdir -p "$EXPORT_DIR/backend/storage/logs"

if [ -f "$PROJECT_ROOT/backend/storage/logs/laravel.log" ]; then
  tail -n 300 "$PROJECT_ROOT/backend/storage/logs/laravel.log" > "$EXPORT_DIR/backend/storage/logs/laravel_tail_300.log"
  echo "[COPIED LOG ] backend/storage/logs/laravel_tail_300.log"
else
  echo "[MISSING    ] backend/storage/logs/laravel.log"
fi

echo ""
echo "===== ROUTE LIST EXPORT ====="

mkdir -p "$EXPORT_DIR/backend/diagnostics"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list" > "$EXPORT_DIR/backend/diagnostics/route-list.txt" || true
  docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -Ei 'auth|login|logout|register|me|sanctum'" > "$EXPORT_DIR/backend/diagnostics/auth-route-list.txt" || true
  docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan --version" > "$EXPORT_DIR/backend/diagnostics/laravel-version.txt" || true
  echo "[CREATED    ] backend/diagnostics route and version files"
else
  echo "[SKIPPED    ] Docker container nixlifeos-backend is not running"
fi

echo ""
echo "===== DATABASE AUTH SNAPSHOT ====="

mkdir -p "$EXPORT_DIR/database"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-postgres$'; then
  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "\dt" > "$EXPORT_DIR/database/tables.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;
" > "$EXPORT_DIR/database/users_columns.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'personal_access_tokens'
ORDER BY ordinal_position;
" > "$EXPORT_DIR/database/personal_access_tokens_columns.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, email, created_at
FROM users
ORDER BY created_at DESC
LIMIT 20;
" > "$EXPORT_DIR/database/users_sample_safe.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, tokenable_type, tokenable_id, name, abilities, last_used_at, expires_at, created_at
FROM personal_access_tokens
ORDER BY created_at DESC
LIMIT 20;
" > "$EXPORT_DIR/database/personal_access_tokens_sample_safe.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name, created_at
FROM roles
ORDER BY name;
" > "$EXPORT_DIR/database/roles.txt" || true

  docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT id, name, guard_name, created_at
FROM permissions
ORDER BY name;
" > "$EXPORT_DIR/database/permissions.txt" || true

  echo "[CREATED    ] database auth snapshot files"
else
  echo "[SKIPPED    ] Docker container nixlifeos-postgres is not running"
fi

echo ""
echo "===== CREATE ARCHIVE ====="

cd "$PROJECT_ROOT"
tar -czf "$ARCHIVE_NAME" "$(basename "$EXPORT_DIR")"

echo ""
echo "=================================================="
echo " EXPORT COMPLETE"
echo " File created:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

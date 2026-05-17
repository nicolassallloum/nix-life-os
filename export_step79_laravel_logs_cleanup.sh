#!/usr/bin/env bash
set -e

EXPORT_DIR="/tmp/step79-laravel-logs-cleanup"
ARCHIVE_NAME="step79-laravel-logs-cleanup-files.tar.gz"
PROJECT_ROOT="/u01/nix-life-os"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo "=================================================="
echo " STEP 79 — Laravel Logs Cleanup Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_DIR/$1"

  if [ -e "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -r "$PROJECT_ROOT/$src" "$dest"
    echo "Copied: $src"
  else
    echo "Missing: $src"
  fi
}

echo ""
echo "1) Exporting backend config files..."
copy_if_exists "backend/.env.example"
copy_if_exists "backend/config/app.php"
copy_if_exists "backend/config/logging.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/auth.php"

echo ""
echo "2) Exporting routes and bootstrap..."
copy_if_exists "backend/routes/api.php"
copy_if_exists "backend/bootstrap/app.php"

echo ""
echo "3) Exporting exception and middleware files..."
copy_if_exists "backend/app/Exceptions/Handler.php"
copy_if_exists "backend/app/Http/Middleware/Authenticate.php"
copy_if_exists "backend/app/Http/Middleware/EnsureFrontendRequestsAreStateful.php"
copy_if_exists "backend/app/Http/Middleware/CheckPermission.php"
copy_if_exists "backend/app/Http/Middleware/CheckRole.php"

echo ""
echo "4) Exporting API controllers..."
copy_if_exists "backend/app/Http/Controllers/Api/V1"

echo ""
echo "5) Exporting models..."
copy_if_exists "backend/app/Models"

echo ""
echo "6) Exporting form requests..."
copy_if_exists "backend/app/Http/Requests"

echo ""
echo "7) Exporting database migrations and seeders..."
copy_if_exists "backend/database/migrations"
copy_if_exists "backend/database/seeders"

echo ""
echo "8) Exporting latest Laravel log..."
mkdir -p "$EXPORT_DIR/backend/storage/logs"

if [ -f "$BACKEND_DIR/storage/logs/laravel.log" ]; then
  cp "$BACKEND_DIR/storage/logs/laravel.log" "$EXPORT_DIR/backend/storage/logs/laravel.log"
  echo "Copied: backend/storage/logs/laravel.log"
else
  echo "Missing: backend/storage/logs/laravel.log"
fi

echo ""
echo "9) Exporting useful diagnostics..."

mkdir -p "$EXPORT_DIR/diagnostics"

docker exec nixlifeos-backend sh -lc "php artisan --version" \
  > "$EXPORT_DIR/diagnostics/artisan-version.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan route:list" \
  > "$EXPORT_DIR/diagnostics/route-list.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan about" \
  > "$EXPORT_DIR/diagnostics/artisan-about.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan config:show app" \
  > "$EXPORT_DIR/diagnostics/config-app.txt" 2>&1 || true

docker exec nixlifeos-backend sh -lc "php artisan config:show logging" \
  > "$EXPORT_DIR/diagnostics/config-logging.txt" 2>&1 || true

docker compose ps \
  > "$EXPORT_DIR/diagnostics/docker-compose-ps.txt" 2>&1 || true

docker logs --tail=300 nixlifeos-backend \
  > "$EXPORT_DIR/diagnostics/docker-backend-last-300.log" 2>&1 || true

docker logs --tail=300 nixlifeos-backend-nginx \
  > "$EXPORT_DIR/diagnostics/docker-backend-nginx-last-300.log" 2>&1 || true

echo ""
echo "10) Creating archive..."
cd "$EXPORT_DIR"
tar -czf "$PROJECT_ROOT/$ARCHIVE_NAME" .

echo ""
echo "=================================================="
echo " Export completed successfully."
echo " Archive created:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

#!/usr/bin/env bash

set -e

EXPORT_DIR="/tmp/step78-browser-console-cleanup"
ARCHIVE_NAME="step78-browser-console-cleanup-files.tar.gz"

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local path="$1"

  if [ -e "$path" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$path")"
    cp -r "$path" "$EXPORT_DIR/$path"
    echo "Copied: $path"
  else
    echo "Missing: $path"
  fi
}

echo "=================================================="
echo " STEP 78 — Browser Console Cleanup File Export"
echo " Project Root: $(pwd)"
echo " Export Dir:   $EXPORT_DIR"
echo "=================================================="

# Frontend core
copy_if_exists "frontend/package.json"
copy_if_exists "frontend/vite.config.js"
copy_if_exists "frontend/index.html"
copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"
copy_if_exists "frontend/src/App.vue"
copy_if_exists "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts"

# Frontend services
copy_if_exists "frontend/src/services"

# Layouts
copy_if_exists "frontend/src/layouts"

# Components
copy_if_exists "frontend/src/components"

# Views
copy_if_exists "frontend/src/views"

# Assets reference only
copy_if_exists "frontend/src/assets"
copy_if_exists "frontend/public"

# Backend reference files
copy_if_exists "backend/routes/api.php"
copy_if_exists "backend/config/cors.php"
copy_if_exists "backend/app/Http/Middleware"
copy_if_exists "backend/app/Http/Controllers/Api/V1"

# Logs and route list
mkdir -p "$EXPORT_DIR/diagnostics"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan route:list" > "$EXPORT_DIR/diagnostics/laravel-route-list.txt" || true
  docker exec nixlifeos-backend sh -lc "tail -n 200 storage/logs/laravel.log" > "$EXPORT_DIR/diagnostics/laravel-log-tail.txt" || true
else
  echo "Backend container nixlifeos-backend not running." > "$EXPORT_DIR/diagnostics/docker-warning.txt"
fi

# Frontend build diagnostics
if [ -d "frontend" ]; then
  cd frontend

  if [ -f "package.json" ]; then
    npm run build > "$EXPORT_DIR/diagnostics/frontend-build-output.txt" 2>&1 || true
  fi

  cd ..
fi

tar -czf "$ARCHIVE_NAME" -C "$EXPORT_DIR" .

echo "=================================================="
echo " Export completed:"
echo " $ARCHIVE_NAME"
echo "=================================================="

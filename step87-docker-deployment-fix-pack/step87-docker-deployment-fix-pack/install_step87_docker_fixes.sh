#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step87-docker-fixes-$(date +%Y%m%d-%H%M%S)"

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR"

backup_file() {
  local f="$1"
  if [ -f "$PROJECT_ROOT/$f" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$f")"
    cp -a "$PROJECT_ROOT/$f" "$BACKUP_DIR/$f"
    echo "🛡️  Backup: $f"
  fi
}

install_file() {
  local f="$1"
  backup_file "$f"
  mkdir -p "$PROJECT_ROOT/$(dirname "$f")"
  cp -a "$PATCH_ROOT/$f" "$PROJECT_ROOT/$f"
  echo "✅ Installed: $f"
}

echo "=================================================="
echo " STEP 87 — Docker Deployment Fix Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

install_file docker-compose.prod.yml
install_file docker/backend-nginx/default.conf
install_file docker/nginx/default.conf
install_file backend/.dockerignore
install_file scripts/step87_deployment_validation.sh

# Fix backend/.env for Docker-safe defaults. Keep a backup first.
if [ -f backend/.env ]; then
  backup_file backend/.env
  sed -i -E 's/^DB_HOST=.*/DB_HOST=postgres/' backend/.env || true
  sed -i -E 's/^DB_PORT=.*/DB_PORT=5445/' backend/.env || true
  sed -i -E 's/^APP_ENV=.*/APP_ENV=production/' backend/.env || true
  sed -i -E 's/^APP_DEBUG=.*/APP_DEBUG=false/' backend/.env || true
  grep -q '^AI_ENGINE_URL=' backend/.env || echo 'AI_ENGINE_URL=http://ai-engine:5000' >> backend/.env
  echo "✅ Updated backend/.env Docker DB host/port"
fi

# Ensure .env.docker has required production variables without printing secrets.
if [ -f .env.docker ]; then
  backup_file .env.docker
  grep -q '^APP_ENV=' .env.docker || echo 'APP_ENV=production' >> .env.docker
  grep -q '^APP_DEBUG=' .env.docker || echo 'APP_DEBUG=false' >> .env.docker
  grep -q '^APP_URL=' .env.docker || echo 'APP_URL=http://localhost' >> .env.docker
  grep -q '^FRONTEND_URL=' .env.docker || echo 'FRONTEND_URL=http://localhost' >> .env.docker
  grep -q '^DB_HOST=' .env.docker || echo 'DB_HOST=postgres' >> .env.docker
  grep -q '^DB_PORT=' .env.docker || echo 'DB_PORT=5445' >> .env.docker
  grep -q '^SESSION_DRIVER=' .env.docker || echo 'SESSION_DRIVER=database' >> .env.docker
  grep -q '^CACHE_STORE=' .env.docker || echo 'CACHE_STORE=database' >> .env.docker
  grep -q '^QUEUE_CONNECTION=' .env.docker || echo 'QUEUE_CONNECTION=database' >> .env.docker
  grep -q '^AI_ENGINE_URL=' .env.docker || echo 'AI_ENGINE_URL=http://ai-engine:5000' >> .env.docker
  echo "✅ Verified .env.docker required keys"
fi

# Add /api/v1/health alias without duplicating it.
if [ -f backend/routes/api.php ] && ! grep -q "Route::get('/v1/health'" backend/routes/api.php; then
  backup_file backend/routes/api.php
  python3 - <<'PY'
from pathlib import Path
p = Path('backend/routes/api.php')
s = p.read_text()
needle = "Route::get('/health', function () {\n    return response()->json([\n        'success' => true,\n        'message' => 'Nix Life OS API is running.',\n        'timestamp' => now()->toISOString(),\n    ]);\n});"
insert = needle + "\n\nRoute::get('/v1/health', function () {\n    return response()->json([\n        'success' => true,\n        'message' => 'Nix Life OS API v1 is running.',\n        'timestamp' => now()->toISOString(),\n    ]);\n});"
if needle in s:
    s = s.replace(needle, insert, 1)
else:
    marker = "/*\n|--------------------------------------------------------------------------\n| API Version 1"
    s = s.replace(marker, "Route::get('/v1/health', function () {\n    return response()->json([\n        'success' => true,\n        'message' => 'Nix Life OS API v1 is running.',\n        'timestamp' => now()->toISOString(),\n    ]);\n});\n\n" + marker, 1)
p.write_text(s)
PY
  echo "✅ Added /api/v1/health alias"
fi

echo "\nNext commands:"
echo "docker compose -f docker-compose.prod.yml down"
echo "docker compose -f docker-compose.prod.yml up -d --build"
echo "docker exec nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan config:cache && php artisan route:cache && php artisan migrate --force'"
echo "./scripts/step87_deployment_validation.sh"

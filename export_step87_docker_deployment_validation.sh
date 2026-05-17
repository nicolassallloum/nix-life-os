#!/usr/bin/env bash
set -euo pipefail

STEP_NAME="step87-docker-deployment-validation"
PROJECT_ROOT="$(pwd)"
EXPORT_DIR="/tmp/${STEP_NAME}"
ARCHIVE_NAME="${STEP_NAME}.tar.gz"

echo "=================================================="
echo " STEP 87 — Docker Deployment Validation Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local path="$1"
  if [ -e "$PROJECT_ROOT/$path" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$path")"
    cp -a "$PROJECT_ROOT/$path" "$EXPORT_DIR/$path"
    echo "✅ Copied: $path"
  else
    echo "⚠️ Missing: $path"
  fi
}

copy_dir_if_exists() {
  local path="$1"
  if [ -d "$PROJECT_ROOT/$path" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$path")"
    cp -a "$PROJECT_ROOT/$path" "$EXPORT_DIR/$path"
    echo "✅ Copied directory: $path"
  else
    echo "⚠️ Missing directory: $path"
  fi
}

echo ""
echo "📦 Copying root Docker/deployment files..."

copy_if_exists "docker-compose.yml"
copy_if_exists "docker-compose.prod.yml"
copy_if_exists "docker-compose.override.yml"
copy_if_exists ".env"
copy_if_exists ".env.docker"
copy_if_exists ".env.production"
copy_if_exists "Dockerfile"
copy_if_exists "Makefile"
copy_if_exists "README.md"

echo ""
echo "📦 Copying backend files..."

copy_if_exists "backend/Dockerfile"
copy_if_exists "backend/.dockerignore"
copy_if_exists "backend/.env"
copy_if_exists "backend/.env.example"
copy_if_exists "backend/composer.json"
copy_if_exists "backend/composer.lock"
copy_if_exists "backend/artisan"

copy_dir_if_exists "backend/app"
copy_dir_if_exists "backend/bootstrap"
copy_dir_if_exists "backend/config"
copy_dir_if_exists "backend/routes"
copy_dir_if_exists "backend/database/migrations"
copy_dir_if_exists "backend/database/seeders"

mkdir -p "$EXPORT_DIR/backend/storage/logs"
if [ -d "$PROJECT_ROOT/backend/storage/logs" ]; then
  find "$PROJECT_ROOT/backend/storage/logs" -maxdepth 1 -type f \( -name "*.log" -o -name "laravel*.log" \) -exec cp {} "$EXPORT_DIR/backend/storage/logs/" \;
  echo "✅ Copied Laravel logs"
else
  echo "⚠️ Missing Laravel logs directory"
fi

echo ""
echo "📦 Copying frontend files..."

copy_if_exists "frontend/Dockerfile"
copy_if_exists "frontend/.dockerignore"
copy_if_exists "frontend/.env"
copy_if_exists "frontend/.env.production"
copy_if_exists "frontend/package.json"
copy_if_exists "frontend/package-lock.json"
copy_if_exists "frontend/vite.config.js"
copy_if_exists "frontend/index.html"
copy_if_exists "frontend/nginx.conf"

copy_dir_if_exists "frontend/src"

echo ""
echo "📦 Copying Nginx / deployment folders..."

copy_dir_if_exists "nginx"
copy_dir_if_exists "docker"
copy_dir_if_exists "deploy"
copy_dir_if_exists "scripts"
copy_dir_if_exists "backend-nginx"

echo ""
echo "🧪 Collecting Docker diagnostics..."

mkdir -p "$EXPORT_DIR/diagnostics"

docker compose ps > "$EXPORT_DIR/diagnostics/docker-compose-ps.txt" 2>&1 || true
docker compose config > "$EXPORT_DIR/diagnostics/docker-compose-config.txt" 2>&1 || true
docker network ls > "$EXPORT_DIR/diagnostics/docker-network-ls.txt" 2>&1 || true
docker volume ls > "$EXPORT_DIR/diagnostics/docker-volume-ls.txt" 2>&1 || true
docker images > "$EXPORT_DIR/diagnostics/docker-images.txt" 2>&1 || true
docker info > "$EXPORT_DIR/diagnostics/docker-info.txt" 2>&1 || true

echo ""
echo "🧾 Collecting service logs..."

mkdir -p "$EXPORT_DIR/diagnostics/logs"

SERVICES="
backend
backend-nginx
frontend
postgres
ai-engine
nginx
db
database
nixlifeos-backend
nixlifeos-backend-nginx
nixlifeos-frontend
nixlifeos-postgres
nixlifeos-ai-engine
"

for service in $SERVICES; do
  docker compose logs --tail=300 "$service" > "$EXPORT_DIR/diagnostics/logs/${service}.log" 2>&1 || true
done

echo ""
echo "🧪 Collecting Laravel diagnostics if backend container exists..."

BACKEND_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E 'nixlifeos-backend$|backend$' | head -1 || true)"

if [ -n "$BACKEND_CONTAINER" ]; then
  echo "✅ Backend container detected: $BACKEND_CONTAINER"

  docker exec "$BACKEND_CONTAINER" sh -lc "php -v" > "$EXPORT_DIR/diagnostics/backend-php-version.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan --version" > "$EXPORT_DIR/diagnostics/backend-artisan-version.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan route:list" > "$EXPORT_DIR/diagnostics/backend-route-list.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan migrate:status" > "$EXPORT_DIR/diagnostics/backend-migrate-status.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan config:show app" > "$EXPORT_DIR/diagnostics/backend-config-app.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan config:show database" > "$EXPORT_DIR/diagnostics/backend-config-database.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan config:show sanctum" > "$EXPORT_DIR/diagnostics/backend-config-sanctum.txt" 2>&1 || true
  docker exec "$BACKEND_CONTAINER" sh -lc "php artisan about" > "$EXPORT_DIR/diagnostics/backend-artisan-about.txt" 2>&1 || true
else
  echo "⚠️ Backend container not detected"
fi

echo ""
echo "🧪 Collecting PostgreSQL diagnostics if postgres container exists..."

POSTGRES_CONTAINER="$(docker ps --format '{{.Names}}' | grep -E 'nixlifeos-postgres$|postgres$|db$|database$' | head -1 || true)"

if [ -n "$POSTGRES_CONTAINER" ]; then
  echo "✅ PostgreSQL container detected: $POSTGRES_CONTAINER"

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql --version" > "$EXPORT_DIR/diagnostics/postgres-version.txt" 2>&1 || true
  docker exec "$POSTGRES_CONTAINER" sh -lc "pg_isready" > "$EXPORT_DIR/diagnostics/postgres-pg-isready.txt" 2>&1 || true
else
  echo "⚠️ PostgreSQL container not detected"
fi

echo ""
echo "🌐 Running basic HTTP checks..."

{
  echo "Checking backend API through backend-nginx:"
  curl -i -s http://127.0.0.1:8000/api/v1/health || true
  echo ""
  echo "Checking backend root:"
  curl -i -s http://127.0.0.1:8000 || true
  echo ""
  echo "Checking frontend:"
  curl -i -s http://127.0.0.1:80 || true
  echo ""
  echo "Checking AI engine:"
  curl -i -s http://127.0.0.1:5000/health || true
} > "$EXPORT_DIR/diagnostics/http-checks.txt" 2>&1 || true

echo ""
echo "🔐 Masking sensitive environment values..."

find "$EXPORT_DIR" -type f \( -name ".env" -o -name ".env.*" -o -name "*config*.txt" -o -name "docker-compose-config.txt" \) -print0 | while IFS= read -r -d '' file; do
  sed -i -E \
    -e 's/(APP_KEY=).*/\1***MASKED***/g' \
    -e 's/(DB_PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(POSTGRES_PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(REDIS_PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(MAIL_PASSWORD=).*/\1***MASKED***/g' \
    -e 's/(AWS_SECRET_ACCESS_KEY=).*/\1***MASKED***/g' \
    -e 's/(OPENAI_API_KEY=).*/\1***MASKED***/g' \
    -e 's/(JWT_SECRET=).*/\1***MASKED***/g' \
    -e 's/(SANCTUM_TOKEN=).*/\1***MASKED***/g' \
    "$file" || true
done

echo ""
echo "🧹 Removing heavy/unneeded folders if accidentally copied..."

rm -rf "$EXPORT_DIR/frontend/node_modules" || true
rm -rf "$EXPORT_DIR/backend/vendor" || true
rm -rf "$EXPORT_DIR/frontend/dist" || true
rm -rf "$EXPORT_DIR/backend/storage/framework/cache" || true
rm -rf "$EXPORT_DIR/backend/storage/framework/sessions" || true
rm -rf "$EXPORT_DIR/backend/storage/framework/views" || true

echo ""
echo "📦 Creating archive..."

cd /tmp
tar -czf "$PROJECT_ROOT/$ARCHIVE_NAME" "$STEP_NAME"

echo ""
echo "=================================================="
echo "✅ Export completed successfully"
echo "Archive created:"
echo "$PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

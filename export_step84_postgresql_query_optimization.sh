#!/usr/bin/env bash
set -e

STEP_NAME="step84-postgresql-query-optimization"
EXPORT_DIR="/tmp/${STEP_NAME}"
ARCHIVE_NAME="${STEP_NAME}-export.tar.gz"
PROJECT_ROOT="/u01/nix-life-os"

echo "=================================================="
echo " STEP 84 — PostgreSQL Query Optimization Export"
echo " Project Root: ${PROJECT_ROOT}"
echo " Export Dir:   ${EXPORT_DIR}"
echo " Archive:      ${ARCHIVE_NAME}"
echo "=================================================="

rm -rf "${EXPORT_DIR}"
mkdir -p "${EXPORT_DIR}"

cd "${PROJECT_ROOT}"

echo "📁 Creating folder structure..."
mkdir -p "${EXPORT_DIR}/backend"
mkdir -p "${EXPORT_DIR}/frontend"
mkdir -p "${EXPORT_DIR}/database-diagnostics"
mkdir -p "${EXPORT_DIR}/docker"
mkdir -p "${EXPORT_DIR}/logs"
mkdir -p "${EXPORT_DIR}/reports"

echo "📦 Exporting Laravel backend query-related files..."

copy_if_exists() {
  local SRC="$1"
  local DEST="$2"

  if [ -e "$SRC" ]; then
    mkdir -p "$(dirname "$DEST")"
    cp -r "$SRC" "$DEST"
    echo "✅ Copied: $SRC"
  else
    echo "⚠️ Missing: $SRC"
  fi
}

copy_if_exists "backend/app/Models" "${EXPORT_DIR}/backend/app/Models"
copy_if_exists "backend/app/Http/Controllers" "${EXPORT_DIR}/backend/app/Http/Controllers"
copy_if_exists "backend/app/Services" "${EXPORT_DIR}/backend/app/Services"
copy_if_exists "backend/app/Repositories" "${EXPORT_DIR}/backend/app/Repositories"
copy_if_exists "backend/app/Actions" "${EXPORT_DIR}/backend/app/Actions"
copy_if_exists "backend/app/Providers" "${EXPORT_DIR}/backend/app/Providers"

copy_if_exists "backend/routes/api.php" "${EXPORT_DIR}/backend/routes/api.php"
copy_if_exists "backend/routes/web.php" "${EXPORT_DIR}/backend/routes/web.php"

copy_if_exists "backend/config/database.php" "${EXPORT_DIR}/backend/config/database.php"
copy_if_exists "backend/config/cache.php" "${EXPORT_DIR}/backend/config/cache.php"
copy_if_exists "backend/config/sanctum.php" "${EXPORT_DIR}/backend/config/sanctum.php"

copy_if_exists "backend/database/migrations" "${EXPORT_DIR}/backend/database/migrations"
copy_if_exists "backend/database/seeders" "${EXPORT_DIR}/backend/database/seeders"
copy_if_exists "backend/database/factories" "${EXPORT_DIR}/backend/database/factories"

echo "📦 Exporting frontend API usage files..."
copy_if_exists "frontend/src" "${EXPORT_DIR}/frontend/src"
copy_if_exists "frontend/package.json" "${EXPORT_DIR}/frontend/package.json"
copy_if_exists "frontend/vite.config.js" "${EXPORT_DIR}/frontend/vite.config.js"
copy_if_exists "frontend/vite.config.ts" "${EXPORT_DIR}/frontend/vite.config.ts"

echo "📦 Exporting Docker / Nginx / environment files..."
copy_if_exists "docker-compose.yml" "${EXPORT_DIR}/docker/docker-compose.yml"
copy_if_exists "docker-compose.prod.yml" "${EXPORT_DIR}/docker/docker-compose.prod.yml"
copy_if_exists ".env.docker" "${EXPORT_DIR}/docker/.env.docker"
copy_if_exists "backend/Dockerfile" "${EXPORT_DIR}/docker/backend-Dockerfile"
copy_if_exists "backend/docker" "${EXPORT_DIR}/docker/backend-docker"
copy_if_exists "backend-nginx" "${EXPORT_DIR}/docker/backend-nginx"
copy_if_exists "nginx" "${EXPORT_DIR}/docker/nginx"

echo "📦 Exporting Laravel logs..."
if [ -d "backend/storage/logs" ]; then
  mkdir -p "${EXPORT_DIR}/logs/backend-storage-logs"
  find backend/storage/logs -type f -name "*.log" -mtime -14 -exec cp {} "${EXPORT_DIR}/logs/backend-storage-logs/" \;
  echo "✅ Copied recent Laravel logs from last 14 days"
else
  echo "⚠️ backend/storage/logs not found"
fi

echo "📦 Exporting Laravel route list..."
if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api" > "${EXPORT_DIR}/reports/laravel-api-routes.txt" || true
  docker exec nixlifeos-backend sh -lc "php artisan migrate:status" > "${EXPORT_DIR}/reports/laravel-migrate-status.txt" || true
  docker exec nixlifeos-backend sh -lc "php artisan about" > "${EXPORT_DIR}/reports/laravel-about.txt" || true
  echo "✅ Exported Laravel route/migration/about reports"
else
  echo "⚠️ nixlifeos-backend container not running. Skipping artisan reports."
fi

echo "📦 Exporting Docker service status..."
docker compose ps > "${EXPORT_DIR}/reports/docker-compose-ps.txt" || true
docker ps -a > "${EXPORT_DIR}/reports/docker-ps-a.txt" || true

echo "📦 Detecting PostgreSQL container..."

POSTGRES_CONTAINER=""

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-postgres$'; then
  POSTGRES_CONTAINER="nixlifeos-postgres"
elif docker ps --format '{{.Names}}' | grep -q 'postgres'; then
  POSTGRES_CONTAINER="$(docker ps --format '{{.Names}}' | grep 'postgres' | head -1)"
fi

echo "PostgreSQL container detected: ${POSTGRES_CONTAINER:-NONE}"

if [ -n "$POSTGRES_CONTAINER" ]; then
  echo "📦 Exporting PostgreSQL diagnostics..."

  docker exec "$POSTGRES_CONTAINER" sh -lc 'printenv | sort' > "${EXPORT_DIR}/database-diagnostics/postgres-container-env.txt" || true

  DB_USER="$(docker exec "$POSTGRES_CONTAINER" sh -lc 'echo ${POSTGRES_USER:-postgres}' | tr -d '\r')"
  DB_NAME="$(docker exec "$POSTGRES_CONTAINER" sh -lc 'echo ${POSTGRES_DB:-postgres}' | tr -d '\r')"

  echo "Detected DB_USER=${DB_USER}" > "${EXPORT_DIR}/database-diagnostics/postgres-detected-db.txt"
  echo "Detected DB_NAME=${DB_NAME}" >> "${EXPORT_DIR}/database-diagnostics/postgres-detected-db.txt"

  docker exec "$POSTGRES_CONTAINER" sh -lc "pg_dump -U \"$DB_USER\" -d \"$DB_NAME\" --schema-only --no-owner --no-privileges" \
    > "${EXPORT_DIR}/database-diagnostics/schema-only.sql" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"\\dt+\"" \
    > "${EXPORT_DIR}/database-diagnostics/tables-size.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"\\di+\"" \
    > "${EXPORT_DIR}/database-diagnostics/indexes-size.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup AS estimated_rows,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
\"" > "${EXPORT_DIR}/database-diagnostics/table-row-estimates-and-vacuum.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC;
\"" > "${EXPORT_DIR}/database-diagnostics/index-usage.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    relname AS table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_live_tup
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC
LIMIT 50;
\"" > "${EXPORT_DIR}/database-diagnostics/sequential-scans-top-50.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;
\"" > "${EXPORT_DIR}/database-diagnostics/columns.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_schema, tc.table_name, kcu.column_name;
\"" > "${EXPORT_DIR}/database-diagnostics/foreign-keys.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY schemaname, tablename, indexname;
\"" > "${EXPORT_DIR}/database-diagnostics/index-definitions.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) AS database_size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
\"" > "${EXPORT_DIR}/database-diagnostics/database-sizes.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS indexes_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 50;
\"" > "${EXPORT_DIR}/database-diagnostics/largest-tables-top-50.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SHOW shared_buffers;
SHOW work_mem;
SHOW maintenance_work_mem;
SHOW effective_cache_size;
SHOW max_connections;
SHOW random_page_cost;
SHOW effective_io_concurrency;
SHOW track_io_timing;
SHOW log_min_duration_statement;
\"" > "${EXPORT_DIR}/database-diagnostics/postgres-settings.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    extname,
    extversion
FROM pg_extension
ORDER BY extname;
\"" > "${EXPORT_DIR}/database-diagnostics/postgres-extensions.txt" || true

  docker exec "$POSTGRES_CONTAINER" sh -lc "psql -U \"$DB_USER\" -d \"$DB_NAME\" -c \"
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 50;
\"" > "${EXPORT_DIR}/database-diagnostics/pg-stat-statements-top-50.txt" 2> "${EXPORT_DIR}/database-diagnostics/pg-stat-statements-error.txt" || true

else
  echo "⚠️ PostgreSQL container not detected. Skipping DB diagnostics."
fi

echo "📦 Creating README..."
cat > "${EXPORT_DIR}/README_STEP84_EXPORT.md" <<README
# STEP 84 — PostgreSQL Query Optimization Export

This archive contains files needed to review and optimize PostgreSQL query performance for Nix Life OS.

## Included Areas

- Laravel backend models, controllers, services, repositories, actions
- API route definitions
- Database migrations, seeders, factories
- PostgreSQL schema-only dump
- Table/index size reports
- Index usage reports
- Sequential scan reports
- Foreign key and column metadata
- PostgreSQL settings
- pg_stat_statements output if available
- Laravel logs
- Docker/Nginx/PHP-FPM configuration
- Frontend API usage files

## Review Goals

1. Identify slow dashboard queries.
2. Detect missing indexes.
3. Detect unused or duplicate indexes.
4. Optimize finance summary queries.
5. Optimize health summary queries.
6. Optimize project progress queries.
7. Optimize productivity and AI insight queries.
8. Recommend EXPLAIN ANALYZE commands.
9. Provide Laravel query rewrites.
10. Provide final PostgreSQL optimization checklist.

README

echo "📦 Creating archive..."
cd /tmp
tar -czf "${PROJECT_ROOT}/${ARCHIVE_NAME}" "${STEP_NAME}"

echo "=================================================="
echo "✅ STEP 84 export complete"
echo "Archive created:"
echo "${PROJECT_ROOT}/${ARCHIVE_NAME}"
echo "=================================================="

#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step84-postgresql-optimization-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "=================================================="
echo " STEP 84 — PostgreSQL Optimization Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

copy_with_backup() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#$PROJECT_ROOT/}")"
    cp "$dest" "$BACKUP_DIR/${dest#$PROJECT_ROOT/}"
    echo "🛡️  Backup: ${dest#$PROJECT_ROOT/}"
  fi
  cp "$src" "$dest"
  echo "✅ Updated: ${dest#$PROJECT_ROOT/}"
}

copy_with_backup "$PATCH_ROOT/backend/app/Services/Dashboard/UnifiedDashboardService.php" "$PROJECT_ROOT/backend/app/Services/Dashboard/UnifiedDashboardService.php"
copy_with_backup "$PATCH_ROOT/backend/database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php" "$PROJECT_ROOT/backend/database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php"

mkdir -p "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/docs"
cp "$PATCH_ROOT/scripts/step84_explain_analyze.sql" "$PROJECT_ROOT/scripts/step84_explain_analyze.sql"
cp "$PATCH_ROOT/scripts/step84_postgres_diagnostics.sql" "$PROJECT_ROOT/scripts/step84_postgres_diagnostics.sql"
cp "$PATCH_ROOT/scripts/step84_retest.sh" "$PROJECT_ROOT/scripts/step84_retest.sh"
chmod +x "$PROJECT_ROOT/scripts/step84_retest.sh"
cp "$PATCH_ROOT/docs/STEP84_POSTGRESQL_QUERY_OPTIMIZATION_REPORT.md" "$PROJECT_ROOT/docs/STEP84_POSTGRESQL_QUERY_OPTIMIZATION_REPORT.md"
cp "$PATCH_ROOT/docs/STEP84_DUPLICATE_INDEX_REVIEW.sql" "$PROJECT_ROOT/docs/STEP84_DUPLICATE_INDEX_REVIEW.sql"

echo "=================================================="
echo "✅ Files installed. Now run:"
echo "cd $PROJECT_ROOT"
echo "docker exec -it nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan migrate --force'"
echo "docker exec -it nixlifeos-backend sh -lc 'php -l app/Services/Dashboard/UnifiedDashboardService.php'"
echo "./scripts/step84_retest.sh"
echo "=================================================="

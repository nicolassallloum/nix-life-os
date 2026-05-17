#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/u01/nix-life-os"
PATCH_ROOT="${PROJECT_ROOT}/step84-postgresql-optimization-hotfix"
BACKUP_DIR="${PROJECT_ROOT}/backups/step84-postgresql-optimization-hotfix-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"
cd "$PROJECT_ROOT"

echo "=================================================="
echo " STEP 84 — PostgreSQL Optimization Hotfix Installer"
echo " Project Root: ${PROJECT_ROOT}"
echo " Patch Root:   ${PATCH_ROOT}"
echo " Backup Dir:   ${BACKUP_DIR}"
echo "=================================================="

copy_with_backup() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    mkdir -p "${BACKUP_DIR}/$(dirname "$dest")"
    cp "$dest" "${BACKUP_DIR}/${dest}"
    echo "🛡️  Backup: $dest"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "✅ Updated: $dest"
}

copy_with_backup "${PATCH_ROOT}/backend/database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php" \
  "backend/database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php"

copy_with_backup "${PATCH_ROOT}/scripts/step84_explain_analyze.sql" \
  "scripts/step84_explain_analyze.sql"

copy_with_backup "${PATCH_ROOT}/scripts/step84_retest.sh" \
  "scripts/step84_retest.sh"

chmod +x scripts/step84_retest.sh

echo "=================================================="
echo "✅ Hotfix files installed. Now run:"
echo "docker exec -it nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan migrate --force'"
echo "docker exec -it nixlifeos-backend sh -lc 'php -l database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php'"
echo "./scripts/step84_retest.sh"
echo "=================================================="

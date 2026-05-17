#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step81-e2e-$(date +%Y%m%d-%H%M%S)"

printf '%s\n' '=================================================='
printf '%s\n' ' STEP 81 — E2E Stabilization Patch Installer'
printf ' Project Root: %s\n' "$PROJECT_ROOT"
printf ' Patch Root:   %s\n' "$PATCH_ROOT"
printf ' Backup Dir:   %s\n' "$BACKUP_DIR"
printf '%s\n' '=================================================='

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR"

copy_with_backup() {
  local src="$1"
  local dest="$2"

  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
    cp -a "$dest" "$BACKUP_DIR/$dest"
    echo "🛡️  Backup: $dest"
  fi

  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  echo "✅ Updated: $dest"
}

copy_with_backup "$PATCH_ROOT/backend/routes/api.php" "backend/routes/api.php"
copy_with_backup "$PATCH_ROOT/backend/app/Http/Controllers/Api/FinanceAccountController.php" "backend/app/Http/Controllers/Api/FinanceAccountController.php"
copy_with_backup "$PATCH_ROOT/backend/app/Http/Controllers/Api/FinanceTransactionController.php" "backend/app/Http/Controllers/Api/FinanceTransactionController.php"
copy_with_backup "$PATCH_ROOT/backend/app/Http/Controllers/Api/V1/ProjectController.php" "backend/app/Http/Controllers/Api/V1/ProjectController.php"
copy_with_backup "$PATCH_ROOT/backend/app/Http/Controllers/Api/V1/ReportController.php" "backend/app/Http/Controllers/Api/V1/ReportController.php"

printf '%s\n' ''
printf '%s\n' '=============================='
printf '%s\n' ' Laravel validation'
printf '%s\n' '=============================='

docker exec nixlifeos-backend sh -lc "php -l app/Http/Controllers/Api/FinanceAccountController.php && php -l app/Http/Controllers/Api/FinanceTransactionController.php && php -l app/Http/Controllers/Api/V1/ProjectController.php && php -l app/Http/Controllers/Api/V1/ReportController.php && php -l routes/api.php"
docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"

printf '%s\n' ''
printf '%s\n' '=============================='
printf '%s\n' ' Route verification'
printf '%s\n' '=============================='

docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1 | grep -E 'finance/accounts|finance/transactions|projects|notifications/unread-count|reports' || true"

printf '%s\n' ''
printf '%s\n' '✅ STEP 81 patch installed. Run scripts/step81_e2e_retest.sh next.'

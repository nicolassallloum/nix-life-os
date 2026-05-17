#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$PROJECT_ROOT/step81-2-finance-json-hotfix"
BACKUP_DIR="$PROJECT_ROOT/backups/step81-2-finance-json-hotfix-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 81.2 — Finance JSON/Alias Hotfix Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR"

copy_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
    cp -a "$dest" "$BACKUP_DIR/$dest"
    echo "🛡️  Backup: $dest"
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$PATCH_ROOT/$src" "$dest"
  echo "✅ Updated: $dest"
}

copy_file "backend/app/Http/Controllers/Api/FinanceAccountController.php" "backend/app/Http/Controllers/Api/FinanceAccountController.php"
copy_file "backend/app/Http/Controllers/Api/FinanceTransactionController.php" "backend/app/Http/Controllers/Api/FinanceTransactionController.php"

echo ""
echo "=============================="
echo " Laravel validation"
echo "=============================="

docker exec nixlifeos-backend sh -lc "php -l app/Http/Controllers/Api/FinanceAccountController.php && php -l app/Http/Controllers/Api/FinanceTransactionController.php"
docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"

echo ""
echo "✅ STEP 81.2 finance JSON/alias hotfix installed."
echo "Next: run ./step81-2-finance-json-hotfix/scripts/step81_2_finance_retest.sh"

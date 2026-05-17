#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step81-1-finance-hotfix-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 81.1 — Finance E2E Hotfix Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR"

copy_file() {
  local rel="$1"
  if [ -f "$rel" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -a "$rel" "$BACKUP_DIR/$rel"
    echo "🛡️  Backup: $rel"
  fi

  mkdir -p "$(dirname "$rel")"
  cp -a "$PATCH_ROOT/$rel" "$rel"
  echo "✅ Updated: $rel"
}

copy_file "backend/app/Http/Controllers/Api/FinanceAccountController.php"
copy_file "backend/app/Http/Controllers/Api/FinanceTransactionController.php"

echo ""
echo "=============================="
echo " Laravel validation"
echo "=============================="

docker exec nixlifeos-backend sh -lc "cd /var/www/html && php -l app/Http/Controllers/Api/FinanceAccountController.php && php -l app/Http/Controllers/Api/FinanceTransactionController.php && php artisan optimize:clear"

echo ""
echo "✅ STEP 81.1 finance hotfix installed."
echo "Next: run ./step81-1-finance-e2e-hotfix/scripts/step81_1_finance_retest.sh"

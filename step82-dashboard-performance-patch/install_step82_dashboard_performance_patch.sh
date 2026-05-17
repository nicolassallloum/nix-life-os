#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step82-dashboard-performance-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

copy_file() {
  local rel="$1"
  local src="$PATCH_ROOT/$rel"
  local dest="$PROJECT_ROOT/$rel"

  if [ ! -f "$src" ]; then
    echo "⚠️ Patch file missing: $rel"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp "$dest" "$BACKUP_DIR/$rel"
    echo "🛡️ Backup: $rel"
  fi

  cp "$src" "$dest"
  echo "✅ Updated: $rel"
}

copy_optional_dir() {
  local rel="$1"
  local src="$PATCH_ROOT/$rel"
  local dest="$PROJECT_ROOT/$rel"

  if [ -d "$src" ]; then
    mkdir -p "$dest"
    cp -r "$src"/. "$dest"/
    echo "✅ Copied directory: $rel"
  fi
}

echo "=================================================="
echo " STEP 82 — Dashboard Performance Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

copy_file "backend/bootstrap/app.php"
copy_file "backend/app/Providers/AppServiceProvider.php"
copy_file "backend/app/Http/Middleware/ApiPerformanceLogger.php"
copy_file "backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php"
copy_file "backend/app/Http/Controllers/Api/LifeBalanceController.php"
copy_file "backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
copy_file "backend/app/Http/Controllers/Api/FinanceTransactionController.php"
copy_file "backend/database/migrations/2026_05_17_220082_add_step82_dashboard_performance_indexes.php"
copy_file "frontend/src/services/dashboardApi.js"
copy_file "frontend/src/views/dashboard/DashboardView.vue"
copy_file "frontend/src/views/dashboard/UnifiedDashboardView.vue"
copy_optional_dir "scripts"
copy_optional_dir "docs"

cd "$PROJECT_ROOT/backend"

php -l app/Providers/AppServiceProvider.php
php -l app/Http/Middleware/ApiPerformanceLogger.php
php -l app/Http/Controllers/Api/V1/Dashboard/DashboardController.php
php -l app/Http/Controllers/Api/LifeBalanceController.php
php -l app/Http/Controllers/Api/V1/Health/HealthDashboardController.php
php -l app/Http/Controllers/Api/V1/ProductivityDashboardController.php
php -l app/Http/Controllers/Api/V1/ProjectDashboardController.php
php -l app/Http/Controllers/Api/FinanceTransactionController.php
php -l database/migrations/2026_05_17_220082_add_step82_dashboard_performance_indexes.php

php artisan optimize:clear
php artisan migrate --force
php artisan optimize:clear

echo ""
echo "✅ STEP 82 patch installed successfully."
echo "Run retest:"
echo "cd $PROJECT_ROOT && ./scripts/step82_retest_dashboard_performance.sh"

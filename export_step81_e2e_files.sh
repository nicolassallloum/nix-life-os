#!/usr/bin/env bash

set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_DIR="$PROJECT_ROOT/step81-e2e-export"
ARCHIVE_NAME="step81-e2e-needed-files.tar.gz"

echo "=================================================="
echo " STEP 81 — Full E2E Files Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $ARCHIVE_NAME"
echo "=================================================="

cd "$PROJECT_ROOT"

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_DIR/$src"

  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "✅ Copied: $src"
  else
    echo "⚠️ Missing: $src"
  fi
}

echo ""
echo "=============================="
echo " Copying Backend Files"
echo "=============================="

copy_if_exists "backend/routes/api.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/AuthController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/DashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceAccountController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceTransactionController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceBudgetController.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthNutritionController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthHydrationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthWeightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthStepController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthLabTestController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthMedicationController.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityTaskController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityGoalController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityHabitController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityCalendarController.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/NotificationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ReportController.php"

copy_if_exists "backend/app/Models/User.php"
copy_if_exists "backend/app/Models/FinanceAccount.php"
copy_if_exists "backend/app/Models/FinanceTransaction.php"
copy_if_exists "backend/app/Models/FinanceBudget.php"
copy_if_exists "backend/app/Models/HealthNutritionLog.php"
copy_if_exists "backend/app/Models/HealthHydrationLog.php"
copy_if_exists "backend/app/Models/HealthWeightLog.php"
copy_if_exists "backend/app/Models/HealthStepLog.php"
copy_if_exists "backend/app/Models/HealthLabTest.php"
copy_if_exists "backend/app/Models/HealthMedication.php"
copy_if_exists "backend/app/Models/Project.php"
copy_if_exists "backend/app/Models/ProductivityTask.php"
copy_if_exists "backend/app/Models/ProductivityGoal.php"
copy_if_exists "backend/app/Models/ProductivityHabit.php"
copy_if_exists "backend/app/Models/AIRecommendation.php"
copy_if_exists "backend/app/Models/Notification.php"

copy_if_exists "backend/app/Services"
copy_if_exists "backend/app/Http/Middleware"
copy_if_exists "backend/app/Exceptions/Handler.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/cors.php"
copy_if_exists "backend/composer.json"

echo ""
echo "=============================="
echo " Copying Database Files"
echo "=============================="

copy_if_exists "backend/database/migrations"
copy_if_exists "backend/database/seeders"
copy_if_exists "backend/database/factories"

echo ""
echo "=============================="
echo " Copying Frontend Files"
echo "=============================="

copy_if_exists "frontend/package.json"
copy_if_exists "frontend/vite.config.js"
copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"

copy_if_exists "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts"

copy_if_exists "frontend/src/services/api.js"
copy_if_exists "frontend/src/services/api.ts"
copy_if_exists "frontend/src/services/authService.js"
copy_if_exists "frontend/src/services/authService.ts"
copy_if_exists "frontend/src/services/financeService.js"
copy_if_exists "frontend/src/services/financeService.ts"
copy_if_exists "frontend/src/services/healthService.js"
copy_if_exists "frontend/src/services/healthService.ts"
copy_if_exists "frontend/src/services/projectService.js"
copy_if_exists "frontend/src/services/projectService.ts"
copy_if_exists "frontend/src/services/productivityService.js"
copy_if_exists "frontend/src/services/productivityService.ts"
copy_if_exists "frontend/src/services/aiRecommendationService.js"
copy_if_exists "frontend/src/services/aiRecommendationService.ts"
copy_if_exists "frontend/src/services/notificationService.js"
copy_if_exists "frontend/src/services/notificationService.ts"
copy_if_exists "frontend/src/services/reportService.js"
copy_if_exists "frontend/src/services/reportService.ts"

copy_if_exists "frontend/src/layouts/AppLayout.vue"
copy_if_exists "frontend/src/components"
copy_if_exists "frontend/src/views/dashboard"
copy_if_exists "frontend/src/views/finance"
copy_if_exists "frontend/src/views/health"
copy_if_exists "frontend/src/views/projects"
copy_if_exists "frontend/src/views/productivity"
copy_if_exists "frontend/src/views/ai"
copy_if_exists "frontend/src/views/notifications"
copy_if_exists "frontend/src/views/reports"
copy_if_exists "frontend/src/views/auth"

echo ""
echo "=============================="
echo " Copying Logs"
echo "=============================="

copy_if_exists "backend/storage/logs/laravel.log"

echo ""
echo "=============================="
echo " Generating Diagnostic Outputs"
echo "=============================="

mkdir -p "$EXPORT_DIR/diagnostics"

echo "Running docker compose ps..."
docker compose ps > "$EXPORT_DIR/diagnostics/docker-compose-ps.txt" 2>&1 || true

echo "Running backend route list..."
docker exec nixlifeos-backend sh -lc "php artisan route:list --path=api/v1" \
  > "$EXPORT_DIR/diagnostics/route-list-api-v1.txt" 2>&1 || true

echo "Running migration status..."
docker exec nixlifeos-backend sh -lc "php artisan migrate:status" \
  > "$EXPORT_DIR/diagnostics/migrate-status.txt" 2>&1 || true

echo "Running backend syntax check..."
docker exec nixlifeos-backend sh -lc "find app routes database -name '*.php' -print0 | xargs -0 -n1 php -l" \
  > "$EXPORT_DIR/diagnostics/php-syntax-check.txt" 2>&1 || true

echo "Exporting backend logs..."
docker compose logs backend --tail=300 \
  > "$EXPORT_DIR/diagnostics/docker-backend-logs.txt" 2>&1 || true

echo "Exporting backend nginx logs..."
docker compose logs backend-nginx --tail=300 \
  > "$EXPORT_DIR/diagnostics/docker-backend-nginx-logs.txt" 2>&1 || true

echo "Exporting frontend logs..."
docker compose logs frontend --tail=300 \
  > "$EXPORT_DIR/diagnostics/docker-frontend-logs.txt" 2>&1 || true

echo ""
echo "=============================="
echo " Creating Archive"
echo "=============================="

tar -czf "$PROJECT_ROOT/$ARCHIVE_NAME" -C "$PROJECT_ROOT" "$(basename "$EXPORT_DIR")"

echo ""
echo "=================================================="
echo " ✅ STEP 81 export completed"
echo " File created:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

#!/usr/bin/env bash
set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_DIR="/tmp/step72-ai-module-export"
ARCHIVE_NAME="step72-ai-module-files.tar.gz"

echo "=================================================="
echo " STEP 72 — AI Module Stabilization File Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local file="$1"

  if [ -f "$PROJECT_ROOT/$file" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$file")"
    cp "$PROJECT_ROOT/$file" "$EXPORT_DIR/$file"
    echo "COPIED: $file"
  else
    echo "MISSING: $file"
  fi
}

copy_glob_if_exists() {
  local pattern="$1"
  shopt -s nullglob

  local files=( "$PROJECT_ROOT"/$pattern )

  if [ ${#files[@]} -gt 0 ]; then
    for fullfile in "${files[@]}"; do
      local relfile="${fullfile#$PROJECT_ROOT/}"
      mkdir -p "$EXPORT_DIR/$(dirname "$relfile")"
      cp "$fullfile" "$EXPORT_DIR/$relfile"
      echo "COPIED: $relfile"
    done
  else
    echo "MISSING GLOB: $pattern"
  fi
}

echo ""
echo "Exporting backend routes..."
copy_if_exists "backend/routes/api.php"

echo ""
echo "Exporting backend AI controllers..."
copy_if_exists "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/RecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceAIInsightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthAIInsightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityAIInsightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/LifeBalanceAIController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/DashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/UnifiedDashboardController.php"

echo ""
echo "Exporting backend AI services..."
copy_if_exists "backend/app/Services/AIRecommendationService.php"
copy_if_exists "backend/app/Services/RecommendationRuleEngineService.php"
copy_if_exists "backend/app/Services/FinanceAIInsightService.php"
copy_if_exists "backend/app/Services/HealthAIInsightService.php"
copy_if_exists "backend/app/Services/ProductivityAIInsightService.php"
copy_if_exists "backend/app/Services/LifeBalanceAIService.php"
copy_if_exists "backend/app/Services/AIInsightScoringService.php"

echo ""
echo "Exporting backend models..."
copy_if_exists "backend/app/Models/AIRecommendation.php"
copy_if_exists "backend/app/Models/AIRecommendationFeedback.php"
copy_if_exists "backend/app/Models/AIInsight.php"
copy_if_exists "backend/app/Models/AIInsightLog.php"
copy_if_exists "backend/app/Models/FinanceTransaction.php"
copy_if_exists "backend/app/Models/FinanceBudget.php"
copy_if_exists "backend/app/Models/FinanceAccount.php"
copy_if_exists "backend/app/Models/HealthNutritionLog.php"
copy_if_exists "backend/app/Models/HealthHydrationLog.php"
copy_if_exists "backend/app/Models/HealthWeightLog.php"
copy_if_exists "backend/app/Models/HealthStepLog.php"
copy_if_exists "backend/app/Models/HealthLabTest.php"
copy_if_exists "backend/app/Models/HealthMedication.php"
copy_if_exists "backend/app/Models/ProductivityTask.php"
copy_if_exists "backend/app/Models/ProductivityHabit.php"
copy_if_exists "backend/app/Models/ProductivityGoal.php"
copy_if_exists "backend/app/Models/ProductivityCalendarEvent.php"
copy_if_exists "backend/app/Models/LifeBalanceScore.php"

echo ""
echo "Exporting AI / recommendation / insight migrations..."
copy_glob_if_exists "backend/database/migrations/*ai*"
copy_glob_if_exists "backend/database/migrations/*AI*"
copy_glob_if_exists "backend/database/migrations/*recommendation*"
copy_glob_if_exists "backend/database/migrations/*insight*"
copy_glob_if_exists "backend/database/migrations/*finance*"
copy_glob_if_exists "backend/database/migrations/*health*"
copy_glob_if_exists "backend/database/migrations/*productivity*"
copy_glob_if_exists "backend/database/migrations/*life_balance*"

echo ""
echo "Exporting seeders and factories..."
copy_if_exists "backend/database/seeders/AIRecommendationSeeder.php"
copy_if_exists "backend/database/seeders/AIRecommendationRuleSeeder.php"
copy_if_exists "backend/database/seeders/FinanceSeeder.php"
copy_if_exists "backend/database/seeders/HealthSeeder.php"
copy_if_exists "backend/database/seeders/ProductivitySeeder.php"
copy_if_exists "backend/database/seeders/LifeBalanceSeeder.php"
copy_if_exists "backend/database/factories/AIRecommendationFactory.php"

echo ""
echo "Exporting Laravel config and middleware..."
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/cors.php"
copy_if_exists "backend/app/Http/Kernel.php"
copy_if_exists "backend/app/Http/Middleware/Authenticate.php"
copy_if_exists "backend/app/Http/Middleware/EnsureFrontendRequestsAreStateful.php"

echo ""
echo "Exporting frontend router..."
copy_if_exists "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts"

echo ""
echo "Exporting frontend services..."
copy_if_exists "frontend/src/services/api.js"
copy_if_exists "frontend/src/services/api.ts"
copy_if_exists "frontend/src/services/aiService.js"
copy_if_exists "frontend/src/services/aiService.ts"
copy_if_exists "frontend/src/services/recommendationService.js"
copy_if_exists "frontend/src/services/recommendationService.ts"
copy_if_exists "frontend/src/services/financeService.js"
copy_if_exists "frontend/src/services/financeService.ts"
copy_if_exists "frontend/src/services/healthService.js"
copy_if_exists "frontend/src/services/healthService.ts"
copy_if_exists "frontend/src/services/productivityService.js"
copy_if_exists "frontend/src/services/productivityService.ts"
copy_if_exists "frontend/src/services/lifeBalanceService.js"
copy_if_exists "frontend/src/services/lifeBalanceService.ts"

echo ""
echo "Exporting frontend AI views..."
copy_if_exists "frontend/src/views/ai/AIRecommendationsView.vue"
copy_if_exists "frontend/src/views/ai/AIInsightsView.vue"
copy_if_exists "frontend/src/views/ai/AIModuleView.vue"
copy_if_exists "frontend/src/views/finance/FinanceAIInsightsView.vue"
copy_if_exists "frontend/src/views/health/HealthAIInsightsView.vue"
copy_if_exists "frontend/src/views/productivity/ProductivityAIInsightsView.vue"
copy_if_exists "frontend/src/views/life-balance/LifeBalanceView.vue"
copy_if_exists "frontend/src/views/dashboard/DashboardView.vue"
copy_if_exists "frontend/src/views/dashboard/UnifiedDashboardView.vue"

echo ""
echo "Exporting frontend AI widgets and dashboard components..."
copy_if_exists "frontend/src/components/ai/AIRecommendationCard.vue"
copy_if_exists "frontend/src/components/ai/AIInsightCard.vue"
copy_if_exists "frontend/src/components/ai/AIInsightWidget.vue"
copy_if_exists "frontend/src/components/dashboard/AIRecommendationWidget.vue"
copy_if_exists "frontend/src/components/dashboard/FinanceAIWidget.vue"
copy_if_exists "frontend/src/components/dashboard/HealthAIWidget.vue"
copy_if_exists "frontend/src/components/dashboard/ProductivityAIWidget.vue"
copy_if_exists "frontend/src/components/dashboard/LifeBalanceAIWidget.vue"

echo ""
echo "Exporting layout/sidebar files..."
copy_if_exists "frontend/src/layouts/AppLayout.vue"
copy_if_exists "frontend/src/components/layout/Sidebar.vue"
copy_if_exists "frontend/src/components/layout/AppSidebar.vue"
copy_if_exists "frontend/src/components/layout/NavigationSidebar.vue"

echo ""
echo "Exporting safe environment and Docker files..."
copy_if_exists "backend/.env.example"
copy_if_exists "frontend/.env.example"
copy_if_exists "docker-compose.yml"
copy_if_exists "docker-compose.prod.yml"

echo ""
echo "Exporting route list, migration status, and project diagnostics..."

mkdir -p "$EXPORT_DIR/diagnostics"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan route:list" > "$EXPORT_DIR/diagnostics/route-list.txt" 2>&1 || true
  docker exec nixlifeos-backend sh -lc "php artisan migrate:status" > "$EXPORT_DIR/diagnostics/migrate-status.txt" 2>&1 || true
  docker exec nixlifeos-backend sh -lc "php artisan about" > "$EXPORT_DIR/diagnostics/laravel-about.txt" 2>&1 || true
  docker exec nixlifeos-backend sh -lc "php -v" > "$EXPORT_DIR/diagnostics/php-version.txt" 2>&1 || true
else
  echo "nixlifeos-backend container not running." > "$EXPORT_DIR/diagnostics/docker-warning.txt"
fi

if [ -f "$PROJECT_ROOT/backend/storage/logs/laravel.log" ]; then
  tail -n 300 "$PROJECT_ROOT/backend/storage/logs/laravel.log" > "$EXPORT_DIR/diagnostics/laravel-log-tail.txt" || true
fi

echo ""
echo "Creating archive..."
cd /tmp
tar -czf "$PROJECT_ROOT/$ARCHIVE_NAME" "$(basename "$EXPORT_DIR")"

echo ""
echo "=================================================="
echo " Export Completed"
echo " Archive created:"
echo " $PROJECT_ROOT/$ARCHIVE_NAME"
echo "=================================================="

ls -lah "$PROJECT_ROOT/$ARCHIVE_NAME"

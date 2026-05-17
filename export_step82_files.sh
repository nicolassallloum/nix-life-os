#!/usr/bin/env bash
set -e

ROOT_DIR="/u01/nix-life-os"
EXPORT_DIR="/tmp/step82-dashboard-performance-files"
ARCHIVE_NAME="step82-dashboard-performance-files.tar.gz"

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR/backend"
mkdir -p "$EXPORT_DIR/frontend"
mkdir -p "$EXPORT_DIR/reports"

copy_if_exists() {
  local src="$1"
  local dest="$2"

  if [ -e "$ROOT_DIR/$src" ]; then
    mkdir -p "$(dirname "$EXPORT_DIR/$dest")"
    cp -r "$ROOT_DIR/$src" "$EXPORT_DIR/$dest"
    echo "✅ Copied: $src"
  else
    echo "⚠️ Missing: $src"
  fi
}

echo "=================================================="
echo " STEP 82 — Export Dashboard Performance Files"
echo " Root: $ROOT_DIR"
echo " Export: $EXPORT_DIR"
echo "=================================================="

# Backend routes and bootstrap
copy_if_exists "backend/routes/api.php" "backend/routes/api.php"
copy_if_exists "backend/bootstrap/app.php" "backend/bootstrap/app.php"

# Dashboard controllers
copy_if_exists "backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php" "backend/app/Http/Controllers/Api/V1/Dashboard/DashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/LifeBalanceController.php" "backend/app/Http/Controllers/Api/LifeBalanceController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php" "backend/app/Http/Controllers/Api/V1/Health/HealthDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php" "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php" "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"

# Finance controllers
copy_if_exists "backend/app/Http/Controllers/Api/FinanceAccountController.php" "backend/app/Http/Controllers/Api/FinanceAccountController.php"
copy_if_exists "backend/app/Http/Controllers/Api/FinanceTransactionController.php" "backend/app/Http/Controllers/Api/FinanceTransactionController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php" "backend/app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php" "backend/app/Http/Controllers/Api/V1/Finance/FinanceAIInsightController.php"

# Health controllers
copy_if_exists "backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php" "backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthAlertController.php" "backend/app/Http/Controllers/Api/V1/HealthAlertController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php" "backend/app/Http/Controllers/Api/V1/HealthHydrationLogController.php"
copy_if_exists "backend/app/Http/Controllers/Api/HealthNutritionLogController.php" "backend/app/Http/Controllers/Api/HealthNutritionLogController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Health/HealthStepLogController.php" "backend/app/Http/Controllers/Api/V1/Health/HealthStepLogController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthWeightLogController.php" "backend/app/Http/Controllers/Api/V1/HealthWeightLogController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php" "backend/app/Http/Controllers/Api/V1/Health/HealthLabTestController.php"

# Project controllers
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectController.php" "backend/app/Http/Controllers/Api/V1/ProjectController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php" "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php" "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectProgressController.php" "backend/app/Http/Controllers/Api/V1/ProjectProgressController.php"

# Productivity controllers
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php" "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityAIInsightController.php" "backend/app/Http/Controllers/Api/V1/ProductivityAIInsightController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/TaskController.php" "backend/app/Http/Controllers/Api/V1/TaskController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityGoalController.php" "backend/app/Http/Controllers/Api/V1/ProductivityGoalController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityHabitController.php" "backend/app/Http/Controllers/Api/V1/ProductivityHabitController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityCalendarEventController.php" "backend/app/Http/Controllers/Api/V1/ProductivityCalendarEventController.php"

# AI and notifications
copy_if_exists "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php" "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/LifeBalanceAiRecommendationController.php" "backend/app/Http/Controllers/Api/V1/LifeBalanceAiRecommendationController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/NotificationController.php" "backend/app/Http/Controllers/Api/V1/NotificationController.php"

# Middleware and providers
copy_if_exists "backend/app/Http/Middleware/ApiPerformanceLogger.php" "backend/app/Http/Middleware/ApiPerformanceLogger.php"
copy_if_exists "backend/app/Providers/AppServiceProvider.php" "backend/app/Providers/AppServiceProvider.php"

# Models
copy_if_exists "backend/app/Models/User.php" "backend/app/Models/User.php"
copy_if_exists "backend/app/Models/FinanceAccount.php" "backend/app/Models/FinanceAccount.php"
copy_if_exists "backend/app/Models/FinanceTransaction.php" "backend/app/Models/FinanceTransaction.php"
copy_if_exists "backend/app/Models/FinanceBudget.php" "backend/app/Models/FinanceBudget.php"
copy_if_exists "backend/app/Models/HealthNutritionLog.php" "backend/app/Models/HealthNutritionLog.php"
copy_if_exists "backend/app/Models/HealthHydrationLog.php" "backend/app/Models/HealthHydrationLog.php"
copy_if_exists "backend/app/Models/HealthWeightLog.php" "backend/app/Models/HealthWeightLog.php"
copy_if_exists "backend/app/Models/HealthStepLog.php" "backend/app/Models/HealthStepLog.php"
copy_if_exists "backend/app/Models/HealthLabTest.php" "backend/app/Models/HealthLabTest.php"
copy_if_exists "backend/app/Models/Project.php" "backend/app/Models/Project.php"
copy_if_exists "backend/app/Models/ProjectTask.php" "backend/app/Models/ProjectTask.php"
copy_if_exists "backend/app/Models/ProductivityTask.php" "backend/app/Models/ProductivityTask.php"
copy_if_exists "backend/app/Models/ProductivityGoal.php" "backend/app/Models/ProductivityGoal.php"
copy_if_exists "backend/app/Models/ProductivityHabit.php" "backend/app/Models/ProductivityHabit.php"
copy_if_exists "backend/app/Models/AIRecommendation.php" "backend/app/Models/AIRecommendation.php"
copy_if_exists "backend/app/Models/Notification.php" "backend/app/Models/Notification.php"

# Migrations
copy_if_exists "backend/database/migrations" "backend/database/migrations"

# Frontend router and services
copy_if_exists "frontend/src/router/index.js" "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts" "frontend/src/router/index.ts"
copy_if_exists "frontend/src/services" "frontend/src/services"

# Frontend views and dashboard/chart components
copy_if_exists "frontend/src/views/dashboard" "frontend/src/views/dashboard"
copy_if_exists "frontend/src/views/finance" "frontend/src/views/finance"
copy_if_exists "frontend/src/views/health" "frontend/src/views/health"
copy_if_exists "frontend/src/views/projects" "frontend/src/views/projects"
copy_if_exists "frontend/src/views/productivity" "frontend/src/views/productivity"
copy_if_exists "frontend/src/views/ai" "frontend/src/views/ai"
copy_if_exists "frontend/src/components/charts" "frontend/src/components/charts"
copy_if_exists "frontend/src/components/dashboard" "frontend/src/components/dashboard"

# Generate useful reports
echo "Generating route list..."
cd "$ROOT_DIR/backend"
php artisan route:list --path=api/v1 > "$EXPORT_DIR/reports/api_v1_route_list.txt" || true

echo "Generating dashboard-related route list..."
php artisan route:list --path=api/v1 | grep -Ei "finance|health|project|productivity|dashboard|life-balance|recommendation|notification" > "$EXPORT_DIR/reports/dashboard_related_routes.txt" || true

echo "Generating Laravel migration status..."
php artisan migrate:status > "$EXPORT_DIR/reports/migrate_status.txt" || true

echo "Generating Laravel log tail..."
tail -300 storage/logs/laravel.log > "$EXPORT_DIR/reports/laravel_log_tail.txt" || true

echo "Generating Git status..."
cd "$ROOT_DIR"
git status --short > "$EXPORT_DIR/reports/git_status_short.txt" 2>/dev/null || true

# Optional database reports
echo "Generating PostgreSQL table stats..."
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    relname AS table_name,
    n_live_tup AS estimated_rows,
    n_dead_tup AS estimated_dead_rows,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
" > "$EXPORT_DIR/reports/postgres_table_stats.txt" 2>&1 || true

echo "Generating PostgreSQL index report..."
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN (
    'finance_transactions',
    'finance_accounts',
    'finance_budgets',
    'health_nutrition_logs',
    'health_hydration_logs',
    'health_weight_logs',
    'health_step_logs',
    'projects',
    'project_tasks',
    'productivity_tasks',
    'productivity_goals',
    'productivity_habits',
    'ai_recommendations',
    'notifications'
)
ORDER BY tablename, indexname;
" > "$EXPORT_DIR/reports/postgres_indexes.txt" 2>&1 || true

# Archive
cd /tmp
tar -czf "$ARCHIVE_NAME" "$(basename "$EXPORT_DIR")"

mv "/tmp/$ARCHIVE_NAME" "$ROOT_DIR/$ARCHIVE_NAME"

echo ""
echo "=================================================="
echo "✅ STEP 82 export completed"
echo "Archive created:"
echo "$ROOT_DIR/$ARCHIVE_NAME"
echo "=================================================="

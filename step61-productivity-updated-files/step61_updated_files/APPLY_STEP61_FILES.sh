#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Applying STEP 61 Productivity Dashboard files to: $PROJECT_ROOT"

mkdir -p "$PROJECT_ROOT/backend/app/Http/Controllers/Api/V1"
mkdir -p "$PROJECT_ROOT/backend/app/Models"
mkdir -p "$PROJECT_ROOT/backend/database/migrations"
mkdir -p "$PROJECT_ROOT/backend/routes"
mkdir -p "$PROJECT_ROOT/frontend/src/services"
mkdir -p "$PROJECT_ROOT/frontend/src/views/productivity"
mkdir -p "$PROJECT_ROOT/frontend/src/router"
mkdir -p "$PROJECT_ROOT/frontend/src/layouts"

cp "$SOURCE_DIR/backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php" "$PROJECT_ROOT/backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
cp "$SOURCE_DIR/backend/app/Models/ProductivityTask.php" "$PROJECT_ROOT/backend/app/Models/ProductivityTask.php"
cp "$SOURCE_DIR/backend/app/Models/ProductivityHabit.php" "$PROJECT_ROOT/backend/app/Models/ProductivityHabit.php"
cp "$SOURCE_DIR/backend/app/Models/ProductivityGoal.php" "$PROJECT_ROOT/backend/app/Models/ProductivityGoal.php"
cp "$SOURCE_DIR/backend/app/Models/ProductivityCalendarEvent.php" "$PROJECT_ROOT/backend/app/Models/ProductivityCalendarEvent.php"
cp "$SOURCE_DIR/backend/database/migrations/2026_05_14_000061_create_productivity_module_tables.php" "$PROJECT_ROOT/backend/database/migrations/2026_05_14_000061_create_productivity_module_tables.php"
cp "$SOURCE_DIR/backend/routes/api.php" "$PROJECT_ROOT/backend/routes/api.php"
cp "$SOURCE_DIR/frontend/src/services/productivityService.js" "$PROJECT_ROOT/frontend/src/services/productivityService.js"
cp "$SOURCE_DIR/frontend/src/views/productivity/ProductivityDashboardView.vue" "$PROJECT_ROOT/frontend/src/views/productivity/ProductivityDashboardView.vue"
cp "$SOURCE_DIR/frontend/src/router/index.js" "$PROJECT_ROOT/frontend/src/router/index.js"
cp "$SOURCE_DIR/frontend/src/layouts/AppLayout.vue" "$PROJECT_ROOT/frontend/src/layouts/AppLayout.vue"

echo "Files applied successfully."
echo "Next commands:"
echo "cd $PROJECT_ROOT/backend && php artisan optimize:clear && php artisan migrate"
echo "cd $PROJECT_ROOT/frontend && npm run build"

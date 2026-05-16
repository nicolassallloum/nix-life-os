#!/usr/bin/env bash

set -e

EXPORT_DIR="step70-productivity-ai-insights-files"
ARCHIVE_NAME="step70-productivity-ai-insights-files.tar.gz"

echo "=================================================="
echo " STEP 70 - Productivity AI Insights Files Export"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_file() {
  local file="$1"

  if [ -f "$file" ]; then
    mkdir -p "$EXPORT_DIR/$(dirname "$file")"
    cp "$file" "$EXPORT_DIR/$file"
    echo "✅ Copied: $file"
  else
    echo "⚠️ Missing: $file"
  fi
}

copy_glob() {
  local pattern="$1"
  shopt -s nullglob
  local files=( $pattern )

  if [ ${#files[@]} -eq 0 ]; then
    echo "⚠️ Missing pattern: $pattern"
  else
    for file in "${files[@]}"; do
      copy_file "$file"
    done
  fi
  shopt -u nullglob
}

echo ""
echo "📁 Exporting Backend Routes..."
copy_file "backend/routes/api.php"

echo ""
echo "📁 Exporting Backend Controllers..."
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityAIInsightController.php"
copy_file "backend/app/Http/Controllers/Api/V1/TaskController.php"
copy_file "backend/app/Http/Controllers/Api/V1/HabitController.php"
copy_file "backend/app/Http/Controllers/Api/V1/GoalController.php"
copy_file "backend/app/Http/Controllers/Api/V1/CalendarController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityTaskController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityHabitController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityGoalController.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityCalendarController.php"

echo ""
echo "📁 Exporting Backend Models..."
copy_file "backend/app/Models/ProductivityTask.php"
copy_file "backend/app/Models/ProductivityHabit.php"
copy_file "backend/app/Models/ProductivityHabitLog.php"
copy_file "backend/app/Models/ProductivityGoal.php"
copy_file "backend/app/Models/ProductivityCalendarEvent.php"

copy_file "backend/app/Models/Task.php"
copy_file "backend/app/Models/Habit.php"
copy_file "backend/app/Models/HabitLog.php"
copy_file "backend/app/Models/Goal.php"
copy_file "backend/app/Models/CalendarEvent.php"

echo ""
echo "📁 Exporting Backend Services If Available..."
copy_file "backend/app/Services/ProductivityAIInsightService.php"
copy_file "backend/app/Services/ProductivityInsightService.php"
copy_file "backend/app/Services/AI/ProductivityAIInsightService.php"

echo ""
echo "📁 Exporting Backend Resources If Available..."
copy_file "backend/app/Http/Resources/ProductivityAIInsightResource.php"
copy_file "backend/app/Http/Resources/ProductivityDashboardResource.php"

echo ""
echo "📁 Exporting Migrations..."
copy_glob "backend/database/migrations/*productivity*.php"
copy_glob "backend/database/migrations/*task*.php"
copy_glob "backend/database/migrations/*habit*.php"
copy_glob "backend/database/migrations/*goal*.php"
copy_glob "backend/database/migrations/*calendar*.php"

echo ""
echo "📁 Exporting Seeders If Available..."
copy_glob "backend/database/seeders/*Productivity*.php"
copy_glob "backend/database/seeders/*Task*.php"
copy_glob "backend/database/seeders/*Habit*.php"
copy_glob "backend/database/seeders/*Goal*.php"
copy_glob "backend/database/seeders/*Calendar*.php"

echo ""
echo "📁 Exporting Frontend Router..."
copy_file "frontend/src/router/index.js"
copy_file "frontend/src/router/index.ts"

echo ""
echo "📁 Exporting Frontend Services..."
copy_file "frontend/src/services/productivityService.js"
copy_file "frontend/src/services/productivityService.ts"
copy_file "frontend/src/services/api.js"
copy_file "frontend/src/services/api.ts"
copy_file "frontend/src/services/http.js"
copy_file "frontend/src/services/http.ts"

echo ""
echo "📁 Exporting Frontend Layouts..."
copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/layouts/MainLayout.vue"
copy_file "frontend/src/components/Sidebar.vue"
copy_file "frontend/src/components/AppSidebar.vue"
copy_file "frontend/src/components/layout/Sidebar.vue"

echo ""
echo "📁 Exporting Frontend Productivity Views..."
copy_file "frontend/src/views/productivity/ProductivityDashboardView.vue"
copy_file "frontend/src/views/productivity/ProductivityAIInsightsView.vue"
copy_file "frontend/src/views/productivity/TasksView.vue"
copy_file "frontend/src/views/productivity/HabitsView.vue"
copy_file "frontend/src/views/productivity/GoalsView.vue"
copy_file "frontend/src/views/productivity/CalendarView.vue"

copy_file "frontend/src/views/productivity/ProductivityTasksView.vue"
copy_file "frontend/src/views/productivity/ProductivityHabitsView.vue"
copy_file "frontend/src/views/productivity/ProductivityGoalsView.vue"
copy_file "frontend/src/views/productivity/ProductivityCalendarView.vue"

echo ""
echo "📁 Exporting Frontend Stores If Available..."
copy_file "frontend/src/stores/auth.js"
copy_file "frontend/src/stores/auth.ts"
copy_file "frontend/src/stores/productivity.js"
copy_file "frontend/src/stores/productivity.ts"

echo ""
echo "📁 Exporting Main Frontend Files..."
copy_file "frontend/src/main.js"
copy_file "frontend/src/main.ts"
copy_file "frontend/package.json"
copy_file "frontend/vite.config.js"
copy_file "frontend/vite.config.ts"

echo ""
echo "📁 Exporting Backend Config Files If Helpful..."
copy_file "backend/composer.json"
copy_file "backend/.env.example"

echo ""
echo "🧾 Creating file list..."
find "$EXPORT_DIR" -type f | sort > "$EXPORT_DIR/FILES_INCLUDED.txt"

echo ""
echo "📦 Creating archive..."
tar -czf "$ARCHIVE_NAME" "$EXPORT_DIR"

echo ""
echo "=================================================="
echo "✅ Export Completed"
echo "Archive Created: $ARCHIVE_NAME"
echo "Folder Created:  $EXPORT_DIR"
echo "=================================================="
echo ""
echo "Now send this file:"
echo "$ARCHIVE_NAME"
echo ""

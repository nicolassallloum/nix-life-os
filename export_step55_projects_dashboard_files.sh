#!/bin/bash

OUTPUT_FILE="step55_projects_dashboard_files.txt"

rm -f "$OUTPUT_FILE"

echo "==================================================" >> "$OUTPUT_FILE"
echo "STEP 55 - PROJECTS DASHBOARD FILE EXPORT" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

add_file () {
  FILE_PATH="$1"

  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "FILE: $FILE_PATH" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  if [ -f "$FILE_PATH" ]; then
    sed -n '1,500p' "$FILE_PATH" >> "$OUTPUT_FILE"
  else
    echo "NOT FOUND: $FILE_PATH" >> "$OUTPUT_FILE"
  fi
}

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND FILE TREE ================" >> "$OUTPUT_FILE"
find frontend/src -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND FILE TREE ================" >> "$OUTPUT_FILE"
find backend/app backend/routes backend/database -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE"

add_file "frontend/src/views/projects/ProjectsDashboardView.vue"
add_file "frontend/src/views/projects/ProjectDashboardView.vue"
add_file "frontend/src/views/projects/ProjectsView.vue"
add_file "frontend/src/router/index.js"
add_file "frontend/src/layouts/AppLayout.vue"
add_file "frontend/src/App.vue"
add_file "frontend/src/services/projectService.js"
add_file "frontend/src/services/api.js"

add_file "backend/routes/api.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
add_file "backend/app/Models/Project.php"
add_file "backend/app/Models/ProjectTask.php"
add_file "backend/app/Models/Task.php"

echo "" >> "$OUTPUT_FILE"
echo "================ PROJECT MIGRATIONS ================" >> "$OUTPUT_FILE"
find backend/database/migrations -iname "*project*" -o -iname "*task*" | sort >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "================ PROJECT ROUTES ================" >> "$OUTPUT_FILE"
cd backend
php artisan route:list | grep -i project >> "../$OUTPUT_FILE" 2>&1
cd ..

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "EXPORT COMPLETED" >> "$OUTPUT_FILE"
echo "Output file: $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

echo "Done. File created: $OUTPUT_FILE"

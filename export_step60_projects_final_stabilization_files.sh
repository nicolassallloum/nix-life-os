#!/bin/bash

OUTPUT_FILE="step60_projects_final_stabilization_files.txt"

rm -f "$OUTPUT_FILE"

echo "==================================================" >> "$OUTPUT_FILE"
echo "STEP 60 - PROJECTS MODULE FINAL STABILIZATION FILE EXPORT" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "Project Path: $(pwd)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

add_file () {
  FILE_PATH="$1"

  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "FILE: $FILE_PATH" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  if [ -f "$FILE_PATH" ]; then
    sed -n '1,700p' "$FILE_PATH" >> "$OUTPUT_FILE"
  else
    echo "NOT FOUND: $FILE_PATH" >> "$OUTPUT_FILE"
  fi
}

echo "" >> "$OUTPUT_FILE"
echo "================ RUNNING CONTAINERS ================" >> "$OUTPUT_FILE"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND ROUTES: PROJECTS ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -i project" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find backend/app backend/routes backend/database -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find frontend/src -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND ROUTER SEARCH ================" >> "$OUTPUT_FILE"
grep -Rni "project" frontend/src/router frontend/src 2>/dev/null | head -300 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "================ LARAVEL LOG LAST 300 LINES ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && tail -300 storage/logs/laravel.log" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ POSTGRES PROJECT TABLES ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name ILIKE '%project%'
ORDER BY table_name;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ POSTGRES PROJECT COLUMNS ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name ILIKE '%project%'
ORDER BY table_name, ordinal_position;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ POSTGRES PROJECT CONSTRAINTS ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name ILIKE '%project%'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ POSTGRES PROJECT ROW COUNTS ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
SELECT 'projects' AS table_name, COUNT(*) FROM projects
UNION ALL
SELECT 'project_tasks', COUNT(*) FROM project_tasks
UNION ALL
SELECT 'project_status_updates', COUNT(*) FROM project_status_updates
UNION ALL
SELECT 'project_milestones', COUNT(*) FROM project_milestones;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND CORE FILES ================" >> "$OUTPUT_FILE"

add_file "backend/routes/api.php"

add_file "backend/app/Http/Controllers/Api/V1/ProjectController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectStatusUpdateController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectMilestoneController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"

add_file "backend/app/Models/Project.php"
add_file "backend/app/Models/ProjectTask.php"
add_file "backend/app/Models/ProjectStatusUpdate.php"
add_file "backend/app/Models/ProjectMilestone.php"

add_file "backend/app/Http/Requests/StoreProjectRequest.php"
add_file "backend/app/Http/Requests/UpdateProjectRequest.php"
add_file "backend/app/Http/Requests/StoreProjectTaskRequest.php"
add_file "backend/app/Http/Requests/UpdateProjectTaskRequest.php"
add_file "backend/app/Http/Requests/StoreProjectStatusUpdateRequest.php"
add_file "backend/app/Http/Requests/StoreProjectMilestoneRequest.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MIGRATIONS ================" >> "$OUTPUT_FILE"

for file in backend/database/migrations/*project*.php backend/database/migrations/*Project*.php; do
  if [ -f "$file" ]; then
    add_file "$file"
  fi
done

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND SEEDERS / FACTORIES ================" >> "$OUTPUT_FILE"

find backend/database/seeders backend/database/factories -iname "*project*" -o -iname "*Project*" | sort | while read file; do
  if [ -f "$file" ]; then
    add_file "$file"
  fi
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND CORE FILES ================" >> "$OUTPUT_FILE"

add_file "frontend/src/router/index.ts"
add_file "frontend/src/router/index.js"

add_file "frontend/src/services/api.ts"
add_file "frontend/src/services/api.js"
add_file "frontend/src/services/projectService.ts"
add_file "frontend/src/services/projectService.js"
add_file "frontend/src/services/projectsService.ts"
add_file "frontend/src/services/projectsService.js"

add_file "frontend/src/views/projects/ProjectsDashboardView.vue"
add_file "frontend/src/views/projects/ProjectListView.vue"
add_file "frontend/src/views/projects/ProjectCreateView.vue"
add_file "frontend/src/views/projects/ProjectEditView.vue"
add_file "frontend/src/views/projects/ProjectDetailsView.vue"
add_file "frontend/src/views/projects/ProjectTasksView.vue"
add_file "frontend/src/views/projects/ProjectStatusUpdatesView.vue"
add_file "frontend/src/views/projects/ProjectMilestonesView.vue"

add_file "frontend/src/components/layout/Sidebar.vue"
add_file "frontend/src/components/Sidebar.vue"
add_file "frontend/src/layouts/AppLayout.vue"
add_file "frontend/src/App.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT COMPONENTS ================" >> "$OUTPUT_FILE"

find frontend/src/components frontend/src/views -iname "*project*.vue" -o -iname "*Project*.vue" | sort | while read file; do
  if [ -f "$file" ]; then
    add_file "$file"
  fi
done

echo "" >> "$OUTPUT_FILE"
echo "================ PACKAGE / ENV STRUCTURE ================" >> "$OUTPUT_FILE"

add_file "frontend/package.json"
add_file "backend/composer.json"
add_file "docker-compose.prod.yml"
add_file ".env.docker"

echo "" >> "$OUTPUT_FILE"
echo "================ BUILD CHECK ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan optimize:clear && php artisan route:list | grep -i project" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "EXPORT COMPLETED" >> "$OUTPUT_FILE"
echo "Output file: $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

echo "Export completed: $OUTPUT_FILE"

#!/bin/bash

OUTPUT_FILE="step58_project_tasks_files.txt"

rm -f "$OUTPUT_FILE"

echo "==================================================" >> "$OUTPUT_FILE"
echo "STEP 58 - PROJECT TASKS TESTING FILE EXPORT" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
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
echo "================ BACKEND ROUTE LIST - PROJECT/TASK ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -Ei 'project|task'" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND PROJECT/TASK FILE TREE ================" >> "$OUTPUT_FILE"
find backend/app backend/routes backend/database -iname "*project*" -o -iname "*task*" | sort >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT/TASK FILE TREE ================" >> "$OUTPUT_FILE"
find frontend/src -iname "*project*" -o -iname "*task*" | sort >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND ROUTES ================" >> "$OUTPUT_FILE"
add_file "backend/routes/api.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND CONTROLLERS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Controllers/Api/V1/ProjectController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php"
add_file "backend/app/Http/Controllers/Api/V1/TaskController.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MODELS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Models/Project.php"
add_file "backend/app/Models/ProjectTask.php"
add_file "backend/app/Models/Task.php"
add_file "backend/app/Models/User.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND REQUESTS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Requests/ProjectTaskStoreRequest.php"
add_file "backend/app/Http/Requests/ProjectTaskUpdateRequest.php"
add_file "backend/app/Http/Requests/TaskStoreRequest.php"
add_file "backend/app/Http/Requests/TaskUpdateRequest.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND RESOURCES ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Resources/ProjectResource.php"
add_file "backend/app/Http/Resources/ProjectTaskResource.php"
add_file "backend/app/Http/Resources/TaskResource.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MIGRATIONS - PROJECT/TASK ================" >> "$OUTPUT_FILE"
for f in backend/database/migrations/*project* backend/database/migrations/*task*; do
  if [ -f "$f" ]; then
    add_file "$f"
  fi
done

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND SEEDERS ================" >> "$OUTPUT_FILE"
add_file "backend/database/seeders/ProjectSeeder.php"
add_file "backend/database/seeders/ProjectTaskSeeder.php"
add_file "backend/database/seeders/TaskSeeder.php"
add_file "backend/database/seeders/DatabaseSeeder.php"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND ROUTER ================" >> "$OUTPUT_FILE"
add_file "frontend/src/router/index.ts"
add_file "frontend/src/router/index.js"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT VIEWS ================" >> "$OUTPUT_FILE"
add_file "frontend/src/views/projects/ProjectsDashboardView.vue"
add_file "frontend/src/views/projects/ProjectsListView.vue"
add_file "frontend/src/views/projects/ProjectCreateView.vue"
add_file "frontend/src/views/projects/ProjectEditView.vue"
add_file "frontend/src/views/projects/ProjectTasksView.vue"
add_file "frontend/src/views/projects/TasksView.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT COMPONENTS ================" >> "$OUTPUT_FILE"
add_file "frontend/src/components/projects/ProjectCard.vue"
add_file "frontend/src/components/projects/ProjectForm.vue"
add_file "frontend/src/components/projects/ProjectTaskCard.vue"
add_file "frontend/src/components/projects/ProjectTaskForm.vue"
add_file "frontend/src/components/projects/TaskStatusBadge.vue"
add_file "frontend/src/components/projects/TaskPriorityBadge.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND SERVICES / API ================" >> "$OUTPUT_FILE"
add_file "frontend/src/services/api.ts"
add_file "frontend/src/services/projectService.ts"
add_file "frontend/src/services/projectTaskService.ts"
add_file "frontend/src/services/taskService.ts"
add_file "frontend/src/api/projectApi.ts"
add_file "frontend/src/api/taskApi.ts"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND STORES ================" >> "$OUTPUT_FILE"
add_file "frontend/src/stores/projectStore.ts"
add_file "frontend/src/stores/projectTaskStore.ts"
add_file "frontend/src/stores/taskStore.ts"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND LAYOUT / SIDEBAR ================" >> "$OUTPUT_FILE"
add_file "frontend/src/layouts/AppLayout.vue"
add_file "frontend/src/components/layout/Sidebar.vue"
add_file "frontend/src/components/Sidebar.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND PHP SYNTAX CHECKS ================" >> "$OUTPUT_FILE"
docker exec nixlifeos-backend sh -lc "cd /var/www/html && find app/Http/Controllers app/Models routes -name '*.php' -print0 | xargs -0 -n1 php -l" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND TYPE CHECK / BUILD INFO ================" >> "$OUTPUT_FILE"
cd frontend 2>/dev/null && npm run type-check >> "../$OUTPUT_FILE" 2>&1
cd .. 2>/dev/null || true

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "EXPORT COMPLETED: $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

echo "Done. File created: $OUTPUT_FILE"

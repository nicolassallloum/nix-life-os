#!/bin/bash

OUTPUT_FILE="step_62_tasks_files_export.txt"

echo "STEP 62 TASKS FILES EXPORT" > "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "Project path: $(pwd)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

print_file () {
  FILE_PATH="$1"
  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "FILE: $FILE_PATH" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  if [ -f "$FILE_PATH" ]; then
    cat "$FILE_PATH" >> "$OUTPUT_FILE"
  else
    echo "NOT FOUND: $FILE_PATH" >> "$OUTPUT_FILE"
  fi
}

print_glob () {
  PATTERN="$1"
  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "GLOB: $PATTERN" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  FOUND=0
  for FILE in $PATTERN; do
    if [ -f "$FILE" ]; then
      FOUND=1
      print_file "$FILE"
    fi
  done

  if [ "$FOUND" -eq 0 ]; then
    echo "NOT FOUND: $PATTERN" >> "$OUTPUT_FILE"
  fi
}

print_file "backend/routes/api.php"
print_file "backend/app/Http/Controllers/Api/V1/TaskController.php"
print_file "backend/app/Models/Task.php"
print_file "backend/app/Http/Requests/StoreTaskRequest.php"
print_file "backend/app/Http/Requests/UpdateTaskRequest.php"

print_glob "backend/database/migrations/*task*"
print_glob "backend/database/migrations/*tasks*"
print_glob "backend/database/seeders/*Task*"
print_glob "backend/database/factories/*Task*"

print_file "frontend/src/router/index.js"
print_file "frontend/src/router/index.ts"

print_file "frontend/src/views/tasks/TasksView.vue"
print_file "frontend/src/views/productivity/TasksView.vue"
print_file "frontend/src/pages/tasks/TasksView.vue"

print_file "frontend/src/components/tasks/TaskForm.vue"
print_file "frontend/src/components/tasks/TaskList.vue"
print_file "frontend/src/components/tasks/TaskCard.vue"

print_file "frontend/src/services/taskService.js"
print_file "frontend/src/services/taskService.ts"
print_file "frontend/src/api/tasks.js"
print_file "frontend/src/api/tasks.ts"

print_file "frontend/src/layouts/Sidebar.vue"
print_file "frontend/src/components/Sidebar.vue"

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "LARAVEL ROUTES CONTAINING TASK" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
cd backend 2>/dev/null && php artisan route:list | grep -i task >> "../$OUTPUT_FILE" 2>&1
cd ..

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "FRONTEND TASK FILE SEARCH" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
find frontend/src -iname "*task*" -type f >> "$OUTPUT_FILE" 2>&1

echo ""
echo "Export completed:"
echo "$OUTPUT_FILE"

#!/bin/bash

OUTPUT_FILE="step57_project_create_edit_files.txt"

rm -f "$OUTPUT_FILE"

echo "==================================================" >> "$OUTPUT_FILE"
echo "STEP 57 - PROJECT CREATE / EDIT TESTING FILE EXPORT" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

add_file () {
  FILE_PATH="$1"

  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "FILE: $FILE_PATH" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  if [ -f "$FILE_PATH" ]; then
    sed -n '1,600p' "$FILE_PATH" >> "$OUTPUT_FILE"
  else
    echo "NOT FOUND: $FILE_PATH" >> "$OUTPUT_FILE"
  fi
}

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find backend/app backend/routes backend/database -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE" 2>/dev/null

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find frontend/src -iname "*project*" -o -iname "*Project*" | sort >> "$OUTPUT_FILE" 2>/dev/null

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND ROUTES ================" >> "$OUTPUT_FILE"
add_file "backend/routes/api.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND CONTROLLERS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Controllers/Api/V1/ProjectController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectsController.php"
add_file "backend/app/Http/Controllers/Api/V1/AuthController.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MODELS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Models/Project.php"
add_file "backend/app/Models/User.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND REQUESTS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Requests/StoreProjectRequest.php"
add_file "backend/app/Http/Requests/UpdateProjectRequest.php"
add_file "backend/app/Http/Requests/ProjectStoreRequest.php"
add_file "backend/app/Http/Requests/ProjectUpdateRequest.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND RESOURCES ================" >> "$OUTPUT_FILE"
add_file "backend/app/Http/Resources/ProjectResource.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND SERVICES / POLICIES / ENUMS ================" >> "$OUTPUT_FILE"
add_file "backend/app/Services/ProjectService.php"
add_file "backend/app/Policies/ProjectPolicy.php"
add_file "backend/app/Enums/ProjectStatus.php"
add_file "backend/app/Enums/ProjectPriority.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MIGRATIONS ================" >> "$OUTPUT_FILE"
for file in backend/database/migrations/*project* backend/database/migrations/*Project*; do
  [ -f "$file" ] && add_file "$file"
done

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND SEEDERS / FACTORIES ================" >> "$OUTPUT_FILE"
for file in backend/database/seeders/*Project* backend/database/factories/*Project*; do
  [ -f "$file" ] && add_file "$file"
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND ROUTER ================" >> "$OUTPUT_FILE"
add_file "frontend/src/router/index.ts"
add_file "frontend/src/router/index.js"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT VIEWS ================" >> "$OUTPUT_FILE"
for file in frontend/src/views/projects/* frontend/src/views/Projects/*; do
  [ -f "$file" ] && add_file "$file"
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT COMPONENTS ================" >> "$OUTPUT_FILE"
for file in frontend/src/components/projects/* frontend/src/components/Projects/*; do
  [ -f "$file" ] && add_file "$file"
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT SERVICES / API / STORE / TYPES ================" >> "$OUTPUT_FILE"
add_file "frontend/src/services/projectService.ts"
add_file "frontend/src/services/projectService.js"
add_file "frontend/src/api/projects.ts"
add_file "frontend/src/api/projects.js"
add_file "frontend/src/stores/projectStore.ts"
add_file "frontend/src/stores/projectStore.js"
add_file "frontend/src/types/project.ts"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND AUTH FILES ================" >> "$OUTPUT_FILE"
add_file "frontend/src/stores/authStore.ts"
add_file "frontend/src/stores/authStore.js"
add_file "frontend/src/services/authService.ts"
add_file "frontend/src/services/authService.js"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND SIDEBAR / LAYOUT FILES ================" >> "$OUTPUT_FILE"
add_file "frontend/src/layouts/Sidebar.vue"
add_file "frontend/src/components/layout/Sidebar.vue"
add_file "frontend/src/components/layout/AppSidebar.vue"
add_file "frontend/src/layouts/AppLayout.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ LARAVEL ROUTE LIST PROJECTS ================" >> "$OUTPUT_FILE"
cd backend
php artisan route:list | grep -i project >> "../$OUTPUT_FILE" 2>&1
cd ..

echo "" >> "$OUTPUT_FILE"
echo "================ DATABASE TABLE CHECK ================" >> "$OUTPUT_FILE"
docker exec -i nixlifeos-postgres psql -U postgres -d nix_life_os -c "\dt *project*" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ PROJECTS TABLE STRUCTURE ================" >> "$OUTPUT_FILE"
docker exec -i nixlifeos-postgres psql -U postgres -d nix_life_os -c "\d projects" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "EXPORT COMPLETED" >> "$OUTPUT_FILE"
echo "Output file: $OUTPUT_FILE" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"

echo "Done. File created: $OUTPUT_FILE"

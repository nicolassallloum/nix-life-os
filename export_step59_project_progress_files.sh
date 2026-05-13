#!/bin/bash

OUTPUT_FILE="step59_project_progress_status_files.txt"

rm -f "$OUTPUT_FILE"

echo "==================================================" >> "$OUTPUT_FILE"
echo "STEP 59 - PROJECT PROGRESS / STATUS TESTING FILE EXPORT" >> "$OUTPUT_FILE"
echo "Generated at: $(date)" >> "$OUTPUT_FILE"
echo "Project Root: $(pwd)" >> "$OUTPUT_FILE"
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

add_dir_files () {
  DIR_PATH="$1"
  PATTERN="$2"

  echo "" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"
  echo "DIRECTORY SCAN: $DIR_PATH | PATTERN: $PATTERN" >> "$OUTPUT_FILE"
  echo "==================================================" >> "$OUTPUT_FILE"

  if [ -d "$DIR_PATH" ]; then
    find "$DIR_PATH" -type f \( -iname "$PATTERN" \) | sort | while read -r FILE_PATH; do
      add_file "$FILE_PATH"
    done
  else
    echo "DIRECTORY NOT FOUND: $DIR_PATH" >> "$OUTPUT_FILE"
  fi
}

echo "" >> "$OUTPUT_FILE"
echo "================ DOCKER CONTAINERS ================" >> "$OUTPUT_FILE"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND ROUTES - PROJECTS ================" >> "$OUTPUT_FILE"
if [ -d "backend" ]; then
  docker exec nixlifeos-backend sh -lc "cd /var/www/html && php artisan route:list | grep -Ei 'project|task|milestone|status|progress|update'" >> "$OUTPUT_FILE" 2>&1
else
  echo "backend directory not found" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find backend/app backend/routes backend/database -type f 2>/dev/null | grep -Ei 'project|task|milestone|status|progress|update' | sort >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT FILE TREE ================" >> "$OUTPUT_FILE"
find frontend/src -type f 2>/dev/null | grep -Ei 'project|task|milestone|status|progress|update|chart|dashboard' | sort >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "================ MAIN BACKEND FILES ================" >> "$OUTPUT_FILE"

add_file "backend/routes/api.php"

add_file "backend/app/Http/Controllers/Api/V1/ProjectController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectTaskController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectMilestoneController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectStatusHistoryController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectUpdateController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectDashboardController.php"
add_file "backend/app/Http/Controllers/Api/V1/ProjectProgressController.php"

add_file "backend/app/Models/Project.php"
add_file "backend/app/Models/ProjectTask.php"
add_file "backend/app/Models/ProjectMilestone.php"
add_file "backend/app/Models/ProjectStatusHistory.php"
add_file "backend/app/Models/ProjectUpdate.php"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND REQUESTS / RESOURCES ================" >> "$OUTPUT_FILE"

add_dir_files "backend/app/Http/Requests" "*Project*"
add_dir_files "backend/app/Http/Requests" "*Task*"
add_dir_files "backend/app/Http/Requests" "*Milestone*"

add_dir_files "backend/app/Http/Resources" "*Project*"
add_dir_files "backend/app/Http/Resources" "*Task*"
add_dir_files "backend/app/Http/Resources" "*Milestone*"

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND MIGRATIONS ================" >> "$OUTPUT_FILE"

find backend/database/migrations -type f 2>/dev/null | grep -Ei 'project|task|milestone|status|progress|update' | sort | while read -r FILE_PATH; do
  add_file "$FILE_PATH"
done

echo "" >> "$OUTPUT_FILE"
echo "================ BACKEND SEEDERS / FACTORIES ================" >> "$OUTPUT_FILE"

find backend/database/seeders backend/database/factories -type f 2>/dev/null | grep -Ei 'project|task|milestone|status|progress|update' | sort | while read -r FILE_PATH; do
  add_file "$FILE_PATH"
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND ROUTER / MAIN ================" >> "$OUTPUT_FILE"

add_file "frontend/src/router/index.ts"
add_file "frontend/src/router/index.js"
add_file "frontend/src/main.ts"
add_file "frontend/src/main.js"
add_file "frontend/src/App.vue"

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT VIEWS ================" >> "$OUTPUT_FILE"

if [ -d "frontend/src/views/projects" ]; then
  find frontend/src/views/projects -type f | sort | while read -r FILE_PATH; do
    add_file "$FILE_PATH"
  done
fi

if [ -d "frontend/src/views/Projects" ]; then
  find frontend/src/views/Projects -type f | sort | while read -r FILE_PATH; do
    add_file "$FILE_PATH"
  done
fi

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND PROJECT COMPONENTS ================" >> "$OUTPUT_FILE"

if [ -d "frontend/src/components/projects" ]; then
  find frontend/src/components/projects -type f | sort | while read -r FILE_PATH; do
    add_file "$FILE_PATH"
  done
fi

if [ -d "frontend/src/components/Projects" ]; then
  find frontend/src/components/Projects -type f | sort | while read -r FILE_PATH; do
    add_file "$FILE_PATH"
  done
fi

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND SERVICES / STORES ================" >> "$OUTPUT_FILE"

find frontend/src/services frontend/src/stores frontend/src/api -type f 2>/dev/null | grep -Ei 'project|task|milestone|status|progress|update' | sort | while read -r FILE_PATH; do
  add_file "$FILE_PATH"
done

echo "" >> "$OUTPUT_FILE"
echo "================ FRONTEND LAYOUT / SIDEBAR FILES ================" >> "$OUTPUT_FILE"

find frontend/src/layouts frontend/src/components/layout frontend/src/components/sidebar -type f 2>/dev/null | sort | while read -r FILE_PATH; do
  add_file "$FILE_PATH"
done

echo "" >> "$OUTPUT_FILE"
echo "================ PACKAGE FILES ================" >> "$OUTPUT_FILE"

add_file "frontend/package.json"
add_file "frontend/vite.config.ts"
add_file "frontend/tsconfig.json"
add_file "backend/composer.json"

echo "" >> "$OUTPUT_FILE"
echo "================ DATABASE TABLE STRUCTURE CHECKS ================" >> "$OUTPUT_FILE"

docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "\dt *project*" >> "$OUTPUT_FILE" 2>&1
docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "\dt *task*" >> "$OUTPUT_FILE" 2>&1
docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "\dt *milestone*" >> "$OUTPUT_FILE" 2>&1
docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "\dt *status*" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ PROJECT TABLE COLUMNS ================" >> "$OUTPUT_FILE"

docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
    table_name ILIKE '%project%'
    OR table_name ILIKE '%task%'
    OR table_name ILIKE '%milestone%'
    OR table_name ILIKE '%status%'
    OR table_name ILIKE '%update%'
  )
ORDER BY table_name, ordinal_position;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ SAMPLE PROJECT DATA COUNTS ================" >> "$OUTPUT_FILE"

docker exec nixlifeos-postgres psql -U postgres -d nix_life_os -c "
SELECT 'projects' AS table_name, COUNT(*) FROM projects
UNION ALL
SELECT 'project_tasks', COUNT(*) FROM project_tasks
UNION ALL
SELECT 'project_milestones', COUNT(*) FROM project_milestones;
" >> "$OUTPUT_FILE" 2>&1

echo "" >> "$OUTPUT_FILE"
echo "================ STEP 59 EXPORT COMPLETED ================" >> "$OUTPUT_FILE"
echo "Output file: $OUTPUT_FILE" >> "$OUTPUT_FILE"

echo ""
echo "=================================================="
echo "STEP 59 export completed."
echo "File created: $OUTPUT_FILE"
echo "=================================================="

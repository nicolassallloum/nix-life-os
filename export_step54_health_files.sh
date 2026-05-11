#!/usr/bin/env bash

set +e

OUTPUT_FILE="step54_health_module_export_$(date +%Y%m%d_%H%M%S).txt"

echo "Exporting STEP 54 Health Module files..."
echo "Output file: $OUTPUT_FILE"

{
echo "============================================================"
echo "STEP 54 — HEALTH MODULE FINAL REGRESSION EXPORT"
echo "Generated At: $(date)"
echo "Project Path: $(pwd)"
echo "============================================================"

echo ""
echo "============================================================"
echo "1) DOCKER STATUS"
echo "============================================================"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "============================================================"
echo "2) DOCKER COMPOSE FILES"
echo "============================================================"
ls -la | grep -i compose

echo ""
echo "============================================================"
echo "3) ROOT DOCKER COMPOSE FILES CONTENT"
echo "============================================================"

for file in docker-compose.yml docker-compose.prod.yml docker-compose.override.yml; do
  if [ -f "$file" ]; then
    echo ""
    echo "================ FILE: $file ================"
    sed -n '1,320p' "$file"
  else
    echo ""
    echo "================ MISSING: $file ================"
  fi
done

echo ""
echo "============================================================"
echo "4) BACKEND ENV SAFE VIEW"
echo "============================================================"
if [ -f backend/.env ]; then
  echo "================ FILE: backend/.env SAFE ================"
  sed -E \
    -e 's/(DB_PASSWORD=).*/\1********/' \
    -e 's/(APP_KEY=).*/\1********/' \
    -e 's/(MAIL_PASSWORD=).*/\1********/' \
    -e 's/(REDIS_PASSWORD=).*/\1********/' \
    -e 's/(AWS_SECRET_ACCESS_KEY=).*/\1********/' \
    -e 's/(SANCTUM_STATEFUL_DOMAINS=).*/\1********/' \
    backend/.env
else
  echo "backend/.env not found"
fi

echo ""
echo "============================================================"
echo "5) FRONTEND ENV SAFE VIEW"
echo "============================================================"
if [ -f frontend/.env ]; then
  echo "================ FILE: frontend/.env SAFE ================"
  sed -E \
    -e 's/(VITE_.*TOKEN=).*/\1********/' \
    -e 's/(.*PASSWORD=).*/\1********/' \
    frontend/.env
else
  echo "frontend/.env not found"
fi

echo ""
echo "============================================================"
echo "6) BACKEND ROUTES API"
echo "============================================================"
if [ -f backend/routes/api.php ]; then
  echo "================ FILE: backend/routes/api.php ================"
  sed -n '1,360p' backend/routes/api.php
else
  echo "backend/routes/api.php not found"
fi

echo ""
echo "============================================================"
echo "7) BACKEND HEALTH ROUTE LIST"
echo "============================================================"
cd backend 2>/dev/null || true
php artisan route:list | grep -Ei "health|nutrition|hydration|sleep|mood|medication|lab|report|alert|steps|weight"
cd .. 2>/dev/null || true

echo ""
echo "============================================================"
echo "8) BACKEND CONTROLLERS LIST"
echo "============================================================"
find backend/app/Http/Controllers -type f \( \
  -iname "*Health*" \
  -o -iname "*Nutrition*" \
  -o -iname "*Hydration*" \
  -o -iname "*Sleep*" \
  -o -iname "*Mood*" \
  -o -iname "*Medication*" \
  -o -iname "*Lab*" \
  -o -iname "*Alert*" \
  -o -iname "*Report*" \
  -o -iname "*Step*" \
  -o -iname "*Weight*" \
\) | sort

echo ""
echo "============================================================"
echo "9) BACKEND CONTROLLERS CONTENT"
echo "============================================================"
for file in $(find backend/app/Http/Controllers -type f \( \
  -iname "*Health*" \
  -o -iname "*Nutrition*" \
  -o -iname "*Hydration*" \
  -o -iname "*Sleep*" \
  -o -iname "*Mood*" \
  -o -iname "*Medication*" \
  -o -iname "*Lab*" \
  -o -iname "*Alert*" \
  -o -iname "*Report*" \
  -o -iname "*Step*" \
  -o -iname "*Weight*" \
\) | sort); do
  echo ""
  echo "================ FILE: $file ================"
  sed -n '1,520p' "$file"
done

echo ""
echo "============================================================"
echo "10) BACKEND MODELS LIST"
echo "============================================================"
find backend/app/Models -type f \( \
  -iname "*Health*" \
  -o -iname "*Nutrition*" \
  -o -iname "*Hydration*" \
  -o -iname "*Sleep*" \
  -o -iname "*Mood*" \
  -o -iname "*Medication*" \
  -o -iname "*Lab*" \
  -o -iname "*Alert*" \
  -o -iname "*Report*" \
  -o -iname "*Step*" \
  -o -iname "*Weight*" \
\) | sort

echo ""
echo "============================================================"
echo "11) BACKEND MODELS CONTENT"
echo "============================================================"
for file in $(find backend/app/Models -type f \( \
  -iname "*Health*" \
  -o -iname "*Nutrition*" \
  -o -iname "*Hydration*" \
  -o -iname "*Sleep*" \
  -o -iname "*Mood*" \
  -o -iname "*Medication*" \
  -o -iname "*Lab*" \
  -o -iname "*Alert*" \
  -o -iname "*Report*" \
  -o -iname "*Step*" \
  -o -iname "*Weight*" \
\) | sort); do
  echo ""
  echo "================ FILE: $file ================"
  sed -n '1,360p' "$file"
done

echo ""
echo "============================================================"
echo "12) BACKEND MIGRATIONS LIST"
echo "============================================================"
ls -lt backend/database/migrations | grep -Ei "health|nutrition|hydration|sleep|mood|medication|lab|alert|report|step|weight"

echo ""
echo "============================================================"
echo "13) BACKEND MIGRATIONS CONTENT"
echo "============================================================"
for file in $(find backend/database/migrations -type f \( \
  -iname "*health*" \
  -o -iname "*nutrition*" \
  -o -iname "*hydration*" \
  -o -iname "*sleep*" \
  -o -iname "*mood*" \
  -o -iname "*medication*" \
  -o -iname "*lab*" \
  -o -iname "*alert*" \
  -o -iname "*report*" \
  -o -iname "*step*" \
  -o -iname "*weight*" \
\) | sort); do
  echo ""
  echo "================ FILE: $file ================"
  sed -n '1,360p' "$file"
done

echo ""
echo "============================================================"
echo "14) BACKEND COMMANDS / JOBS / SEEDERS RELATED TO HEALTH"
echo "============================================================"
for dir in backend/app/Console backend/app/Jobs backend/database/seeders; do
  if [ -d "$dir" ]; then
    echo ""
    echo "================ DIR: $dir ================"
    find "$dir" -type f \( \
      -iname "*Health*" \
      -o -iname "*Nutrition*" \
      -o -iname "*Medication*" \
      -o -iname "*Lab*" \
      -o -iname "*Alert*" \
      -o -iname "*Report*" \
    \) | sort

    for file in $(find "$dir" -type f \( \
      -iname "*Health*" \
      -o -iname "*Nutrition*" \
      -o -iname "*Medication*" \
      -o -iname "*Lab*" \
      -o -iname "*Alert*" \
      -o -iname "*Report*" \
    \) | sort); do
      echo ""
      echo "================ FILE: $file ================"
      sed -n '1,420p' "$file"
    done
  fi
done

echo ""
echo "============================================================"
echo "15) FRONTEND ROUTER"
echo "============================================================"
if [ -f frontend/src/router/index.js ]; then
  echo "================ FILE: frontend/src/router/index.js ================"
  sed -n '1,460p' frontend/src/router/index.js
else
  echo "frontend/src/router/index.js not found"
fi

echo ""
echo "============================================================"
echo "16) FRONTEND LAYOUT / APP"
echo "============================================================"
for file in frontend/src/layouts/AppLayout.vue frontend/src/App.vue; do
  if [ -f "$file" ]; then
    echo ""
    echo "================ FILE: $file ================"
    sed -n '1,420p' "$file"
  else
    echo ""
    echo "================ MISSING: $file ================"
  fi
done

echo ""
echo "============================================================"
echo "17) FRONTEND HEALTH VIEWS LIST"
echo "============================================================"
find frontend/src/views/health -maxdepth 1 -type f -name "*.vue" | sort

echo ""
echo "============================================================"
echo "18) FRONTEND HEALTH VIEWS CONTENT"
echo "============================================================"
for file in $(find frontend/src/views/health -maxdepth 1 -type f -name "*.vue" | sort); do
  echo ""
  echo "================ FILE: $file ================"
  sed -n '1,760p' "$file"
done

echo ""
echo "============================================================"
echo "19) FRONTEND SERVICES / API LIST"
echo "============================================================"
find frontend/src -type f \( \
  -iname "*api*.js" \
  -o -iname "*service*.js" \
  -o -iname "*axios*.js" \
  -o -iname "*http*.js" \
  -o -iname "*health*.js" \
  -o -iname "*nutrition*.js" \
  -o -iname "*medication*.js" \
  -o -iname "*lab*.js" \
\) | sort

echo ""
echo "============================================================"
echo "20) FRONTEND SERVICES / API CONTENT"
echo "============================================================"
for file in $(find frontend/src -type f \( \
  -iname "*api*.js" \
  -o -iname "*service*.js" \
  -o -iname "*axios*.js" \
  -o -iname "*http*.js" \
  -o -iname "*health*.js" \
  -o -iname "*nutrition*.js" \
  -o -iname "*medication*.js" \
  -o -iname "*lab*.js" \
\) | sort); do
  echo ""
  echo "================ FILE: $file ================"
  sed -n '1,520p' "$file"
done

echo ""
echo "============================================================"
echo "21) FRONTEND PACKAGE CONFIG"
echo "============================================================"
for file in frontend/package.json frontend/vite.config.js frontend/src/main.js; do
  if [ -f "$file" ]; then
    echo ""
    echo "================ FILE: $file ================"
    sed -n '1,260p' "$file"
  else
    echo ""
    echo "================ MISSING: $file ================"
  fi
done

echo ""
echo "============================================================"
echo "22) DATABASE TABLE LIST - HEALTH RELATED"
echo "============================================================"
DB_CONTAINER="nixlifeos-postgres"

docker exec -i "$DB_CONTAINER" psql -U postgres -d nix_life_os -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND (
    table_name ILIKE '%health%'
    OR table_name ILIKE '%nutrition%'
    OR table_name ILIKE '%hydration%'
    OR table_name ILIKE '%sleep%'
    OR table_name ILIKE '%mood%'
    OR table_name ILIKE '%medication%'
    OR table_name ILIKE '%lab%'
    OR table_name ILIKE '%alert%'
    OR table_name ILIKE '%report%'
    OR table_name ILIKE '%step%'
    OR table_name ILIKE '%weight%'
)
ORDER BY table_name;
"

echo ""
echo "============================================================"
echo "23) DATABASE ROW COUNTS - HEALTH RELATED"
echo "============================================================"
docker exec -i "$DB_CONTAINER" psql -U postgres -d nix_life_os -c "
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup AS estimated_rows
FROM pg_stat_user_tables
WHERE
    relname ILIKE '%health%'
    OR relname ILIKE '%nutrition%'
    OR relname ILIKE '%hydration%'
    OR relname ILIKE '%sleep%'
    OR relname ILIKE '%mood%'
    OR relname ILIKE '%medication%'
    OR relname ILIKE '%lab%'
    OR relname ILIKE '%alert%'
    OR relname ILIKE '%report%'
    OR relname ILIKE '%step%'
    OR relname ILIKE '%weight%'
ORDER BY relname;
"

echo ""
echo "============================================================"
echo "24) LARAVEL LOG LAST 200 LINES"
echo "============================================================"
if [ -f backend/storage/logs/laravel.log ]; then
  tail -n 200 backend/storage/logs/laravel.log
else
  docker exec -i nixlifeos-backend sh -c 'tail -n 200 storage/logs/laravel.log' 2>/dev/null
fi

echo ""
echo "============================================================"
echo "25) FRONTEND HEALTH STRING SEARCH"
echo "============================================================"
grep -RniE "health|nutrition|hydration|sleep|mood|medication|lab|alert|report|steps|weight" frontend/src 2>/dev/null | head -n 500

echo ""
echo "============================================================"
echo "26) BACKEND HEALTH STRING SEARCH"
echo "============================================================"
grep -RniE "health|nutrition|hydration|sleep|mood|medication|lab|alert|report|steps|weight" backend/app backend/routes backend/database 2>/dev/null | head -n 700

echo ""
echo "============================================================"
echo "EXPORT COMPLETED"
echo "============================================================"

} > "$OUTPUT_FILE" 2>&1

echo ""
echo "Done."
echo "Saved file:"
echo "$OUTPUT_FILE"
echo ""
echo "File size:"
ls -lh "$OUTPUT_FILE"

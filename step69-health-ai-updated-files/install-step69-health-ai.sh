#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PACKAGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$PROJECT_ROOT"

copy_file() {
  local src="$1"
  local dest="$PROJECT_ROOT/$1"

  if [ ! -f "$PACKAGE_ROOT/$src" ]; then
    echo "Missing package file: $src"
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$PACKAGE_ROOT/$src" "$dest"
  echo "Updated: $src"
}

copy_file "backend/routes/api.php"
copy_file "backend/app/Http/Controllers/Api/V1/Health/HealthAIInsightController.php"
copy_file "backend/app/Services/Health/HealthAIInsightService.php"
copy_file "frontend/src/router/index.js"
copy_file "frontend/src/services/healthService.js"
copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/views/health/HealthAIInsightsView.vue"

echo ""
echo "Step 69 files copied successfully."
echo "Now run:"
echo "docker exec -it nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan route:list | grep -i ai-insights'"
echo "cd frontend && npm run build"

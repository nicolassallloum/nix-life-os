#!/usr/bin/env bash
set -e

PROJECT_ROOT="${1:-/u01/nix-life-os}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " STEP 70 - Apply Productivity AI Insights Updates"
echo " Project root: $PROJECT_ROOT"
echo "=================================================="

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "❌ Project root not found: $PROJECT_ROOT"
  exit 1
fi

copy_file() {
  local file="$1"
  mkdir -p "$PROJECT_ROOT/$(dirname "$file")"
  cp "$SCRIPT_DIR/$file" "$PROJECT_ROOT/$file"
  echo "✅ Updated: $file"
}

copy_file "backend/routes/api.php"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityAIInsightController.php"
copy_file "backend/app/Services/ProductivityAIInsightService.php"
copy_file "frontend/src/services/productivityService.js"
copy_file "frontend/src/router/index.js"
copy_file "frontend/src/router/index.ts"
copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/views/productivity/ProductivityAIInsightsView.vue"

echo ""
echo "🧹 Clearing Laravel cache..."
docker exec -it nixlifeos-backend sh -lc "php artisan optimize:clear" || true

echo ""
echo "🔍 PHP syntax checks..."
docker exec -it nixlifeos-backend sh -lc "php -l app/Http/Controllers/Api/V1/ProductivityAIInsightController.php && php -l app/Services/ProductivityAIInsightService.php" || true

echo ""
echo "🔍 Route check..."
docker exec -it nixlifeos-backend sh -lc "php artisan route:list | grep -i 'productivity/ai-insights'" || true

echo ""
echo "✅ Step 70 files applied. Now rebuild frontend if needed:"
echo "cd $PROJECT_ROOT/frontend && npm run build"

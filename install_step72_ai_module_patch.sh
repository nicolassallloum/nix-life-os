#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

copy_file() {
  local rel="$1"
  if [ -f "$PATCH_ROOT/$rel" ]; then
    mkdir -p "$PROJECT_ROOT/$(dirname "$rel")"
    cp "$PATCH_ROOT/$rel" "$PROJECT_ROOT/$rel"
    echo "UPDATED: $rel"
  else
    echo "SKIPPED missing patch file: $rel"
  fi
}

echo "=================================================="
echo " STEP 72 — AI Module Stabilization Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo "=================================================="

copy_file "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"
copy_file "frontend/src/services/aiRecommendationService.js"
copy_file "backend/database/sql/step72_ai_regression_checks.sql"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  echo "Clearing Laravel caches..."
  docker exec nixlifeos-backend sh -lc "php artisan optimize:clear && php artisan route:clear && php artisan config:clear && php artisan cache:clear"

  echo "Checking patched PHP syntax..."
  docker exec nixlifeos-backend sh -lc "php -l app/Http/Controllers/Api/V1/AIRecommendationController.php"
else
  echo "WARNING: nixlifeos-backend container is not running. Run Laravel cache clear manually after starting it."
fi

echo "=================================================="
echo " Patch installed. Now run frontend build and Step 72 CURL tests."
echo "=================================================="

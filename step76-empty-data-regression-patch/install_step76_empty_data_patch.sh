#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " STEP 76 — Empty Data Regression Patch Installer"
echo " Project Root: ${PROJECT_ROOT}"
echo " Patch Root:   ${PATCH_ROOT}"
echo "=================================================="

copy_file() {
  local src="$1"
  local dest="${PROJECT_ROOT}/$1"

  if [ -f "${PATCH_ROOT}/${src}" ]; then
    mkdir -p "$(dirname "${dest}")"
    cp "${PATCH_ROOT}/${src}" "${dest}"
    echo "[UPDATED] ${src}"
  else
    echo "[SKIP] ${src}"
  fi
}

copy_file "frontend/src/components/common/EmptyState.vue"
copy_file "frontend/src/components/finance/FinanceBudgetProgress.vue"
copy_file "frontend/src/components/finance/FinanceIncomeExpenseChart.vue"
copy_file "frontend/src/components/finance/FinanceTransactionsTable.vue"
copy_file "frontend/src/views/dashboard/DashboardView.vue"
copy_file "frontend/src/views/projects/ProjectDashboardView.vue"
copy_file "frontend/src/views/productivity/ProductivityDashboardView.vue"
copy_file "frontend/src/views/ai/AIRecommendationsView.vue"
copy_file "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_file "scripts/step76_empty_data_cleanup.sql"
copy_file "scripts/step76_empty_data_api_tests.sh"

echo ""
echo "Clearing Laravel caches if backend container is available..."
if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan optimize:clear"
else
  echo "[SKIP] nixlifeos-backend container not running."
fi

echo ""
echo "=================================================="
echo " STEP 76 patch installed."
echo " Next: cd ${PROJECT_ROOT}/frontend && npm run build"
echo "=================================================="

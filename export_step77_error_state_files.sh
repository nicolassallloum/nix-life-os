#!/usr/bin/env bash
set -e

PROJECT_ROOT="/u01/nix-life-os"
EXPORT_DIR="$PROJECT_ROOT/step77-error-state-review-files"
ARCHIVE_NAME="$PROJECT_ROOT/step77-error-state-review-files.tar.gz"

echo "=================================================="
echo " STEP 77 — Error State Regression Export"
echo " Project Root: $PROJECT_ROOT"
echo " Export Dir:   $EXPORT_DIR"
echo " Archive:      $ARCHIVE_NAME"
echo "=================================================="

rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

copy_if_exists() {
  local src="$1"
  local dest="$EXPORT_DIR/$src"

  if [ -e "$PROJECT_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp -r "$PROJECT_ROOT/$src" "$dest"
    echo "[OK] Copied: $src"
  else
    echo "[SKIP] Missing: $src"
  fi
}

echo ""
echo "Copying backend files..."

copy_if_exists "backend/routes/api.php"
copy_if_exists "backend/bootstrap/app.php"
copy_if_exists "backend/app/Exceptions/Handler.php"

copy_if_exists "backend/app/Http/Middleware/Authenticate.php"
copy_if_exists "backend/app/Http/Middleware/EnsureFrontendRequestsAreStateful.php"

copy_if_exists "backend/app/Http/Controllers/Api/V1/AuthController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/DashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/UnifiedDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceAccountController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceTransactionController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/FinanceBudgetController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/HealthDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProjectController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/ProductivityDashboardController.php"
copy_if_exists "backend/app/Http/Controllers/Api/V1/AIRecommendationController.php"

copy_if_exists "backend/app/Http/Requests"
copy_if_exists "backend/app/Models/User.php"

copy_if_exists "backend/config/app.php"
copy_if_exists "backend/config/auth.php"
copy_if_exists "backend/config/sanctum.php"
copy_if_exists "backend/config/permission.php"
copy_if_exists "backend/config/logging.php"
copy_if_exists "backend/config/cors.php"

echo ""
echo "Copying frontend files..."

copy_if_exists "frontend/src/main.js"
copy_if_exists "frontend/src/main.ts"

copy_if_exists "frontend/src/router/index.js"
copy_if_exists "frontend/src/router/index.ts"

copy_if_exists "frontend/src/services/api.js"
copy_if_exists "frontend/src/services/api.ts"
copy_if_exists "frontend/src/services/authService.js"
copy_if_exists "frontend/src/services/authService.ts"
copy_if_exists "frontend/src/services/financeService.js"
copy_if_exists "frontend/src/services/financeService.ts"
copy_if_exists "frontend/src/services/healthService.js"
copy_if_exists "frontend/src/services/healthService.ts"
copy_if_exists "frontend/src/services/projectService.js"
copy_if_exists "frontend/src/services/projectService.ts"
copy_if_exists "frontend/src/services/productivityService.js"
copy_if_exists "frontend/src/services/productivityService.ts"
copy_if_exists "frontend/src/services/aiService.js"
copy_if_exists "frontend/src/services/aiService.ts"

copy_if_exists "frontend/src/stores"
copy_if_exists "frontend/src/layouts/AppLayout.vue"
copy_if_exists "frontend/src/components"
copy_if_exists "frontend/src/views"

echo ""
echo "Copying docker and env examples..."

copy_if_exists "docker-compose.yml"
copy_if_exists "docker-compose.prod.yml"
copy_if_exists ".env.example"
copy_if_exists "backend/.env.example"
copy_if_exists "frontend/.env.example"

echo ""
echo "Copying Laravel log safely..."

mkdir -p "$EXPORT_DIR/backend/storage/logs"

if [ -f "$PROJECT_ROOT/backend/storage/logs/laravel.log" ]; then
  tail -n 500 "$PROJECT_ROOT/backend/storage/logs/laravel.log" > "$EXPORT_DIR/backend/storage/logs/laravel-step77-tail.log"
  echo "[OK] Copied last 500 lines of Laravel log"
else
  echo "[SKIP] backend/storage/logs/laravel.log not found"
fi

echo ""
echo "Generating route list..."

mkdir -p "$EXPORT_DIR/diagnostics"

if docker ps --format '{{.Names}}' | grep -q '^nixlifeos-backend$'; then
  docker exec nixlifeos-backend sh -lc "php artisan route:list" > "$EXPORT_DIR/diagnostics/route-list.txt" || true
  docker exec nixlifeos-backend sh -lc "php artisan about" > "$EXPORT_DIR/diagnostics/artisan-about.txt" || true
  docker exec nixlifeos-backend sh -lc "php artisan config:show app" > "$EXPORT_DIR/diagnostics/config-app.txt" || true
  echo "[OK] Generated Laravel diagnostics"
else
  echo "[SKIP] Docker container nixlifeos-backend not running"
fi

echo ""
echo "Generating frontend diagnostics..."

if [ -d "$PROJECT_ROOT/frontend" ]; then
  (
    cd "$PROJECT_ROOT/frontend"
    npm list --depth=0 > "$EXPORT_DIR/diagnostics/frontend-npm-list.txt" 2>&1 || true
  )
  echo "[OK] Generated frontend npm diagnostics"
fi

echo ""
echo "Removing sensitive files if accidentally copied..."

find "$EXPORT_DIR" -name ".env" -type f -delete
find "$EXPORT_DIR" -name "*.key" -type f -delete
find "$EXPORT_DIR" -name "*.pem" -type f -delete

echo ""
echo "Creating archive..."

cd "$PROJECT_ROOT"
tar -czf "$ARCHIVE_NAME" "$(basename "$EXPORT_DIR")"

echo ""
echo "=================================================="
echo " DONE"
echo " Send this file to ChatGPT:"
echo " $ARCHIVE_NAME"
echo "=================================================="

#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step83-api-load-testing-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 83 — API Load Testing Package Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

mkdir -p "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/tests/load" "$PROJECT_ROOT/docs" "$PROJECT_ROOT/sql" "$BACKUP_DIR"

copy_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "${dest#$PROJECT_ROOT/}")"
    cp "$dest" "$BACKUP_DIR/${dest#$PROJECT_ROOT/}"
    echo "🛡️  Backup: ${dest#$PROJECT_ROOT/}"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "✅ Installed: ${dest#$PROJECT_ROOT/}"
}

copy_file "$PATCH_ROOT/scripts/step83_auth_token_setup.sh" "$PROJECT_ROOT/scripts/step83_auth_token_setup.sh"
copy_file "$PATCH_ROOT/scripts/step83_endpoint_health_check.sh" "$PROJECT_ROOT/scripts/step83_endpoint_health_check.sh"
copy_file "$PATCH_ROOT/scripts/step83_api_load_test.sh" "$PROJECT_ROOT/scripts/step83_api_load_test.sh"
copy_file "$PATCH_ROOT/scripts/step83_curl_concurrency_test.sh" "$PROJECT_ROOT/scripts/step83_curl_concurrency_test.sh"
copy_file "$PATCH_ROOT/tests/load/step83-k6-load-test.js" "$PROJECT_ROOT/tests/load/step83-k6-load-test.js"
copy_file "$PATCH_ROOT/docs/STEP83_API_ENDPOINT_MATRIX.md" "$PROJECT_ROOT/docs/STEP83_API_ENDPOINT_MATRIX.md"
copy_file "$PATCH_ROOT/docs/STEP83_API_LOAD_TESTING_PLAN.md" "$PROJECT_ROOT/docs/STEP83_API_LOAD_TESTING_PLAN.md"
copy_file "$PATCH_ROOT/docs/STEP83_BOTTLENECK_ANALYSIS.md" "$PROJECT_ROOT/docs/STEP83_BOTTLENECK_ANALYSIS.md"
copy_file "$PATCH_ROOT/docs/STEP83_FINAL_CHECKLIST.md" "$PROJECT_ROOT/docs/STEP83_FINAL_CHECKLIST.md"
copy_file "$PATCH_ROOT/docs/STEP83_LARAVEL_OPTIMIZATION_COMMANDS.md" "$PROJECT_ROOT/docs/STEP83_LARAVEL_OPTIMIZATION_COMMANDS.md"
copy_file "$PATCH_ROOT/sql/step83_index_recommendations.sql" "$PROJECT_ROOT/sql/step83_index_recommendations.sql"

chmod +x "$PROJECT_ROOT/scripts/step83_"*.sh

echo "=================================================="
echo " DONE"
echo " Next commands:"
echo " export API_BASE=\"http://127.0.0.1:8000/api/v1\""
echo " export ADMIN_EMAIL=\"step74.admin@gmail.com\""
echo " export ADMIN_PASSWORD=\"Password@123\""
echo " ./scripts/step83_endpoint_health_check.sh"
echo " ./scripts/step83_api_load_test.sh"
echo "=================================================="

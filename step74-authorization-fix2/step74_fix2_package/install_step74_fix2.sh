#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " STEP 74 — Fix 2 Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo "=================================================="

mkdir -p "$PROJECT_ROOT/frontend/src/utils"
cp "$PATCH_ROOT/frontend/src/utils/auth.d.ts" "$PROJECT_ROOT/frontend/src/utils/auth.d.ts"
cp "$PATCH_ROOT/step74_authorization_regression_test_v3.sh" "$PROJECT_ROOT/step74_authorization_regression_test_v3.sh"
chmod +x "$PROJECT_ROOT/step74_authorization_regression_test_v3.sh"

echo "Updated: frontend/src/utils/auth.d.ts"
echo "Updated: step74_authorization_regression_test_v3.sh"

echo ""
echo "Run frontend type check/build:"
echo "cd $PROJECT_ROOT/frontend && npm run build"
echo ""
echo "Run QA test:"
echo "cd $PROJECT_ROOT && ./step74_authorization_regression_test_v3.sh"
echo "=================================================="

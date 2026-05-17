#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_ROOT="$PROJECT_ROOT/step81-3-final-e2e-retest"

echo "=================================================="
echo " STEP 81.3 — Final E2E Retest Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo "=================================================="

chmod +x "$PATCH_ROOT/scripts/step81_3_final_e2e_retest.sh"

docker exec nixlifeos-backend sh -lc "php artisan optimize:clear" || true

echo "✅ STEP 81.3 final retest script is ready."
echo "Next: run ./step81-3-final-e2e-retest/scripts/step81_3_final_e2e_retest.sh"

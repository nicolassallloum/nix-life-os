#!/usr/bin/env bash
set -e

PROJECT_ROOT="/u01/nix-life-os"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo " STEP 74 — Sidebar / Navigation Patch Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo "=================================================="

copy_file() {
  local src="$1"
  local dest="$PROJECT_ROOT/$src"

  if [ -f "$PATCH_ROOT/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$PATCH_ROOT/$src" "$dest"
    echo "[OK] Updated: $src"
  else
    echo "[SKIP] Missing from patch: $src"
  fi
}

copy_file "frontend/src/router/index.js"
copy_file "frontend/src/router/index.ts"
copy_file "frontend/src/App.vue"
copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/utils/auth.js"
copy_file "frontend/src/utils/permissions.js"
copy_file "frontend/package.json"

echo ""
echo "Patch installed. Now run:"
echo "cd $PROJECT_ROOT/frontend"
echo "npm install"
echo "npm run build"
echo "=================================================="

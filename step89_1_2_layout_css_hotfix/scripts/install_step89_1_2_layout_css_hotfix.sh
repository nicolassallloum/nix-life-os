#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89_1-2-layout-css-hotfix-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 89.1.2 — Layout CSS Independence Hotfix"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

mkdir -p "$BACKUP_DIR"

backup_file() {
  local relative_path="$1"
  if [ -f "$PROJECT_ROOT/$relative_path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative_path")"
    cp -f "$PROJECT_ROOT/$relative_path" "$BACKUP_DIR/$relative_path"
    echo "🛡️  Backup: $relative_path"
  fi
}

install_file() {
  local relative_path="$1"
  mkdir -p "$PROJECT_ROOT/$(dirname "$relative_path")"
  cp -f "$PATCH_ROOT/$relative_path" "$PROJECT_ROOT/$relative_path"
  echo "✅ Updated: $relative_path"
}

backup_file "frontend/src/layouts/AppLayout.vue"
backup_file "frontend/src/assets/main.css"

install_file "frontend/src/layouts/AppLayout.vue"
install_file "frontend/src/assets/main.css"

echo "=================================================="
echo "✅ STEP 89.1.2 hotfix installed."
echo "Next commands:"
echo "cd $PROJECT_ROOT/frontend"
echo "npm run build"
echo "cd $PROJECT_ROOT"
echo "docker compose -f docker-compose.prod.yml up -d --build frontend"
echo "=================================================="

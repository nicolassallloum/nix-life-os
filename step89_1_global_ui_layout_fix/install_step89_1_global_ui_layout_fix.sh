#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89_1-global-ui-layout-fix-$(date +%Y%m%d-%H%M%S)"

if [ ! -d "$PROJECT_ROOT/frontend" ]; then
  echo "❌ frontend directory not found under: $PROJECT_ROOT"
  echo "Usage: ./install_step89_1_global_ui_layout_fix.sh /path/to/nix-life-os"
  exit 1
fi

echo "=================================================="
echo " STEP 89.1 — Global UI/Layout Design Fix Installer"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

mkdir -p "$BACKUP_DIR"

backup_file() {
  local rel="$1"
  if [ -f "$PROJECT_ROOT/$rel" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -f "$PROJECT_ROOT/$rel" "$BACKUP_DIR/$rel"
    echo "🛡️  Backup: $rel"
  fi
}

copy_file() {
  local rel="$1"
  mkdir -p "$PROJECT_ROOT/$(dirname "$rel")"
  cp -f "$PATCH_ROOT/$rel" "$PROJECT_ROOT/$rel"
  echo "✅ Updated: $rel"
}

backup_file "frontend/src/layouts/AppLayout.vue"
backup_file "frontend/src/assets/main.css"
backup_file "frontend/src/components/ui/BaseButton.vue"
backup_file "frontend/src/components/ui/BaseCard.vue"
backup_file "frontend/src/components/ui/BaseAlert.vue"
backup_file "frontend/src/components/ui/LoadingState.vue"
backup_file "frontend/src/components/ui/EmptyState.vue"

copy_file "frontend/src/layouts/AppLayout.vue"
copy_file "frontend/src/assets/main.css"
copy_file "frontend/src/components/ui/BaseButton.vue"
copy_file "frontend/src/components/ui/BaseCard.vue"
copy_file "frontend/src/components/ui/BaseAlert.vue"
copy_file "frontend/src/components/ui/LoadingState.vue"
copy_file "frontend/src/components/ui/EmptyState.vue"

echo "=================================================="
echo "✅ STEP 89.1 patch files installed."
echo "Next commands:"
echo "cd $PROJECT_ROOT/frontend"
echo "npm run build"
echo "cd $PROJECT_ROOT"
echo "docker compose -f docker-compose.prod.yml up -d --build frontend"
echo "=================================================="

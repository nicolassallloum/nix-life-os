#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_ROOT="$PROJECT_ROOT/frontend"
BACKUP_DIR="$PROJECT_ROOT/backups/step85-vite-hotfix-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

backup_and_copy() {
  local relative_path="$1"
  if [ -f "$PROJECT_ROOT/$relative_path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative_path")"
    cp -a "$PROJECT_ROOT/$relative_path" "$BACKUP_DIR/$relative_path"
  fi
  mkdir -p "$(dirname "$PROJECT_ROOT/$relative_path")"
  cp -a "$PATCH_ROOT/$relative_path" "$PROJECT_ROOT/$relative_path"
  echo "✅ Updated: $relative_path"
}

backup_and_copy "frontend/vite.config.ts"
backup_and_copy "frontend/vite.config.js"

cd "$FRONTEND_ROOT"
rm -rf dist

echo "✅ STEP 85 Vite hotfix applied. Backup: $BACKUP_DIR"
echo "Next run: cd $FRONTEND_ROOT && npm run type-check && npm run build"

#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89_1-tailwind-apply-hotfix-$(date +%Y%m%d-%H%M%S)"

printf '%s\n' '=================================================='
printf '%s\n' ' STEP 89.1 — Tailwind @apply Build Hotfix Installer'
printf ' Project Root: %s\n' "$PROJECT_ROOT"
printf ' Patch Root:   %s\n' "$PATCH_ROOT"
printf ' Backup Dir:   %s\n' "$BACKUP_DIR"
printf '%s\n' '=================================================='

if [ ! -d "$PROJECT_ROOT/frontend" ]; then
  echo "❌ frontend directory not found under: $PROJECT_ROOT"
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend/src/assets"

if [ -f "$PROJECT_ROOT/frontend/src/assets/main.css" ]; then
  cp -f "$PROJECT_ROOT/frontend/src/assets/main.css" "$BACKUP_DIR/frontend/src/assets/main.css"
  echo "🛡️  Backup: frontend/src/assets/main.css"
fi

cp -f "$PATCH_ROOT/frontend/src/assets/main.css" "$PROJECT_ROOT/frontend/src/assets/main.css"
echo "✅ Updated: frontend/src/assets/main.css"

printf '%s\n' '=================================================='
printf '%s\n' '✅ STEP 89.1 Tailwind @apply hotfix installed.'
printf '%s\n' 'Next commands:'
printf '%s\n' 'cd /u01/nix-life-os/frontend'
printf '%s\n' 'npm run build'
printf '%s\n' 'cd /u01/nix-life-os'
printf '%s\n' 'docker compose -f docker-compose.prod.yml up -d --build frontend'
printf '%s\n' '=================================================='

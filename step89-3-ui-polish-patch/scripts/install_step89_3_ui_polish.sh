#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89-3-ui-polish-$(date +%Y%m%d-%H%M%S)"

printf '%s\n' '=================================================='
printf '%s\n' ' STEP 89.3 — UI Polish Installer'
printf ' Project Root: %s\n' "$PROJECT_ROOT"
printf ' Patch Root:   %s\n' "$PATCH_ROOT"
printf ' Backup Dir:   %s\n' "$BACKUP_DIR"
printf '%s\n' '=================================================='

mkdir -p "$BACKUP_DIR"

copy_file() {
  local relative_path="$1"
  local source_file="$PATCH_ROOT/$relative_path"
  local target_file="$PROJECT_ROOT/$relative_path"

  if [[ ! -f "$source_file" ]]; then
    printf '❌ Missing patch file: %s\n' "$source_file" >&2
    exit 1
  fi

  if [[ -f "$target_file" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$relative_path")"
    cp "$target_file" "$BACKUP_DIR/$relative_path"
    printf '🛡️  Backup: %s\n' "$relative_path"
  fi

  mkdir -p "$(dirname "$target_file")"
  cp "$source_file" "$target_file"
  printf '✅ Updated: %s\n' "$relative_path"
}

copy_file 'frontend/src/views/notifications/NotificationSettingsView.vue'
copy_file 'frontend/src/assets/main.css'

printf '%s\n' '=================================================='
printf '%s\n' ' STEP 89.3 UI polish patch installed successfully.'
printf '%s\n' ' Next:'
printf '%s\n' '   cd frontend'
printf '%s\n' '   npm run build'
printf '%s\n' '   npm run dev -- --host 0.0.0.0'
printf '%s\n' '=================================================='

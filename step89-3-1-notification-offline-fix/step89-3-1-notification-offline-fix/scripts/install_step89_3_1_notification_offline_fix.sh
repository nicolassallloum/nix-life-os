#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89-3-1-notification-offline-fix-$(date +%Y%m%d-%H%M%S)"

cd "$PROJECT_ROOT"
mkdir -p "$BACKUP_DIR"

echo "=================================================="
echo " STEP 89.3.1 — Notification Offline UI Fix"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

TARGET="frontend/src/views/notifications/NotificationSettingsView.vue"

if [ -f "$TARGET" ]; then
  mkdir -p "$BACKUP_DIR/$(dirname "$TARGET")"
  cp "$TARGET" "$BACKUP_DIR/$TARGET"
  echo "🛡️  Backup: $TARGET"
fi

mkdir -p "$(dirname "$TARGET")"
cp "$PATCH_ROOT/$TARGET" "$TARGET"
echo "✅ Updated: $TARGET"

echo "=================================================="
echo " Done. Now run:"
echo " cd frontend && npm run build"
echo "=================================================="

#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${1:-/u01/nix-life-os}"
PATCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$PROJECT_ROOT/backups/step89_1-3-tailwind-vite-compat-hotfix-$(date +%Y%m%d-%H%M%S)"

echo "=================================================="
echo " STEP 89.1.3 — Tailwind Vite Compatibility Hotfix"
echo " Project Root: $PROJECT_ROOT"
echo " Patch Root:   $PATCH_ROOT"
echo " Backup Dir:   $BACKUP_DIR"
echo "=================================================="

if [ ! -d "$PROJECT_ROOT/frontend" ]; then
  echo "❌ frontend directory not found at $PROJECT_ROOT/frontend"
  exit 1
fi

mkdir -p "$BACKUP_DIR/frontend"

if [ -f "$PROJECT_ROOT/frontend/vite.config.js" ]; then
  cp "$PROJECT_ROOT/frontend/vite.config.js" "$BACKUP_DIR/frontend/vite.config.js"
  echo "🛡️  Backup: frontend/vite.config.js"
else
  echo "❌ Missing frontend/vite.config.js"
  exit 1
fi

python3 - <<'PY' "$PROJECT_ROOT/frontend/vite.config.js"
from pathlib import Path
import re, sys
path = Path(sys.argv[1])
text = path.read_text()
original = text
# Remove Tailwind v4 Vite plugin import. The project uses tailwindcss v3 + PostCSS.
text = re.sub(r"^import\s+tailwindcss\s+from\s+['\"]@tailwindcss/vite['\"]\s*\n", "", text, flags=re.M)
# Remove tailwindcss() from plugins array while keeping vue() and other plugins if any.
text = re.sub(r"plugins:\s*\[\s*vue\(\)\s*,\s*tailwindcss\(\)\s*\]", "plugins: [vue()]", text)
text = re.sub(r"plugins:\s*\[\s*tailwindcss\(\)\s*,\s*vue\(\)\s*\]", "plugins: [vue()]", text)
# Defensive cleanup for trailing commas if user edited manually.
text = text.replace(', tailwindcss()', '').replace('tailwindcss(), ', '')
if text == original:
    print("ℹ️  No @tailwindcss/vite plugin reference found or already fixed.")
else:
    path.write_text(text)
    print("✅ Updated: frontend/vite.config.js")
PY

echo "=================================================="
echo "✅ STEP 89.1.3 Tailwind Vite compatibility hotfix installed."
echo "Next commands:"
echo "cd $PROJECT_ROOT/frontend"
echo "npm run build"
echo "cd $PROJECT_ROOT"
echo "docker compose -f docker-compose.prod.yml up -d --build frontend"
echo "=================================================="

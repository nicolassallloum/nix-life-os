#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
cd "$PROJECT_ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="backups/step86-1-security-deploy-hotfix-$TS"
mkdir -p "$BACKUP_DIR"

backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    cp "$file" "$BACKUP_DIR/$file"
  fi
}

backup_file docker-compose.prod.yml
backup_file docker-compose.security-override.yml
backup_file scripts/step86_security_test.sh

cp step86-1-hotfix/files/docker-compose.security-override.yml docker-compose.security-override.yml

python3 - <<'PY'
from pathlib import Path
p = Path('docker-compose.prod.yml')
text = p.read_text()
text = text.replace('      - "5445:5432"', '      - "127.0.0.1:5445:5432"')
text = text.replace('      - "8000:80"', '      - "127.0.0.1:8000:80"')
text = text.replace('      - "5000:5000"', '      - "127.0.0.1:5000:5000"')
p.write_text(text)
PY

chmod +x scripts/step86_security_test.sh 2>/dev/null || true

echo "STEP 86.1 security deployment hotfix applied."
echo "Backup directory: $BACKUP_DIR"
echo "Next commands:"
echo "docker compose -f docker-compose.prod.yml -f docker-compose.security-override.yml down"
echo "docker compose -f docker-compose.prod.yml -f docker-compose.security-override.yml up -d --build"
echo "docker compose -f docker-compose.prod.yml -f docker-compose.security-override.yml ps"
echo "docker ps --format 'table {{.Names}}\t{{.Ports}}'"

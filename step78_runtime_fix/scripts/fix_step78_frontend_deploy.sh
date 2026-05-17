#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
cd "$PROJECT_ROOT"

echo "=================================================="
echo " STEP 78 — Frontend Static Asset Runtime Fix"
echo " Project Root: $PROJECT_ROOT"
echo "=================================================="

if [ ! -d frontend ]; then
  echo "ERROR: frontend directory not found under $PROJECT_ROOT"
  exit 1
fi

cd frontend

# Fix oxlint unused catch binding if the file exists.
if [ -f src/utils/auth.js ]; then
  sed -i 's/catch (_error)/catch {/g' src/utils/auth.js
fi

if [ -f src/layouts/AppLayout.vue ]; then
  sed -i 's/catch (_error)/catch {/g' src/layouts/AppLayout.vue
fi

npm install
npm run build

if [ ! -f dist/index.html ]; then
  echo "ERROR: frontend/dist/index.html was not created. Build failed or wrong outDir."
  exit 1
fi

cd "$PROJECT_ROOT"

# Restart/rebuild containers using compose when available.
if [ -f docker-compose.prod.yml ]; then
  docker compose -f docker-compose.prod.yml up -d --build frontend nginx || true
fi

if [ -f docker-compose.yml ] || [ -f compose.yml ] || [ -f compose.yaml ]; then
  docker compose up -d --build frontend nginx || true
fi

# Fallback to known container names from Nix Life OS.
docker restart nixlifeos-frontend >/dev/null 2>&1 || true
docker restart nixlifeos-nginx >/dev/null 2>&1 || true

echo "=================================================="
echo " Validation commands"
echo "=================================================="
echo "curl -I http://127.0.0.1/"
echo "curl -I http://127.0.0.1/assets/<copy-one-js-file-from-frontend/dist/assets>"
echo "Expected JS asset Content-Type: application/javascript or text/javascript"
echo "Expected missing JS asset: 404, not 200 text/html"
echo "=================================================="

#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/u01/nix-life-os}"
PATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/files"
BACKUP_DIR="$PROJECT_ROOT/backups/step86-security-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP_DIR"

backup_and_copy() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$PROJECT_ROOT/$dst")"
  if [[ -f "$PROJECT_ROOT/$dst" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$dst")"
    cp "$PROJECT_ROOT/$dst" "$BACKUP_DIR/$dst"
  fi
  cp "$PATCH_DIR/$src" "$PROJECT_ROOT/$dst"
  echo "Updated: $dst"
}

backup_and_copy SensitiveDataRedactor.php backend/app/Support/SensitiveDataRedactor.php
backup_and_copy SecurityHeaders.php backend/app/Http/Middleware/SecurityHeaders.php
backup_and_copy ApiAuditLogger.php backend/app/Http/Middleware/ApiAuditLogger.php
backup_and_copy ApiPerformanceLogger.php backend/app/Http/Middleware/ApiPerformanceLogger.php
backup_and_copy bootstrap_app.php backend/bootstrap/app.php
backup_and_copy cors.php backend/config/cors.php
backup_and_copy sanctum.php backend/config/sanctum.php
backup_and_copy auth.js frontend/src/utils/auth.js
backup_and_copy router_index.js frontend/src/router/index.js
backup_and_copy docker_nginx_default.conf docker/nginx/default.conf
backup_and_copy backend_nginx_default.conf docker/backend-nginx/default.conf
backup_and_copy docker-compose.security-override.yml docker-compose.security-override.yml
backup_and_copy step86_security_test.sh scripts/step86_security_test.sh
chmod +x "$PROJECT_ROOT/scripts/step86_security_test.sh"

cat <<'NEXT'

STEP 86 security patch copied successfully.

Recommended manual .env.docker additions/updates:
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warning
AUTH_TOKEN_EXPIRATION_MINUTES=120
SANCTUM_EXPIRATION=120
SANCTUM_TOKEN_PREFIX=nixlifeos_
CORS_ALLOWED_ORIGINS=http://localhost,http://127.0.0.1,http://localhost:5173,http://127.0.0.1:5173
CORS_SUPPORTS_CREDENTIALS=false
SESSION_SECURE_COOKIE=false   # true only when HTTPS is enabled
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax
DB_PASSWORD=<strong-password-not-postgres>

Run:
cd /u01/nix-life-os
php -l backend/app/Support/SensitiveDataRedactor.php
php -l backend/app/Http/Middleware/SecurityHeaders.php
php -l backend/app/Http/Middleware/ApiAuditLogger.php
php -l backend/app/Http/Middleware/ApiPerformanceLogger.php
php -l backend/bootstrap/app.php
php -l backend/config/cors.php
php -l backend/config/sanctum.php

docker exec nixlifeos-backend sh -lc "php artisan optimize:clear && php artisan route:list --path=api | head -80"
docker compose -f docker-compose.prod.yml -f docker-compose.security-override.yml up -d --build
API_BASE=http://127.0.0.1:8000/api/v1 scripts/step86_security_test.sh
NEXT

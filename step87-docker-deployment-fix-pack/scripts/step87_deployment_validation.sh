#!/usr/bin/env bash
set -euo pipefail

cd /u01/nix-life-os
COMPOSE="docker compose -f docker-compose.prod.yml"
API_BASE="http://127.0.0.1:8000"
FRONTEND_URL="http://127.0.0.1"
AI_URL="http://127.0.0.1:5000"

echo "=================================================="
echo " STEP 87 — Docker Deployment Validation"
echo "=================================================="

echo "\n[1] Compose config validation"
$COMPOSE config >/tmp/step87-compose-config.out
$COMPOSE ps

echo "\n[2] Container health"
docker inspect --format='{{.Name}} => {{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \
  nixlifeos-postgres nixlifeos-backend nixlifeos-backend-nginx nixlifeos-frontend nixlifeos-ai-engine nixlifeos-nginx || true

echo "\n[3] Laravel runtime checks"
docker exec nixlifeos-backend sh -lc 'php -v | head -1'
docker exec nixlifeos-backend sh -lc 'php artisan about | sed -n "1,45p"'
docker exec nixlifeos-backend sh -lc 'php artisan migrate:status | tail -20'
docker exec nixlifeos-backend sh -lc 'php artisan route:list | grep -E "api/(health|v1/health|v1/dashboard/summary|v1/auth/login)"'
docker exec nixlifeos-backend sh -lc 'php -r "new PDO(\"pgsql:host=postgres;port=5445;dbname=\".getenv(\"DB_DATABASE\"), getenv(\"DB_USERNAME\"), getenv(\"DB_PASSWORD\")); echo \"DB_OK\\n\";"'

echo "\n[4] PostgreSQL checks"
docker exec nixlifeos-postgres pg_isready -U nixlifeos_user -d nixlifeos_db
docker exec nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c 'select current_database(), current_user, now();'

echo "\n[5] HTTP checks"
curl -fsS "$API_BASE/api/health" | jq . || curl -i "$API_BASE/api/health"
curl -fsS "$API_BASE/api/v1/health" | jq . || echo "WARN: /api/v1/health is missing. /api/health exists."
curl -i -s "$API_BASE/api/v1/dashboard/summary" -H 'Accept: application/json' | sed -n '1,15p'
curl -I -s "$FRONTEND_URL" | sed -n '1,15p'
curl -fsS "$AI_URL/health" | jq . || curl -i "$AI_URL/health"

echo "\n[6] Logs: last important errors"
$COMPOSE logs --tail=120 backend backend-nginx frontend postgres ai-engine nginx | grep -Ei 'error|critical|exception|permission denied|connection refused|502|504' || true

echo "\n[7] Volumes and networks"
docker volume ls | grep nix-life-os || true
docker network ls | grep nix-life-os || true

echo "\n✅ STEP 87 validation script completed. Review warnings above."

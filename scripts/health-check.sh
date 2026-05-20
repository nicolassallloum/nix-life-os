#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-https://nixlifeos.com}"
PROJECT_DIR="/u01/nix-life-os"
LOG_DIR="$PROJECT_DIR/backups/monitoring"

mkdir -p "$LOG_DIR"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S %Z"
}

check_http() {
  local name="$1"
  local url="$2"
  local expected_code="$3"

  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url" || true)"

  if [ "$code" = "$expected_code" ]; then
    echo "[$(timestamp)] PASS - $name - HTTP $code"
  else
    echo "[$(timestamp)] FAIL - $name - Expected $expected_code but got $code"
    return 1
  fi
}

echo "=================================================="
echo "Nix Life OS Health Check"
echo "Started: $(timestamp)"
echo "Base URL: $BASE_URL"
echo "=================================================="

STATUS=0

check_http "Frontend HTTPS" "$BASE_URL/" "200" || STATUS=1
check_http "Backend API HTTPS" "$BASE_URL/api/v1/health" "200" || STATUS=1
check_http "AI Public Block HTTPS" "$BASE_URL/ai/health" "404" || STATUS=1

echo "--------------------------------------------------"
echo "Docker Containers"
echo "--------------------------------------------------"

docker compose -f "$PROJECT_DIR/docker-compose.prod.yml" ps || STATUS=1

echo "--------------------------------------------------"
echo "PostgreSQL Internal Health"
echo "--------------------------------------------------"

docker exec nixlifeos-postgres pg_isready -U nixlifeos_user -d nixlifeos_db || STATUS=1

echo "--------------------------------------------------"
echo "AI Engine Internal Health"
echo "--------------------------------------------------"

docker exec nixlifeos-ai-engine python - <<'PY' || STATUS=1
import urllib.request
import sys

try:
    with urllib.request.urlopen("http://127.0.0.1:5000/health", timeout=10) as response:
        print(response.read().decode())
        sys.exit(0 if response.status == 200 else 1)
except Exception as exc:
    print(f"AI health check failed: {exc}")
    sys.exit(1)
PY

echo "=================================================="
if [ "$STATUS" -eq 0 ]; then
  echo "Nix Life OS Health Check: PASS"
else
  echo "Nix Life OS Health Check: FAIL"
fi
echo "Finished: $(timestamp)"
echo "=================================================="

exit "$STATUS"

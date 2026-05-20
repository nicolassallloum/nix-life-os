#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1}"
PROJECT_DIR="/u01/nix-life-os"
LOG_DIR="$PROJECT_DIR/backups/monitoring"
LOG_FILE="$LOG_DIR/health-check.log"

mkdir -p "$LOG_DIR"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S %Z"
}

check_http() {
  local name="$1"
  local url="$2"
  local expected_code="$3"

  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || true)"

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

check_http "Frontend" "$BASE_URL/" "200" || STATUS=1
check_http "Frontend Health" "$BASE_URL/health" "200" || STATUS=1
check_http "Nginx Health" "$BASE_URL/nginx-health" "200" || STATUS=1
bash -n scripts/health-check.shh========================"alhost:5000/health" || STATUS=1
nix@DESKTOP-0VMMAOM:/u01/nix-life-os$ cd /u01/nix-life-os

./scripts/health-check.sh
==================================================
Nix Life OS Health Check
Started: 2026-05-20 03:07:02 EEST
Base URL: http://127.0.0.1
==================================================
[2026-05-20 03:07:02 EEST] PASS - Frontend - HTTP 200
[2026-05-20 03:07:02 EEST] PASS - Frontend Health - HTTP 200
[2026-05-20 03:07:02 EEST] PASS - Nginx Health - HTTP 200
[2026-05-20 03:07:02 EEST] PASS - Backend API Health - HTTP 200
[2026-05-20 03:07:02 EEST] PASS - AI Public Block - HTTP 404
--------------------------------------------------
Docker Containers
--------------------------------------------------
NAME                      IMAGE                   COMMAND                  SERVICE         CREATED          STATUS                    PORTS
nixlifeos-ai-engine       nix-life-os-ai-engine   "uvicorn app:app --h…"   ai-engine       40 minutes ago   Up 40 minutes (healthy)   5000/tcp
nixlifeos-backend         nix-life-os-backend     "docker-php-entrypoi…"   backend         39 minutes ago   Up 39 minutes (healthy)   9000/tcp
nixlifeos-backend-nginx   nginx:1.27-alpine       "/docker-entrypoint.…"   backend-nginx   39 minutes ago   Up 39 minutes             80/tcp
nixlifeos-frontend        nix-life-os-frontend    "/docker-entrypoint.…"   frontend        39 minutes ago   Up 39 minutes             80/tcp
nixlifeos-nginx           nginx:1.27-alpine       "/docker-entrypoint.…"   nginx           39 minutes ago   Up 39 minutes             0.0.0.0:80->80/tcp, [::]:80->80/tcp
nixlifeos-postgres        postgres:18             "docker-entrypoint.s…"   postgres        40 minutes ago   Up 40 minutes (healthy)   5432/tcp
--------------------------------------------------
PostgreSQL Internal Health
--------------------------------------------------
/var/run/postgresql:5432 - accepting connections
--------------------------------------------------
AI Engine Internal Health
--------------------------------------------------
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    42  100    42    0     0  22913      0 --:--:-- --:--:-- --:--:-- 42000{"status":"healthy","service":"ai-engine"}
==================================================
Nix Life OS Health Check: PASS
Finished: 2026-05-20 03:07:02 EEST
==================================================
nix@DESKTOP-0VMMAOM:/u01/nix-life-os$ cd /u01/nix-life-os

crontab -l > /tmp/nixlifeos-cron-monitoring 2>/dev/null || true

grep -q "health-check.sh" /tmp/nixlifeos-cron-monitoring || cat >> /tmp/nixlifeos-cron-monitoring <<'EOF'
# Nix Life OS health check every 5 minutes
*/5 * * * * cd /u01/nix-life-os && /u01/nix-life-os/scripts/health-check.sh >> /u01/nix-life-os/backups/monitoring/health-check.log 2>&1

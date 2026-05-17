#!/usr/bin/env bash
set -Eeuo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TOKEN_FILE="${TOKEN_FILE:-.step83_token}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
RESULT_DIR="${RESULT_DIR:-storage/app/step83-load-results/$(date +%Y%m%d-%H%M%S)}"
REQUESTS_SMOKE="${REQUESTS_SMOKE:-50}"
CONCURRENCY_SMOKE="${CONCURRENCY_SMOKE:-5}"
REQUESTS_BASELINE="${REQUESTS_BASELINE:-200}"
CONCURRENCY_BASELINE="${CONCURRENCY_BASELINE:-20}"
REQUESTS_STRESS="${REQUESTS_STRESS:-500}"
CONCURRENCY_STRESS="${CONCURRENCY_STRESS:-50}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-30}"

if [ -z "$ADMIN_TOKEN" ] && [ -f "$TOKEN_FILE" ]; then
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

if [ -z "$ADMIN_TOKEN" ]; then
  echo "⚠️  No ADMIN_TOKEN found. Running auth setup first."
  ./scripts/step83_auth_token_setup.sh
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

if ! command -v ab >/dev/null 2>&1; then
  echo "❌ ApacheBench 'ab' is missing. Install it: sudo apt-get update && sudo apt-get install -y apache2-utils"
  exit 1
fi

mkdir -p "$RESULT_DIR"

declare -a ENDPOINTS=(
  "dashboard_summary|GET|/dashboard/summary|core"
  "life_balance_summary|GET|/life-balance/summary|core"
  "finance_accounts|GET|/finance/accounts|finance"
  "finance_transactions|GET|/finance/transactions|finance"
  "finance_budgets|GET|/finance/budgets|finance"
  "finance_ai_insights|GET|/finance/ai-insights|ai"
  "health_dashboard|GET|/health/dashboard|health"
  "health_steps|GET|/health/steps|health"
  "health_nutrition_summary|GET|/health/nutrition/summary|health"
  "health_hydration_daily|GET|/health/hydration/summary/daily|health"
  "health_ai_insights|GET|/health/ai-insights|ai"
  "projects_dashboard|GET|/projects/dashboard|projects"
  "projects_index|GET|/projects|projects"
  "productivity_dashboard|GET|/productivity/dashboard|productivity"
  "productivity_tasks|GET|/productivity/tasks|productivity"
  "productivity_ai_insights|GET|/productivity/ai-insights|ai"
  "ai_recommendations|GET|/ai/recommendations|ai"
  "ai_daily_scores|GET|/ai/scores/daily|ai"
  "auth_me|GET|/auth/me|auth"
)

run_ab() {
  local phase="$1"
  local requests="$2"
  local concurrency="$3"
  local name="$4"
  local method="$5"
  local path="$6"
  local group="$7"
  local url="$API_BASE$path"
  local out="$RESULT_DIR/${phase}_${name}.txt"

  echo "▶️  [$phase] $method $path | requests=$requests concurrency=$concurrency"
  ab -k -s "$TIMEOUT_SECONDS" -n "$requests" -c "$concurrency" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    "$url" > "$out" 2>&1 || true

  local failed rps mean p95 longest non2xx
  failed=$(grep -E '^Failed requests:' "$out" | awk '{print $3}' || echo "N/A")
  rps=$(grep -E '^Requests per second:' "$out" | awk '{print $4}' || echo "N/A")
  mean=$(grep -E '^Time per request:' "$out" | head -1 | awk '{print $4}' || echo "N/A")
  p95=$(grep -E '^  95%' "$out" | awk '{print $2}' || echo "N/A")
  longest=$(grep -E '^ 100%' "$out" | awk '{print $2}' || echo "N/A")
  non2xx=$(grep -E '^Non-2xx responses:' "$out" | awk '{print $3}' || echo "0")
  printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" "$phase" "$group" "$name" "$method" "$path" "$requests" "$concurrency" "$failed" "$non2xx" "$rps" "$p95" >> "$RESULT_DIR/summary.csv"
  echo "   failed=$failed non2xx=$non2xx rps=$rps p95_ms=$p95 longest_ms=$longest"
}

echo "phase,group,name,method,path,requests,concurrency,failed,non2xx,rps,p95_ms" > "$RESULT_DIR/summary.csv"

echo "=================================================="
echo " STEP 83 — ApacheBench Load Test"
echo " API_BASE: $API_BASE"
echo " Result:   $RESULT_DIR"
echo "=================================================="

for item in "${ENDPOINTS[@]}"; do
  IFS='|' read -r name method path group <<< "$item"
  run_ab "smoke" "$REQUESTS_SMOKE" "$CONCURRENCY_SMOKE" "$name" "$method" "$path" "$group"
done

for item in "${ENDPOINTS[@]}"; do
  IFS='|' read -r name method path group <<< "$item"
  run_ab "baseline" "$REQUESTS_BASELINE" "$CONCURRENCY_BASELINE" "$name" "$method" "$path" "$group"
done

for item in "${ENDPOINTS[@]}"; do
  IFS='|' read -r name method path group <<< "$item"
  run_ab "stress" "$REQUESTS_STRESS" "$CONCURRENCY_STRESS" "$name" "$method" "$path" "$group"
done

cat <<MSG
==================================================
 STEP 83 DONE
 Summary CSV:
 $RESULT_DIR/summary.csv

 Review slow API logs:
 docker exec -it nixlifeos-backend sh -lc "tail -200 storage/logs/laravel.log | grep -i 'slow API performance signal' -A 12"
==================================================
MSG

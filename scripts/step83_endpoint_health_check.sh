#!/usr/bin/env bash
set -Eeuo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TOKEN_FILE="${TOKEN_FILE:-.step83_token}"
ADMIN_TOKEN="${ADMIN_TOKEN:-}"

if [ -z "$ADMIN_TOKEN" ] && [ -f "$TOKEN_FILE" ]; then
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

if [ -z "$ADMIN_TOKEN" ]; then
  echo "⚠️  No ADMIN_TOKEN found. Running auth setup first."
  ./scripts/step83_auth_token_setup.sh
  ADMIN_TOKEN="$(cat "$TOKEN_FILE")"
fi

ENDPOINTS=(
  "GET /dashboard/summary"
  "GET /life-balance/summary"
  "GET /finance/accounts"
  "GET /finance/transactions"
  "GET /finance/budgets"
  "GET /finance/ai-insights"
  "GET /health/dashboard"
  "GET /health/steps"
  "GET /health/steps/summary"
  "GET /health/weight"
  "GET /health/weight/summary"
  "GET /health/nutrition"
  "GET /health/nutrition/summary"
  "GET /health/hydration"
  "GET /health/hydration/summary/daily"
  "GET /health/reports/daily"
  "GET /health/ai-insights"
  "GET /projects"
  "GET /projects/dashboard"
  "GET /productivity/dashboard"
  "GET /productivity/tasks"
  "GET /productivity/goals"
  "GET /productivity/habits"
  "GET /productivity/ai-insights"
  "GET /ai/recommendations"
  "GET /ai/scores/daily"
  "GET /auth/me"
)

echo "=================================================="
echo " STEP 83 — Endpoint Health Check"
echo " API_BASE: $API_BASE"
echo "=================================================="
printf "%-8s %-48s %-8s %-12s %-12s\n" "METHOD" "ENDPOINT" "HTTP" "TIME_S" "QUERIES"

FAILED=0
for item in "${ENDPOINTS[@]}"; do
  METHOD="${item%% *}"
  PATH_ONLY="${item#* }"
  TMP_HEADERS="$(mktemp)"
  CODE_TIME=$(curl -sS -o /dev/null -D "$TMP_HEADERS" -w "%{http_code} %{time_total}" \
    -X "$METHOD" "$API_BASE$PATH_ONLY" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" || echo "000 0")
  CODE="${CODE_TIME%% *}"
  TIME="${CODE_TIME#* }"
  QUERIES=$(grep -i '^X-Nix-Query-Count:' "$TMP_HEADERS" | awk '{print $2}' | tr -d '\r' || true)
  printf "%-8s %-48s %-8s %-12s %-12s\n" "$METHOD" "$PATH_ONLY" "$CODE" "$TIME" "${QUERIES:-N/A}"
  rm -f "$TMP_HEADERS"
  if [[ "$CODE" != "200" && "$CODE" != "201" ]]; then
    FAILED=$((FAILED+1))
  fi
done

if [ "$FAILED" -gt 0 ]; then
  echo "❌ Health check completed with $FAILED failing endpoint(s). Fix these before heavy load testing."
  exit 1
fi

echo "✅ All selected endpoints returned success HTTP codes."

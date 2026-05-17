#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
RESULT_DIR="${RESULT_DIR:-/tmp/step82-ab-results}"
mkdir -p "$RESULT_DIR"

if [ -z "${ADMIN_TOKEN:-}" ] || [ "${ADMIN_TOKEN:-}" = "null" ]; then
  echo "❌ ADMIN_TOKEN is missing. Export ADMIN_TOKEN first."
  exit 1
fi

ENDPOINTS=(
  "dashboard_summary:/dashboard/summary"
  "life_balance_summary:/life-balance/summary"
  "health_dashboard:/health/dashboard"
  "projects_dashboard:/projects/dashboard"
  "productivity_dashboard:/productivity/dashboard"
  "finance_accounts:/finance/accounts"
  "finance_transactions:/finance/transactions"
  "finance_budgets:/finance/budgets"
  "ai_recommendations:/ai/recommendations"
  "notifications:/notifications"
  "notifications_unread_count:/notifications/unread-count"
)

for item in "${ENDPOINTS[@]}"; do
  name="${item%%:*}"
  endpoint="${item#*:}"
  echo "Running AB: $endpoint"
  ab -n 100 -c 10 \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    "$API_BASE$endpoint" > "$RESULT_DIR/${name}.txt" || true

  grep -E "Complete requests|Failed requests|Non-2xx responses|Requests per second|Time per request|95%|99%|100%" "$RESULT_DIR/${name}.txt" || true
  echo "Saved: $RESULT_DIR/${name}.txt"
  echo ""
done

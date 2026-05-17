#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Password@123}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for this script. Install jq first."
  exit 1
fi

TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | jq -r '.data.token // .token // empty')

if [ -z "$TOKEN" ]; then
  echo "Login failed. Check API_BASE / credentials."
  exit 1
fi

ENDPOINTS=(
  "/dashboard/summary"
  "/dashboard/unified"
  "/finance/accounts"
  "/finance/transactions?limit=50"
  "/finance/budgets"
  "/health/dashboard"
  "/health/hydration-logs"
  "/projects/dashboard"
  "/productivity/dashboard"
  "/ai/recommendations?limit=20&active_only=1"
  "/notifications"
)

for ep in "${ENDPOINTS[@]}"; do
  echo "===== GET $ep"
  curl -s -o /tmp/step84_response.json -w "HTTP=%{http_code} TIME=%{time_total}s SIZE=%{size_download}\n" \
    "$API_BASE$ep" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TOKEN"
  head -c 300 /tmp/step84_response.json; echo; echo
done

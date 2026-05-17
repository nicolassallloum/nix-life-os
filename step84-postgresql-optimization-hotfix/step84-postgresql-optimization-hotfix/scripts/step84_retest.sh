#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TOKEN="${ADMIN_TOKEN:-${TOKEN:-}}"

if [ -z "$TOKEN" ]; then
  echo "ERROR: Please export ADMIN_TOKEN or TOKEN before running this script."
  echo "Example: export ADMIN_TOKEN=your_token_here"
  exit 1
fi

call_api() {
  local path="$1"
  echo
  echo "===== GET ${path}"
  curl -sS -w '\nHTTP=%{http_code} TIME=%{time_total}s SIZE=%{size_download}\n' \
    "${API_BASE}${path}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer ${TOKEN}" | head -c 900
  echo
}

call_api "/dashboard/summary"
call_api "/finance/accounts"
call_api "/finance/transactions?limit=50"
call_api "/finance/budgets"
call_api "/health/dashboard"
call_api "/projects/dashboard"
call_api "/productivity/dashboard"
call_api "/ai/recommendations?limit=20&active_only=1"
call_api "/notifications"

echo
echo "NOTE: /dashboard/unified and /health/hydration-logs were removed from this retest because your route list does not expose them in the current build."

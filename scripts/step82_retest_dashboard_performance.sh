#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Password@123}"
RESULT_DIR="${RESULT_DIR:-/tmp/step82-performance-results}"
REQUESTS="${REQUESTS:-100}"
CONCURRENCY="${CONCURRENCY:-10}"

mkdir -p "$RESULT_DIR"

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required. Install with: sudo apt install -y jq"
  exit 1
fi

if [ -z "${ADMIN_TOKEN:-}" ] || [ "${ADMIN_TOKEN:-}" = "null" ]; then
  echo "Generating ADMIN_TOKEN from $API_BASE/auth/login ..."
  ADMIN_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | jq -r '.data.token // empty')
  export ADMIN_TOKEN
fi

if [ -z "${ADMIN_TOKEN:-}" ] || [ "${ADMIN_TOKEN:-}" = "null" ]; then
  echo "❌ ADMIN_TOKEN is missing or invalid. Check admin credentials."
  exit 1
fi

ENDPOINTS=(
  "/auth/me"
  "/dashboard/summary"
  "/life-balance/summary"
  "/health/dashboard"
  "/projects/dashboard"
  "/productivity/dashboard"
  "/finance/accounts"
  "/finance/transactions"
  "/finance/budgets"
  "/finance/ai-insights"
  "/health/ai-insights"
  "/productivity/ai-insights"
  "/ai/recommendations"
  "/notifications"
  "/notifications/unread-count"
)

echo "=================================================="
echo " STEP 82 — Real Route Dashboard Performance Retest"
echo " API_BASE: $API_BASE"
echo " Results: $RESULT_DIR"
echo "=================================================="

: > "$RESULT_DIR/baseline.tsv"
echo -e "endpoint\thttp\ttotal_seconds\tsize_bytes\tx_response_time_ms\tx_query_count" >> "$RESULT_DIR/baseline.tsv"

for endpoint in "${ENDPOINTS[@]}"; do
  safe_name=$(echo "$endpoint" | sed 's#^/##; s#[^A-Za-z0-9._-]#_#g')
  header_file="$RESULT_DIR/${safe_name}.headers"
  body_file="$RESULT_DIR/${safe_name}.json"

  echo ""
  echo "Testing: $endpoint"

  metrics=$(curl -s -D "$header_file" -o "$body_file" \
    -w "HTTP=%{http_code} TOTAL=%{time_total} SIZE=%{size_download}" \
    "$API_BASE$endpoint" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "X-Request-ID: step82-$(date +%s)-$safe_name")

  echo "$metrics"

  http=$(echo "$metrics" | sed -n 's/.*HTTP=\([0-9]*\).*/\1/p')
  total=$(echo "$metrics" | sed -n 's/.*TOTAL=\([^ ]*\).*/\1/p')
  size=$(echo "$metrics" | sed -n 's/.*SIZE=\([^ ]*\).*/\1/p')
  response_ms=$(grep -i '^X-Nix-Response-Time-Ms:' "$header_file" | awk '{print $2}' | tr -d '\r' || true)
  query_count=$(grep -i '^X-Nix-Query-Count:' "$header_file" | awk '{print $2}' | tr -d '\r' || true)

  echo -e "$endpoint\t$http\t$total\t$size\t${response_ms:-NA}\t${query_count:-NA}" >> "$RESULT_DIR/baseline.tsv"

  if command -v jq >/dev/null 2>&1; then
    jq -r '.success // .status // .message // empty' "$body_file" 2>/dev/null || true
  fi

done

if command -v column >/dev/null 2>&1; then
  echo ""
  column -t -s $'\t' "$RESULT_DIR/baseline.tsv"
fi

if command -v ab >/dev/null 2>&1; then
  echo ""
  echo "Running ApacheBench for /dashboard/summary: -n $REQUESTS -c $CONCURRENCY"
  ab -n "$REQUESTS" -c "$CONCURRENCY" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    "$API_BASE/dashboard/summary" > "$RESULT_DIR/ab_dashboard_summary_${REQUESTS}_${CONCURRENCY}.txt" || true

  grep -E "Complete requests|Failed requests|Non-2xx responses|Requests per second|Time per request|95%|99%|100%" "$RESULT_DIR/ab_dashboard_summary_${REQUESTS}_${CONCURRENCY}.txt" || true
else
  echo "⚠️ ApacheBench not found. Install with: sudo apt install -y apache2-utils"
fi

echo ""
echo "✅ STEP 82 retest finished: $RESULT_DIR"

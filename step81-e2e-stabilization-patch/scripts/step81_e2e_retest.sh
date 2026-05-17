#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TEST_EMAIL="${TEST_EMAIL:-test@nixlifeos.com}"
TEST_PASSWORD="${TEST_PASSWORD:-password}"
TODAY="$(date +%F)"

echo "=================================================="
echo " STEP 81 — E2E Retest"
echo " API_BASE: $API_BASE"
echo "=================================================="

TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r '.data.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed"
  exit 1
fi

echo "✅ Login passed"

curl -s "$API_BASE/auth/me" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success,.data.user.email'
curl -s -i "$API_BASE/dashboard/summary" -H "Accept: application/json" | head -n 1
curl -s "$API_BASE/dashboard/summary" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.status // .success'

ACCOUNT_ID=$(curl -s -X POST "$API_BASE/finance/accounts" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"STEP 81 Test Cash","type":"cash","currency":"USD","opening_balance":100,"current_balance":100,"is_active":true}' | jq -r '.data.id')

echo "ACCOUNT_ID=$ACCOUNT_ID"
if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "null" ]; then echo "❌ Finance account create failed"; exit 1; fi

TRANSACTION_ID=$(curl -s -X POST "$API_BASE/finance/transactions" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"account_id\":\"$ACCOUNT_ID\",\"type\":\"expense\",\"amount\":10,\"currency\":\"USD\",\"transaction_date\":\"$TODAY\",\"description\":\"STEP 81 test expense\"}" | jq -r '.data.id')

echo "TRANSACTION_ID=$TRANSACTION_ID"
if [ -z "$TRANSACTION_ID" ] || [ "$TRANSACTION_ID" = "null" ]; then echo "❌ Finance transaction create failed"; exit 1; fi

curl -s -X PUT "$API_BASE/finance/transactions/$TRANSACTION_ID" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"account_id\":\"$ACCOUNT_ID\",\"type\":\"expense\",\"amount\":15,\"currency\":\"USD\",\"transaction_date\":\"$TODAY\",\"description\":\"STEP 81 updated expense\"}" | jq '.success'

PROJECT_ID=$(curl -s -X POST "$API_BASE/projects" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"name":"STEP 81 E2E Project","description":"Full end-to-end test project","status":"active","priority":"medium","start_date":"2026-05-17"}' | jq -r '.data.id')

echo "PROJECT_ID=$PROJECT_ID"
if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then echo "❌ Project create failed"; exit 1; fi

curl -s "$API_BASE/notifications/unread-count" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq .
curl -s "$API_BASE/reports" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success,.data.finance.accounts_count'
curl -s "$API_BASE/reports/finance" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'
curl -s "$API_BASE/reports/health" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'
curl -s "$API_BASE/reports/productivity" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'

REC_ID=$(curl -s "$API_BASE/ai/recommendations" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq -r '.data.recommendations[0].id // empty')
if [ -n "$REC_ID" ]; then
  curl -s -X POST "$API_BASE/ai/recommendations/$REC_ID/feedback" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"feedback":"helpful"}' | jq '.success'
fi

curl -s -X DELETE "$API_BASE/finance/transactions/$TRANSACTION_ID" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'
curl -s -X DELETE "$API_BASE/finance/accounts/$ACCOUNT_ID" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'
curl -s -X DELETE "$API_BASE/projects/$PROJECT_ID" -H "Accept: application/json" -H "Authorization: Bearer $TOKEN" | jq '.success'

echo "✅ STEP 81 E2E retest completed"

#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TEST_EMAIL="${TEST_EMAIL:-test@nixlifeos.com}"
TEST_PASSWORD="${TEST_PASSWORD:-password}"

echo "=================================================="
echo " STEP 81.2 — Finance JSON/Alias Retest"
echo " API_BASE: $API_BASE"
echo "=================================================="

TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r '.data.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed"
  exit 1
fi

echo "✅ Login passed"

echo ""
echo "Creating finance account with alias payload..."
ACCOUNT_RESPONSE=$(curl -s -X POST "$API_BASE/finance/accounts" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data-raw '{"name":"STEP 81.2 Test Cash","type":"cash","currency":"USD","opening_balance":100,"current_balance":100,"is_active":true}')

echo "$ACCOUNT_RESPONSE" | jq .
ACCOUNT_ID=$(echo "$ACCOUNT_RESPONSE" | jq -r '.data.id // .data.account_id // empty')

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "null" ]; then
  echo "❌ Alias payload create failed. Trying canonical payload for diagnosis..."
  CANONICAL_RESPONSE=$(curl -s -X POST "$API_BASE/finance/accounts" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    --data-raw '{"account_name":"STEP 81.2 Canonical Cash","account_type":"cash","currency_code":"USD","opening_balance":100,"current_balance":100,"is_active":true}')
  echo "$CANONICAL_RESPONSE" | jq .
  ACCOUNT_ID=$(echo "$CANONICAL_RESPONSE" | jq -r '.data.id // .data.account_id // empty')
fi

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "null" ]; then
  echo "❌ Finance account create still failed"
  exit 1
fi

echo "✅ ACCOUNT_ID=$ACCOUNT_ID"

echo ""
echo "Creating finance transaction..."
TRANSACTION_RESPONSE=$(curl -s -X POST "$API_BASE/finance/transactions" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data-raw "{\"account_id\":\"$ACCOUNT_ID\",\"type\":\"expense\",\"amount\":10,\"currency\":\"USD\",\"transaction_date\":\"2026-05-17\",\"description\":\"STEP 81.2 test expense\"}")

echo "$TRANSACTION_RESPONSE" | jq .
TRANSACTION_ID=$(echo "$TRANSACTION_RESPONSE" | jq -r '.data.id // .data.transaction_id // empty')

if [ -z "$TRANSACTION_ID" ] || [ "$TRANSACTION_ID" = "null" ]; then
  echo "❌ Finance transaction create failed"
  exit 1
fi

echo "✅ TRANSACTION_ID=$TRANSACTION_ID"

echo ""
echo "Updating finance transaction..."
curl -s -X PUT "$API_BASE/finance/transactions/$TRANSACTION_ID" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  --data-raw "{\"account_id\":\"$ACCOUNT_ID\",\"type\":\"expense\",\"amount\":15,\"currency\":\"USD\",\"transaction_date\":\"2026-05-17\",\"description\":\"STEP 81.2 updated test expense\"}" | jq .

echo ""
echo "Deleting finance transaction..."
curl -s -X DELETE "$API_BASE/finance/transactions/$TRANSACTION_ID" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "Checking invalid UUID returns clean 404..."
curl -s -X DELETE "$API_BASE/finance/transactions/null" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "Deleting finance account..."
curl -s -X DELETE "$API_BASE/finance/accounts/$ACCOUNT_ID" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .

echo ""
echo "Checking STEP 81 routes..."
curl -s "$API_BASE/notifications/unread-count" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .

curl -s "$API_BASE/reports" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq '.success, .data.summary'

echo ""
echo "✅ STEP 81.2 finance JSON/alias retest completed."

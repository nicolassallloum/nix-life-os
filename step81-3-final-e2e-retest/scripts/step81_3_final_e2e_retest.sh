#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
TEST_EMAIL="${TEST_EMAIL:-test@nixlifeos.com}"
TEST_PASSWORD="${TEST_PASSWORD:-password}"
TEST_DATE="${TEST_DATE:-2026-05-17}"

line() { echo "=================================================="; }
json_get() { jq -r "$1 // empty"; }

line
echo " STEP 81.3 — Final E2E Retest"
echo " API_BASE: $API_BASE"
line

TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r '.data.token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed"
  exit 1
fi

echo "✅ Login passed"

AUTH=(-H "Accept: application/json" -H "Authorization: Bearer $TOKEN")
JSON_AUTH=(-H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN")

echo ""
echo "Checking authenticated user..."
curl -s "$API_BASE/auth/me" "${AUTH[@]}" | jq '.success, .data.user.email'

echo ""
echo "Checking security 401 without token..."
curl -i -s "$API_BASE/dashboard/summary" -H "Accept: application/json" | head -n 1

echo ""
echo "Checking dashboard..."
curl -s "$API_BASE/dashboard/summary" "${AUTH[@]}" | jq '.status // .success, .data.generated_at'

echo ""
echo "Creating finance account with canonical payload..."
ACCOUNT_RESPONSE=$(curl -s -X POST "$API_BASE/finance/accounts" \
  "${JSON_AUTH[@]}" \
  --data-raw '{"account_name":"STEP 81.3 Canonical Cash","account_type":"cash","currency_code":"USD","opening_balance":100,"current_balance":100,"is_active":true}')

echo "$ACCOUNT_RESPONSE" | jq .
ACCOUNT_ID=$(echo "$ACCOUNT_RESPONSE" | jq -r '.data.id // .data.account_id // empty')

if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" = "null" ]; then
  echo "❌ Finance account create failed"
  exit 1
fi

echo "✅ ACCOUNT_ID=$ACCOUNT_ID"

echo ""
echo "Creating finance transaction with canonical transaction_type..."
TRANSACTION_RESPONSE=$(curl -s -X POST "$API_BASE/finance/transactions" \
  "${JSON_AUTH[@]}" \
  --data-raw "{\"account_id\":\"$ACCOUNT_ID\",\"transaction_type\":\"expense\",\"amount\":10,\"currency_code\":\"USD\",\"transaction_date\":\"$TEST_DATE\",\"description\":\"STEP 81.3 test expense\"}")

echo "$TRANSACTION_RESPONSE" | jq .
TRANSACTION_ID=$(echo "$TRANSACTION_RESPONSE" | jq -r '.data.id // .data.transaction_id // empty')

if [ -z "$TRANSACTION_ID" ] || [ "$TRANSACTION_ID" = "null" ]; then
  echo "❌ Finance transaction create failed"
  exit 1
fi

echo "✅ TRANSACTION_ID=$TRANSACTION_ID"

echo ""
echo "Updating finance transaction..."
UPDATE_RESPONSE=$(curl -s -X PUT "$API_BASE/finance/transactions/$TRANSACTION_ID" \
  "${JSON_AUTH[@]}" \
  --data-raw "{\"account_id\":\"$ACCOUNT_ID\",\"transaction_type\":\"expense\",\"amount\":15,\"currency_code\":\"USD\",\"transaction_date\":\"$TEST_DATE\",\"description\":\"STEP 81.3 updated test expense\"}")
echo "$UPDATE_RESPONSE" | jq .
echo "$UPDATE_RESPONSE" | jq -e '.success == true' >/dev/null || { echo "❌ Finance transaction update failed"; exit 1; }

echo ""
echo "Deleting finance transaction..."
DELETE_TX_RESPONSE=$(curl -s -X DELETE "$API_BASE/finance/transactions/$TRANSACTION_ID" "${AUTH[@]}")
echo "$DELETE_TX_RESPONSE" | jq .
echo "$DELETE_TX_RESPONSE" | jq -e '.success == true' >/dev/null || { echo "❌ Finance transaction delete failed"; exit 1; }

echo ""
echo "Checking invalid UUID returns clean not-found response..."
INVALID_RESPONSE=$(curl -s -X DELETE "$API_BASE/finance/transactions/null" "${AUTH[@]}")
echo "$INVALID_RESPONSE" | jq .
echo "$INVALID_RESPONSE" | jq -e '.success == false and ((.error.status == 404) or (.error.code == "NOT_FOUND"))' >/dev/null || { echo "❌ Invalid UUID did not return clean 404"; exit 1; }

echo ""
echo "Deleting finance account..."
DELETE_ACCOUNT_RESPONSE=$(curl -s -X DELETE "$API_BASE/finance/accounts/$ACCOUNT_ID" "${AUTH[@]}")
echo "$DELETE_ACCOUNT_RESPONSE" | jq .
echo "$DELETE_ACCOUNT_RESPONSE" | jq -e '.success == true' >/dev/null || { echo "❌ Finance account delete failed"; exit 1; }

echo ""
echo "Creating project with canonical payload..."
PROJECT_RESPONSE=$(curl -s -X POST "$API_BASE/projects" \
  "${JSON_AUTH[@]}" \
  --data-raw "{\"project_name\":\"STEP 81.3 E2E Project\",\"project_code\":\"S813-$(date +%s)\",\"description\":\"Final STEP 81.3 E2E test project\",\"status\":\"in_progress\",\"priority\":\"medium\",\"start_date\":\"$TEST_DATE\"}")
echo "$PROJECT_RESPONSE" | jq .
PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.data.id // empty')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  echo "❌ Project create failed"
  exit 1
fi

echo "✅ PROJECT_ID=$PROJECT_ID"

echo ""
echo "Deleting project..."
DELETE_PROJECT_RESPONSE=$(curl -s -X DELETE "$API_BASE/projects/$PROJECT_ID" "${AUTH[@]}")
echo "$DELETE_PROJECT_RESPONSE" | jq .
echo "$DELETE_PROJECT_RESPONSE" | jq -e '.success == true' >/dev/null || { echo "❌ Project delete failed"; exit 1; }

echo ""
echo "Checking health/productivity/AI/notifications/reports endpoints..."
curl -s "$API_BASE/health/nutrition" "${AUTH[@]}" | jq '.success'
curl -s "$API_BASE/productivity/tasks" "${AUTH[@]}" | jq '.success'
curl -s "$API_BASE/ai/recommendations" "${AUTH[@]}" | jq '.success'
curl -s "$API_BASE/notifications/unread-count" "${AUTH[@]}" | jq '.success, .data'
curl -s "$API_BASE/reports" "${AUTH[@]}" | jq '.success, .data.summary'
curl -s "$API_BASE/reports/finance" "${AUTH[@]}" | jq '.success'
curl -s "$API_BASE/reports/health" "${AUTH[@]}" | jq '.success'
curl -s "$API_BASE/reports/productivity" "${AUTH[@]}" | jq '.success'

echo ""
line
echo "✅ STEP 81.3 final E2E retest completed successfully."
line

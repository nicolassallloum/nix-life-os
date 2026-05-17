#!/usr/bin/env bash
set -Eeuo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Password@123}"
TOKEN_FILE="${TOKEN_FILE:-.step83_token}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Missing required command: $1"
    exit 1
  }
}

require_cmd curl
require_cmd jq

echo "=================================================="
echo " STEP 83 — Auth Token Setup"
echo " API_BASE: $API_BASE"
echo " Email:    $ADMIN_EMAIL"
echo "=================================================="

LOGIN_RESPONSE=$(curl -sS -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.token // .token // .access_token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed or token not found. Response:"
  echo "$LOGIN_RESPONSE" | jq . 2>/dev/null || echo "$LOGIN_RESPONSE"
  echo "Set ADMIN_EMAIL and ADMIN_PASSWORD, then retry."
  exit 1
fi

echo "$TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo "✅ Token saved to $TOKEN_FILE"
echo "export ADMIN_TOKEN=\"$TOKEN\""

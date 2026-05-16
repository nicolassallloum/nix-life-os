#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8001/api/v1}"
USER_EMAIL="${USER_EMAIL:-step76.empty@gmail.com}"
USER_PASSWORD="${USER_PASSWORD:-Password@123}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1"; exit 1; }
}

require_cmd curl
require_cmd jq

echo "API_BASE=${API_BASE}"

echo "Checking API health..."
curl -fsS "${API_BASE%/v1}/health" -H "Accept: application/json" | jq . >/dev/null

echo "Ensuring STEP 76 user exists..."
REGISTER_RESPONSE=$(curl -s -X POST "${API_BASE}/auth/register" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Step 76 Empty User\",\"email\":\"${USER_EMAIL}\",\"password\":\"${USER_PASSWORD}\",\"password_confirmation\":\"${USER_PASSWORD}\"}")

echo "${REGISTER_RESPONSE}" | jq . || true

echo "Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "${API_BASE}/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${USER_EMAIL}\",\"password\":\"${USER_PASSWORD}\"}")

TOKEN=$(echo "${LOGIN_RESPONSE}" | jq -r '.data.token // empty')

if [ -z "${TOKEN}" ] || [ "${TOKEN}" = "null" ]; then
  echo "Login failed. Response:"
  echo "${LOGIN_RESPONSE}" | jq . || echo "${LOGIN_RESPONSE}"
  exit 1
fi

echo "Token acquired."

ENDPOINTS=(
  "/dashboard/summary"
  "/finance/accounts"
  "/finance/transactions"
  "/finance/budgets"
  "/health/dashboard"
  "/health/nutrition"
  "/health/hydration"
  "/health/weight"
  "/health/steps"
  "/health/lab-tests"
  "/health/medications"
  "/projects"
  "/projects/dashboard"
  "/productivity/dashboard"
  "/productivity/tasks"
  "/productivity/habits"
  "/productivity/goals"
  "/productivity/calendar"
  "/ai/recommendations"
  "/ai/scores/daily"
)

FAILED=0

for endpoint in "${ENDPOINTS[@]}"; do
  printf '\n=== GET %s ===\n' "${endpoint}"
  HTTP_CODE=$(curl -s -o /tmp/step76_response.json -w "%{http_code}" \
    "${API_BASE}${endpoint}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer ${TOKEN}")

  cat /tmp/step76_response.json | jq . || cat /tmp/step76_response.json

  if [ "${HTTP_CODE}" -lt 200 ] || [ "${HTTP_CODE}" -ge 300 ]; then
    echo "[FAIL] ${endpoint} returned HTTP ${HTTP_CODE}"
    FAILED=1
  else
    echo "[PASS] ${endpoint} returned HTTP ${HTTP_CODE}"
  fi
done

exit "${FAILED}"

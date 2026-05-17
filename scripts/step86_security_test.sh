#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
USER_EMAIL="${USER_EMAIL:-step86.user@example.com}"
USER_PASSWORD="${USER_PASSWORD:-Password@123!}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step86.admin@example.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Password@123!}"

echo "STEP 86 Security Regression Test"
echo "API_BASE=$API_BASE"

status_of() {
  curl -s -o /tmp/step86_response.json -w "%{http_code}" "$@"
}

expect_status() {
  local expected="$1"; shift
  local actual
  actual=$(status_of "$@")
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL expected=$expected actual=$actual command=curl $*"
    cat /tmp/step86_response.json || true
    exit 1
  fi
  echo "PASS $expected $*"
}

expect_status 200 -H "Accept: application/json" "$API_BASE/../health"
expect_status 401 -H "Accept: application/json" "$API_BASE/auth/me"
expect_status 401 -H "Accept: application/json" -H "Authorization: Bearer invalid-token" "$API_BASE/auth/me"
expect_status 401 -H "Accept: application/json" "$API_BASE/dashboard/summary"

USER_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASSWORD\"}" | jq -r '.data.token // empty')

if [[ -n "$USER_TOKEN" ]]; then
  expect_status 200 -H "Accept: application/json" -H "Authorization: Bearer $USER_TOKEN" "$API_BASE/auth/me"
  expect_status 403 -H "Accept: application/json" -H "Authorization: Bearer $USER_TOKEN" "$API_BASE/admin"
  expect_status 403 -H "Accept: application/json" -H "Authorization: Bearer $USER_TOKEN" "$API_BASE/security"
else
  echo "WARN user login failed; create USER_EMAIL/USER_PASSWORD or export valid credentials."
fi

echo "Header check"
curl -s -I "$API_BASE/../health" | grep -Ei 'x-content-type-options|x-frame-options|referrer-policy|permissions-policy' || true

echo "STEP 86 test script completed."

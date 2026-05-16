#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8000/api/v1}"
NORMAL_EMAIL="${NORMAL_EMAIL:-step74.user.$(date +%s)@gmail.com}"
NORMAL_PASSWORD="${NORMAL_PASSWORD:-Step74@2026!}"
NORMAL_NAME="${NORMAL_NAME:-Step74 Normal User}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@gmail.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@2026!}"
INVALID_TOKEN="999|invalid-invalid-invalid-invalid"
RESULT_FILE="step74_authorization_regression_result_v3.log"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

print_header() {
  echo ""
  echo "=================================================="
  echo " $1"
  echo "=================================================="
}

record_result() {
  local actual="$1"
  local expected_regex="$2"
  local label="$3"

  if [[ "$actual" =~ $expected_regex ]]; then
    echo "PASS: $label => HTTP $actual"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: $label => HTTP $actual | Expected: $expected_regex"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    if [ -f /tmp/step74_response.json ]; then
      cat /tmp/step74_response.json | jq . 2>/dev/null || cat /tmp/step74_response.json
    fi
  fi
}

check_for_leak() {
  if [ -f /tmp/step74_response.json ] && grep -qiE "exception|trace|stack|sqlstate|syntax error|undefined|fatal error|/var/www|vendor/laravel" /tmp/step74_response.json; then
    echo "SECURITY FAIL: Possible internal error or stack trace leaked."
    FAIL_COUNT=$((FAIL_COUNT + 1))
    cat /tmp/step74_response.json | jq . 2>/dev/null || cat /tmp/step74_response.json
  fi
}

request_status() {
  local method="$1"
  local route="$2"
  local token="${3:-}"

  if [ -z "$token" ]; then
    curl -s -o /tmp/step74_response.json -w "%{http_code}" -X "$method" "$BASE_URL$route" \
      -H "Accept: application/json"
  else
    curl -s -o /tmp/step74_response.json -w "%{http_code}" -X "$method" "$BASE_URL$route" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $token"
  fi
}

login_token() {
  local email="$1"
  local password="$2"

  curl -s -X POST "$BASE_URL/auth/login" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data-raw "{\"email\":\"$email\",\"password\":\"$password\"}" | jq -r '.data.token // .token // .access_token // empty'
}

register_user() {
  local name="$1"
  local email="$2"
  local password="$3"

  curl -s -X POST "$BASE_URL/auth/register" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data-raw "{\"name\":\"$name\",\"email\":\"$email\",\"password\":\"$password\",\"password_confirmation\":\"$password\"}"
}

{
print_header "STEP 74 — Protected Routes & Authorization Regression Test V3"

echo "BASE_URL=$BASE_URL"
echo "NORMAL_EMAIL=$NORMAL_EMAIL"
echo "ADMIN_EMAIL=$ADMIN_EMAIL"

print_header "Register/login normal user"
USER_TOKEN="$(login_token "$NORMAL_EMAIL" "$NORMAL_PASSWORD")"

if [ -z "$USER_TOKEN" ]; then
  echo "Normal user does not exist or password changed. Registering test user..."
  REGISTER_RESPONSE="$(register_user "$NORMAL_NAME" "$NORMAL_EMAIL" "$NORMAL_PASSWORD")"
  echo "$REGISTER_RESPONSE" | jq . 2>/dev/null || echo "$REGISTER_RESPONSE"

  USER_TOKEN="$(login_token "$NORMAL_EMAIL" "$NORMAL_PASSWORD")"
fi

if [ -z "$USER_TOKEN" ]; then
  echo "FAIL: Unable to create/login normal user."
  echo "Most likely cause: your Laravel email validator requires DNS/MX-valid domains."
  echo "Try: NORMAL_EMAIL=yourrealtest@gmail.com NORMAL_PASSWORD='Step74@2026!' ./step74_authorization_regression_test_v3.sh"
  exit 1
fi

echo "Normal token loaded: ${USER_TOKEN:0:16}..."

ADMIN_TOKEN="$(login_token "$ADMIN_EMAIL" "$ADMIN_PASSWORD")"
if [ -z "$ADMIN_TOKEN" ]; then
  echo "WARN: Admin login skipped. Set ADMIN_EMAIL and ADMIN_PASSWORD env vars or create admin user."
  WARN_COUNT=$((WARN_COUNT + 1))
else
  echo "Admin token loaded: ${ADMIN_TOKEN:0:16}..."
fi

USER_ROUTES=(
  "/auth/me"
  "/dashboard/summary"
  "/finance/accounts"
  "/finance/transactions"
  "/finance/budgets"
  "/health/dashboard"
  "/health/steps"
  "/health/weight"
  "/health/nutrition"
  "/health/hydration"
  "/health/medications"
  "/health/lab-tests"
  "/health/reports/weekly"
  "/projects/dashboard"
  "/projects"
  "/productivity/dashboard"
  "/productivity/tasks"
  "/productivity/habits"
  "/productivity/goals"
  "/productivity/calendar"
  "/ai/recommendations"
  "/notifications"
  "/automation"
)

ADMIN_ROUTES=(
  "/admin"
  "/admin/users"
  "/admin/roles"
  "/admin/permissions"
  "/security"
  "/security/audit-logs"
  "/security/login-history"
  "/user-management/users"
  "/user-management/roles"
)

print_header "A — Missing token must return 401"
for route in "${USER_ROUTES[@]}" "${ADMIN_ROUTES[@]}"; do
  status="$(request_status GET "$route")"
  check_for_leak
  record_result "$status" "^401$" "MISSING TOKEN GET $route"
done

print_header "B — Invalid token must return 401"
for route in "${USER_ROUTES[@]}" "${ADMIN_ROUTES[@]}"; do
  status="$(request_status GET "$route" "$INVALID_TOKEN")"
  check_for_leak
  record_result "$status" "^401$" "INVALID TOKEN GET $route"
done

print_header "C — Valid normal user token should access user routes"
for route in "${USER_ROUTES[@]}"; do
  status="$(request_status GET "$route" "$USER_TOKEN")"
  check_for_leak
  record_result "$status" "^(200|204|422)$" "USER TOKEN GET $route"
done

print_header "D — Normal user must be blocked from admin/security/user-management"
for route in "${ADMIN_ROUTES[@]}"; do
  status="$(request_status GET "$route" "$USER_TOKEN")"
  check_for_leak
  record_result "$status" "^403$" "NORMAL USER BLOCKED GET $route"
done

print_header "E — Admin token should access admin/security/user-management"
if [ -n "$ADMIN_TOKEN" ]; then
  for route in "${ADMIN_ROUTES[@]}"; do
    status="$(request_status GET "$route" "$ADMIN_TOKEN")"
    check_for_leak
    record_result "$status" "^(200|204|422)$" "ADMIN TOKEN GET $route"
  done
else
  echo "Skipped because ADMIN_TOKEN is empty."
fi

print_header "F — Logout must invalidate token"
logout_status="$(request_status POST "/auth/logout" "$USER_TOKEN")"
record_result "$logout_status" "^(200|204)$" "LOGOUT"
after_logout_status="$(request_status GET "/auth/me" "$USER_TOKEN")"
record_result "$after_logout_status" "^401$" "AFTER LOGOUT /auth/me"

print_header "Summary"
echo "PASS=$PASS_COUNT"
echo "FAIL=$FAIL_COUNT"
echo "WARN=$WARN_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "STEP 74 RESULT: PASS"
else
  echo "STEP 74 RESULT: FAIL"
fi
} | tee "$RESULT_FILE"

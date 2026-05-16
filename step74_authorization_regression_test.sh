#!/usr/bin/env bash

set -e

BASE_URL="http://127.0.0.1:8000/api/v1"

NORMAL_EMAIL="step74.user@nixlifeos.com"
NORMAL_PASSWORD="password"

ADMIN_EMAIL="admin@nixlifeos.com"
ADMIN_PASSWORD="password"

INVALID_TOKEN="999|invalid-invalid-invalid-invalid"

echo "=================================================="
echo " STEP 74 — Protected Routes & Authorization Tests"
echo "=================================================="

echo ""
echo "1) Login normal user"
USER_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$NORMAL_EMAIL\",
    \"password\": \"$NORMAL_PASSWORD\"
  }" | jq -r '.data.token // empty')

if [ -z "$USER_TOKEN" ]; then
  echo "Normal user login failed. Trying to register user..."

  curl -s -X POST "$BASE_URL/auth/register" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"Step74 Normal User\",
      \"email\": \"$NORMAL_EMAIL\",
      \"password\": \"$NORMAL_PASSWORD\",
      \"password_confirmation\": \"$NORMAL_PASSWORD\"
    }" | jq .

  USER_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"$NORMAL_EMAIL\",
      \"password\": \"$NORMAL_PASSWORD\"
    }" | jq -r '.data.token // empty')
fi

echo "USER_TOKEN=${USER_TOKEN:0:20}..."

echo ""
echo "2) Login admin user if available"
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }" | jq -r '.data.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
  echo "Admin login skipped or failed. Admin tests will still run with empty token and should fail."
else
  echo "ADMIN_TOKEN=${ADMIN_TOKEN:0:20}..."
fi

echo ""
echo "=================================================="
echo " Protected user route list"
echo "=================================================="

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

test_route() {
  local METHOD="$1"
  local URL="$2"
  local TOKEN="$3"
  local LABEL="$4"
  local EXPECTED="$5"

  if [ -z "$TOKEN" ]; then
    STATUS=$(curl -s -o /tmp/step74_response.json -w "%{http_code}" -X "$METHOD" "$BASE_URL$URL" \
      -H "Accept: application/json")
  else
    STATUS=$(curl -s -o /tmp/step74_response.json -w "%{http_code}" -X "$METHOD" "$BASE_URL$URL" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $TOKEN")
  fi

  echo "[$LABEL] $METHOD $URL => HTTP $STATUS | Expected: $EXPECTED"

  if grep -qiE "exception|trace|stack|sqlstate|syntax error|undefined|fatal error" /tmp/step74_response.json; then
    echo "  SECURITY WARNING: Possible stack trace or internal error leaked."
    cat /tmp/step74_response.json | jq . 2>/dev/null || cat /tmp/step74_response.json
  fi
}

echo ""
echo "=================================================="
echo " Test A — Missing token should return 401"
echo "=================================================="

for route in "${USER_ROUTES[@]}"; do
  test_route "GET" "$route" "" "MISSING TOKEN" "401"
done

for route in "${ADMIN_ROUTES[@]}"; do
  test_route "GET" "$route" "" "MISSING TOKEN ADMIN" "401"
done

echo ""
echo "=================================================="
echo " Test B — Invalid token should return 401"
echo "=================================================="

for route in "${USER_ROUTES[@]}"; do
  test_route "GET" "$route" "$INVALID_TOKEN" "INVALID TOKEN" "401"
done

for route in "${ADMIN_ROUTES[@]}"; do
  test_route "GET" "$route" "$INVALID_TOKEN" "INVALID TOKEN ADMIN" "401"
done

echo ""
echo "=================================================="
echo " Test C — Valid normal user token on user routes"
echo "=================================================="

for route in "${USER_ROUTES[@]}"; do
  test_route "GET" "$route" "$USER_TOKEN" "VALID USER TOKEN" "200 or valid handled response"
done

echo ""
echo "=================================================="
echo " Test D — Normal user must not access admin routes"
echo "=================================================="

for route in "${ADMIN_ROUTES[@]}"; do
  test_route "GET" "$route" "$USER_TOKEN" "NORMAL USER ADMIN ACCESS" "403"
done

echo ""
echo "=================================================="
echo " Test E — Admin token on admin routes"
echo "=================================================="

if [ -n "$ADMIN_TOKEN" ]; then
  for route in "${ADMIN_ROUTES[@]}"; do
    test_route "GET" "$route" "$ADMIN_TOKEN" "ADMIN TOKEN" "200 or valid handled response"
  done
else
  echo "Skipped admin success tests because admin token is empty."
fi

echo ""
echo "=================================================="
echo " Test F — Logout blocks protected route"
echo "=================================================="

LOGOUT_STATUS=$(curl -s -o /tmp/step74_logout.json -w "%{http_code}" -X POST "$BASE_URL/auth/logout" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN")

echo "Logout status: $LOGOUT_STATUS"

AFTER_LOGOUT_STATUS=$(curl -s -o /tmp/step74_after_logout.json -w "%{http_code}" "$BASE_URL/auth/me" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN")

echo "After logout /auth/me => HTTP $AFTER_LOGOUT_STATUS | Expected: 401"

echo ""
echo "=================================================="
echo " STEP 74 CURL Regression Completed"
echo "=================================================="

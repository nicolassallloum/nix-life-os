#!/usr/bin/env bash
set -euo pipefail

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"
USER_EMAIL="${USER_EMAIL:-test@nixlifeos.com}"
USER_PASSWORD="${USER_PASSWORD:-password}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@nixlifeos.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Password@123}"

TMP_RESPONSE="/tmp/step75_response.json"

pass() { echo "PASS: $*"; }
warn() { echo "WARN: $*"; }
fail() { echo "FAIL: $*"; }

request_status() {
  local method="$1" route="$2" token="${3:-}"
  if [ -n "$token" ]; then
    curl -s -o "$TMP_RESPONSE" -w "%{http_code}" -X "$method" "$API_BASE$route" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $token"
  else
    curl -s -o "$TMP_RESPONSE" -w "%{http_code}" -X "$method" "$API_BASE$route" \
      -H "Accept: application/json"
  fi
}

echo "=================================================="
echo " STEP 75 — API Authorization Regression Testing V2"
echo " API_BASE: $API_BASE"
echo "=================================================="

USER_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASSWORD\"}" | jq -r '.data.token // empty')

if [ -z "$USER_TOKEN" ]; then
  fail "Could not login as normal user: $USER_EMAIL"
  exit 1
fi
pass "Normal user token acquired."

ADMIN_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | jq -r '.data.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
  warn "Could not login as admin user: $ADMIN_EMAIL"
else
  pass "Admin token acquired."
fi

PROTECTED_ROUTES=(
  "/auth/me"
  "/dashboard/summary"
  "/finance/accounts"
  "/finance/transactions"
  "/finance/budgets"
  "/health/dashboard"
  "/health/nutrition"
  "/health/hydration"
  "/health/weight"
  "/health/steps"
  "/projects"
  "/productivity/dashboard"
  "/productivity/tasks"
  "/productivity/habits"
  "/productivity/goals"
  "/productivity/calendar"
  "/ai/recommendations"
  "/notifications"
  "/automation"
  "/automation/logs"
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

echo ""
echo "1) Missing token tests"
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(request_status GET "$route")
  if [ "$STATUS" = "401" ]; then
    pass "401 missing token: $route"
  else
    fail "expected 401 got $STATUS: $route"
    cat "$TMP_RESPONSE"; echo ""
  fi
done

echo ""
echo "2) Invalid token tests"
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(request_status GET "$route" "invalid-token")
  if [ "$STATUS" = "401" ]; then
    pass "401 invalid token: $route"
  else
    fail "expected 401 got $STATUS: $route"
    cat "$TMP_RESPONSE"; echo ""
  fi
done

echo ""
echo "3) Valid user token tests"
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(request_status GET "$route" "$USER_TOKEN")
  if [[ "$STATUS" =~ ^(200|201|204|422)$ ]]; then
    pass "valid user token $STATUS: $route"
  else
    warn "unexpected status $STATUS for valid user token: $route"
    cat "$TMP_RESPONSE"; echo ""
  fi
done

echo ""
echo "4) Non-admin blocked from admin/security routes"
for route in "${ADMIN_ROUTES[@]}"; do
  STATUS=$(request_status GET "$route" "$USER_TOKEN")
  if [[ "$STATUS" =~ ^(403|404)$ ]]; then
    pass "user blocked $STATUS: $route"
  else
    fail "non-admin not blocked. Status $STATUS: $route"
    cat "$TMP_RESPONSE"; echo ""
  fi
done

if [ -n "$ADMIN_TOKEN" ]; then
  echo ""
  echo "5) Admin access tests"
  for route in "${ADMIN_ROUTES[@]}"; do
    STATUS=$(request_status GET "$route" "$ADMIN_TOKEN")
    if [[ "$STATUS" =~ ^(200|201|204|422)$ ]]; then
      pass "admin route status $STATUS: $route"
    else
      fail "admin unexpected status $STATUS: $route"
      cat "$TMP_RESPONSE"; echo ""
    fi
  done
fi

echo ""
echo "6) Invalid task ID safety test"
STATUS=$(request_status GET "/productivity/tasks/invalid-id" "$USER_TOKEN")
if [ "$STATUS" = "404" ]; then
  pass "invalid productivity task ID returns 404"
else
  fail "invalid productivity task ID expected 404 got $STATUS"
  cat "$TMP_RESPONSE"; echo ""
fi

echo ""
echo "7) Stack trace leak test"
STACK_CHECK=$(curl -s "$API_BASE/productivity/tasks/invalid-id" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  | grep -Ei "APP_KEY|SQLSTATE|Stack trace|Illuminate|PDOException|QueryException|vendor/laravel" || true)

if [ -z "$STACK_CHECK" ]; then
  pass "No stack trace leaked."
else
  fail "Possible stack trace leaked:"
  echo "$STACK_CHECK"
fi

echo "=================================================="
echo " STEP 75 V2 TESTING COMPLETE"
echo "=================================================="

#!/usr/bin/env bash

set -e

API_BASE="${API_BASE:-http://127.0.0.1:8000/api/v1}"

USER_EMAIL="${USER_EMAIL:-test@nixlifeos.com}"
USER_PASSWORD="${USER_PASSWORD:-password}"

ADMIN_EMAIL="${ADMIN_EMAIL:-admin@nixlifeos.com}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-password}"

echo "=================================================="
echo " STEP 75 — API Authorization Regression Testing"
echo " API_BASE: $API_BASE"
echo "=================================================="

echo ""
echo "1) Login as normal user..."
USER_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$USER_EMAIL\",
    \"password\": \"$USER_PASSWORD\"
  }" | jq -r '.data.token // empty')

if [ -z "$USER_TOKEN" ]; then
  echo "FAIL: Could not login as normal user."
  exit 1
fi

echo "PASS: Normal user token acquired."

echo ""
echo "2) Login as admin user..."
ADMIN_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }" | jq -r '.data.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
  echo "WARN: Could not login as admin user. Admin route tests may fail or be skipped."
else
  echo "PASS: Admin token acquired."
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
  "/automation/rules"
)

ADMIN_ROUTES=(
  "/admin/users"
  "/admin/roles"
  "/admin/permissions"
  "/security/users"
  "/security/roles"
  "/security/permissions"
  "/security/audit-logs"
)

echo ""
echo "3) Missing token tests..."
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(curl -s -o /tmp/step75_response.json -w "%{http_code}" "$API_BASE$route" \
    -H "Accept: application/json")

  if [ "$STATUS" = "401" ]; then
    echo "PASS 401 missing token: $route"
  else
    echo "FAIL expected 401 got $STATUS: $route"
    cat /tmp/step75_response.json
    echo ""
  fi
done

echo ""
echo "4) Invalid token tests..."
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(curl -s -o /tmp/step75_response.json -w "%{http_code}" "$API_BASE$route" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer invalid-token")

  if [ "$STATUS" = "401" ]; then
    echo "PASS 401 invalid token: $route"
  else
    echo "FAIL expected 401 got $STATUS: $route"
    cat /tmp/step75_response.json
    echo ""
  fi
done

echo ""
echo "5) Valid user token tests..."
for route in "${PROTECTED_ROUTES[@]}"; do
  STATUS=$(curl -s -o /tmp/step75_response.json -w "%{http_code}" "$API_BASE$route" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $USER_TOKEN")

  if [[ "$STATUS" =~ ^(200|201|204|422)$ ]]; then
    echo "PASS valid user token $STATUS: $route"
  else
    echo "WARN unexpected status $STATUS for valid user token: $route"
    cat /tmp/step75_response.json
    echo ""
  fi
done

echo ""
echo "6) Non-admin blocked from admin/security routes..."
for route in "${ADMIN_ROUTES[@]}"; do
  STATUS=$(curl -s -o /tmp/step75_response.json -w "%{http_code}" "$API_BASE$route" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $USER_TOKEN")

  if [[ "$STATUS" =~ ^(403|404)$ ]]; then
    echo "PASS user blocked $STATUS: $route"
  elif [ "$STATUS" = "401" ]; then
    echo "WARN route requires auth but user token rejected 401: $route"
  elif [ "$STATUS" = "405" ]; then
    echo "WARN method not allowed, verify route method: $route"
  else
    echo "FAIL non-admin not blocked. Status $STATUS: $route"
    cat /tmp/step75_response.json
    echo ""
  fi
done

if [ -n "$ADMIN_TOKEN" ]; then
  echo ""
  echo "7) Admin access tests..."
  for route in "${ADMIN_ROUTES[@]}"; do
    STATUS=$(curl -s -o /tmp/step75_response.json -w "%{http_code}" "$API_BASE$route" \
      -H "Accept: application/json" \
      -H "Authorization: Bearer $ADMIN_TOKEN")

    if [[ "$STATUS" =~ ^(200|201|204|422|405)$ ]]; then
      echo "PASS/WARN admin route status $STATUS: $route"
    else
      echo "FAIL admin unexpected status $STATUS: $route"
      cat /tmp/step75_response.json
      echo ""
    fi
  done
fi

echo ""
echo "8) Logout token revocation test..."
TEMP_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$USER_EMAIL\",
    \"password\": \"$USER_PASSWORD\"
  }" | jq -r '.data.token // empty')

if [ -z "$TEMP_TOKEN" ]; then
  echo "FAIL: Could not create temp token."
else
  LOGOUT_STATUS=$(curl -s -o /tmp/step75_logout.json -w "%{http_code}" -X POST "$API_BASE/auth/logout" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TEMP_TOKEN")

  REUSE_STATUS=$(curl -s -o /tmp/step75_reuse.json -w "%{http_code}" "$API_BASE/auth/me" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TEMP_TOKEN")

  if [ "$REUSE_STATUS" = "401" ]; then
    echo "PASS: Logged-out token rejected."
  else
    echo "FAIL: Logged-out token still works. Status: $REUSE_STATUS"
    cat /tmp/step75_reuse.json
    echo ""
  fi
fi

echo ""
echo "9) Stack trace leak test..."
STACK_CHECK=$(curl -s "$API_BASE/dashboard/summary" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer invalid-token" \
  | grep -Ei "APP_KEY|SQLSTATE|Stack trace|Illuminate|PDOException|QueryException|vendor/laravel" || true)

if [ -z "$STACK_CHECK" ]; then
  echo "PASS: No stack trace leaked."
else
  echo "FAIL: Possible stack trace leaked:"
  echo "$STACK_CHECK"
fi

echo ""
echo "=================================================="
echo " STEP 75 TESTING COMPLETE"
echo "=================================================="

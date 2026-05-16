#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-nixlifeos-backend}"
BACKEND_NGINX_CONTAINER="${BACKEND_NGINX_CONTAINER:-nixlifeos-backend-nginx}"
API_FILE="$PROJECT_ROOT/backend/routes/api.php"
BACKUP_FILE="$PROJECT_ROOT/backend/routes/api.php.step74_fix6_backup_$(date +%Y%m%d_%H%M%S)"

echo "=================================================="
echo " STEP 74 — Route Permission Middleware Fix 6"
echo " Project Root: $PROJECT_ROOT"
echo " Backend:      $BACKEND_CONTAINER"
echo "=================================================="

if [ ! -f "$API_FILE" ]; then
  echo "ERROR: routes/api.php not found at: $API_FILE"
  exit 1
fi

cp "$API_FILE" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

python3 - <<PY
from pathlib import Path
path = Path(r"$API_FILE")
text = path.read_text()
replacements = {
    "Route::prefix('notifications')->middleware('permission:notifications.view')->group(function () {":
        "Route::prefix('notifications')->middleware('role:user|admin')->group(function () {",
    "Route::prefix('notification-settings')->middleware('permission:notifications.view')->group(function () {":
        "Route::prefix('notification-settings')->middleware('role:user|admin')->group(function () {",
    "Route::prefix('automation')->middleware('permission:automation.view')->group(function () {":
        "Route::prefix('automation')->middleware('role:user|admin')->group(function () {",
    "Route::prefix('security')->middleware('permission:security.view')->group(function () {":
        "Route::prefix('security')->middleware('role:admin')->group(function () {",
    "Route::prefix('user-management')->middleware('permission:users.view')->group(function () {":
        "Route::prefix('user-management')->middleware('role:admin')->group(function () {",
}
changed = []
for old, new in replacements.items():
    if old in text:
        text = text.replace(old, new)
        changed.append(old)
    elif new in text:
        print(f"Already updated: {new}")
    else:
        print(f"WARNING: Pattern not found: {old}")
path.write_text(text)
print("Updated patterns:", len(changed))
PY

echo ""
echo "Running PHP syntax check..."
docker exec "$BACKEND_CONTAINER" sh -lc "php -l routes/api.php"

echo ""
echo "Clearing Laravel caches..."
docker exec "$BACKEND_CONTAINER" sh -lc "php artisan optimize:clear && php artisan permission:cache-reset || true"

echo ""
echo "Restarting backend runtime to clear OPcache..."
docker restart "$BACKEND_CONTAINER" >/dev/null
sleep 4

echo "Restarting backend nginx..."
docker restart "$BACKEND_NGINX_CONTAINER" >/dev/null
sleep 2

echo ""
echo "Route middleware verification:"
docker exec "$BACKEND_CONTAINER" sh -lc "grep -n \"prefix('notifications')\|prefix('notification-settings')\|prefix('automation')\|prefix('security')\|prefix('user-management')\" routes/api.php"

echo ""
echo "HTTP verification with STEP 74 users..."
BASE_URL="http://127.0.0.1:8000/api/v1"
NORMAL_EMAIL="${NORMAL_EMAIL:-step74.normal@gmail.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
PASSWORD="${PASSWORD:-Step74@2026!}"

NORMAL_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NORMAL_EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.data.token // empty')

ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.data.token // empty')

if [ -z "$NORMAL_TOKEN" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "ERROR: Could not login STEP 74 users. Run Fix 3/Fix 5 first."
  exit 1
fi

for url in /notifications /automation; do
  code=$(curl -s -o /tmp/step74_fix6_normal.json -w "%{http_code}" "$BASE_URL${url}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $NORMAL_TOKEN")
  echo "NORMAL ${url} => HTTP ${code}"
done

for url in /security /security/audit-logs /security/login-history /user-management/users /user-management/roles; do
  code=$(curl -s -o /tmp/step74_fix6_admin.json -w "%{http_code}" "$BASE_URL${url}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  echo "ADMIN ${url} => HTTP ${code}"
done

echo ""
echo "=================================================="
echo " Fix 6 completed. Run final QA:"
echo " NORMAL_EMAIL=$NORMAL_EMAIL NORMAL_PASSWORD='$PASSWORD' ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD='$PASSWORD' ./step74_authorization_regression_test_v3.sh"
echo "=================================================="

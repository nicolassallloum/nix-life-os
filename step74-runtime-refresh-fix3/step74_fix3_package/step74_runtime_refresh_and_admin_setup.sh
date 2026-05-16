#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-nixlifeos-backend}"
BACKEND_NGINX_CONTAINER="${BACKEND_NGINX_CONTAINER:-nixlifeos-backend-nginx}"
NORMAL_EMAIL="${NORMAL_EMAIL:-step74.normal@gmail.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
TEST_PASSWORD="${TEST_PASSWORD:-Step74@2026!}"

cd "$PROJECT_ROOT"

echo "=================================================="
echo " STEP 74 — Runtime Refresh + Test User Setup"
echo " Project Root: $PROJECT_ROOT"
echo " Backend:      $BACKEND_CONTAINER"
echo " Backend Nginx:$BACKEND_NGINX_CONTAINER"
echo "=================================================="

echo ""
echo "Clearing Laravel caches and rate limiter cache..."
docker exec "$BACKEND_CONTAINER" sh -lc "php artisan optimize:clear && php artisan route:clear && php artisan config:clear && php artisan cache:clear"

echo ""
echo "Restarting PHP-FPM backend runtime to clear OPcache..."
docker restart "$BACKEND_CONTAINER" >/dev/null
sleep 4

echo ""
echo "Restarting backend nginx..."
docker restart "$BACKEND_NGINX_CONTAINER" >/dev/null
sleep 2

echo ""
echo "Creating/updating STEP 74 normal and admin users directly through Laravel..."
docker exec "$BACKEND_CONTAINER" sh -lc "php artisan tinker --execute='
use App\\Models\\User;
use Illuminate\\Support\\Facades\\Hash;
use Spatie\\Permission\\Models\\Role;
use Spatie\\Permission\\PermissionRegistrar;

app(PermissionRegistrar::class)->forgetCachedPermissions();
\$guard = config(\"auth.defaults.guard\", \"web\");
\$normalRole = Role::firstOrCreate([\"name\" => \"user\", \"guard_name\" => \$guard]);
\$adminRole = Role::firstOrCreate([\"name\" => \"admin\", \"guard_name\" => \$guard]);

\$normal = User::updateOrCreate(
    [\"email\" => \"'"$NORMAL_EMAIL"'\"],
    [\"name\" => \"Step74 Normal User\", \"password\" => Hash::make(\"'"$TEST_PASSWORD"'\")]
);
\$normal->syncRoles([\"user\"]);

\$admin = User::updateOrCreate(
    [\"email\" => \"'"$ADMIN_EMAIL"'\"],
    [\"name\" => \"Step74 Admin User\", \"password\" => Hash::make(\"'"$TEST_PASSWORD"'\")]
);
\$admin->syncRoles([\"admin\"]);

app(PermissionRegistrar::class)->forgetCachedPermissions();
echo \"NORMAL_EMAIL='"$NORMAL_EMAIL"'\\nADMIN_EMAIL='"$ADMIN_EMAIL"'\\nPASSWORD='"$TEST_PASSWORD"'\\n\";
'"

echo ""
echo "Verifying HTTP route availability after restart..."
for route in \
  /api/v1/productivity/tasks \
  /api/v1/productivity/calendar \
  /api/v1/notifications \
  /api/v1/automation \
  /api/v1/admin \
  /api/v1/security \
  /api/v1/user-management/users
  do
    status=$(curl -s -o /tmp/step74_probe.json -w "%{http_code}" "http://127.0.0.1:8000${route}" -H "Accept: application/json" || true)
    echo "$route => HTTP $status"
  done

echo ""
echo "Run final QA with:"
echo "NORMAL_EMAIL=$NORMAL_EMAIL NORMAL_PASSWORD='$TEST_PASSWORD' ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD='$TEST_PASSWORD' ./step74_authorization_regression_test_v3.sh"

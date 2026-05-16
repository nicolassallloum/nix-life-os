#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-nixlifeos-backend}"
NORMAL_EMAIL="${NORMAL_EMAIL:-step74.normal@gmail.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
TEST_PASSWORD="${TEST_PASSWORD:-Step74@2026!}"

cd "$PROJECT_ROOT"

echo "=================================================="
echo " STEP 74 — Permission Alignment Fix 4"
echo " Project Root: $PROJECT_ROOT"
echo " Backend:      $BACKEND_CONTAINER"
echo "=================================================="

echo ""
echo "Aligning Spatie role permissions used by STEP 74 routes..."

docker exec "$BACKEND_CONTAINER" sh -lc "php artisan tinker --execute='
use App\\Models\\User;
use Illuminate\\Support\\Facades\\Hash;
use Spatie\\Permission\\Models\\Role;
use Spatie\\Permission\\Models\\Permission;
use Spatie\\Permission\\PermissionRegistrar;

app(PermissionRegistrar::class)->forgetCachedPermissions();

\$guards = array_values(array_unique(array_filter([
    config("auth.defaults.guard", "web"),
    "web",
    "api",
])));

\$userPermissions = [
    "dashboard.view",
    "finance.view",
    "finance.create",
    "finance.update",
    "health.view",
    "health.create",
    "health.update",
    "projects.view",
    "projects.create",
    "projects.update",
    "productivity.view",
    "productivity.create",
    "productivity.update",
    "ai.view",
    "ai.generate",
    "notifications.view",
    "automation.view",
    "automation.create",
    "automation.update",
];

\$adminOnlyPermissions = [
    "security.view",
    "security.create",
    "security.update",
    "users.view",
    "users.create",
    "users.update",
    "users.delete",
    "roles.view",
    "roles.create",
    "roles.update",
    "roles.delete",
    "permissions.view",
    "permissions.create",
    "permissions.update",
    "permissions.delete",
    "admin.view",
];

foreach (\$guards as \$guard) {
    \$userRole = Role::firstOrCreate(["name" => "user", "guard_name" => \$guard]);
    \$adminRole = Role::firstOrCreate(["name" => "admin", "guard_name" => \$guard]);

    foreach (array_merge(\$userPermissions, \$adminOnlyPermissions) as \$permissionName) {
        Permission::firstOrCreate(["name" => \$permissionName, "guard_name" => \$guard]);
    }

    \$userRole->syncPermissions(\$userPermissions);
    \$adminRole->syncPermissions(array_merge(\$userPermissions, \$adminOnlyPermissions));
}

\$normal = User::updateOrCreate(
    ["email" => "'"$NORMAL_EMAIL"'"],
    ["name" => "Step74 Normal User", "password" => Hash::make("'"$TEST_PASSWORD"'")]
);
\$normal->syncRoles(["user"]);

\$admin = User::updateOrCreate(
    ["email" => "'"$ADMIN_EMAIL"'"],
    ["name" => "Step74 Admin User", "password" => Hash::make("'"$TEST_PASSWORD"'")]
);
\$admin->syncRoles(["admin"]);

app(PermissionRegistrar::class)->forgetCachedPermissions();

\$normal->refresh();
\$admin->refresh();

echo "Normal user permissions: ".implode(", ", \$normal->getAllPermissions()->pluck("name")->sort()->values()->all())."\\n";
echo "Admin user permissions: ".implode(", ", \$admin->getAllPermissions()->pluck("name")->sort()->values()->all())."\\n";
'"

echo ""
echo "Clearing Laravel caches after permission update..."
docker exec "$BACKEND_CONTAINER" sh -lc "php artisan optimize:clear && php artisan permission:cache-reset || true"

echo ""
echo "Testing the previously failing authorization probes..."
USER_TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NORMAL_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r '.data.token // empty')

ADMIN_TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" | jq -r '.data.token // empty')

for route in /notifications /automation; do
  status=$(curl -s -o /tmp/step74_fix4_user.json -w "%{http_code}" "http://127.0.0.1:8000/api/v1${route}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $USER_TOKEN" || true)
  echo "USER $route => HTTP $status"
done

for route in /security /security/audit-logs /security/login-history /user-management/users /user-management/roles; do
  status=$(curl -s -o /tmp/step74_fix4_admin.json -w "%{http_code}" "http://127.0.0.1:8000/api/v1${route}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" || true)
  echo "ADMIN $route => HTTP $status"
done

echo ""
echo "Run final QA:"
echo "NORMAL_EMAIL=$NORMAL_EMAIL NORMAL_PASSWORD='$TEST_PASSWORD' ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD='$TEST_PASSWORD' ./step74_authorization_regression_test_v3.sh"

#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${1:-/u01/nix-life-os}"
BACKEND_CONTAINER="${BACKEND_CONTAINER:-nixlifeos-backend}"
NORMAL_EMAIL="${NORMAL_EMAIL:-step74.normal@gmail.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-step74.admin@gmail.com}"
PASSWORD="${PASSWORD:-Step74@2026!}"

echo "=================================================="
echo " STEP 74 — Permission Alignment Fix 5"
echo " Project Root: $PROJECT_ROOT"
echo " Backend:      $BACKEND_CONTAINER"
echo " Normal User:  $NORMAL_EMAIL"
echo " Admin User:   $ADMIN_EMAIL"
echo "=================================================="

cd "$PROJECT_ROOT"

cat > /tmp/step74_align_permissions.php <<'PHP'
<?php

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

$normalEmail = getenv('STEP74_NORMAL_EMAIL') ?: 'step74.normal@gmail.com';
$adminEmail = getenv('STEP74_ADMIN_EMAIL') ?: 'step74.admin@gmail.com';
$password = getenv('STEP74_PASSWORD') ?: 'Step74@2026!';
$guard = 'web';

app(PermissionRegistrar::class)->forgetCachedPermissions();

$userPermissions = [
    'dashboard.view',
    'finance.view',
    'finance.create',
    'finance.update',
    'health.view',
    'health.create',
    'health.update',
    'projects.view',
    'projects.create',
    'projects.update',
    'productivity.view',
    'productivity.create',
    'productivity.update',
    'ai.view',
    'ai.generate',
    'notifications.view',
    'automation.view',
    'automation.create',
    'automation.update',
];

$adminExtraPermissions = [
    'admin.view',
    'roles.view',
    'permissions.view',
    'security.view',
    'audit-logs.view',
    'login-history.view',
    'users.view',
    'users.create',
    'users.update',
    'users.delete',
    'user-management.view',
];

foreach (array_unique(array_merge($userPermissions, $adminExtraPermissions)) as $permissionName) {
    Permission::firstOrCreate([
        'name' => $permissionName,
        'guard_name' => $guard,
    ]);
}

$userRole = Role::firstOrCreate([
    'name' => 'user',
    'guard_name' => $guard,
]);

$adminRole = Role::firstOrCreate([
    'name' => 'admin',
    'guard_name' => $guard,
]);

$userRole->syncPermissions($userPermissions);
$adminRole->syncPermissions(array_unique(array_merge($userPermissions, $adminExtraPermissions)));

$normalUser = User::firstOrCreate(
    ['email' => $normalEmail],
    [
        'name' => 'Step74 Normal User',
        'password' => Hash::make($password),
    ]
);

$normalUser->forceFill([
    'name' => $normalUser->name ?: 'Step74 Normal User',
    'password' => Hash::make($password),
])->save();
$normalUser->syncRoles(['user']);

$adminUser = User::firstOrCreate(
    ['email' => $adminEmail],
    [
        'name' => 'Step74 Admin User',
        'password' => Hash::make($password),
    ]
);

$adminUser->forceFill([
    'name' => $adminUser->name ?: 'Step74 Admin User',
    'password' => Hash::make($password),
])->save();
$adminUser->syncRoles(['admin']);

app(PermissionRegistrar::class)->forgetCachedPermissions();

$output = [
    'status' => 'ok',
    'normal_user' => [
        'email' => $normalUser->email,
        'roles' => $normalUser->getRoleNames()->values(),
        'permissions' => $normalUser->getAllPermissions()->pluck('name')->sort()->values(),
    ],
    'admin_user' => [
        'email' => $adminUser->email,
        'roles' => $adminUser->getRoleNames()->values(),
        'permissions' => $adminUser->getAllPermissions()->pluck('name')->sort()->values(),
    ],
];

echo json_encode($output, JSON_PRETTY_PRINT) . PHP_EOL;
PHP

# Copy script into backend container and execute it through artisan tinker using require.
docker cp /tmp/step74_align_permissions.php "$BACKEND_CONTAINER:/tmp/step74_align_permissions.php"

docker exec \
  -e STEP74_NORMAL_EMAIL="$NORMAL_EMAIL" \
  -e STEP74_ADMIN_EMAIL="$ADMIN_EMAIL" \
  -e STEP74_PASSWORD="$PASSWORD" \
  "$BACKEND_CONTAINER" \
  sh -lc "php artisan tinker --execute='require \"/tmp/step74_align_permissions.php\";'"

echo ""
echo "Clearing Laravel caches after permission sync..."
docker exec "$BACKEND_CONTAINER" sh -lc "php artisan optimize:clear && php artisan permission:cache-reset || true"

echo ""
echo "Verifying user permissions from HTTP..."
NORMAL_TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$NORMAL_EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.data.token // empty')

ADMIN_TOKEN=$(curl -s -X POST "http://127.0.0.1:8000/api/v1/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$PASSWORD\"}" | jq -r '.data.token // empty')

if [ -z "$NORMAL_TOKEN" ]; then
  echo "ERROR: normal user login failed after permission sync."
  exit 1
fi

if [ -z "$ADMIN_TOKEN" ]; then
  echo "ERROR: admin user login failed after permission sync."
  exit 1
fi

for url in /notifications /automation; do
  code=$(curl -s -o /tmp/step74_normal_check.json -w "%{http_code}" "http://127.0.0.1:8000/api/v1${url}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $NORMAL_TOKEN")
  echo "NORMAL ${url} => HTTP ${code}"
done

for url in /security /security/audit-logs /security/login-history /user-management/users /user-management/roles; do
  code=$(curl -s -o /tmp/step74_admin_check.json -w "%{http_code}" "http://127.0.0.1:8000/api/v1${url}" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  echo "ADMIN ${url} => HTTP ${code}"
done

echo ""
echo "=================================================="
echo " Fix 5 completed. Run final QA:"
echo " NORMAL_EMAIL=$NORMAL_EMAIL NORMAL_PASSWORD='$PASSWORD' ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD='$PASSWORD' ./step74_authorization_regression_test_v3.sh"
echo "=================================================="

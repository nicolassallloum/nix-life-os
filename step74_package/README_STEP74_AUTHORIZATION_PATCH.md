# STEP 74 — Global Protected Routes & Authorization Patch

This patch stabilizes protected routes and authorization regression testing for Nix Life OS.

## What was fixed

- Added Laravel middleware aliases for `role`, `permission`, and `role_or_permission` in `backend/bootstrap/app.php`.
- Hardened custom role and permission middleware to return clean 401/403 JSON responses.
- Added protected API aliases used by QA and frontend:
  - `GET /api/v1/productivity/tasks`
  - `GET /api/v1/productivity/calendar`
  - `GET /api/v1/notifications`
  - `GET /api/v1/automation`
- Added protected admin/security/user-management API routes:
  - `/api/v1/admin/*`
  - `/api/v1/security/*`
  - `/api/v1/user-management/*`
- Added frontend auth utility helpers.
- Upgraded Vue route guards to check token, roles, and permissions.
- Added `/unauthorized` frontend page.
- Added admin/security placeholder pages.
- Updated sidebar so admin/security links only appear for authorized users.
- Added a new strong-password compatible regression test script.

## Install

From the extracted patch folder:

```bash
chmod +x install_step74_authorization_patch.sh
./install_step74_authorization_patch.sh /u01/nix-life-os
```

## Run backend/frontend checks

```bash
cd /u01/nix-life-os

docker exec nixlifeos-backend sh -lc "php artisan optimize:clear && php artisan route:list --path=api/v1"

cd frontend
npm run build
```

## Run STEP 74 regression test

```bash
cd /u01/nix-life-os
cp /path/to/patch/step74_authorization_regression_test_v2.sh .
chmod +x step74_authorization_regression_test_v2.sh
./step74_authorization_regression_test_v2.sh
```

## Optional admin user setup

If you do not already have an admin user, assign one in Tinker:

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan tinker"
```

Then:

```php
$user = App\Models\User::where('email', 'step74.user@nixlifeos.com')->first();
$user->assignRole('admin');
```

Then run the test with that account as admin:

```bash
ADMIN_EMAIL=step74.user@nixlifeos.com ADMIN_PASSWORD='Step74@2026!' ./step74_authorization_regression_test_v2.sh
```

For a true negative/positive test, use one normal user and one separate admin user.

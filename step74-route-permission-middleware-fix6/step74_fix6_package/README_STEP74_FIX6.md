# STEP 74 — Route Permission Middleware Fix 6

This fix resolves the remaining STEP 74 authorization failures where the database permissions exist, but the HTTP route-level `permission:*` middleware still returns Spatie permission-denied responses.

## Why this fix is needed

The STEP 74 QA shows role middleware is working correctly (`role:admin` passes for `/admin/*`), but permission middleware still denies:

- `/notifications`
- `/automation`
- `/security/*`
- `/user-management/*`

Fix 6 aligns these QA routes with role-based authorization:

- Notifications and automation: `role:user|admin`
- Security and user-management: `role:admin`

## Install

```bash
cd /u01/nix-life-os

tar -xzf step74-route-permission-middleware-fix6.tar.gz

cd step74_fix6_package

chmod +x step74_route_permission_middleware_fix6.sh

./step74_route_permission_middleware_fix6.sh /u01/nix-life-os
```

## Final QA

```bash
cd /u01/nix-life-os

NORMAL_EMAIL=step74.normal@gmail.com \
NORMAL_PASSWORD='Step74@2026!' \
ADMIN_EMAIL=step74.admin@gmail.com \
ADMIN_PASSWORD='Step74@2026!' \
./step74_authorization_regression_test_v3.sh
```

Expected:

```text
STEP 74 RESULT: PASS
```

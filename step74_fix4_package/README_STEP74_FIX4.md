# STEP 74 — Permission Alignment Fix 4

This fix resolves the remaining STEP 74 authorization failures where:

- Normal user received 403 on `/api/v1/notifications` and `/api/v1/automation`.
- Admin user received 403 on `/api/v1/security/*` and `/api/v1/user-management/*`.

It creates/synchronizes the exact permission names used by the patched routes:

- `notifications.view`
- `automation.view`
- `security.view`
- `users.view`

It also refreshes the Spatie permission cache and recreates the STEP 74 normal/admin test users.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step74-permission-alignment-fix4.tar.gz

cd step74_fix4_package

chmod +x step74_permission_alignment_fix.sh

./step74_permission_alignment_fix.sh /u01/nix-life-os
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

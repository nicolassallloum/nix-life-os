# STEP 74 — Permission Alignment Fix 5

This fix replaces the broken Fix 4 permission script. It avoids nested shell quote errors by writing a PHP permission alignment script and executing it inside the backend container.

## What it does

- Creates/updates Spatie permissions required by STEP 74 routes.
- Syncs the `user` role with normal module permissions.
- Syncs the `admin` role with user permissions plus admin/security/user-management permissions.
- Creates/updates test users:
  - `step74.normal@gmail.com`
  - `step74.admin@gmail.com`
- Clears Laravel and Spatie permission caches.
- Performs quick HTTP checks for the previously failing routes.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step74-permission-alignment-fix5.tar.gz

cd step74_fix5_package

chmod +x step74_permission_alignment_fix5.sh

./step74_permission_alignment_fix5.sh /u01/nix-life-os
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

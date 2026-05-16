# STEP 75 Backend Authorization Patch V2

This patch fixes the previous installer issue where files were copied onto themselves on the host and not applied inside the running backend container.

## Fixes
- Applies patched backend files to both host and `nixlifeos-backend` container.
- Fixes registration email validation by using `email:rfc` instead of DNS validation.
- Raises QA auth throttles in `routes/api.php`.
- Adds numeric route constraints for task IDs.
- Adds safe `Task::resolveRouteBinding()` to prevent PostgreSQL bigint cast 500 errors.
- Includes corrected Step 75 regression script with real automation/admin/security routes.

## Install

```bash
cd /u01/nix-life-os
tar -xzf step75-backend-authorization-patch-v2.tar.gz
chmod +x install_step75_backend_authorization_patch_v2.sh
./install_step75_backend_authorization_patch_v2.sh
```

## Retest

```bash
chmod +x step75_api_authorization_regression_v2.sh
./step75_api_authorization_regression_v2.sh
```

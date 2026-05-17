# STEP 77 — Error State Regression Patch

## Updated files

- `backend/bootstrap/app.php`
- `backend/routes/api.php`
- `frontend/src/main.js`
- `frontend/src/main.ts`
- `frontend/src/router/index.js`
- `frontend/src/router/index.ts`
- `frontend/src/services/api.js`
- `frontend/src/services/apiFetch.js`
- `frontend/src/services/financeService.ts`
- `frontend/src/views/SecurityRolesView.vue`
- `frontend/src/views/NotFoundView.vue`
- `frontend/src/views/auth/UnauthorizedView.vue`

## Main improvements

- Standardized JSON API responses for 401, 403, 404, 405, 422, 429, 500, and database service failures.
- Wrapped database-backed exception logging so logging failures no longer cascade into another exception.
- Sanitized API responses so SQL, file paths, stack traces, and database host details are not returned to the frontend.
- Added frontend Axios timeout and normalized API errors.
- Added a `apiFetch()` wrapper for fetch-based screens with timeout, auth header, 401 redirect, 403 redirect, and normalized errors.
- Fixed Security Roles frontend API URLs to use `/api/v1/security/roles` and `/api/v1/security/permissions` through the shared API wrapper.
- Added API routes for `/api/v1/security/roles` and `/api/v1/security/permissions` under admin role protection.
- Improved frontend 403 and 404 pages.
- Added Vue global error and unhandled promise rejection logging.
- Added router chunk-load error handling.

## Install

```bash
cd /u01/nix-life-os
mkdir -p /tmp/step77-error-state-patch
tar -xzf step77-error-state-patch.tar.gz -C /tmp/step77-error-state-patch
chmod +x /tmp/step77-error-state-patch/install_step77_error_state_patch.sh
/tmp/step77-error-state-patch/install_step77_error_state_patch.sh /u01/nix-life-os
```

## After install

```bash
docker compose restart backend backend-nginx frontend nginx
```

Then run the STEP 77 CURL checklist again.

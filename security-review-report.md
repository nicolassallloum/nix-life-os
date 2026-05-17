# STEP 86 — Nix Life OS Security Review Report

## Review Scope
Reviewed the uploaded Laravel backend, Vue frontend, Docker/Nginx deployment, environment templates, and Laravel logs from the STEP 86 archive.

## Executive Summary
Overall status: **CONDITIONAL PASS AFTER FIXES**.

Nix Life OS already has several good controls: protected API route groups, Sanctum bearer-token authentication, strong password rules, login throttling, safe JSON error rendering in Laravel 11 bootstrap, user-scoped queries in many finance/health/project controllers, and no detected `v-html` usage in the uploaded Vue source.

The main security risks are not basic authentication failure. The biggest risks are **sensitive logs**, **frontend authorization bug**, **localStorage bearer token exposure**, **over-exposed Docker ports**, **hardcoded/default database password in deployment config**, and **insufficient production security headers / CORS hardening**.

---

## Critical Findings

### C-01 — Sensitive Laravel logs expose stack traces, SQL, hostnames, paths, and health table names
**Evidence:** `backend/storage/logs/laravel.log` contains `production.ERROR` stack traces, SQL queries against `personal_access_tokens`, health tables, scheduler failures, hostnames, ports, filesystem paths, and request URLs.

**Risk:** High-impact information disclosure. In a health-focused app, logs can indirectly reveal sensitive data model structure, medical modules, user identifiers, tokens table details, database names, and infrastructure details.

**Fix:**
- Redact log context before writing.
- Do not log full request payloads, authorization headers, tokens, passwords, medical notes, or full SQL.
- Do not write DB-backed error logs when the DB is unavailable.
- Keep `LOG_LEVEL=warning` or higher in production.
- Add `SensitiveDataRedactor` and update API audit/performance logging.

Files provided in patch package:
- `backend/app/Support/SensitiveDataRedactor.php`
- `backend/app/Http/Middleware/ApiAuditLogger.php`
- `backend/app/Http/Middleware/ApiPerformanceLogger.php`
- `backend/bootstrap/app.php`

---

## High Findings

### H-01 — Vue route authorization has a logic bug
**Evidence:** `router/index.js` calls `canAccessRoute(to.meta, user)`, but `canAccessRoute()` reads `route?.meta || {}`. Passing `to.meta` causes the function to ignore `requiresAuth`, `permissions`, and `requiresRole` in several cases. Also, the utility checks `meta.roles`, but routes use `requiresRole`.

**Risk:** Frontend route guards and sidebar visibility can be bypassed client-side. Backend still protects admin/security routes, so this is not a complete authorization bypass, but it can expose UI screens and create confusing 403 behavior.

**Fix:**
- Update `canAccessRoute()` to accept either a route object or a meta object.
- Add support for `requiresRole` and `permission`.
- Pass the full route object from the router guard.
- Add `requiresRole: 'admin'` to security routes.

Files provided:
- `frontend/src/utils/auth.js`
- `frontend/src/router/index.js`

---

### H-02 — Bearer tokens are stored in `localStorage`
**Evidence:** `frontend/src/utils/auth.js` stores tokens under localStorage keys like `token`, `auth_token`, `access_token`, and `nixlifeos_token`.

**Risk:** Any future XSS bug can steal long-lived API tokens. This is especially sensitive because Nix Life OS contains health and finance data.

**Fix options:**
1. Best production option: use Sanctum first-party SPA cookies with `HttpOnly`, `Secure`, `SameSite=Lax/Strict`, CSRF cookie flow.
2. Acceptable short-term option: keep bearer token flow but enforce strict XSS prevention, no `v-html`, CSP, shorter token lifetime, logout token deletion, and log redaction.

Immediate hardening:
- Set `AUTH_TOKEN_EXPIRATION_MINUTES=120` or lower.
- Set `SANCTUM_TOKEN_PREFIX=nixlifeos_`.
- Avoid storing permissions as a trusted source; use server-side authorization as the source of truth.

---

### H-03 — Docker production config exposes internal services
**Evidence:** `docker-compose.prod.yml` exposes Postgres on `5445:5432`, backend-nginx on `8000:80`, and ai-engine on `5000:5000`.

**Risk:** Internal services become reachable from the host/network. Postgres and AI engine should not be public in production.

**Fix:**
- Only expose the edge Nginx service.
- Keep Postgres, backend-nginx, backend, frontend, and ai-engine internal on the Docker network.
- Use an override file for local development if direct ports are needed.

File provided:
- `docker-compose.security-override.yml`

---

### H-04 — Hardcoded/default database password in production compose and env example
**Evidence:** `docker-compose.prod.yml` has `POSTGRES_PASSWORD: postgres`, and `backend.env.example` also uses `DB_PASSWORD=postgres`.

**Risk:** Default credentials are commonly abused and can leak into deployed environments.

**Fix:**
- Use `${DB_PASSWORD:?DB_PASSWORD must be set}`.
- Rotate the database password.
- Never commit real `.env.docker`.

---

## Medium Findings

### M-01 — CORS should be environment-driven and stricter
**Evidence:** `config/cors.php` allows all methods and all headers. Origins are hardcoded to localhost and one LAN IP.

**Risk:** Not immediately exploitable with bearer auth and `supports_credentials=false`, but broad headers/methods increase attack surface and create unsafe defaults if credentials are enabled later.

**Fix:** Provided hardened `config/cors.php` using `CORS_ALLOWED_ORIGINS` and explicit methods/headers.

---

### M-02 — Sanctum expiration config is not centralized
**Evidence:** `AuthController` sets token `expires_at`, but `config/sanctum.php` has `'expiration' => null`.

**Risk:** Future tokens created elsewhere may not inherit the intended expiration behavior.

**Fix:** Provided hardened `config/sanctum.php` with `SANCTUM_EXPIRATION` and token prefix support.

---

### M-03 — Nginx security headers are incomplete
**Evidence:** Root and frontend Nginx configs lack several useful headers: `Referrer-Policy`, `Permissions-Policy`, and consistent `always` behavior.

**Risk:** Missing browser hardening.

**Fix:** Provided hardened root and backend Nginx configs.

---

### M-04 — API performance headers leak internals in production
**Evidence:** `ApiPerformanceLogger` sets `X-Nix-Response-Time-Ms` and `X-Nix-Query-Count` for responses.

**Risk:** Useful for testing, but in production they leak application internals and query behavior.

**Fix:** Patch only emits these headers outside production.

---

### M-05 — Audit logger stores raw query string values
**Evidence:** `ApiAuditLogger` logs `$request->query()` into audit metadata.

**Risk:** Search/filter values may include names, medical terms, notes, emails, or other sensitive personal data.

**Fix:** Patch redacts query metadata before writing.

---

### M-06 — Admin and security inline routes expose user emails and full roles/permissions
**Evidence:** `/admin/users`, `/user-management/users`, `/admin/roles`, `/security/roles`, and `/security/permissions` return identity and authorization data.

**Risk:** Fine for admin, but should have dedicated controllers, pagination, audit logging, and least-privilege permissions such as `users.view`, `roles.manage`, and `security.view` rather than only `role:admin`.

**Fix:** Keep role protection for now, but move these inline closures into controllers and add permission middleware in STEP 87.

---

## Low Findings

### L-01 — Public route loading test should not exist in production
`/api/v1/sleep-route-test` is useful during QA but should be disabled in production.

### L-02 — Root Dockerfile appears unrelated to Laravel/Vue stack
The root `Dockerfile` exposes port 3000 and runs Node. Confirm it is not used in production.

### L-03 — `client_max_body_size 50M` is high
For most JSON APIs, 20M or less is safer unless file uploads are required.

---

## Positive Findings

- Password policy uses Laravel `Password::min(8)->letters()->mixedCase()->numbers()->symbols()`.
- Login route has throttling and internal per-email/IP throttling.
- Register route normalizes/lowercases emails.
- Most finance and health data access is scoped by `user_id`.
- Admin/security routes are backend-protected with `role:admin`.
- Laravel 11 exception renderer returns JSON and hides stack traces from API responses.
- No uploaded Vue files contained `v-html`, `innerHTML`, or dangerous HTML rendering patterns.
- Dynamic imports and route-level lazy loading are already implemented in the router.

---

## Files That Need Changes

### Backend
- `backend/app/Http/Middleware/ApiAuditLogger.php`
- `backend/app/Http/Middleware/ApiPerformanceLogger.php`
- `backend/app/Http/Middleware/SecurityHeaders.php` new
- `backend/app/Support/SensitiveDataRedactor.php` new
- `backend/bootstrap/app.php`
- `backend/config/cors.php`
- `backend/config/sanctum.php`

### Frontend
- `frontend/src/utils/auth.js`
- `frontend/src/router/index.js`

### Deployment
- `docker/nginx/default.conf`
- `docker/backend-nginx/default.conf`
- `docker-compose.security-override.yml` new
- `.env.docker` values should be updated manually, not shared.

---

## Final Readiness

Current readiness: **NOT READY FOR PRODUCTION**.

Readiness after applying the included patches and passing tests: **READY FOR INTERNAL QA / PORTFOLIO DEMO**.

For public production use, complete STEP 87 hardening and add HTTPS, CSP, cookie-based Sanctum auth, proper secret management, database backups, and vulnerability scans.

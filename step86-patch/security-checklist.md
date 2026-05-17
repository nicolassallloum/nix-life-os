# STEP 86 — Final Security Checklist

## Authentication
- [ ] Login returns a short-lived Sanctum token.
- [ ] Invalid login returns 401 without revealing whether email exists.
- [ ] Login is throttled by route and by email/IP.
- [ ] Logout deletes the current access token.
- [ ] Token expiration is configured using `AUTH_TOKEN_EXPIRATION_MINUTES` and/or `SANCTUM_EXPIRATION`.
- [ ] Future production plan exists for HttpOnly Sanctum SPA cookies.

## Authorization
- [ ] All business APIs are under `auth:sanctum`.
- [ ] Admin routes use `role:admin` plus permission middleware where possible.
- [ ] Security routes require admin role and `security.view` permission.
- [ ] Frontend route guard checks `requiresRole`, `roles`, `permission`, and `permissions`.
- [ ] Sidebar visibility uses the same guard logic as router access.
- [ ] Backend remains the source of truth; frontend permissions are UI-only.

## API Security
- [ ] Missing token returns 401.
- [ ] Invalid token returns 401.
- [ ] Non-admin user receives 403 on admin/security routes.
- [ ] Validation errors return 422 without stack traces.
- [ ] 500 errors return generic messages.
- [ ] Rate limiting exists for auth and sensitive write endpoints.
- [ ] User input is validated with FormRequests or explicit validators.

## CORS / CSRF
- [ ] CORS origins are configured through `CORS_ALLOWED_ORIGINS`.
- [ ] CORS methods and headers are explicit.
- [ ] `supports_credentials=false` for bearer-token mode.
- [ ] If cookie auth is enabled later, CSRF flow is tested with `/sanctum/csrf-cookie`.

## SQL Injection
- [ ] No user input is concatenated into raw SQL.
- [ ] `whereRaw` uses parameter binding.
- [ ] Search filters are length-limited.
- [ ] Sort fields are allowlisted before `orderBy`.
- [ ] Dashboard/report dynamic table names are controlled internally, not by user input.

## XSS
- [ ] No `v-html` unless sanitized with a vetted sanitizer.
- [ ] API error messages are rendered as text, not HTML.
- [ ] Notification/message content is rendered as text.
- [ ] Chart labels and tooltips use escaped text.
- [ ] CSP is planned before public production.

## Sensitive Health Data
- [ ] Health endpoints always filter by `user_id`.
- [ ] Lab tests, medications, nutrition logs, AI insights, and reports are not logged in raw form.
- [ ] API resources do not expose unnecessary `user_id` fields to frontend.
- [ ] AI recommendation payloads do not include private notes unless needed.
- [ ] Audit logs redact medical notes and free-text fields.

## Environment / Secrets
- [ ] `APP_ENV=production` in production.
- [ ] `APP_DEBUG=false` in production.
- [ ] `DB_PASSWORD` is strong and not `postgres`.
- [ ] `.env`, `.env.docker`, keys, and tokens are not committed.
- [ ] Frontend env only contains safe `VITE_*` variables.

## Logs
- [ ] Logs do not contain bearer tokens.
- [ ] Logs do not contain passwords.
- [ ] Logs do not contain raw request payloads.
- [ ] Logs do not contain medical notes/lab details.
- [ ] Stack traces are not returned to API clients.
- [ ] Log level is warning or higher in production.

## Docker / Nginx
- [ ] Only edge Nginx exposes a public port.
- [ ] Postgres is not publicly exposed.
- [ ] AI engine is not publicly exposed.
- [ ] Backend PHP-FPM is not publicly exposed.
- [ ] Nginx has security headers.
- [ ] Hidden files and backup files are denied.
- [ ] HTTPS/TLS is configured for real public deployment.

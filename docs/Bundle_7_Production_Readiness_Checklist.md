# Bundle 7 — Production Readiness Checklist

## Automated release gate

- [ ] All PostgreSQL migrations are recorded as ran
- [ ] `migrate --pretend --force` reports nothing pending
- [ ] Authentication tests pass
- [ ] Finance regression tests pass
- [ ] Health regression tests pass
- [ ] To-Do regression tests pass
- [ ] Backend npm audit reports no high/critical findings
- [ ] Backend asset build succeeds
- [ ] Frontend npm audit reports no high/critical findings
- [ ] Vue TypeScript check succeeds
- [ ] Vitest succeeds
- [ ] Oxlint and ESLint return zero errors
- [ ] Frontend production build succeeds
- [ ] Laravel configuration, route, view, and optimization caches build successfully

## Staging smoke test

- [ ] Login and logout
- [ ] Finance dashboard totals match transactions
- [ ] Finance account and transaction CRUD
- [ ] Income, expense, transfer, category, currency, reports, and charts
- [ ] Health dashboard summaries
- [ ] Steps, weight/BMI, nutrition, hydration, sleep, mood, medications, lab tests, and sport CRUD
- [ ] Health reports and date filters
- [ ] To-Do dashboard, project/task CRUD, finish/reopen, points, progress, move, reorder, and drag-and-drop
- [ ] Success, validation, server-error, empty, and loading states
- [ ] Dark mode and light mode readability
- [ ] Mobile widths: 360px, 390px, 768px
- [ ] Browser console has no uncaught errors
- [ ] Network tab has no unexpected 4xx/5xx responses

## Deployment controls

- [ ] Backup production database
- [ ] Confirm production `APP_KEY` and secrets are configured and not committed
- [ ] Confirm `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Confirm PostgreSQL, Redis/cache, queue, mail, CORS, Sanctum, and domain variables
- [ ] Confirm writable `storage/` and `bootstrap/cache/`
- [ ] Deploy backend and built frontend artifacts
- [ ] Run migrations once through the backend container
- [ ] Rebuild Laravel production caches
- [ ] Restart application services
- [ ] Run post-deployment smoke checks
- [ ] Keep rollback artifact and database backup available

## Final Git commit

Recommended commit message:

`test(bundle7): complete finance health todo production readiness`

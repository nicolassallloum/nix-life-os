# STEP 82 — Dashboard Performance Patch

## What this patch updates

- Uses only real dashboard-related routes in the retest suite.
- Adds API performance response headers:
  - `X-Nix-Response-Time-Ms`
  - `X-Nix-Query-Count`
- Adds slow API logging through `ApiPerformanceLogger`.
- Adds slow SQL query logging through `AppServiceProvider`.
- Adds safe 60-second cache for dashboard summary endpoints.
- Fixes finance transaction delete/show/update malformed UUID handling.
- Adds conditional dashboard performance indexes.
- Adds frontend dashboard timing logs in development mode.
- Adds frontend request deduplication/cache for `/dashboard/summary`.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step82-dashboard-performance-patch.tar.gz
chmod +x step82-dashboard-performance-patch/install_step82_dashboard_performance_patch.sh
./step82-dashboard-performance-patch/install_step82_dashboard_performance_patch.sh
```

## Retest

```bash
cd /u01/nix-life-os

export API_BASE="http://127.0.0.1:8000/api/v1"
export ADMIN_EMAIL="step74.admin@gmail.com"
export ADMIN_PASSWORD="Password@123"

./scripts/step82_retest_dashboard_performance.sh
```

## ApacheBench suite

```bash
cd /u01/nix-life-os
export API_BASE="http://127.0.0.1:8000/api/v1"
export ADMIN_TOKEN="YOUR_TOKEN_HERE"
./scripts/step82_ab_suite.sh
```

## SQL EXPLAIN

```bash
cd /u01/nix-life-os/backend

USER_ID=$(php artisan tinker --execute="echo App\\Models\\User::where('email','step74.admin@gmail.com')->value('id');")

docker exec -i nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db \
  -v USER_ID="$USER_ID" \
  -f /u01/nix-life-os/scripts/step82_sql_explain.sql
```

If the host path is not mounted inside PostgreSQL, use:

```bash
docker cp /u01/nix-life-os/scripts/step82_sql_explain.sql nixlifeos-postgres:/tmp/step82_sql_explain.sql

docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db \
  -v USER_ID="$USER_ID" \
  -f /tmp/step82_sql_explain.sql
```

## Final checklist

### PASS

- `/dashboard/summary` returns 200.
- `/life-balance/summary` returns 200.
- `/health/dashboard` returns 200.
- `/projects/dashboard` returns 200.
- `/productivity/dashboard` returns 200.
- Main dashboard baseline is below 500 ms.
- ApacheBench has 0 failed requests.
- ApacheBench has 0 non-2xx responses.
- Laravel log has no new timeout/memory/SQLSTATE errors.
- Nginx log has no 502/504.
- Browser console shows STEP82 timing logs with no errors.

### WARNING

- P95 is above 1000 ms under normal load.
- Query count header is above 25 for a simple dashboard endpoint.
- Slow API or slow SQL warnings appear but requests still return 200.
- Empty dataset is tested but large-data scenario is still pending.

### FAIL

- Any core dashboard endpoint returns 500.
- Any core dashboard endpoint returns 401 with a valid token.
- ApacheBench has failed requests.
- Nginx logs show 502/504.
- Laravel logs show memory exhausted, timeout, or repeated SQL errors.

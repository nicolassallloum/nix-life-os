# STEP 83 — API Load Testing Plan

## Objective

Validate Nix Life OS API stability under concurrent requests across dashboard, finance, health, projects, productivity, authentication, and AI endpoints.

## Test Phases

| Phase | Requests | Concurrency | Goal |
|---|---:|---:|---|
| Health check | 1 per endpoint | 1 | Confirm endpoints return 200 before load testing. |
| Smoke | 50 | 5 | Catch immediate route/auth/500 errors. |
| Baseline | 200 | 20 | Measure normal expected load. |
| Stress | 500 | 50 | Identify saturation point on local Docker stack. |
| Spike optional | 1000 | 100 | Only after baseline and stress pass. |

## Expected Thresholds

These thresholds are realistic for a local Docker Laravel + PostgreSQL setup on a laptop. Adjust upward for weaker hardware and downward after optimization.

| API Group | P95 Target | Error Rate | Notes |
|---|---:|---:|---|
| Auth `/auth/me` | `< 300 ms` | `< 1%` | Should be light. |
| Dashboard summary | `< 800 ms` | `< 1%` | Cached result should often be much faster. |
| Finance lists | `< 900 ms` | `< 1%` | Transaction indexes are critical. |
| Health summaries | `< 1000 ms` | `< 1%` | Date filtering must be indexed. |
| Projects | `< 900 ms` | `< 1%` | Project/task status indexes are important. |
| Productivity | `< 1000 ms` | `< 1%` | AI insights may execute many counts. |
| AI insights | `< 1800 ms` | `< 1%` | Higher tolerance because they aggregate recommendations. |
| Login | `< 700 ms` | Controlled | Heavy concurrency may hit throttle 429. |

## Commands

### 1. Start Stack

```bash
cd /u01/nix-life-os
docker compose ps
```

### 2. Set API Base

For your current exported setup:

```bash
export API_BASE="http://127.0.0.1:8000/api/v1"
```

If you moved backend Nginx to 8001:

```bash
export API_BASE="http://127.0.0.1:8001/api/v1"
```

### 3. Set Credentials

```bash
export ADMIN_EMAIL="step74.admin@gmail.com"
export ADMIN_PASSWORD="Password@123"
```

### 4. Generate Token

```bash
./scripts/step83_auth_token_setup.sh
```

### 5. Endpoint Health Check

```bash
./scripts/step83_endpoint_health_check.sh
```

### 6. ApacheBench Load Test

```bash
./scripts/step83_api_load_test.sh
```

### 7. Smaller Custom Test

```bash
ENDPOINT="/dashboard/summary" TOTAL=100 CONCURRENCY=10 ./scripts/step83_curl_concurrency_test.sh
```

### 8. k6 Test

```bash
export ADMIN_TOKEN="$(cat .step83_token)"
k6 run tests/load/step83-k6-load-test.js
```

## ApacheBench Direct Examples

Dashboard:

```bash
ab -k -s 30 -n 200 -c 20 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_BASE/dashboard/summary"
```

Finance transactions:

```bash
ab -k -s 30 -n 200 -c 20 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_BASE/finance/transactions"
```

Productivity AI:

```bash
ab -k -s 45 -n 100 -c 10 \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  "$API_BASE/productivity/ai-insights"
```

Login throttle test:

```bash
cat > /tmp/step83-login.json <<JSON
{"email":"$ADMIN_EMAIL","password":"$ADMIN_PASSWORD"}
JSON

ab -s 30 -n 30 -c 5 \
  -p /tmp/step83-login.json \
  -T "application/json" \
  -H "Accept: application/json" \
  "$API_BASE/auth/login"
```

Expected: after throttle limit, some responses may become HTTP 429. That is acceptable for security testing, but not a performance failure.

## Success Criteria

STEP 83 is passing when:

1. Health check returns 200 for all selected read endpoints.
2. Smoke phase has 0 failed requests and 0 non-2xx responses.
3. Baseline phase has `< 1%` failed requests.
4. Dashboard P95 is below 800 ms.
5. Standard module list endpoints are below 900–1000 ms P95.
6. AI endpoints stay below 1800 ms P95.
7. Laravel logs do not show repeated slow query warnings for the same endpoint.
8. No 500 errors appear during stress phase.
9. PostgreSQL CPU/IO does not stay saturated after the test ends.


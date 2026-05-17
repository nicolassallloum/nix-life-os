# STEP 83 — Final Checklist

## Before Testing

- [ ] Docker stack is running.
- [ ] Backend Nginx is reachable on port 8000 or 8001.
- [ ] `ADMIN_EMAIL` and `ADMIN_PASSWORD` are set.
- [ ] `./scripts/step83_auth_token_setup.sh` creates `.step83_token`.
- [ ] `./scripts/step83_endpoint_health_check.sh` returns 200 for all selected endpoints.
- [ ] Laravel logs are clean before starting.
- [ ] Database migrations are complete.
- [ ] Test is not running against important production data.

## During Testing

- [ ] Run smoke phase.
- [ ] Run baseline phase.
- [ ] Run stress phase.
- [ ] Watch containers with `docker stats`.
- [ ] Watch Laravel logs for slow query warnings.
- [ ] Watch PostgreSQL active queries.

## Pass Criteria

- [ ] Smoke: 0 failed requests.
- [ ] Baseline: `< 1%` failed requests.
- [ ] Stress: no repeated 500 errors.
- [ ] No backend container restart.
- [ ] No PostgreSQL container restart.
- [ ] Dashboard P95 `< 800 ms` after cache warm-up.
- [ ] Finance/Health/Projects/Productivity standard endpoints P95 `< 1000 ms`.
- [ ] AI endpoints P95 `< 1800 ms`.
- [ ] Login throttle behavior understood; 429 is acceptable only on auth throttle tests.

## Failure Diagnosis

### Failed requests in ApacheBench

Open the specific result file in:

```bash
storage/app/step83-load-results/<timestamp>/
```

Look for:

```text
Failed requests:
Non-2xx responses:
Document Length:
```

### Laravel errors

```bash
docker exec -it nixlifeos-backend sh -lc "tail -300 storage/logs/laravel.log"
```

### Nginx / PHP-FPM errors

```bash
docker compose logs --tail=200 backend-nginx backend
```

### PostgreSQL bottleneck

```bash
docker compose logs --tail=200 postgres
```

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
select pid, state, wait_event_type, wait_event, now() - query_start as runtime, left(query, 180) as query
from pg_stat_activity
where datname = current_database()
order by query_start nulls last;
"
```

## Final Report Template

```text
STEP 83 — API Load Testing Result

API Base:
Date:
Tester:
Environment:

Smoke Result:
- Passed:
- Failed endpoints:

Baseline Result:
- Best endpoint:
- Slowest endpoint:
- Failed requests:
- P95 range:

Stress Result:
- Passed:
- Saturation point:
- Errors observed:

Main Bottlenecks:
1.
2.
3.

Optimization Applied:
1.
2.
3.

Final Status:
PASS / PASS WITH NOTES / FAIL
```


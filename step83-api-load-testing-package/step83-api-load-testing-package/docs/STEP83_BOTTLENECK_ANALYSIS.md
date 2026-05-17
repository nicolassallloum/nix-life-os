# STEP 83 — Bottleneck Analysis

## Findings From Uploaded Export

### 1. Laravel production optimization is not fully enabled

`php artisan about` shows:

| Item | Status |
|---|---|
| Config cache | NOT CACHED |
| Route cache | NOT CACHED |
| View cache | NOT CACHED |
| Event cache | NOT CACHED |

This is acceptable during development, but it reduces API performance under load. Before final performance testing, run the optimization commands in `STEP83_LARAVEL_OPTIMIZATION_COMMANDS.md`.

### 2. Dashboard summary is already cached

`DashboardController@summary` uses:

```php
Cache::remember($cacheKey, now()->addSeconds(60), ...)
```

This is good. The first request per user/day is heavier; repeated requests should become faster. During load tests, compare cold-cache and warm-cache behavior.

### 3. Dashboard summary performs schema checks dynamically

The dashboard controller checks table and column existence using `Schema::hasTable`, `information_schema.tables`, and `Schema::hasColumn` style logic. This protects against migration differences, but it adds overhead under load.

Recommendation after schema stabilizes: replace dynamic table/column detection with fixed table names and fixed column names.

### 4. Dashboard and AI endpoints use multiple aggregate queries

High-risk endpoints:

| Endpoint | Risk |
|---|---|
| `/dashboard/summary` | Finance + health + project aggregation. |
| `/life-balance/summary` | Cross-module aggregation. |
| `/productivity/ai-insights` | Many counts and insight queries. |
| `/finance/ai-insights` | Financial aggregation and warning logic. |
| `/health/ai-insights` | Health summary and alert logic. |
| `/projects/dashboard` | Project and task aggregation. |

### 5. Database cache driver can become a bottleneck

The app uses `CACHE_DRIVER=database` from the Laravel about output. Under high concurrency, dashboard cache reads/writes go through PostgreSQL. For heavier testing or production, Redis is recommended.

Recommended future setup:

```env
CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
```

### 6. Queue driver is database

The app uses `QUEUE_CONNECTION=database`. This is fine for development, but any queued AI, notification, monitoring, or audit jobs may compete with API reads/writes. Redis queue is better for production performance.

### 7. API performance headers already exist

`ApiPerformanceLogger` adds:

| Header | Meaning |
|---|---|
| `X-Nix-Response-Time-Ms` | Laravel-side request duration. |
| `X-Nix-Query-Count` | Number of DB queries executed. |

It logs warnings when duration is `>= 500 ms`, query count is `>= 25`, or slow queries are detected. This is excellent for STEP 83 diagnostics.

### 8. Existing Step 82 indexes are strong, but verify usage

The project includes Step 82 indexes for finance, health, projects, productivity, and AI tables. During load tests, use PostgreSQL `EXPLAIN ANALYZE` on slow queries from Laravel logs to verify index usage.

## Bottleneck Diagnosis Commands

### Laravel slow performance signals

```bash
docker exec -it nixlifeos-backend sh -lc \
  "tail -300 storage/logs/laravel.log | grep -i 'slow API performance signal' -A 15"
```

### Last 200 Laravel log lines

```bash
docker exec -it nixlifeos-backend sh -lc \
  "tail -200 storage/logs/laravel.log"
```

### Container resource usage

```bash
docker stats nixlifeos-backend nixlifeos-backend-nginx nixlifeos-postgres nixlifeos-ai-engine
```

### PostgreSQL active queries

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
select pid, state, wait_event_type, wait_event, now() - query_start as runtime, left(query, 150) as query
from pg_stat_activity
where datname = current_database()
order by query_start nulls last;
"
```

### PostgreSQL index inventory

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "
select schemaname, tablename, indexname, indexdef
from pg_indexes
where schemaname in ('public', 'nix_life_os')
  and (
    tablename like 'finance_%'
    or tablename like 'health_%'
    or tablename like 'project%'
    or tablename like 'productivity_%'
    or tablename like 'ai_%'
  )
order by tablename, indexname;
"
```

## Bottleneck Decision Tree

### Symptom: P95 high but failed requests are 0

Likely cause:

- Slow DB queries.
- Cold cache.
- Too many aggregate queries.
- PHP-FPM worker saturation.

Actions:

1. Warm cache with 5 manual requests.
2. Re-run baseline.
3. Check `X-Nix-Query-Count` in endpoint health check.
4. Inspect Laravel slow performance logs.
5. Run `EXPLAIN ANALYZE` for slow queries.

### Symptom: 500 errors under load

Likely cause:

- PHP memory limit.
- Database connection exhaustion.
- Race condition in cache/write logic.
- Missing table/column branch under concurrency.

Actions:

```bash
docker exec -it nixlifeos-backend sh -lc "tail -300 storage/logs/laravel.log"
docker compose logs --tail=200 backend backend-nginx postgres
```

### Symptom: 502 Bad Gateway

Likely cause:

- PHP-FPM backend unavailable.
- PHP-FPM worker exhaustion.
- Container restart.
- Nginx fastcgi timeout.

Actions:

```bash
docker compose ps
docker compose logs --tail=200 backend-nginx backend
```

### Symptom: 429 Too Many Requests

Likely cause:

- Expected for `/auth/login` or `/auth/register` because throttles are applied.

Actions:

- Do not count 429 as failure for throttle/security tests.
- Do count 429 as failure for normal protected GET endpoints unless rate limits are intentionally added.


# STEP 83 — Laravel Optimization Commands

## Pre-Test Optimization

Run before baseline and stress tests:

```bash
cd /u01/nix-life-os

docker exec -it nixlifeos-backend sh -lc "php artisan optimize:clear"
docker exec -it nixlifeos-backend sh -lc "php artisan config:cache"
docker exec -it nixlifeos-backend sh -lc "php artisan route:cache"
docker exec -it nixlifeos-backend sh -lc "php artisan view:cache"
docker exec -it nixlifeos-backend sh -lc "php artisan event:cache || true"
```

Verify:

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan about"
```

Expected after optimization:

| Item | Expected |
|---|---|
| Config | CACHED |
| Routes | CACHED |
| Views | CACHED |
| Events | CACHED if supported |

## Important Warning

If route caching fails, it usually means there are closure routes in `routes/api.php`. Your file currently contains multiple closure routes for test/fallback/admin responses. Laravel route cache may fail until those are converted to controller methods.

If `route:cache` fails, still run:

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan config:cache"
docker exec -it nixlifeos-backend sh -lc "php artisan view:cache"
```

## Cache Warm-Up

```bash
export API_BASE="http://127.0.0.1:8000/api/v1"
export ADMIN_TOKEN="$(cat .step83_token)"

for i in 1 2 3 4 5; do
  curl -s "$API_BASE/dashboard/summary" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" >/dev/null
  curl -s "$API_BASE/productivity/ai-insights" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" >/dev/null
  curl -s "$API_BASE/finance/ai-insights" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" >/dev/null
  sleep 1
done
```

## Recommended `.env.docker` Performance Values

Do not send your real `.env.docker`. Review these values locally:

```env
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=warning
CACHE_STORE=database
QUEUE_CONNECTION=database
SESSION_DRIVER=database
```

For stronger performance later, consider Redis:

```env
CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
```

## PHP-FPM / OPcache Recommendations

Your backend Dockerfile installs OPcache. Verify PHP settings inside the container:

```bash
docker exec -it nixlifeos-backend sh -lc "php -i | grep -i opcache | head -40"
```

Recommended production-like OPcache values in `backend/docker/php.ini`:

```ini
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=1
opcache.revalidate_freq=2
realpath_cache_size=4096K
realpath_cache_ttl=600
memory_limit=512M
max_execution_time=60
```

For final production, `opcache.validate_timestamps=0` is faster, but only use it if deployment restarts PHP-FPM after every code change.

## Post-Test Cleanup

```bash
docker exec -it nixlifeos-backend sh -lc "php artisan optimize:clear"
```


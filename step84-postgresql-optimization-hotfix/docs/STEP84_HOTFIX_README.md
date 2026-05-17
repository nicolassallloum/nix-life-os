# STEP 84 PostgreSQL Optimization Hotfix

## Fixes

1. Migration failure caused by missing `automation_rules.next_run_at`.
2. EXPLAIN script failure caused by placeholder UUID usage.
3. EXPLAIN script failure caused by missing `public.health_step_log.calories_burned`.
4. Retest script optional 404 routes removed from main pass/fail check.

## Why the migration failed

The current `automation_rules` table has:

- `user_id`
- `is_active`
- `last_triggered_at`
- `created_at`
- `updated_at`

It does not have:

- `next_run_at`

The hotfix migration checks both table and column existence before creating each index.

## Install

```bash
cd /u01/nix-life-os

tar -xzf step84-postgresql-optimization-hotfix.tar.gz

chmod +x step84-postgresql-optimization-hotfix/install_step84_postgresql_optimization_hotfix.sh
./step84-postgresql-optimization-hotfix/install_step84_postgresql_optimization_hotfix.sh

docker exec -it nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan migrate --force'
docker exec -it nixlifeos-backend sh -lc 'php -l database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php'
```

## Correct EXPLAIN usage

Use a real UUID from your users table, not `PASTE_USER_UUID_HERE`.

Example:

```bash
docker cp scripts/step84_explain_analyze.sql nixlifeos-postgres:/tmp/step84_explain_analyze.sql

docker exec -it nixlifeos-postgres psql \
  -U nixlifeos_user \
  -d nixlifeos_db \
  -v user_id='019e3185-81c4-70c6-b9c0-29405d7757a3' \
  -f /tmp/step84_explain_analyze.sql
```

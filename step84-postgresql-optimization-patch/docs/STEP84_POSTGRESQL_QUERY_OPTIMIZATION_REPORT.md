# STEP 84 — PostgreSQL Query Optimization Review

## Review status

**Status: READY FOR CONTROLLED INSTALL / RETEST**

The uploaded database currently contains very small row counts, so true runtime bottlenecks cannot be proven from execution time alone. The review still found several structural risks that should be fixed before the tables grow.

## Highest-priority findings

### 1. Slow-query history is not available

`pg_stat_statements` failed with `relation "pg_stat_statements" does not exist`. This means PostgreSQL is not currently collecting normalized query timings. Enable it before the next performance cycle.

Recommended PostgreSQL settings for local development:

```conf
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
track_io_timing = on
log_min_duration_statement = 250ms
```

After enabling it, restart PostgreSQL and run:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT pg_stat_statements_reset();
```

### 2. UnifiedDashboardService was using old table names

The dashboard service used old/singular schema references such as:

```php
finance_account
nix_life_os.finance_transaction
nix_life_os.health_step_log
```

Your active Laravel controllers mostly use current/public tables such as:

```php
finance_accounts
finance_transactions
health_step_log
health_hydration_logs
health_meal_logs
projects
```

This patch updates `UnifiedDashboardService.php` to use the active public tables and index-friendly date ranges.

### 3. `whereDate`, `whereMonth`, and `whereYear` reduce index efficiency

Several dashboard and health queries wrap date columns in functions. This can prevent efficient use of normal B-tree indexes when tables become large.

Preferred pattern:

```php
->where('transaction_date', '>=', $monthStart)
->where('transaction_date', '<', $nextMonthStart)
```

Avoid:

```php
->whereMonth('transaction_date', now()->month)
->whereYear('transaction_date', now()->year)
->whereDate('transaction_date', $date)
```

### 4. Duplicate indexes exist

Exact duplicate or overlapping indexes were found on important tables:

- `finance_transactions.user_id`
- `finance_accounts.user_id`
- `finance_accounts(user_id, is_active)`
- `finance_budgets.user_id`
- `finance_budget_lines.user_id`
- `health_hydration_logs(user_id, log_date)`
- `health_weight_logs(user_id, log_date)`
- `health_lab_tests(user_id, test_date)`
- `projects(user_id, status)`
- `project_tasks(project_id, status)`
- `project_tasks(user_id, status)`
- `ai_recommendations.user_id`
- `ai_user_daily_scores.user_id`

Do not drop them immediately on a tiny dev DB. First enable query stats and observe `pg_stat_user_indexes` after real usage.

### 5. Current PostgreSQL settings are conservative defaults

Current export:

```text
shared_buffers = 128MB
work_mem = 4MB
maintenance_work_mem = 64MB
effective_cache_size = 4GB
max_connections = 100
random_page_cost = 4
track_io_timing = off
log_min_duration_statement = -1
```

For a local Docker development database, safer tuning would be:

```conf
shared_buffers = 512MB
work_mem = 16MB
maintenance_work_mem = 256MB
effective_cache_size = 4GB
random_page_cost = 1.5
track_io_timing = on
log_min_duration_statement = 250ms
```

## Query optimization recommendations by module

### Dashboard

Main risks:

- Repeated independent summary queries.
- Old schema/table names in unified dashboard service.
- Function-wrapped date filters.
- No short TTL cache for expensive summary endpoints.

Applied in patch:

- Corrected table names.
- Replaced `whereMonth`, `whereYear`, and most `whereDate` dashboard patterns.
- Added 60-second cache to the unified dashboard overview.
- Combined project critical/overdue counts into one aggregate query.

### Finance

Important queries:

- Account balance total by user.
- Transaction income/expense summaries by user/date/type.
- Monthly finance trend grouped by transaction date.
- Account transaction listing ordered by transaction date.

Recommended index pattern:

```sql
CREATE INDEX IF NOT EXISTS idx_step84_finance_tx_user_date_type_amount
ON finance_transactions (user_id, transaction_date, transaction_type) INCLUDE (amount);
```

### Health

Important queries:

- Daily hydration sum.
- Daily step sum.
- Nutrition daily nutrient sums.
- Latest weight by user/date.
- Lab tests by user/test/date.
- Medication dose counts by user/scheduled/status.

Recommended index pattern:

```sql
CREATE INDEX IF NOT EXISTS idx_step84_health_nutrition_user_date_type
ON health_nutrition_logs (user_id, meal_date, meal_type);
```

### Projects

Important queries:

- Project counts by user/status/priority.
- Overdue projects by user/target date/status.
- Project progress payload tasks ordered by task order.
- Recent status updates ordered by created date.

Recommended partial index:

```sql
CREATE INDEX IF NOT EXISTS idx_step84_projects_user_overdue_open
ON projects (user_id, target_end_date)
WHERE target_end_date IS NOT NULL AND status NOT IN ('completed', 'cancelled');
```

### Productivity

Existing Step 82 indexes already cover many productivity dashboard patterns:

- `productivity_tasks(user_id, status, due_date)`
- `productivity_habits(user_id, status)`
- `productivity_goals(user_id, status, target_date)`
- `productivity_calendar_events(user_id, start_time, status)`

Main recommendation: keep dashboard queries as aggregate SQL instead of loading all tasks/habits/goals into collections for counting.

### AI insights / recommendations

Main query pattern:

```php
where user_id
optional module/status/severity/type
order by priority, generated_at desc
limit 20
```

Recommended index:

```sql
CREATE INDEX IF NOT EXISTS idx_step84_ai_recs_active_feed
ON ai_recommendations (user_id, module, status, priority, generated_at DESC)
WHERE deleted_at IS NULL;
```

### Notifications / automation

Recommended patterns:

```sql
CREATE INDEX IF NOT EXISTS idx_step84_life_notifications_unread
ON life_notifications (user_id, created_at DESC)
WHERE is_read = false;
```

```sql
CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_next_run
ON automation_rules (user_id, is_active, next_run_at)
WHERE is_active = true;
```

## Files included in this patch

```text
backend/app/Services/Dashboard/UnifiedDashboardService.php
backend/database/migrations/2026_05_18_000084_add_step84_postgresql_optimization_indexes.php
scripts/step84_explain_analyze.sql
scripts/step84_postgres_diagnostics.sql
scripts/step84_retest.sh
docs/STEP84_POSTGRESQL_QUERY_OPTIMIZATION_REPORT.md
docs/STEP84_DUPLICATE_INDEX_REVIEW.sql
install_step84_postgresql_optimization.sh
```

## Installation

```bash
cd /u01/nix-life-os

tar -xzf step84-postgresql-optimization-patch.tar.gz

chmod +x step84-postgresql-optimization-patch/install_step84_postgresql_optimization.sh
chmod +x step84-postgresql-optimization-patch/scripts/step84_retest.sh

./step84-postgresql-optimization-patch/install_step84_postgresql_optimization.sh
```

Then run:

```bash
docker exec -it nixlifeos-backend sh -lc 'php artisan optimize:clear && php artisan migrate --force'
docker exec -it nixlifeos-backend sh -lc 'php -l app/Services/Dashboard/UnifiedDashboardService.php'
./scripts/step84_retest.sh
```

## EXPLAIN ANALYZE retest

Get a real user id:

```bash
docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -c "SELECT id, email FROM users LIMIT 5;"
```

Run explain script:

```bash
docker cp scripts/step84_explain_analyze.sql nixlifeos-postgres:/tmp/step84_explain_analyze.sql

docker exec -it nixlifeos-postgres psql \
  -U nixlifeos_user \
  -d nixlifeos_db \
  -v user_id='PASTE_USER_UUID_HERE' \
  -f /tmp/step84_explain_analyze.sql
```

## Final readiness report

| Area | Status | Notes |
|---|---:|---|
| Slow query history | FAIL | `pg_stat_statements` not enabled yet. |
| Dashboard query correctness | PATCHED | Old table names corrected in `UnifiedDashboardService`. |
| Dashboard date filtering | PATCHED | Replaced function-wrapped date filters in patched service. |
| Finance indexes | READY | Added covering/range index migration. |
| Health indexes | READY | Added nutrition, dose, lab, alert indexes. |
| Project indexes | READY | Added overdue/open and ordering indexes. |
| AI recommendation indexes | READY | Added active feed and expiration indexes. |
| Duplicate indexes | REVIEW REQUIRED | Do not auto-drop until stats are collected. |
| PostgreSQL tuning | REVIEW REQUIRED | Settings are safe defaults but not optimized. |
| Final production readiness | NOT YET | Needs retest after migration + pg_stat_statements. |

## Final checklist

- [ ] Install patch.
- [ ] Run `php artisan migrate --force`.
- [ ] Run `php artisan optimize:clear`.
- [ ] Retest dashboard, finance, health, projects, productivity, AI, notifications.
- [ ] Enable `pg_stat_statements`.
- [ ] Run load test from STEP 83 again.
- [ ] Run `scripts/step84_postgres_diagnostics.sql` after realistic usage.
- [ ] Review duplicate indexes after several days of `idx_scan` data.
- [ ] Drop duplicates only after confirming they are unused or fully covered.

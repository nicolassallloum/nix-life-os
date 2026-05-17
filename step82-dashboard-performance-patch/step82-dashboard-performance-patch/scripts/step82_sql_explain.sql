-- STEP 82 SQL EXPLAIN ANALYZE COMMANDS
-- Replace :USER_ID when running manually, or use psql -v USER_ID='uuid-here'.

\echo 'STEP 82 — finance transactions monthly summary'
EXPLAIN (ANALYZE, BUFFERS)
SELECT transaction_type, SUM(amount) AS total_amount, COUNT(*) AS total_count
FROM finance_transactions
WHERE user_id = :'USER_ID'
  AND transaction_date >= date_trunc('month', CURRENT_DATE)
  AND transaction_date < (date_trunc('month', CURRENT_DATE) + interval '1 month')
GROUP BY transaction_type;

\echo 'STEP 82 — finance accounts balance'
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) AS accounts_count, SUM(current_balance) AS total_balance
FROM finance_accounts
WHERE user_id = :'USER_ID';

\echo 'STEP 82 — health hydration daily chart'
EXPLAIN (ANALYZE, BUFFERS)
SELECT log_date, SUM(amount_ml) AS total_ml
FROM health_hydration_logs
WHERE user_id = :'USER_ID'
  AND log_date >= CURRENT_DATE - interval '30 days'
GROUP BY log_date
ORDER BY log_date;

\echo 'STEP 82 — health steps daily chart'
EXPLAIN (ANALYZE, BUFFERS)
SELECT log_date, SUM(steps_count) AS total_steps
FROM health_step_log
WHERE user_id = :'USER_ID'
  AND log_date >= CURRENT_DATE - interval '30 days'
GROUP BY log_date
ORDER BY log_date;

\echo 'STEP 82 — projects by status'
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*)
FROM projects
WHERE user_id = :'USER_ID'
GROUP BY status;

\echo 'STEP 82 — project tasks by status'
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*)
FROM project_tasks
WHERE user_id = :'USER_ID'
GROUP BY status;

\echo 'STEP 82 — productivity tasks by status'
EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*)
FROM productivity_tasks
WHERE user_id = :'USER_ID'
GROUP BY status;

\echo 'STEP 82 — notifications latest'
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, title, message, read_at, created_at
FROM notifications
WHERE user_id = :'USER_ID'
ORDER BY created_at DESC
LIMIT 20;

\echo 'STEP 82 — AI recommendations'
EXPLAIN (ANALYZE, BUFFERS)
SELECT module, status, COUNT(*)
FROM ai_recommendations
WHERE user_id = :'USER_ID'
GROUP BY module, status;

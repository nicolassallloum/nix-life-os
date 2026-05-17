-- STEP 84 — EXPLAIN ANALYZE commands, hotfix version
-- Correct usage:
-- docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -v user_id='019e3185-81c4-70c6-b9c0-29405d7757a3' -f /tmp/step84_explain_analyze.sql

SET track_io_timing = on;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT COALESCE(SUM(current_balance), 0) AS total_balance, COUNT(*) AS total_accounts
FROM finance_accounts
WHERE user_id = :'user_id'::uuid AND is_active = true;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
  COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS monthly_income,
  COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS monthly_expenses
FROM finance_transactions
WHERE user_id = :'user_id'::uuid
  AND transaction_date >= date_trunc('month', CURRENT_DATE)::date
  AND transaction_date < (date_trunc('month', CURRENT_DATE) + interval '1 month')::date;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT transaction_date AS date,
       COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS income,
       COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS expenses
FROM finance_transactions
WHERE user_id = :'user_id'::uuid
  AND transaction_date >= CURRENT_DATE - interval '30 days'
GROUP BY transaction_date
ORDER BY date;

-- Current public.health_step_log does not have calories_burned.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT COALESCE(SUM(steps_count), 0) AS total_steps,
       COALESCE(SUM(distance_km), 0) AS total_distance_km
FROM health_step_log
WHERE user_id = :'user_id'::uuid
  AND log_date = CURRENT_DATE;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT COALESCE(SUM(amount_ml), 0) AS total_water_ml
FROM health_hydration_logs
WHERE user_id = :'user_id'::uuid
  AND log_date = CURRENT_DATE;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT COUNT(*) AS total_projects,
       COUNT(*) FILTER (WHERE status = 'not_started') AS not_started,
       COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
       COUNT(*) FILTER (WHERE status = 'completed') AS completed,
       COUNT(*) FILTER (WHERE priority = 'critical') AS critical_projects,
       COUNT(*) FILTER (WHERE target_end_date IS NOT NULL AND target_end_date < CURRENT_DATE AND status NOT IN ('completed', 'cancelled')) AS overdue_projects,
       COALESCE(AVG(progress_percentage), 0) AS average_progress
FROM projects
WHERE user_id = :'user_id'::uuid;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT *
FROM ai_recommendations
WHERE user_id = :'user_id'::uuid
  AND module = 'health'
  AND status = 'pending'
  AND deleted_at IS NULL
ORDER BY priority, generated_at DESC
LIMIT 20;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT *
FROM life_notifications
WHERE user_id = :'user_id'::uuid
  AND is_read = false
ORDER BY created_at DESC
LIMIT 20;

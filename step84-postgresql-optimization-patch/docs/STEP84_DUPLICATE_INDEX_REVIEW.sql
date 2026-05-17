-- STEP 84 — Duplicate index review only
-- Do NOT run all DROP statements blindly. Review after at least several days of real pg_stat_user_indexes usage.
-- Duplicates found in the uploaded export included these exact duplicate or overlapping indexes.

-- Examples of safe candidates AFTER review:
-- DROP INDEX IF EXISTS idx_finance_transactions_user_id; -- covered by finance_transactions_user_id_index and composite indexes
-- DROP INDEX IF EXISTS idx_finance_accounts_user_id; -- covered by finance_accounts_user_id_index and user_id,is_active composites
-- DROP INDEX IF EXISTS idx_step82_health_hydration_user_date; -- duplicate of health_hydration_logs_user_id_log_date_index / idx_health_hydration_logs_user_date
-- DROP INDEX IF EXISTS idx_step82_health_weight_user_date; -- duplicate of health_weight_logs_user_id_log_date_index / idx_health_weight_logs_user_date
-- DROP INDEX IF EXISTS idx_step82_projects_user_status; -- duplicate of idx_projects_user_status / projects_user_id_status_index
-- DROP INDEX IF EXISTS idx_ai_recommendations_user_id; -- duplicate of idx_ai_recommendations_user
-- DROP INDEX IF EXISTS idx_ai_user_daily_scores_user_id; -- duplicate of idx_ai_daily_scores_user

-- Use this query before dropping:
SELECT schemaname, relname AS table_name, indexrelname AS index_name, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE indexrelname IN (
  'idx_finance_transactions_user_id',
  'idx_finance_accounts_user_id',
  'idx_step82_health_hydration_user_date',
  'idx_step82_health_weight_user_date',
  'idx_step82_projects_user_status',
  'idx_ai_recommendations_user_id',
  'idx_ai_user_daily_scores_user_id'
)
ORDER BY table_name, index_name;

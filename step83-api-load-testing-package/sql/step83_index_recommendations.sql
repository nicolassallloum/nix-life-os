-- STEP 83 — SQL Index Recommendations
-- Review before running. Prefer running during low-traffic time.
-- PostgreSQL CONCURRENTLY cannot run inside a transaction block.

-- Finance: transaction listing, monthly aggregation, and account filtering.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_finance_transactions_user_date_type
ON finance_transactions (user_id, transaction_date, transaction_type);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_finance_transactions_user_created
ON finance_transactions (user_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_finance_accounts_user_active_created
ON finance_accounts (user_id, is_active, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_finance_budgets_user_active_month
ON finance_budgets (user_id, is_active, budget_month);

-- Health: summary endpoints by user/date.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_health_hydration_user_log_date
ON health_hydration_logs (user_id, log_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_health_weight_user_log_date_created
ON health_weight_logs (user_id, log_date DESC, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_health_nutrition_user_log_date
ON health_nutrition_logs (user_id, log_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_health_sleep_user_sleep_date
ON health_sleep_logs (user_id, sleep_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_health_lab_tests_user_test_date
ON health_lab_tests (user_id, test_date DESC);

-- Projects: dashboard and task status aggregation.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_projects_user_status_priority
ON projects (user_id, status, priority);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_project_tasks_user_status_due
ON project_tasks (user_id, status, due_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_project_milestones_project_status_target
ON project_milestones (project_id, status, target_date);

-- Productivity: AI insight service uses many status/date counts.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_productivity_tasks_user_status_priority_due
ON productivity_tasks (user_id, status, priority, due_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_productivity_goals_user_status_target
ON productivity_goals (user_id, status, target_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_productivity_habits_user_status_completed
ON productivity_habits (user_id, status, last_completed_at);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_productivity_calendar_user_start_end
ON productivity_calendar_events (user_id, start_time, end_time);

-- AI recommendations and scores.
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_ai_recommendations_user_module_status_priority
ON ai_recommendations (user_id, module, status, priority);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_step83_ai_daily_scores_user_score_date
ON ai_user_daily_scores (user_id, score_date DESC);

-- Verify index usage after slow query logs identify specific SQL:
-- EXPLAIN (ANALYZE, BUFFERS) <your slow SQL here>;

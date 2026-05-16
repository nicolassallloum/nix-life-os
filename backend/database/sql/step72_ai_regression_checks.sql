-- STEP 72 — AI Module Stabilization SQL Regression Checks
-- Run inside nixlifeos_db:
-- docker exec -it nixlifeos-postgres psql -U nixlifeos_user -d nixlifeos_db -f /path/to/step72_ai_regression_checks.sql

\echo '1) AI tables'
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name ILIKE '%ai%'
    OR table_name ILIKE '%recommendation%'
    OR table_name ILIKE '%insight%'
  )
ORDER BY table_name;

\echo '2) AI recommendation records'
SELECT
    id,
    user_id,
    module,
    recommendation_type,
    severity,
    priority,
    status,
    confidence_score,
    impact_score,
    period_key,
    created_at
FROM ai_recommendations
ORDER BY created_at DESC
LIMIT 20;

\echo '3) Active duplicate prevention check — expected 0 rows'
SELECT
    user_id,
    module,
    recommendation_type,
    title,
    period_key,
    COUNT(*) AS duplicate_count
FROM ai_recommendations
WHERE status IN ('pending', 'viewed', 'accepted')
  AND deleted_at IS NULL
GROUP BY user_id, module, recommendation_type, title, period_key
HAVING COUNT(*) > 1;

\echo '4) Feedback records'
SELECT
    recommendation_id,
    user_id,
    feedback_type,
    feedback_value,
    feedback_comment,
    created_at
FROM ai_recommendation_feedback
ORDER BY created_at DESC
LIMIT 20;

\echo '5) Daily score records'
SELECT
    user_id,
    score_date,
    finance_score,
    health_score,
    productivity_score,
    goals_score,
    habits_score,
    life_balance_score,
    classification,
    created_at
FROM ai_user_daily_scores
ORDER BY score_date DESC, created_at DESC
LIMIT 20;

\echo '6) AI insights audit table currently used by project'
SELECT
    id,
    user_id,
    insight_type,
    category,
    title,
    severity,
    score,
    insight_date,
    created_at
FROM ai_insights
ORDER BY created_at DESC
LIMIT 20;

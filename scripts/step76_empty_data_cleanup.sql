-- STEP 76 — Safe Empty Data Cleanup
-- Usage in psql:
--   \set step76_email 'step76.empty@gmail.com'
--   \i scripts/step76_empty_data_cleanup.sql
--
-- This script never uses the literal text USER_ID. It resolves the UUID from users.email
-- and skips optional tables that do not exist in the current environment.

DO $$
DECLARE
    v_email text := :'step76_email';
    v_user_id uuid;
BEGIN
    SELECT id INTO v_user_id FROM users WHERE email = v_email LIMIT 1;

    IF v_user_id IS NULL THEN
        RAISE NOTICE 'No user found for %. Nothing to clean.', v_email;
        RETURN;
    END IF;

    RAISE NOTICE 'Cleaning empty-data records for user % (%)', v_email, v_user_id;

    IF to_regclass('public.ai_recommendation_feedback') IS NOT NULL THEN
        DELETE FROM ai_recommendation_feedback WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.ai_recommendations') IS NOT NULL THEN
        DELETE FROM ai_recommendations WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.productivity_calendar_events') IS NOT NULL THEN
        DELETE FROM productivity_calendar_events WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.productivity_goals') IS NOT NULL THEN
        DELETE FROM productivity_goals WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.productivity_habit_check_ins') IS NOT NULL THEN
        DELETE FROM productivity_habit_check_ins
        WHERE habit_id IN (SELECT id FROM productivity_habits WHERE user_id = v_user_id);
    END IF;

    IF to_regclass('public.productivity_habits') IS NOT NULL THEN
        DELETE FROM productivity_habits WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.productivity_tasks') IS NOT NULL THEN
        DELETE FROM productivity_tasks WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.project_status_updates') IS NOT NULL THEN
        DELETE FROM project_status_updates WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.project_tasks') IS NOT NULL THEN
        DELETE FROM project_tasks WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.project_milestones') IS NOT NULL THEN
        DELETE FROM project_milestones WHERE project_id IN (SELECT id FROM projects WHERE user_id = v_user_id);
    END IF;

    IF to_regclass('public.projects') IS NOT NULL THEN
        DELETE FROM projects WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_medication_dose_logs') IS NOT NULL THEN
        DELETE FROM health_medication_dose_logs WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_medication_reminders') IS NOT NULL THEN
        DELETE FROM health_medication_reminders WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_medications') IS NOT NULL THEN
        DELETE FROM health_medications WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_lab_tests') IS NOT NULL THEN
        DELETE FROM health_lab_tests WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_step_logs') IS NOT NULL THEN
        DELETE FROM health_step_logs WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_weight_logs') IS NOT NULL THEN
        DELETE FROM health_weight_logs WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_hydration_logs') IS NOT NULL THEN
        DELETE FROM health_hydration_logs WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.health_nutrition_logs') IS NOT NULL THEN
        DELETE FROM health_nutrition_logs WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.finance_transactions') IS NOT NULL THEN
        DELETE FROM finance_transactions WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.finance_budget_lines') IS NOT NULL THEN
        DELETE FROM finance_budget_lines
        WHERE budget_id IN (SELECT id FROM finance_budgets WHERE user_id = v_user_id);
    END IF;

    IF to_regclass('public.finance_budgets') IS NOT NULL THEN
        DELETE FROM finance_budgets WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.finance_accounts') IS NOT NULL THEN
        DELETE FROM finance_accounts WHERE user_id = v_user_id;
    END IF;

    RAISE NOTICE 'STEP 76 cleanup completed for %.', v_email;
END $$;

SELECT id, name, email
FROM users
WHERE email = :'step76_email';

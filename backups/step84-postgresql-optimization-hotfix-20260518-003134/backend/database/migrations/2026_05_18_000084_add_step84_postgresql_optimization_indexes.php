<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->index('finance_transactions', 'idx_step84_finance_tx_user_date_type_amount',
            "CREATE INDEX IF NOT EXISTS idx_step84_finance_tx_user_date_type_amount ON finance_transactions (user_id, transaction_date, transaction_type) INCLUDE (amount)");

        $this->index('finance_transactions', 'idx_step84_finance_tx_user_account_date_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_finance_tx_user_account_date_desc ON finance_transactions (user_id, account_id, transaction_date DESC)");

        $this->index('health_nutrition_logs', 'idx_step84_health_nutrition_user_date_type',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_nutrition_user_date_type ON health_nutrition_logs (user_id, meal_date, meal_type)");

        $this->index('health_medication_dose_logs', 'idx_step84_med_doses_user_scheduled_status',
            "CREATE INDEX IF NOT EXISTS idx_step84_med_doses_user_scheduled_status ON health_medication_dose_logs (user_id, scheduled_for, status)");

        $this->index('health_lab_tests', 'idx_step84_lab_tests_user_name_date_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_lab_tests_user_name_date_desc ON health_lab_tests (user_id, test_name, test_date DESC)");

        $this->index('health_alerts', 'idx_step84_health_alerts_user_active_severity',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_alerts_user_active_severity ON health_alerts (user_id, severity) WHERE status = 'active'");

        $this->index('projects', 'idx_step84_projects_user_overdue_open',
            "CREATE INDEX IF NOT EXISTS idx_step84_projects_user_overdue_open ON projects (user_id, target_end_date) WHERE target_end_date IS NOT NULL AND status NOT IN ('completed', 'cancelled')");

        $this->index('projects', 'idx_step84_projects_user_updated_at',
            "CREATE INDEX IF NOT EXISTS idx_step84_projects_user_updated_at ON projects (user_id, updated_at)");

        $this->index('project_tasks', 'idx_step84_project_tasks_project_order_created',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_tasks_project_order_created ON project_tasks (project_id, task_order, created_at)");

        $this->index('project_milestones', 'idx_step84_project_milestones_project_target_created',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_milestones_project_target_created ON project_milestones (project_id, target_date, created_at)");

        $this->index('project_status_updates', 'idx_step84_project_updates_project_created_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_updates_project_created_desc ON project_status_updates (project_id, created_at DESC)");

        $this->index('ai_recommendations', 'idx_step84_ai_recs_active_feed',
            "CREATE INDEX IF NOT EXISTS idx_step84_ai_recs_active_feed ON ai_recommendations (user_id, module, status, priority, generated_at DESC) WHERE deleted_at IS NULL");

        $this->index('ai_recommendations', 'idx_step84_ai_recs_not_expired',
            "CREATE INDEX IF NOT EXISTS idx_step84_ai_recs_not_expired ON ai_recommendations (user_id, expires_at) WHERE deleted_at IS NULL AND expires_at IS NOT NULL");

        $this->index('life_notifications', 'idx_step84_life_notifications_unread',
            "CREATE INDEX IF NOT EXISTS idx_step84_life_notifications_unread ON life_notifications (user_id, created_at DESC) WHERE is_read = false");

        $this->index('automation_rules', 'idx_step84_automation_rules_user_active_next_run',
            "CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_next_run ON automation_rules (user_id, is_active, next_run_at) WHERE is_active = true");
    }

    public function down(): void
    {
        foreach ([
            'idx_step84_finance_tx_user_date_type_amount',
            'idx_step84_finance_tx_user_account_date_desc',
            'idx_step84_health_nutrition_user_date_type',
            'idx_step84_med_doses_user_scheduled_status',
            'idx_step84_lab_tests_user_name_date_desc',
            'idx_step84_health_alerts_user_active_severity',
            'idx_step84_projects_user_overdue_open',
            'idx_step84_projects_user_updated_at',
            'idx_step84_project_tasks_project_order_created',
            'idx_step84_project_milestones_project_target_created',
            'idx_step84_project_updates_project_created_desc',
            'idx_step84_ai_recs_active_feed',
            'idx_step84_ai_recs_not_expired',
            'idx_step84_life_notifications_unread',
            'idx_step84_automation_rules_user_active_next_run',
        ] as $index) {
            DB::statement("DROP INDEX IF EXISTS {$index}");
        }
    }

    private function index(string $table, string $index, string $sql): void
    {
        if (Schema::hasTable($table)) {
            DB::statement($sql);
        }
    }
};

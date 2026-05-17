<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->indexIfColumnsExist(
            'finance_transactions',
            ['user_id', 'transaction_date', 'transaction_type', 'amount'],
            'idx_step84_finance_tx_user_date_type_amount',
            "CREATE INDEX IF NOT EXISTS idx_step84_finance_tx_user_date_type_amount ON finance_transactions (user_id, transaction_date, transaction_type) INCLUDE (amount)"
        );

        $this->indexIfColumnsExist(
            'finance_transactions',
            ['user_id', 'account_id', 'transaction_date'],
            'idx_step84_finance_tx_user_account_date_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_finance_tx_user_account_date_desc ON finance_transactions (user_id, account_id, transaction_date DESC)"
        );

        $this->indexIfColumnsExist(
            'health_nutrition_logs',
            ['user_id', 'meal_date', 'meal_type'],
            'idx_step84_health_nutrition_user_date_type',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_nutrition_user_date_type ON health_nutrition_logs (user_id, meal_date, meal_type)"
        );

        $this->indexIfColumnsExist(
            'health_meal_logs',
            ['user_id', 'meal_date', 'meal_type'],
            'idx_step84_health_meal_logs_user_date_type',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_meal_logs_user_date_type ON health_meal_logs (user_id, meal_date, meal_type)"
        );

        $this->indexIfColumnsExist(
            'health_step_log',
            ['user_id', 'log_date'],
            'idx_step84_health_step_log_user_date',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_step_log_user_date ON health_step_log (user_id, log_date)"
        );

        $this->indexIfColumnsExist(
            'health_medication_dose_logs',
            ['user_id', 'scheduled_for', 'status'],
            'idx_step84_med_doses_user_scheduled_status',
            "CREATE INDEX IF NOT EXISTS idx_step84_med_doses_user_scheduled_status ON health_medication_dose_logs (user_id, scheduled_for, status)"
        );

        $this->indexIfColumnsExist(
            'health_lab_tests',
            ['user_id', 'test_name', 'test_date'],
            'idx_step84_lab_tests_user_name_date_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_lab_tests_user_name_date_desc ON health_lab_tests (user_id, test_name, test_date DESC)"
        );

        $this->indexIfColumnsExist(
            'health_alerts',
            ['user_id', 'severity', 'status'],
            'idx_step84_health_alerts_user_active_severity',
            "CREATE INDEX IF NOT EXISTS idx_step84_health_alerts_user_active_severity ON health_alerts (user_id, severity) WHERE status = 'active'"
        );

        $this->indexIfColumnsExist(
            'projects',
            ['user_id', 'target_end_date', 'status'],
            'idx_step84_projects_user_overdue_open',
            "CREATE INDEX IF NOT EXISTS idx_step84_projects_user_overdue_open ON projects (user_id, target_end_date) WHERE target_end_date IS NOT NULL AND status NOT IN ('completed', 'cancelled')"
        );

        $this->indexIfColumnsExist(
            'projects',
            ['user_id', 'updated_at'],
            'idx_step84_projects_user_updated_at',
            "CREATE INDEX IF NOT EXISTS idx_step84_projects_user_updated_at ON projects (user_id, updated_at)"
        );

        $this->indexIfColumnsExist(
            'project_tasks',
            ['project_id', 'task_order', 'created_at'],
            'idx_step84_project_tasks_project_order_created',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_tasks_project_order_created ON project_tasks (project_id, task_order, created_at)"
        );

        $this->indexIfColumnsExist(
            'project_milestones',
            ['project_id', 'target_date', 'created_at'],
            'idx_step84_project_milestones_project_target_created',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_milestones_project_target_created ON project_milestones (project_id, target_date, created_at)"
        );

        $this->indexIfColumnsExist(
            'project_status_updates',
            ['project_id', 'created_at'],
            'idx_step84_project_updates_project_created_desc',
            "CREATE INDEX IF NOT EXISTS idx_step84_project_updates_project_created_desc ON project_status_updates (project_id, created_at DESC)"
        );

        $this->indexIfColumnsExist(
            'ai_recommendations',
            ['user_id', 'module', 'status', 'priority', 'generated_at', 'deleted_at'],
            'idx_step84_ai_recs_active_feed',
            "CREATE INDEX IF NOT EXISTS idx_step84_ai_recs_active_feed ON ai_recommendations (user_id, module, status, priority, generated_at DESC) WHERE deleted_at IS NULL"
        );

        $this->indexIfColumnsExist(
            'ai_recommendations',
            ['user_id', 'expires_at', 'deleted_at'],
            'idx_step84_ai_recs_not_expired',
            "CREATE INDEX IF NOT EXISTS idx_step84_ai_recs_not_expired ON ai_recommendations (user_id, expires_at) WHERE deleted_at IS NULL AND expires_at IS NOT NULL"
        );

        $this->indexIfColumnsExist(
            'life_notifications',
            ['user_id', 'created_at', 'is_read'],
            'idx_step84_life_notifications_unread',
            "CREATE INDEX IF NOT EXISTS idx_step84_life_notifications_unread ON life_notifications (user_id, created_at DESC) WHERE is_read = false"
        );

        // Your current automation_rules table does not have next_run_at.
        // Use last_triggered_at when available, otherwise use updated_at/created_at.
        if ($this->tableHasColumns('automation_rules', ['user_id', 'is_active', 'next_run_at'])) {
            DB::statement("CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_next_run ON automation_rules (user_id, is_active, next_run_at) WHERE is_active = true");
        } elseif ($this->tableHasColumns('automation_rules', ['user_id', 'is_active', 'last_triggered_at'])) {
            DB::statement("CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_last_triggered ON automation_rules (user_id, is_active, last_triggered_at) WHERE is_active = true");
        } elseif ($this->tableHasColumns('automation_rules', ['user_id', 'is_active', 'updated_at'])) {
            DB::statement("CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_updated ON automation_rules (user_id, is_active, updated_at) WHERE is_active = true");
        } elseif ($this->tableHasColumns('automation_rules', ['user_id', 'is_active', 'created_at'])) {
            DB::statement("CREATE INDEX IF NOT EXISTS idx_step84_automation_rules_user_active_created ON automation_rules (user_id, is_active, created_at) WHERE is_active = true");
        }
    }

    public function down(): void
    {
        foreach ([
            'idx_step84_finance_tx_user_date_type_amount',
            'idx_step84_finance_tx_user_account_date_desc',
            'idx_step84_health_nutrition_user_date_type',
            'idx_step84_health_meal_logs_user_date_type',
            'idx_step84_health_step_log_user_date',
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
            'idx_step84_automation_rules_user_active_last_triggered',
            'idx_step84_automation_rules_user_active_updated',
            'idx_step84_automation_rules_user_active_created',
        ] as $index) {
            DB::statement("DROP INDEX IF EXISTS {$index}");
        }
    }

    private function indexIfColumnsExist(string $table, array $columns, string $indexName, string $sql): void
    {
        if ($this->tableHasColumns($table, $columns)) {
            DB::statement($sql);
        }
    }

    private function tableHasColumns(string $table, array $columns): bool
    {
        if (! Schema::hasTable($table)) {
            return false;
        }

        foreach ($columns as $column) {
            if (! Schema::hasColumn($table, $column)) {
                return false;
            }
        }

        return true;
    }
};

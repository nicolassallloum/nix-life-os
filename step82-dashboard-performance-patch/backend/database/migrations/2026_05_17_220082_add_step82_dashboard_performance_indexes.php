<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->indexIfTableAndColumns('finance_accounts', 'idx_step82_finance_accounts_user_active', ['user_id', 'is_active']);
        $this->indexIfTableAndColumns('finance_transactions', 'idx_step82_finance_transactions_user_type_date', ['user_id', 'transaction_type', 'transaction_date']);
        $this->indexIfTableAndColumns('finance_transactions', 'idx_step82_finance_transactions_user_account_date', ['user_id', 'account_id', 'transaction_date']);
        $this->indexIfTableAndColumns('finance_budgets', 'idx_step82_finance_budgets_user_month_active', ['user_id', 'budget_month', 'is_active']);

        $this->indexIfTableAndColumns('health_step_log', 'idx_step82_health_step_log_user_date', ['user_id', 'log_date']);
        $this->indexIfTableAndColumns('health_step_logs', 'idx_step82_health_step_logs_user_date', ['user_id', 'log_date']);
        $this->indexIfTableAndColumns('health_hydration_logs', 'idx_step82_health_hydration_user_date', ['user_id', 'log_date']);
        $this->indexIfTableAndColumns('health_weight_logs', 'idx_step82_health_weight_user_date', ['user_id', 'log_date']);
        $this->indexIfTableAndColumns('health_nutrition_logs', 'idx_step82_health_nutrition_user_date', ['user_id', 'log_date']);
        $this->indexIfTableAndColumns('health_lab_tests', 'idx_step82_health_lab_tests_user_date', ['user_id', 'test_date']);
        $this->indexIfTableAndColumns('health_alerts', 'idx_step82_health_alerts_user_status', ['user_id', 'status']);

        $this->indexIfTableAndColumns('projects', 'idx_step82_projects_user_status', ['user_id', 'status']);
        $this->indexIfTableAndColumns('project_tasks', 'idx_step82_project_tasks_user_status_due', ['user_id', 'status', 'due_date']);
        $this->indexIfTableAndColumns('project_milestones', 'idx_step82_project_milestones_user_status', ['user_id', 'status']);

        $this->indexIfTableAndColumns('productivity_tasks', 'idx_step82_productivity_tasks_user_status_due', ['user_id', 'status', 'due_date']);
        $this->indexIfTableAndColumns('productivity_goals', 'idx_step82_productivity_goals_user_status_target', ['user_id', 'status', 'target_date']);
        $this->indexIfTableAndColumns('productivity_habits', 'idx_step82_productivity_habits_user_status', ['user_id', 'status']);
        $this->indexIfTableAndColumns('productivity_calendar_events', 'idx_step82_productivity_calendar_user_start_status', ['user_id', 'start_time', 'status']);

        $this->indexIfTableAndColumns('ai_recommendations', 'idx_step82_ai_recommendations_user_module_status', ['user_id', 'module', 'status']);
        $this->indexIfTableAndColumns('notifications', 'idx_step82_notifications_user_read_created', ['user_id', 'read_at', 'created_at']);
    }

    public function down(): void
    {
        foreach ([
            ['finance_accounts', 'idx_step82_finance_accounts_user_active'],
            ['finance_transactions', 'idx_step82_finance_transactions_user_type_date'],
            ['finance_transactions', 'idx_step82_finance_transactions_user_account_date'],
            ['finance_budgets', 'idx_step82_finance_budgets_user_month_active'],
            ['health_step_log', 'idx_step82_health_step_log_user_date'],
            ['health_step_logs', 'idx_step82_health_step_logs_user_date'],
            ['health_hydration_logs', 'idx_step82_health_hydration_user_date'],
            ['health_weight_logs', 'idx_step82_health_weight_user_date'],
            ['health_nutrition_logs', 'idx_step82_health_nutrition_user_date'],
            ['health_lab_tests', 'idx_step82_health_lab_tests_user_date'],
            ['health_alerts', 'idx_step82_health_alerts_user_status'],
            ['projects', 'idx_step82_projects_user_status'],
            ['project_tasks', 'idx_step82_project_tasks_user_status_due'],
            ['project_milestones', 'idx_step82_project_milestones_user_status'],
            ['productivity_tasks', 'idx_step82_productivity_tasks_user_status_due'],
            ['productivity_goals', 'idx_step82_productivity_goals_user_status_target'],
            ['productivity_habits', 'idx_step82_productivity_habits_user_status'],
            ['productivity_calendar_events', 'idx_step82_productivity_calendar_user_start_status'],
            ['ai_recommendations', 'idx_step82_ai_recommendations_user_module_status'],
            ['notifications', 'idx_step82_notifications_user_read_created'],
        ] as [$table, $index]) {
            $this->dropIndexIfExists($table, $index);
        }
    }

    private function indexIfTableAndColumns(string $table, string $indexName, array $columns): void
    {
        if (! Schema::hasTable($table)) {
            return;
        }

        foreach ($columns as $column) {
            if (! Schema::hasColumn($table, $column)) {
                return;
            }
        }

        $columnList = implode(', ', array_map(fn ($column) => '"'.$column.'"', $columns));
        DB::statement("CREATE INDEX IF NOT EXISTS {$indexName} ON {$table} ({$columnList})");
    }

    private function dropIndexIfExists(string $table, string $indexName): void
    {
        if (! Schema::hasTable($table)) {
            return;
        }

        DB::statement("DROP INDEX IF EXISTS {$indexName}");
    }
};

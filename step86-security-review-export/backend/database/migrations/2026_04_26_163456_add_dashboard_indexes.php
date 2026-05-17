<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        /*
         |--------------------------------------------------------------------------
         | Dashboard Performance Indexes
         |--------------------------------------------------------------------------
         | This migration is safe for local Docker and production environments.
         | It checks if each table exists before creating indexes.
         */

        if (Schema::hasTable('finance_accounts')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_accounts_user_id ON finance_accounts (user_id)');
        }

        if (Schema::hasTable('finance_transactions')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_id ON finance_transactions (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_transactions_transaction_date ON finance_transactions (transaction_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_date ON finance_transactions (user_id, transaction_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_transactions_category_id ON finance_transactions (category_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_finance_transactions_account_id ON finance_transactions (account_id)');
        }

        if (Schema::hasTable('health_weight_logs')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_id ON health_weight_logs (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_weight_logs_log_date ON health_weight_logs (log_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_date ON health_weight_logs (user_id, log_date)');
        }

        if (Schema::hasTable('health_step_logs')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_id ON health_step_logs (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_step_logs_step_date ON health_step_logs (step_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_date ON health_step_logs (user_id, step_date)');
        }

        if (Schema::hasTable('health_meal_logs')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_id ON health_meal_logs (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_meal_logs_meal_date ON health_meal_logs (meal_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_date ON health_meal_logs (user_id, meal_date)');
        }

        if (Schema::hasTable('health_hydration_logs')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_id ON health_hydration_logs (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_log_date ON health_hydration_logs (log_date)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_date ON health_hydration_logs (user_id, log_date)');
        }

        if (Schema::hasTable('projects')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects (user_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_projects_status ON projects (status)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_projects_user_status ON projects (user_id, status)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_projects_priority ON projects (priority)');
        }

        if (Schema::hasTable('project_tasks')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_project_tasks_project_id ON project_tasks (project_id)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_project_tasks_status ON project_tasks (status)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_project_tasks_priority ON project_tasks (priority)');
            DB::statement('CREATE INDEX IF NOT EXISTS idx_project_tasks_due_date ON project_tasks (due_date)');
        }
    }

    public function down(): void
    {
        $indexes = [
            'idx_finance_accounts_user_id',

            'idx_finance_transactions_user_id',
            'idx_finance_transactions_transaction_date',
            'idx_finance_transactions_user_date',
            'idx_finance_transactions_category_id',
            'idx_finance_transactions_account_id',

            'idx_health_weight_logs_user_id',
            'idx_health_weight_logs_log_date',
            'idx_health_weight_logs_user_date',

            'idx_health_step_logs_user_id',
            'idx_health_step_logs_step_date',
            'idx_health_step_logs_user_date',

            'idx_health_meal_logs_user_id',
            'idx_health_meal_logs_meal_date',
            'idx_health_meal_logs_user_date',

            'idx_health_hydration_logs_user_id',
            'idx_health_hydration_logs_log_date',
            'idx_health_hydration_logs_user_date',

            'idx_projects_user_id',
            'idx_projects_status',
            'idx_projects_user_status',
            'idx_projects_priority',

            'idx_project_tasks_project_id',
            'idx_project_tasks_status',
            'idx_project_tasks_priority',
            'idx_project_tasks_due_date',
        ];

        foreach ($indexes as $index) {
            DB::statement("DROP INDEX IF EXISTS {$index}");
        }
    }
};

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
        | Finance Indexes
        |--------------------------------------------------------------------------
        */

        if (Schema::hasTable('finance_transactions')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_date
                ON finance_transactions (user_id, transaction_date DESC)
            ");

            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_type_date
                ON finance_transactions (user_id, transaction_type, transaction_date DESC)
            ");

            if (Schema::hasColumn('finance_transactions', 'category_id')) {
                DB::statement("
                    CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_category
                    ON finance_transactions (user_id, category_id)
                ");
            }
        }

        if (Schema::hasTable('finance_accounts')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_finance_accounts_user
                ON finance_accounts (user_id)
            ");
        }

        /*
        |--------------------------------------------------------------------------
        | Health Indexes
        |--------------------------------------------------------------------------
        */

        if (Schema::hasTable('health_weight_logs')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_date
                ON health_weight_logs (user_id, log_date DESC)
            ");
        }

        if (Schema::hasTable('health_step_logs')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_date
                ON health_step_logs (user_id, log_date DESC)
            ");
        }

        if (Schema::hasTable('health_hydration_logs')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_date
                ON health_hydration_logs (user_id, log_date DESC)
            ");
        }

        if (Schema::hasTable('health_meal_logs')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_date
                ON health_meal_logs (user_id, meal_date DESC)
            ");
        }

        /*
        |--------------------------------------------------------------------------
        | Project Indexes
        |--------------------------------------------------------------------------
        */

        if (Schema::hasTable('projects')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_projects_user_status
                ON projects (user_id, status)
            ");
        }

        if (Schema::hasTable('project_tasks')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_project_tasks_user_status
                ON project_tasks (user_id, status)
            ");

            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_project_tasks_project_status
                ON project_tasks (project_id, status)
            ");
        }

        /*
        |--------------------------------------------------------------------------
        | Notification Indexes
        |--------------------------------------------------------------------------
        | Only created if notification tables already exist.
        |--------------------------------------------------------------------------
        */

        if (Schema::hasTable('notifications')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_notifications_user_read_created
                ON notifications (user_id, is_read, created_at DESC)
            ");
        }

        /*
        |--------------------------------------------------------------------------
        | Automation Indexes
        |--------------------------------------------------------------------------
        | Only created if automation tables already exist.
        |--------------------------------------------------------------------------
        */

        if (Schema::hasTable('automation_rules')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_automation_rules_user_active
                ON automation_rules (user_id, is_active)
            ");
        }

        if (Schema::hasTable('automation_logs')) {
            DB::statement("
                CREATE INDEX IF NOT EXISTS idx_automation_logs_user_created
                ON automation_logs (user_id, created_at DESC)
            ");
        }
    }

    public function down(): void
    {
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_type_date");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_category");
        DB::statement("DROP INDEX IF EXISTS idx_finance_accounts_user");

        DB::statement("DROP INDEX IF EXISTS idx_health_weight_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_step_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_hydration_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_meal_logs_user_date");

        DB::statement("DROP INDEX IF EXISTS idx_projects_user_status");
        DB::statement("DROP INDEX IF EXISTS idx_project_tasks_user_status");
        DB::statement("DROP INDEX IF EXISTS idx_project_tasks_project_status");

        DB::statement("DROP INDEX IF EXISTS idx_notifications_user_read_created");

        DB::statement("DROP INDEX IF EXISTS idx_automation_rules_user_active");
        DB::statement("DROP INDEX IF EXISTS idx_automation_logs_user_created");
    }
};
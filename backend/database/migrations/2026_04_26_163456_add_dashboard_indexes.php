<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_accounts_user_id
            ON nix_life_os.finance_account (user_id)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_type_date
            ON nix_life_os.finance_transaction (user_id, transaction_type, transaction_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_date
            ON nix_life_os.health_step_log (user_id, log_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_date
            ON health_hydration_logs (user_id, log_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_date
            ON health_meal_logs (user_id, meal_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_date
            ON health_weight_logs (user_id, log_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_projects_user_status_priority
            ON projects (user_id, status, priority)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_projects_user_target_end_date
            ON projects (user_id, target_end_date)
        ");
    }

    public function down(): void
    {
        DB::statement("DROP INDEX IF EXISTS idx_finance_accounts_user_id");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_type_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_step_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_hydration_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_meal_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_weight_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_projects_user_status_priority");
        DB::statement("DROP INDEX IF EXISTS idx_projects_user_target_end_date");
    }
};
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * STEP 80 — Database Integrity Stabilization
     *
     * Purpose:
     * - Adds missing user_id foreign keys safely.
     * - Cleans existing orphan records before adding constraints.
     * - Adds missing FK indexes detected by PostgreSQL integrity checks.
     * - Keeps audit/error logs by setting orphan user_id values to NULL.
     * - Deletes orphan rows from true user-owned operational tables.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        // User-owned tables: orphan rows cannot safely belong to any account, so delete them.
        $this->addUserForeignKey('ai_predictions', 'cascade', 'delete');
        $this->addUserForeignKey('ai_recommendations', 'cascade', 'delete');
        $this->addUserForeignKey('ai_user_daily_scores', 'cascade', 'delete');
        $this->addUserForeignKey('finance_accounts', 'cascade', 'delete');
        $this->addUserForeignKey('finance_budget_lines', 'cascade', 'delete');
        $this->addUserForeignKey('finance_budgets', 'cascade', 'delete');
        $this->addUserForeignKey('finance_transactions', 'cascade', 'delete');
        $this->addUserForeignKey('health_lab_tests', 'cascade', 'delete');
        $this->addUserForeignKey('health_medication_dose_logs', 'cascade', 'delete');
        $this->addUserForeignKey('health_nutrition_profiles', 'cascade', 'delete');
        $this->addUserForeignKey('health_profile', 'cascade', 'delete');
        $this->addUserForeignKey('health_step_log', 'cascade', 'delete');
        $this->addUserForeignKey('health_weight_logs', 'cascade', 'delete');
        $this->addUserForeignKey('life_balance_scores', 'cascade', 'delete');
        $this->addUserForeignKey('life_notifications', 'cascade', 'delete');
        $this->addUserForeignKey('notification_preferences', 'cascade', 'delete');
        $this->addUserForeignKey('nutrition_custom_foods', 'cascade', 'delete');
        $this->addUserForeignKey('subscription_usage', 'cascade', 'delete');
        $this->addUserForeignKey('subscriptions', 'cascade', 'delete');

        // Log tables: preserve history, but remove invalid user reference.
        $this->addUserForeignKey('audit_logs', 'set null', 'nullify');
        $this->addUserForeignKey('error_logs', 'set null', 'nullify');

        // FK columns reported by integrity test as missing supporting indexes.
        $this->addIndexIfMissing('project_status_updates', 'milestone_id', 'idx_project_status_updates_milestone_id');
        $this->addIndexIfMissing('project_status_updates', 'task_id', 'idx_project_status_updates_task_id');
        $this->addIndexIfMissing('health_nutrition_logs', 'custom_food_id', 'idx_health_nutrition_logs_custom_food_id');
        $this->addIndexIfMissing('nutrition_food_sources', 'food_id', 'idx_nutrition_food_sources_food_id');

        // Real table name in this project is health_step_log, not health_step_logs.
        if (Schema::hasTable('health_step_log') && Schema::hasColumn('health_step_log', 'user_id') && Schema::hasColumn('health_step_log', 'log_date')) {
            DB::statement('CREATE INDEX IF NOT EXISTS idx_health_step_log_user_date_desc ON health_step_log (user_id, log_date DESC)');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        foreach ([
            'ai_predictions',
            'ai_recommendations',
            'ai_user_daily_scores',
            'audit_logs',
            'error_logs',
            'finance_accounts',
            'finance_budget_lines',
            'finance_budgets',
            'finance_transactions',
            'health_lab_tests',
            'health_medication_dose_logs',
            'health_nutrition_profiles',
            'health_profile',
            'health_step_log',
            'health_weight_logs',
            'life_balance_scores',
            'life_notifications',
            'notification_preferences',
            'nutrition_custom_foods',
            'subscription_usage',
            'subscriptions',
        ] as $table) {
            if (Schema::hasTable($table)) {
                $constraint = $this->fkName($table, 'user_id');
                DB::statement("ALTER TABLE {$table} DROP CONSTRAINT IF EXISTS {$constraint}");
            }
        }

        DB::statement('DROP INDEX IF EXISTS idx_project_status_updates_milestone_id');
        DB::statement('DROP INDEX IF EXISTS idx_project_status_updates_task_id');
        DB::statement('DROP INDEX IF EXISTS idx_health_nutrition_logs_custom_food_id');
        DB::statement('DROP INDEX IF EXISTS idx_nutrition_food_sources_food_id');
        DB::statement('DROP INDEX IF EXISTS idx_health_step_log_user_date_desc');
    }

    private function addUserForeignKey(string $table, string $onDelete, string $orphanAction): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, 'user_id') || ! Schema::hasTable('users')) {
            return;
        }

        $constraint = $this->fkName($table, 'user_id');
        $deleteAction = match ($onDelete) {
            'set null' => 'ON DELETE SET NULL',
            'restrict' => 'ON DELETE RESTRICT',
            default => 'ON DELETE CASCADE',
        };

        $quotedTable = $this->quoteIdentifier($table);
        $quotedConstraint = $this->quoteIdentifier($constraint);

        DB::statement("CREATE INDEX IF NOT EXISTS idx_{$table}_user_id ON {$quotedTable} (user_id)");

        if ($orphanAction === 'nullify') {
            DB::statement("\n                UPDATE {$quotedTable} child\n                SET user_id = NULL\n                WHERE child.user_id IS NOT NULL\n                  AND NOT EXISTS (\n                      SELECT 1\n                      FROM users parent\n                      WHERE parent.id = child.user_id\n                  )\n            ");
        } else {
            DB::statement("\n                DELETE FROM {$quotedTable} child\n                WHERE child.user_id IS NOT NULL\n                  AND NOT EXISTS (\n                      SELECT 1\n                      FROM users parent\n                      WHERE parent.id = child.user_id\n                  )\n            ");
        }

        DB::statement("\n            DO $$\n            BEGIN\n                IF NOT EXISTS (\n                    SELECT 1\n                    FROM pg_constraint\n                    WHERE conname = '{$constraint}'\n                      AND conrelid = '{$table}'::regclass\n                ) THEN\n                    ALTER TABLE {$quotedTable}\n                    ADD CONSTRAINT {$quotedConstraint}\n                    FOREIGN KEY (user_id)\n                    REFERENCES users(id)\n                    {$deleteAction};\n                END IF;\n            END\n            $$;\n        ");
    }

    private function addIndexIfMissing(string $table, string $column, string $indexName): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, $column)) {
            return;
        }

        $quotedTable = $this->quoteIdentifier($table);
        $quotedColumn = $this->quoteIdentifier($column);
        $quotedIndex = $this->quoteIdentifier($indexName);

        DB::statement("CREATE INDEX IF NOT EXISTS {$quotedIndex} ON {$quotedTable} ({$quotedColumn})");
    }

    private function fkName(string $table, string $column): string
    {
        return substr("{$table}_{$column}_foreign_step80", 0, 63);
    }

    private function quoteIdentifier(string $identifier): string
    {
        return '"' . str_replace('"', '""', $identifier) . '"';
    }
};

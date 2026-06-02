<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('finance_transactions') || ! Schema::hasColumn('finance_transactions', 'transaction_type')) {
            return;
        }

        DB::statement('ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_type_check');
        DB::statement('ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_transaction_type_check');

        DB::statement("
            ALTER TABLE finance_transactions
            ADD CONSTRAINT finance_transactions_transaction_type_check
            CHECK (transaction_type IN ('income', 'expense', 'transfer'))
        ");
    }

    public function down(): void
    {
        if (! Schema::hasTable('finance_transactions') || ! Schema::hasColumn('finance_transactions', 'transaction_type')) {
            return;
        }

        DB::statement('ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_type_check');
        DB::statement('ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_transaction_type_check');

        DB::statement("
            ALTER TABLE finance_transactions
            ADD CONSTRAINT finance_transactions_transaction_type_check
            CHECK (transaction_type IN ('income', 'expense'))
        ");
    }
};

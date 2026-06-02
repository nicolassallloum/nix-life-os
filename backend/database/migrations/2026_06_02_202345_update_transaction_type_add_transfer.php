<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
         * Run the migrations.
         */
    public function up(): void
    {
        DB::statement("ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_type_check");

        DB::statement("
            ALTER TABLE finance_transactions
            ADD CONSTRAINT finance_transactions_type_check
            CHECK (type IN ('income', 'expense', 'transfer'))
        ");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE finance_transactions DROP CONSTRAINT IF EXISTS finance_transactions_type_check");

        DB::statement("
            ALTER TABLE finance_transactions
            ADD CONSTRAINT finance_transactions_type_check
            CHECK (type IN ('income', 'expense'))
        ");
    }
};

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('finance_transactions')) {
            return;
        }

        /*
         |--------------------------------------------------------------------------
         | PostgreSQL-only migration
         |--------------------------------------------------------------------------
         |
         | This migration uses PostgreSQL syntax:
         | - CREATE EXTENSION
         | - ALTER COLUMN SET DEFAULT
         | - ALTER COLUMN DROP NOT NULL
         |
         | SQLite is used during automated tests, so we skip this migration
         | when the active database driver is not PostgreSQL.
         |
         */
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('CREATE EXTENSION IF NOT EXISTS pgcrypto');

        DB::statement("
            ALTER TABLE finance_transactions
            ALTER COLUMN id SET DEFAULT gen_random_uuid()
        ");

        if (Schema::hasColumn('finance_transactions', 'currency_code')) {
            DB::statement("
                ALTER TABLE finance_transactions
                ALTER COLUMN currency_code SET DEFAULT 'USD'
            ");
        }

        foreach ([
            'account_id',
            'transfer_account_id',
            'to_account_id',
            'category_id',
            'transaction_date',
            'description',
            'notes',
            'reference_no',
            'metadata_json',
        ] as $column) {
            if (Schema::hasColumn('finance_transactions', $column)) {
                DB::statement("ALTER TABLE finance_transactions ALTER COLUMN {$column} DROP NOT NULL");
            }
        }
    }

    public function down(): void
    {
        //
    }
};
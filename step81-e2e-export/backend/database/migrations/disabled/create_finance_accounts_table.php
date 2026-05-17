create_finance_accounts_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        DB::statement("
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_type_enum') THEN
                    CREATE TYPE nix_life_os.account_type_enum AS ENUM ('main', 'savings');
                END IF;
            END$$;
        ");

        DB::statement("
            CREATE TABLE nix_life_os.finance_account (
                account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
                account_name VARCHAR(100) NOT NULL,
                account_type nix_life_os.account_type_enum NOT NULL,
                currency_code VARCHAR(3) NOT NULL DEFAULT 'USD',
                opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
                current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
                description TEXT,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                CONSTRAINT chk_finance_account_currency CHECK (char_length(currency_code) = 3)
            )
        ");

        DB::statement("
            CREATE UNIQUE INDEX uq_finance_account_user_name
            ON nix_life_os.finance_account (user_id, lower(account_name))
        ");

        DB::statement("
            CREATE INDEX idx_finance_account_user
            ON nix_life_os.finance_account (user_id)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.finance_account');
    }
};

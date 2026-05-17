<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        DB::statement("CREATE SCHEMA IF NOT EXISTS nix_life_os");

        DB::statement("
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type_enum') THEN
                    CREATE TYPE nix_life_os.transaction_type_enum AS ENUM ('income', 'expense', 'transfer');
                END IF;
            END$$;
        ");

        DB::statement("
            CREATE TABLE nix_life_os.finance_category (
                category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
                category_name VARCHAR(100) NOT NULL,
                category_type nix_life_os.transaction_type_enum NOT NULL,
                icon VARCHAR(100),
                color_code VARCHAR(20),
                is_system BOOLEAN NOT NULL DEFAULT FALSE,
                is_active BOOLEAN NOT NULL DEFAULT TRUE,
                notes TEXT,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                CONSTRAINT chk_category_type_no_transfer CHECK (category_type IN ('income', 'expense'))
            )
        ");

        DB::statement("
            CREATE UNIQUE INDEX uq_finance_category_user_name_type
            ON nix_life_os.finance_category (user_id, lower(category_name), category_type)
        ");

        DB::statement("
            CREATE INDEX idx_finance_category_user
            ON nix_life_os.finance_category (user_id)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.finance_category');
    }
};
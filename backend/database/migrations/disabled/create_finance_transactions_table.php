<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        DB::statement("
            CREATE TABLE nix_life_os.finance_transaction (
                transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
                transaction_type nix_life_os.transaction_type_enum NOT NULL,
                account_id UUID NOT NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE CASCADE,
                transfer_account_id UUID NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE CASCADE,
                category_id UUID NULL REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
                amount NUMERIC(18,2) NOT NULL,
                transaction_date DATE NOT NULL,
                description TEXT,
                reference_no VARCHAR(100),
                metadata_json JSONB NOT NULL DEFAULT '{}'::JSONB,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                CONSTRAINT chk_finance_transaction_amount_positive CHECK (amount > 0),
                CONSTRAINT chk_finance_transaction_transfer_rules CHECK (
                    (transaction_type IN ('income', 'expense') AND transfer_account_id IS NULL)
                    OR
                    (transaction_type = 'transfer' AND transfer_account_id IS NOT NULL AND transfer_account_id <> account_id)
                )
            )
        ");

        DB::statement("CREATE INDEX idx_finance_transaction_user ON nix_life_os.finance_transaction (user_id)");
        DB::statement("CREATE INDEX idx_finance_transaction_account ON nix_life_os.finance_transaction (account_id)");
        DB::statement("CREATE INDEX idx_finance_transaction_transfer_account ON nix_life_os.finance_transaction (transfer_account_id)");
        DB::statement("CREATE INDEX idx_finance_transaction_category ON nix_life_os.finance_transaction (category_id)");
        DB::statement("CREATE INDEX idx_finance_transaction_date ON nix_life_os.finance_transaction (transaction_date)");
        DB::statement("CREATE INDEX idx_finance_transaction_type ON nix_life_os.finance_transaction (transaction_type)");
    }

    public function down(): void
    {
        Schema::dropIfExists('nix_life_os.finance_transaction');
    }
};
CREATE SCHEMA IF NOT EXISTS nix_life_os;

CREATE TABLE IF NOT EXISTS nix_life_os.finance_account (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(100) NOT NULL DEFAULT 'cash',
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    initial_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(15,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nix_life_os.finance_category (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_name VARCHAR(255) NOT NULL,
    category_type VARCHAR(50) NOT NULL DEFAULT 'expense',
    color VARCHAR(50) NULL,
    icon VARCHAR(100) NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nix_life_os.finance_transaction (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    account_id UUID NULL,
    category_id UUID NULL,
    transaction_type VARCHAR(50) NOT NULL DEFAULT 'expense',
    amount NUMERIC(15,2) NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    description TEXT NULL,
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    metadata JSONB NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nix_life_os.finance_budget (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    category_id UUID NULL,
    budget_name VARCHAR(255) NOT NULL,
    budget_month VARCHAR(7) NULL,
    amount NUMERIC(15,2) NOT NULL DEFAULT 0,
    spent_amount NUMERIC(15,2) NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata JSONB NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_finance_account_user_id
ON nix_life_os.finance_account(user_id);

CREATE INDEX IF NOT EXISTS idx_finance_category_user_id
ON nix_life_os.finance_category(user_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_user_id
ON nix_life_os.finance_transaction(user_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_account_id
ON nix_life_os.finance_transaction(account_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_category_id
ON nix_life_os.finance_transaction(category_id);

CREATE INDEX IF NOT EXISTS idx_finance_budget_user_id
ON nix_life_os.finance_budget(user_id);

CREATE INDEX IF NOT EXISTS idx_finance_budget_category_id
ON nix_life_os.finance_budget(category_id);

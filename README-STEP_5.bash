STEP 5 — Finance Backend

This builds the finance backend for:

Accounts: Main + Savings
Transactions: income, expense, transfer
Categories
CRUD APIs

It assumes:

Laravel backend already exists
PostgreSQL is being used
Auth from STEP 4 is ready
app_user.user_id is the main user PK in schema nix_life_os
1) PostgreSQL Design
Core rules
Each user can have multiple accounts
Default account types:
main
savings
Transactions support:
income
expense
transfer
Transfers move money between two accounts
Categories are user-level and reusable
Balances are derived from transactions, but we can also cache them in finance_account.current_balance
All finance tables live under nix_life_os
2) PostgreSQL Schema

Use this as your reference design.

CREATE SCHEMA IF NOT EXISTS nix_life_os;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_type_enum') THEN
        CREATE TYPE nix_life_os.account_type_enum AS ENUM ('main', 'savings');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type_enum') THEN
        CREATE TYPE nix_life_os.transaction_type_enum AS ENUM ('income', 'expense', 'transfer');
    END IF;
END$$;

DROP TABLE nix_life_os.finance_category cascade
CREATE TABLE IF NOT EXISTS nix_life_os.finance_category (
    category_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    category_name        VARCHAR(100) NOT NULL,
    category_type        nix_life_os.transaction_type_enum NOT NULL,
    icon                 VARCHAR(100),
    color_code           VARCHAR(20),
    is_system            BOOLEAN NOT NULL DEFAULT FALSE,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    notes                TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_category_type_no_transfer
        CHECK (category_type IN ('income', 'expense'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_finance_category_user_name_type
    ON nix_life_os.finance_category (user_id, lower(category_name), category_type);

CREATE INDEX IF NOT EXISTS idx_finance_category_user
    ON nix_life_os.finance_category (user_id);

DROP TABLE nix_life_os.finance_account cascade
CREATE TABLE IF NOT EXISTS nix_life_os.finance_account (
    account_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    account_name         VARCHAR(100) NOT NULL,
    account_type         nix_life_os.account_type_enum NOT NULL,
    currency_code        VARCHAR(3) NOT NULL DEFAULT 'USD',
    opening_balance      NUMERIC(18,2) NOT NULL DEFAULT 0,
    current_balance      NUMERIC(18,2) NOT NULL DEFAULT 0,
    description          TEXT,
    is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_finance_account_currency
        CHECK (char_length(currency_code) = 3)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_finance_account_user_name
    ON nix_life_os.finance_account (user_id, lower(account_name));

CREATE INDEX IF NOT EXISTS idx_finance_account_user
    ON nix_life_os.finance_account (user_id);

DROP TABLE nix_life_os.finance_transaction cascade
CREATE TABLE IF NOT EXISTS nix_life_os.finance_transaction (
    transaction_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                   UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    transaction_type          nix_life_os.transaction_type_enum NOT NULL,
    account_id                UUID NOT NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE CASCADE,
    transfer_account_id       UUID NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE CASCADE,
    category_id               UUID NULL REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
    amount                    NUMERIC(18,2) NOT NULL,
    transaction_date          DATE NOT NULL,
    description               TEXT,
    reference_no              VARCHAR(100),
    metadata_json             JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_finance_transaction_amount_positive
        CHECK (amount > 0),

    CONSTRAINT chk_finance_transaction_transfer_rules
        CHECK (
            (transaction_type IN ('income', 'expense') AND transfer_account_id IS NULL)
            OR
            (transaction_type = 'transfer' AND transfer_account_id IS NOT NULL AND transfer_account_id <> account_id)
        )
);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_user
    ON nix_life_os.finance_transaction (user_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_account
    ON nix_life_os.finance_transaction (account_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_transfer_account
    ON nix_life_os.finance_transaction (transfer_account_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_category
    ON nix_life_os.finance_transaction (category_id);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_date
    ON nix_life_os.finance_transaction (transaction_date);

CREATE INDEX IF NOT EXISTS idx_finance_transaction_type
    ON nix_life_os.finance_transaction (transaction_type);
3) Optional Balance Rebuild Function

This is useful after imports, edits, or debugging.

CREATE OR REPLACE FUNCTION nix_life_os.fn_rebuild_account_balance(p_account_id UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_opening_balance NUMERIC(18,2);
    v_user_id UUID;
    v_balance NUMERIC(18,2);
BEGIN
    SELECT opening_balance, user_id
    INTO v_opening_balance, v_user_id
    FROM nix_life_os.finance_account
    WHERE account_id = p_account_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Account not found: %', p_account_id;
    END IF;

    SELECT
        COALESCE(v_opening_balance, 0)
        + COALESCE(SUM(
            CASE
                WHEN transaction_type = 'income' AND account_id = p_account_id THEN amount
                WHEN transaction_type = 'expense' AND account_id = p_account_id THEN -amount
                WHEN transaction_type = 'transfer' AND account_id = p_account_id THEN -amount
                WHEN transaction_type = 'transfer' AND transfer_account_id = p_account_id THEN amount
                ELSE 0
            END
        ), 0)
    INTO v_balance
    FROM nix_life_os.finance_transaction
    WHERE user_id = v_user_id
      AND (account_id = p_account_id OR transfer_account_id = p_account_id);

    UPDATE nix_life_os.finance_account
    SET current_balance = v_balance,
        updated_at = NOW()
    WHERE account_id = p_account_id;
END;
$$;
4) Laravel Folder Structure

Use this structure:

app/
 ├── Enums/
 │    ├── AccountType.php
 │    └── TransactionType.php
 ├── Http/
 │    ├── Controllers/Api/
 │    │    ├── FinanceAccountController.php
 │    │    ├── FinanceCategoryController.php
 │    │    └── FinanceTransactionController.php
 │    └── Requests/
 │         ├── StoreFinanceAccountRequest.php
 │         ├── UpdateFinanceAccountRequest.php
 │         ├── StoreFinanceCategoryRequest.php
 │         ├── UpdateFinanceCategoryRequest.php
 │         ├── StoreFinanceTransactionRequest.php
 │         └── UpdateFinanceTransactionRequest.php
 ├── Models/
 │    ├── FinanceAccount.php
 │    ├── FinanceCategory.php
 │    └── FinanceTransaction.php
 └── Services/
      └── FinanceBalanceService.php

database/
 └── migrations/
      ├── xxxx_create_finance_categories_table.php
      ├── xxxx_create_finance_accounts_table.php
      └── xxxx_create_finance_transactions_table.php
5) Laravel Enums
app/Enums/AccountType.php
<?php

namespace App\Enums;

enum AccountType: string
{
    case MAIN = 'main';
    case SAVINGS = 'savings';
}
app/Enums/TransactionType.php
<?php

namespace App\Enums;

enum TransactionType: string
{
    case INCOME = 'income';
    case EXPENSE = 'expense';
    case TRANSFER = 'transfer';
}
6) Laravel Models
app/Models/FinanceAccount.php
<?php

namespace App\Models;

use App\Enums\AccountType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FinanceAccount extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_account';
    protected $primaryKey = 'account_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'account_name',
        'account_type',
        'currency_code',
        'opening_balance',
        'current_balance',
        'description',
        'is_active',
    ];

    protected $casts = [
        'account_type' => AccountType::class,
        'opening_balance' => 'decimal:2',
        'current_balance' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(AppUser::class, 'user_id', 'user_id');
    }

    public function outgoingTransactions(): HasMany
    {
        return $this->hasMany(FinanceTransaction::class, 'account_id', 'account_id');
    }

    public function incomingTransfers(): HasMany
    {
        return $this->hasMany(FinanceTransaction::class, 'transfer_account_id', 'account_id');
    }
}
app/Models/FinanceCategory.php
<?php

namespace App\Models;

use App\Enums\TransactionType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FinanceCategory extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_category';
    protected $primaryKey = 'category_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'category_name',
        'category_type',
        'icon',
        'color_code',
        'is_system',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'category_type' => TransactionType::class,
        'is_system' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(AppUser::class, 'user_id', 'user_id');
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(FinanceTransaction::class, 'category_id', 'category_id');
    }
}
app/Models/FinanceTransaction.php
<?php

namespace App\Models;

use App\Enums\TransactionType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FinanceTransaction extends Model
{
    use HasUuids;

    protected $table = 'nix_life_os.finance_transaction';
    protected $primaryKey = 'transaction_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'transaction_type',
        'account_id',
        'transfer_account_id',
        'category_id',
        'amount',
        'transaction_date',
        'description',
        'reference_no',
        'metadata_json',
    ];

    protected $casts = [
        'transaction_type' => TransactionType::class,
        'amount' => 'decimal:2',
        'transaction_date' => 'date',
        'metadata_json' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(AppUser::class, 'user_id', 'user_id');
    }

    public function account(): BelongsTo
    {
        return $this->belongsTo(FinanceAccount::class, 'account_id', 'account_id');
    }

    public function transferAccount(): BelongsTo
    {
        return $this->belongsTo(FinanceAccount::class, 'transfer_account_id', 'account_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(FinanceCategory::class, 'category_id', 'category_id');
    }
}
7) Migrations
create_finance_categories_table.php
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
create_finance_transactions_table.php
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
8) Validation Requests
StoreFinanceAccountRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;
use App\Enums\AccountType;

class StoreFinanceAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_name' => ['required', 'string', 'max:100'],
            'account_type' => ['required', new Enum(AccountType::class)],
            'currency_code' => ['nullable', 'string', 'size:3'],
            'opening_balance' => ['nullable', 'numeric'],
            'description' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
UpdateFinanceAccountRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;
use App\Enums\AccountType;

class UpdateFinanceAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_name' => ['sometimes', 'string', 'max:100'],
            'account_type' => ['sometimes', new Enum(AccountType::class)],
            'currency_code' => ['sometimes', 'string', 'size:3'],
            'opening_balance' => ['sometimes', 'numeric'],
            'description' => ['nullable', 'string'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
StoreFinanceCategoryRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFinanceCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_name' => ['required', 'string', 'max:100'],
            'category_type' => ['required', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color_code' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
UpdateFinanceCategoryRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateFinanceCategoryRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_name' => ['sometimes', 'string', 'max:100'],
            'category_type' => ['sometimes', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color_code' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }
}
StoreFinanceTransactionRequest.php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFinanceTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'transaction_type' => ['required', Rule::in(['income', 'expense', 'transfer'])],
            'account_id' => ['required', 'uuid'],
            'transfer_account_id' => ['nullable', 'uuid'],
            'category_id' => ['nullable', 'uuid'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'transaction_date' => ['required', 'date'],
            'description' => ['nullable', 'string'],
            'reference_no' => ['nullable', 'string', 'max:100'],
            'metadata_json' => ['nullable', 'array'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $type = $this->input('transaction_type');

            if (in_array($type, ['income', 'expense'], true) && $this->filled('transfer_account_id')) {
                $validator->errors()->add('transfer_account_id', 'transfer_account_id must be null for income or expense.');
            }

            if ($type === 'transfer' && !$this->filled('transfer_account_id')) {
                $validator->errors()->add('transfer_account_id', 'transfer_account_id is required for transfer.');
            }

            if ($type === 'transfer' && $this->input('transfer_account_id') === $this->input('account_id')) {
                $validator->errors()->add('transfer_account_id', 'Transfer account must be different from account_id.');
            }
        });
    }
}
UpdateFinanceTransactionRequest.php
<?php

namespace App\Http\Requests;

class UpdateFinanceTransactionRequest extends StoreFinanceTransactionRequest
{
}
9) Balance Service
app/Services/FinanceBalanceService.php
<?php

namespace App\Services;

use App\Enums\TransactionType;
use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use Illuminate\Support\Facades\DB;

class FinanceBalanceService
{
    public function rebuildAccountBalance(string $accountId): void
    {
        $account = FinanceAccount::query()->findOrFail($accountId);

        $balance = (float) $account->opening_balance;

        $transactions = FinanceTransaction::query()
            ->where('user_id', $account->user_id)
            ->where(function ($query) use ($accountId) {
                $query->where('account_id', $accountId)
                      ->orWhere('transfer_account_id', $accountId);
            })
            ->get();

        foreach ($transactions as $tx) {
            if ($tx->transaction_type === TransactionType::INCOME && $tx->account_id === $accountId) {
                $balance += (float) $tx->amount;
            }

            if ($tx->transaction_type === TransactionType::EXPENSE && $tx->account_id === $accountId) {
                $balance -= (float) $tx->amount;
            }

            if ($tx->transaction_type === TransactionType::TRANSFER) {
                if ($tx->account_id === $accountId) {
                    $balance -= (float) $tx->amount;
                }

                if ($tx->transfer_account_id === $accountId) {
                    $balance += (float) $tx->amount;
                }
            }
        }

        $account->update([
            'current_balance' => $balance,
        ]);
    }

    public function rebuildMany(array $accountIds): void
    {
        $uniqueIds = array_values(array_unique(array_filter($accountIds)));

        foreach ($uniqueIds as $accountId) {
            $this->rebuildAccountBalance($accountId);
        }
    }
}
10) Controllers
app/Http/Controllers/Api/FinanceAccountController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceAccountRequest;
use App\Http\Requests\UpdateFinanceAccountRequest;
use App\Models\FinanceAccount;
use App\Services\FinanceBalanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinanceAccountController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $accounts = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->orderBy('account_name')
            ->get();

        return response()->json($accounts);
    }

    public function store(StoreFinanceAccountRequest $request): JsonResponse
    {
        $account = FinanceAccount::query()->create([
            'user_id' => $request->user()->user_id,
            'account_name' => $request->account_name,
            'account_type' => $request->account_type,
            'currency_code' => strtoupper($request->input('currency_code', 'USD')),
            'opening_balance' => $request->input('opening_balance', 0),
            'current_balance' => $request->input('opening_balance', 0),
            'description' => $request->description,
            'is_active' => $request->input('is_active', true),
        ]);

        return response()->json($account, 201);
    }

    public function show(Request $request, string $accountId): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        return response()->json($account);
    }

    public function update(UpdateFinanceAccountRequest $request, string $accountId, FinanceBalanceService $balanceService): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        $account->update([
            'account_name' => $request->input('account_name', $account->account_name),
            'account_type' => $request->input('account_type', $account->account_type?->value ?? $account->account_type),
            'currency_code' => strtoupper($request->input('currency_code', $account->currency_code)),
            'opening_balance' => $request->input('opening_balance', $account->opening_balance),
            'description' => $request->input('description', $account->description),
            'is_active' => $request->input('is_active', $account->is_active),
        ]);

        $balanceService->rebuildAccountBalance($account->account_id);

        return response()->json($account->fresh());
    }

    public function destroy(Request $request, string $accountId): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        $account->delete();

        return response()->json(['message' => 'Account deleted successfully.']);
    }
}
app/Http/Controllers/Api/FinanceCategoryController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceCategoryRequest;
use App\Http\Requests\UpdateFinanceCategoryRequest;
use App\Models\FinanceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinanceCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $categories = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->orderBy('category_type')
            ->orderBy('category_name')
            ->get();

        return response()->json($categories);
    }

    public function store(StoreFinanceCategoryRequest $request): JsonResponse
    {
        $category = FinanceCategory::query()->create([
            'user_id' => $request->user()->user_id,
            'category_name' => $request->category_name,
            'category_type' => $request->category_type,
            'icon' => $request->icon,
            'color_code' => $request->color_code,
            'notes' => $request->notes,
            'is_active' => $request->input('is_active', true),
            'is_system' => false,
        ]);

        return response()->json($category, 201);
    }

    public function show(Request $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        return response()->json($category);
    }

    public function update(UpdateFinanceCategoryRequest $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        $category->update($request->validated());

        return response()->json($category->fresh());
    }

    public function destroy(Request $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        $category->delete();

        return response()->json(['message' => 'Category deleted successfully.']);
    }
}
app/Http/Controllers/Api/FinanceTransactionController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceTransactionRequest;
use App\Http\Requests\UpdateFinanceTransactionRequest;
use App\Models\FinanceAccount;
use App\Models\FinanceCategory;
use App\Models\FinanceTransaction;
use App\Services\FinanceBalanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceTransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transactions = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $request->user()->user_id)
            ->when($request->filled('transaction_type'), fn ($q) => $q->where('transaction_type', $request->transaction_type))
            ->when($request->filled('account_id'), fn ($q) => $q->where('account_id', $request->account_id))
            ->when($request->filled('date_from'), fn ($q) => $q->whereDate('transaction_date', '>=', $request->date_from))
            ->when($request->filled('date_to'), fn ($q) => $q->whereDate('transaction_date', '<=', $request->date_to))
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($transactions);
    }

    public function store(
        StoreFinanceTransactionRequest $request,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->user_id;
        $data = $request->validated();

        $account = FinanceAccount::query()
            ->where('user_id', $userId)
            ->findOrFail($data['account_id']);

        if (!empty($data['transfer_account_id'])) {
            FinanceAccount::query()
                ->where('user_id', $userId)
                ->findOrFail($data['transfer_account_id']);
        }

        if (!empty($data['category_id'])) {
            FinanceCategory::query()
                ->where('user_id', $userId)
                ->findOrFail($data['category_id']);
        }

        $transaction = DB::transaction(function () use ($data, $userId) {
            return FinanceTransaction::query()->create([
                'user_id' => $userId,
                'transaction_type' => $data['transaction_type'],
                'account_id' => $data['account_id'],
                'transfer_account_id' => $data['transfer_account_id'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'amount' => $data['amount'],
                'transaction_date' => $data['transaction_date'],
                'description' => $data['description'] ?? null,
                'reference_no' => $data['reference_no'] ?? null,
                'metadata_json' => $data['metadata_json'] ?? [],
            ]);
        });

        $balanceService->rebuildMany([
            $transaction->account_id,
            $transaction->transfer_account_id,
        ]);

        return response()->json($transaction->load(['account', 'transferAccount', 'category']), 201);
    }

    public function show(Request $request, string $transactionId): JsonResponse
    {
        $transaction = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($transactionId);

        return response()->json($transaction);
    }

    public function update(
        UpdateFinanceTransactionRequest $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->user_id;

        $transaction = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->findOrFail($transactionId);

        $oldAccountId = $transaction->account_id;
        $oldTransferAccountId = $transaction->transfer_account_id;

        $data = $request->validated();

        FinanceAccount::query()
            ->where('user_id', $userId)
            ->findOrFail($data['account_id']);

        if (!empty($data['transfer_account_id'])) {
            FinanceAccount::query()
                ->where('user_id', $userId)
                ->findOrFail($data['transfer_account_id']);
        }

        if (!empty($data['category_id'])) {
            FinanceCategory::query()
                ->where('user_id', $userId)
                ->findOrFail($data['category_id']);
        }

        DB::transaction(function () use ($transaction, $data) {
            $transaction->update([
                'transaction_type' => $data['transaction_type'],
                'account_id' => $data['account_id'],
                'transfer_account_id' => $data['transfer_account_id'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'amount' => $data['amount'],
                'transaction_date' => $data['transaction_date'],
                'description' => $data['description'] ?? null,
                'reference_no' => $data['reference_no'] ?? null,
                'metadata_json' => $data['metadata_json'] ?? [],
            ]);
        });

        $balanceService->rebuildMany([
            $oldAccountId,
            $oldTransferAccountId,
            $transaction->account_id,
            $transaction->transfer_account_id,
        ]);

        return response()->json($transaction->fresh()->load(['account', 'transferAccount', 'category']));
    }

    public function destroy(
        Request $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $transaction = FinanceTransaction::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($transactionId);

        $accountIds = [
            $transaction->account_id,
            $transaction->transfer_account_id,
        ];

        DB::transaction(function () use ($transaction) {
            $transaction->delete();
        });

        $balanceService->rebuildMany($accountIds);

        return response()->json(['message' => 'Transaction deleted successfully.']);
    }
}
11) API Routes

Add to routes/api.php

<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\FinanceAccountController;
use App\Http\Controllers\Api\FinanceCategoryController;
use App\Http\Controllers\Api\FinanceTransactionController;

Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('finance/accounts', FinanceAccountController::class);
    Route::apiResource('finance/categories', FinanceCategoryController::class);
    Route::apiResource('finance/transactions', FinanceTransactionController::class);
});
12) Example API Payloads
Create account

POST /api/v1/finance/accounts

{
  "account_name": "Main Wallet",
  "account_type": "main",
  "currency_code": "USD",
  "opening_balance": 1000,
  "description": "Daily spending account",
  "is_active": true
}
Create savings account
{
  "account_name": "Savings Vault",
  "account_type": "savings",
  "currency_code": "USD",
  "opening_balance": 2500
}
Create income category

POST /api/v1/finance/categories

{
  "category_name": "Salary",
  "category_type": "income",
  "icon": "wallet",
  "color_code": "#22C55E"
}
Create expense category
{
  "category_name": "Groceries",
  "category_type": "expense",
  "icon": "cart",
  "color_code": "#EF4444"
}
Create income transaction

POST /api/v1/finance/transactions

{
  "transaction_type": "income",
  "account_id": "ACCOUNT_UUID",
  "category_id": "CATEGORY_UUID",
  "amount": 1500,
  "transaction_date": "2026-04-11",
  "description": "Monthly salary",
  "reference_no": "SAL-APR-2026"
}
Create expense transaction
{
  "transaction_type": "expense",
  "account_id": "ACCOUNT_UUID",
  "category_id": "CATEGORY_UUID",
  "amount": 120,
  "transaction_date": "2026-04-11",
  "description": "Supermarket"
}
Create transfer transaction
{
  "transaction_type": "transfer",
  "account_id": "MAIN_ACCOUNT_UUID",
  "transfer_account_id": "SAVINGS_ACCOUNT_UUID",
  "amount": 300,
  "transaction_date": "2026-04-11",
  "description": "Move money to savings"
}


-------Test Scripts-------
curl -X POST http://127.0.0.1:8000/api/v1/finance/transactions \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "transaction_type": "income",
    "account_id": "019d8223-49b2-73b8-91ea-aa8e0215fc06",
    "category_id": "019d8224-915e-7157-b55e-0746cd24688f",
    "amount": 1500,
    "transaction_date": "2026-04-12",
    "description": "Monthly salary"
  }'
Then create the expense transaction with the Groceries category UUID:
019d8224-b74d-72e1-b4bf-998b31a23591
curl -X POST http://127.0.0.1:8000/api/v1/finance/transactions \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "transaction_type": "expense",
    "account_id": "019d8223-49b2-73b8-91ea-aa8e0215fc06",
    "category_id": "019d8224-b74d-72e1-b4bf-998b31a23591",
    "amount": 120,
    "transaction_date": "2026-04-12",
    "description": "Supermarket groceries"
  }'
Then test a transfer from Main Wallet to Savings Vault. Savings Vault UUID is:
019d8224-7d82-73ba-8ce1-1b76fabf89b1
curl -X POST http://127.0.0.1:8000/api/v1/finance/transactions \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "transaction_type": "transfer",
    "account_id": "019d8223-49b2-73b8-91ea-aa8e0215fc06",
    "transfer_account_id": "019d8224-7d82-73ba-8ce1-1b76fabf89b1",
    "amount": 300,
    "transaction_date": "2026-04-12",
    "description": "Transfer to savings"
  }'
After these, list accounts again to confirm balances updated:
curl http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d"



7) After saving, test again
List accounts
curl http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d"

Create account
curl -X POST http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "account_name": "Test Professional Account",
    "account_type": "main",
    "currency_code": "USD",
    "opening_balance": 50,
    "description": "Professional display test",
    "is_active": true
  }'

13) Seeder for Default Categories

This is useful on registration or onboarding.

database/seeders/FinanceCategorySeeder.php
<?php

namespace Database\Seeders;

use App\Models\AppUser;
use App\Models\FinanceCategory;
use Illuminate\Database\Seeder;

class FinanceCategorySeeder extends Seeder
{
    public function run(): void
    {
        $defaultIncome = [
            ['category_name' => 'Salary', 'category_type' => 'income'],
            ['category_name' => 'Freelance', 'category_type' => 'income'],
            ['category_name' => 'Gift', 'category_type' => 'income'],
        ];

        $defaultExpense = [
            ['category_name' => 'Groceries', 'category_type' => 'expense'],
            ['category_name' => 'Transport', 'category_type' => 'expense'],
            ['category_name' => 'Health', 'category_type' => 'expense'],
            ['category_name' => 'Bills', 'category_type' => 'expense'],
            ['category_name' => 'Shopping', 'category_type' => 'expense'],
        ];

        AppUser::query()->chunk(100, function ($users) use ($defaultIncome, $defaultExpense) {
            foreach ($users as $user) {
                foreach (array_merge($defaultIncome, $defaultExpense) as $category) {
                    FinanceCategory::query()->firstOrCreate([
                        'user_id' => $user->user_id,
                        'category_name' => $category['category_name'],
                        'category_type' => $category['category_type'],
                    ], [
                        'is_system' => true,
                        'is_active' => true,
                    ]);
                }
            }
        });
    }
}
14) Recommended Business Rules

Add these rules in your service layer later:

Prevent deleting an account if it has transactions
Prevent deleting a system category
Ensure category type matches transaction type
income transaction → income category only
expense transaction → expense category only
For transfer:
category should usually be null
Support multi-currency later if needed
Add soft deletes only if you want audit/history recovery
15) Recommended Next Improvements

After this backend, your next finance upgrades should be:

Monthly budget table
Recurring transactions
Account summary endpoint
Dashboard KPIs
Transaction search/filter endpoint
CSV import/export
Audit logging
16) Suggested Next Step Number

This should be your next formal project step:

STEP 6 — Finance Dashboard APIs

Build:

account summary
monthly income/expense totals
category spending breakdown
savings growth
recent transactions widget
17) Exact Command Flow

Run:

php artisan make:model FinanceAccount
php artisan make:model FinanceCategory
php artisan make:model FinanceTransaction

php artisan make:controller Api/FinanceAccountController --api
php artisan make:controller Api/FinanceCategoryController --api
php artisan make:controller Api/FinanceTransactionController --api

php artisan make:request StoreFinanceAccountRequest
php artisan make:request UpdateFinanceAccountRequest
php artisan make:request StoreFinanceCategoryRequest
php artisan make:request UpdateFinanceCategoryRequest
php artisan make:request StoreFinanceTransactionRequest
php artisan make:request UpdateFinanceTransactionRequest

php artisan migrate
18) Best Implementation Note

For production, I recommend:

keep current_balance as cached value
always rebuild balances after create/update/delete
use DB transaction around transaction writes
keep transfer as one row, not two rows
keep schema-qualified PostgreSQL tables exactly as above



---DataBase
sudo -u postgres psql -d nixlifeos_db
DROP TABLE IF EXISTS nix_life_os.finance_transaction CASCADE;
DROP TABLE IF EXISTS nix_life_os.finance_account CASCADE;
DROP TABLE IF EXISTS nix_life_os.finance_category CASCADE;
DELETE FROM migrations WHERE migration = 'create_finance_categories_table';
DELETE FROM migrations WHERE migration = 'create_finance_accounts_table';
DELETE FROM migrations WHERE migration = 'create_finance_transactions_table';

php artisan optimize:clear
php artisan migrate

GRANT USAGE, CREATE ON SCHEMA nix_life_os TO nixlifeos_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nix_life_os TO nixlifeos_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA nix_life_os TO nixlifeos_user;

ALTER SCHEMA nix_life_os OWNER TO nixlifeos_user;

GRANT USAGE, CREATE ON SCHEMA nix_life_os TO nixlifeos_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA nix_life_os TO nixlifeos_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA nix_life_os TO nixlifeos_user;


GRANT USAGE, CREATE ON SCHEMA nix_life_os TO nixlifeos_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA nix_life_os
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO nixlifeos_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA nix_life_os
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO nixlifeos_user;



19)Re-add test data
    1) Create Main Wallet
    curl -X POST http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "account_name": "Main Wallet",
    "account_type": "main",
    "currency_code": "USD",
    "opening_balance": 1000,
    "description": "Daily spending account",
    "is_active": true
  }'
    2) Create Savings Vault
    curl -X POST http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "account_name": "Savings Vault",
    "account_type": "savings",
    "currency_code": "USD",
    "opening_balance": 500,
    "description": "Savings account",
    "is_active": true
  }'
    3) Create Salary category
    curl -X POST http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "account_name": "Savings Vault",
    "account_type": "savings",
    "currency_code": "USD",
    "opening_balance": 500,
    "description": "Savings account",
    "is_active": true
  }'
    4) Create Groceries category
    curl -X POST http://127.0.0.1:8000/api/v1/finance/categories \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "category_name": "Groceries",
    "category_type": "expense",
    "icon": "cart",
    "color_code": "#EF4444",
    "is_active": true
  }'
Then list them
Accounts
curl http://127.0.0.1:8000/api/v1/finance/accounts \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d"
Categories
curl http://127.0.0.1:8000/api/v1/finance/categories \
  -H "Accept: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d"
    

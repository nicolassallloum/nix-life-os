STEP 6 — Financial Intelligence Engine
1. Goal

Add intelligent finance capabilities to the backend:

Budget Tracking
Forecast Savings
Pay Yourself System
Expense Anomaly Detection

This step is modular, production-ready, and designed so that later you can plug in:

AI predictions
ML anomaly scoring
automated financial recommendations
scheduled monthly snapshot jobs
2. Architecture Overview
New domains added
A. Budgets

Stores monthly budgets by:

category
account
or both
B. Finance Intelligence Settings

Stores user-level intelligent finance preferences:

auto-save enabled
save percentage
default savings account
thresholds for warnings/anomalies
C. Forecast Engine

Computes month-end projected:

savings
balance
cash flow

Can optionally store snapshots.

D. Anomaly Engine

Rule-based detection for:

unusually large expense
category spike
abnormal daily spend

Logs anomaly results for traceability.

3. Database Design
3.1 New Tables
Table 1 — finance_budget

Monthly budget header.

CREATE TABLE nix_life_os.finance_budget (
    budget_id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    budget_name              VARCHAR(150) NOT NULL,
    budget_month             DATE NOT NULL,
    currency_code            VARCHAR(10) NOT NULL DEFAULT 'USD',
    is_active                BOOLEAN NOT NULL DEFAULT TRUE,
    notes                    TEXT,
    metadata_json            JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_finance_budget_month_start
        CHECK (date_trunc('month', budget_month)::date = budget_month)
);

CREATE UNIQUE INDEX ux_finance_budget_user_name_month
    ON nix_life_os.finance_budget (user_id, budget_name, budget_month);

CREATE INDEX ix_finance_budget_user_month
    ON nix_life_os.finance_budget (user_id, budget_month);
Table 2 — finance_budget_line

Budget breakdown lines by category/account.

CREATE TABLE nix_life_os.finance_budget_line (
    budget_line_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id                  UUID NOT NULL REFERENCES nix_life_os.finance_budget(budget_id) ON DELETE CASCADE,
    user_id                    UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    category_id                UUID NULL REFERENCES nix_life_os.finance_category(category_id) ON DELETE SET NULL,
    account_id                 UUID NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE SET NULL,
    planned_amount             NUMERIC(18,2) NOT NULL CHECK (planned_amount >= 0),
    warning_percentage         NUMERIC(5,2) NOT NULL DEFAULT 80.00 CHECK (warning_percentage >= 0 AND warning_percentage <= 100),
    exceeded_percentage        NUMERIC(5,2) NOT NULL DEFAULT 100.00 CHECK (exceeded_percentage >= 0),
    line_notes                 TEXT,
    metadata_json              JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_finance_budget_line_dimension
        CHECK (category_id IS NOT NULL OR account_id IS NOT NULL)
);

CREATE INDEX ix_finance_budget_line_budget
    ON nix_life_os.finance_budget_line (budget_id);

CREATE INDEX ix_finance_budget_line_user_category
    ON nix_life_os.finance_budget_line (user_id, category_id);

CREATE INDEX ix_finance_budget_line_user_account
    ON nix_life_os.finance_budget_line (user_id, account_id);

This supports:

category budget only
account budget only
combined category + account budget
Table 3 — finance_intelligence_setting

User-level settings.

CREATE TABLE nix_life_os.finance_intelligence_setting (
    finance_intelligence_setting_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                           UUID NOT NULL UNIQUE REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    auto_save_enabled                 BOOLEAN NOT NULL DEFAULT FALSE,
    auto_save_percentage              NUMERIC(5,2) NOT NULL DEFAULT 50.00 CHECK (auto_save_percentage >= 0 AND auto_save_percentage <= 100),
    default_savings_account_id        UUID NULL REFERENCES nix_life_os.finance_account(account_id) ON DELETE SET NULL,
    budget_warning_default_pct        NUMERIC(5,2) NOT NULL DEFAULT 80.00 CHECK (budget_warning_default_pct >= 0 AND budget_warning_default_pct <= 100),
    large_expense_multiplier          NUMERIC(10,2) NOT NULL DEFAULT 2.00 CHECK (large_expense_multiplier > 0),
    category_spike_multiplier         NUMERIC(10,2) NOT NULL DEFAULT 1.80 CHECK (category_spike_multiplier > 0),
    abnormal_daily_multiplier         NUMERIC(10,2) NOT NULL DEFAULT 2.00 CHECK (abnormal_daily_multiplier > 0),
    anomaly_minimum_amount            NUMERIC(18,2) NOT NULL DEFAULT 20.00 CHECK (anomaly_minimum_amount >= 0),
    metadata_json                     JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_finance_intelligence_setting_user
    ON nix_life_os.finance_intelligence_setting (user_id);
Table 4 — finance_forecast_snapshot

Optional snapshot storage.

CREATE TABLE nix_life_os.finance_forecast_snapshot (
    forecast_snapshot_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                       UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    forecast_month                DATE NOT NULL,
    current_total_balance         NUMERIC(18,2) NOT NULL DEFAULT 0,
    projected_income_total        NUMERIC(18,2) NOT NULL DEFAULT 0,
    projected_expense_total       NUMERIC(18,2) NOT NULL DEFAULT 0,
    projected_net_cash_flow       NUMERIC(18,2) NOT NULL DEFAULT 0,
    projected_savings_transfer    NUMERIC(18,2) NOT NULL DEFAULT 0,
    projected_month_end_balance   NUMERIC(18,2) NOT NULL DEFAULT 0,
    forecast_data_json            JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_finance_forecast_snapshot_month_start
        CHECK (date_trunc('month', forecast_month)::date = forecast_month)
);

CREATE INDEX ix_finance_forecast_snapshot_user_month
    ON nix_life_os.finance_forecast_snapshot (user_id, forecast_month);
Table 5 — finance_anomaly_log

Stores anomaly detection results.

CREATE TABLE nix_life_os.finance_anomaly_log (
    anomaly_log_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL REFERENCES nix_life_os.app_user(user_id) ON DELETE CASCADE,
    transaction_id              UUID NULL REFERENCES nix_life_os.finance_transaction(transaction_id) ON DELETE CASCADE,
    anomaly_type                VARCHAR(50) NOT NULL,
    anomaly_score               NUMERIC(5,2) NOT NULL CHECK (anomaly_score >= 0 AND anomaly_score <= 100),
    severity                    VARCHAR(20) NOT NULL,
    title                       VARCHAR(200) NOT NULL,
    explanation                 TEXT NOT NULL,
    baseline_amount             NUMERIC(18,2) NULL,
    observed_amount             NUMERIC(18,2) NULL,
    detected_at                 TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status                      VARCHAR(20) NOT NULL DEFAULT 'open',
    extra_data_json             JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_finance_anomaly_log_user_detected_at
    ON nix_life_os.finance_anomaly_log (user_id, detected_at DESC);

CREATE INDEX ix_finance_anomaly_log_transaction
    ON nix_life_os.finance_anomaly_log (transaction_id);

CREATE INDEX ix_finance_anomaly_log_type
    ON nix_life_os.finance_anomaly_log (anomaly_type);
4. Laravel Migrations
4.1 Migration order

Create these migrations in this order:

create_finance_budget_table
create_finance_budget_line_table
create_finance_intelligence_setting_table
create_finance_forecast_snapshot_table
create_finance_anomaly_log_table
4.2 Example migration — finance_budget
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('finance_budget', function (Blueprint $table) {
            $table->uuid('budget_id')->primary()->default(DB::raw('gen_random_uuid()'));
            $table->uuid('user_id');
            $table->string('budget_name', 150);
            $table->date('budget_month');
            $table->string('currency_code', 10)->default('USD');
            $table->boolean('is_active')->default(true);
            $table->text('notes')->nullable();
            $table->jsonb('metadata_json')->default(DB::raw("'{}'::jsonb"));
            $table->timestampTz('created_at')->useCurrent();
            $table->timestampTz('updated_at')->useCurrent();

            $table->foreign('user_id')
                ->references('user_id')
                ->on('app_user')
                ->cascadeOnDelete();

            $table->unique(['user_id', 'budget_name', 'budget_month'], 'ux_finance_budget_user_name_month');
            $table->index(['user_id', 'budget_month'], 'ix_finance_budget_user_month');
        });

        DB::statement("
            ALTER TABLE finance_budget
            ADD CONSTRAINT chk_finance_budget_month_start
            CHECK (date_trunc('month', budget_month)::date = budget_month)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('finance_budget');
    }
};

In AppServiceProvider or DB config, make sure default schema is nix_life_os, or prefix table names explicitly if needed.

5. Eloquent Models
5.1 FinanceBudget.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceBudget extends Model
{
    use HasUuids;

    protected $table = 'finance_budget';
    protected $primaryKey = 'budget_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'budget_name',
        'budget_month',
        'currency_code',
        'is_active',
        'notes',
        'metadata_json',
    ];

    protected $casts = [
        'budget_month' => 'date',
        'is_active' => 'boolean',
        'metadata_json' => 'array',
    ];

    public function lines()
    {
        return $this->hasMany(FinanceBudgetLine::class, 'budget_id', 'budget_id');
    }
}
5.2 FinanceBudgetLine.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceBudgetLine extends Model
{
    use HasUuids;

    protected $table = 'finance_budget_line';
    protected $primaryKey = 'budget_line_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'budget_id',
        'user_id',
        'category_id',
        'account_id',
        'planned_amount',
        'warning_percentage',
        'exceeded_percentage',
        'line_notes',
        'metadata_json',
    ];

    protected $casts = [
        'planned_amount' => 'decimal:2',
        'warning_percentage' => 'decimal:2',
        'exceeded_percentage' => 'decimal:2',
        'metadata_json' => 'array',
    ];

    public function budget()
    {
        return $this->belongsTo(FinanceBudget::class, 'budget_id', 'budget_id');
    }
}
5.3 FinanceIntelligenceSetting.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceIntelligenceSetting extends Model
{
    use HasUuids;

    protected $table = 'finance_intelligence_setting';
    protected $primaryKey = 'finance_intelligence_setting_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'auto_save_enabled',
        'auto_save_percentage',
        'default_savings_account_id',
        'budget_warning_default_pct',
        'large_expense_multiplier',
        'category_spike_multiplier',
        'abnormal_daily_multiplier',
        'anomaly_minimum_amount',
        'metadata_json',
    ];

    protected $casts = [
        'auto_save_enabled' => 'boolean',
        'auto_save_percentage' => 'decimal:2',
        'budget_warning_default_pct' => 'decimal:2',
        'large_expense_multiplier' => 'decimal:2',
        'category_spike_multiplier' => 'decimal:2',
        'abnormal_daily_multiplier' => 'decimal:2',
        'anomaly_minimum_amount' => 'decimal:2',
        'metadata_json' => 'array',
    ];
}
5.4 FinanceForecastSnapshot.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceForecastSnapshot extends Model
{
    use HasUuids;

    protected $table = 'finance_forecast_snapshot';
    protected $primaryKey = 'forecast_snapshot_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'forecast_month',
        'current_total_balance',
        'projected_income_total',
        'projected_expense_total',
        'projected_net_cash_flow',
        'projected_savings_transfer',
        'projected_month_end_balance',
        'forecast_data_json',
    ];

    protected $casts = [
        'forecast_month' => 'date',
        'current_total_balance' => 'decimal:2',
        'projected_income_total' => 'decimal:2',
        'projected_expense_total' => 'decimal:2',
        'projected_net_cash_flow' => 'decimal:2',
        'projected_savings_transfer' => 'decimal:2',
        'projected_month_end_balance' => 'decimal:2',
        'forecast_data_json' => 'array',
    ];
}
5.5 FinanceAnomalyLog.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceAnomalyLog extends Model
{
    use HasUuids;

    protected $table = 'finance_anomaly_log';
    protected $primaryKey = 'anomaly_log_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'transaction_id',
        'anomaly_type',
        'anomaly_score',
        'severity',
        'title',
        'explanation',
        'baseline_amount',
        'observed_amount',
        'detected_at',
        'status',
        'extra_data_json',
    ];

    protected $casts = [
        'anomaly_score' => 'decimal:2',
        'baseline_amount' => 'decimal:2',
        'observed_amount' => 'decimal:2',
        'detected_at' => 'datetime',
        'extra_data_json' => 'array',
    ];
}
6. Business Rules and Formulas
6.1 Budget Tracking
Actual spending

Only expense transactions count.

Actual line amount

For a budget line:

actual_spent =
SUM(expense transactions.amount)
WHERE:
- transaction.user_id = budget_line.user_id
- transaction date inside budget month
- if category_id is set → transaction.category_id = category_id
- if account_id is set → transaction.account_id = account_id
- only posted/valid expense rows
Remaining budget
remaining_budget = planned_amount - actual_spent
Usage percentage
budget_usage_pct =
CASE
    WHEN planned_amount = 0 THEN 0
    ELSE (actual_spent / planned_amount) * 100
END
Budget status
IF budget_usage_pct < warning_percentage
    status = safe
ELSE IF budget_usage_pct >= warning_percentage AND budget_usage_pct < exceeded_percentage
    status = warning
ELSE
    status = exceeded
6.2 Forecast Savings

Use current month partial data + recent trend.

Base variables
days_elapsed = current_day_of_month
days_in_month = total days in current month
days_remaining = days_in_month - days_elapsed
Current total balance
current_total_balance = SUM(current account balances)
MTD income
mtd_income = SUM(income transactions from month start until today)
MTD expense
mtd_expense = SUM(expense transactions from month start until today)
Daily averages
avg_daily_income = mtd_income / max(days_elapsed, 1)
avg_daily_expense = mtd_expense / max(days_elapsed, 1)
Projected month totals
projected_income_total = avg_daily_income * days_in_month
projected_expense_total = avg_daily_expense * days_in_month
Projected net cash flow
projected_net_cash_flow = projected_income_total - projected_expense_total
Savings behavior factor

Let:

recent_savings_transfer_ratio =
(total transfers into savings accounts in recent 90 days)
/
(total income in recent 90 days)

If not enough data, fallback to user setting:

recent_savings_transfer_ratio = auto_save_percentage / 100
Projected savings transfer
projected_savings_transfer = projected_income_total * recent_savings_transfer_ratio
Projected month-end balance
projected_month_end_balance =
current_total_balance
+ (avg_daily_income * days_remaining)
- (avg_daily_expense * days_remaining)
Forecast end-of-month savings

If a default savings account exists:

forecast_end_of_month_savings =
current_savings_balance + (projected_savings_transfer - savings_already_transferred_this_month)
6.3 Pay Yourself System
Auto-transfer amount

When an eligible income transaction is inserted:

auto_transfer_amount = income_transaction.amount * (auto_save_percentage / 100)
Conditions to execute auto-save

Run only if:

auto_save_enabled = true
inserted transaction type = income
transaction is not already a system-generated transfer
default savings account exists
source account exists
source account != savings account
auto_transfer_amount > 0
enough available balance if your account logic enforces this
Duplicate prevention

Add an idempotency reference inside transaction metadata:

{
  "auto_generated": true,
  "auto_save_source_transaction_id": "uuid"
}

Before generating a transfer, check whether a transfer already exists for that source transaction.

6.4 Expense Anomaly Detection
Rule 1 — Large expense anomaly

For a new expense transaction:

baseline = average expense amount for same category in last 90 days

If no category history exists, fallback to:

user's average expense amount in last 90 days

Trigger anomaly if:

transaction_amount >= baseline * large_expense_multiplier
AND transaction_amount >= anomaly_minimum_amount

Suggested score:

score = min(100, (transaction_amount / max(baseline,1)) * 25)
Rule 2 — Category spike anomaly

Compare current month category spend against recent history:

current_month_category_total
vs
average monthly category spend over previous 3 months

Trigger if:

current_month_category_total >= historical_monthly_avg * category_spike_multiplier

Score:

score = min(100, (current_month_category_total / max(historical_monthly_avg,1)) * 30)
Rule 3 — Abnormal daily spending anomaly

Compute:

today_total_expense
vs
average daily expense over last 30 days

Trigger if:

today_total_expense >= avg_daily_expense_30d * abnormal_daily_multiplier

Score:

score = min(100, (today_total_expense / max(avg_daily_expense_30d,1)) * 35)
7. Backend Service Layer

Recommended structure:

app/
└── Services/
    └── Finance/
        ├── BudgetCalculationService.php
        ├── SavingsForecastService.php
        ├── PayYourselfAutomationService.php
        ├── ExpenseAnomalyDetectionService.php
        └── FinanceIntelligenceOrchestrator.php
7.1 BudgetCalculationService.php

Responsibilities:

compute actual spend per budget line
compute usage %, remaining, status
compute full budget summary
Example
<?php

namespace App\Services\Finance;

use App\Models\FinanceBudget;
use App\Models\FinanceTransaction;
use Carbon\Carbon;

class BudgetCalculationService
{
    public function getBudgetSummary(FinanceBudget $budget): array
    {
        $monthStart = Carbon::parse($budget->budget_month)->startOfMonth();
        $monthEnd   = Carbon::parse($budget->budget_month)->endOfMonth();

        $lines = $budget->lines()->get()->map(function ($line) use ($monthStart, $monthEnd) {
            $query = FinanceTransaction::query()
                ->where('user_id', $line->user_id)
                ->whereBetween('transaction_date', [$monthStart, $monthEnd])
                ->where('transaction_type', 'expense');

            if ($line->category_id) {
                $query->where('category_id', $line->category_id);
            }

            if ($line->account_id) {
                $query->where('account_id', $line->account_id);
            }

            $actualSpent = (float) $query->sum('amount');
            $planned = (float) $line->planned_amount;
            $remaining = $planned - $actualSpent;
            $usagePct = $planned > 0 ? round(($actualSpent / $planned) * 100, 2) : 0;

            $status = 'safe';
            if ($usagePct >= (float) $line->exceeded_percentage) {
                $status = 'exceeded';
            } elseif ($usagePct >= (float) $line->warning_percentage) {
                $status = 'warning';
            }

            return [
                'budget_line_id' => $line->budget_line_id,
                'category_id' => $line->category_id,
                'account_id' => $line->account_id,
                'planned_amount' => $planned,
                'actual_spent' => round($actualSpent, 2),
                'remaining_budget' => round($remaining, 2),
                'budget_usage_percentage' => $usagePct,
                'status' => $status,
            ];
        });

        return [
            'budget_id' => $budget->budget_id,
            'budget_name' => $budget->budget_name,
            'budget_month' => $budget->budget_month->format('Y-m-d'),
            'totals' => [
                'planned_amount' => round($lines->sum('planned_amount'), 2),
                'actual_spent' => round($lines->sum('actual_spent'), 2),
                'remaining_budget' => round($lines->sum('remaining_budget'), 2),
            ],
            'lines' => $lines->values(),
        ];
    }
}
7.2 SavingsForecastService.php

Responsibilities:

calculate current balances
calculate MTD trends
calculate savings forecast
optionally persist snapshot
Example output structure
[
    'forecast_month' => '2026-04-01',
    'current_total_balance' => 1200.00,
    'mtd_income' => 900.00,
    'mtd_expense' => 420.00,
    'avg_daily_income' => 75.00,
    'avg_daily_expense' => 35.00,
    'projected_income_total' => 2250.00,
    'projected_expense_total' => 1050.00,
    'projected_net_cash_flow' => 1200.00,
    'projected_savings_transfer' => 1125.00,
    'projected_month_end_balance' => 1980.00,
]
7.3 PayYourselfAutomationService.php

Best place to trigger:

a transaction-created domain event
or in transaction service after successful DB insert
Core method
public function handleIncomeTransaction(FinanceTransaction $transaction): ?FinanceTransaction

Responsibilities:

load user setting
validate source and savings account
calculate transfer amount
prevent duplicate creation
create transfer transaction
mark metadata as system-generated
Important metadata

Source income transaction:

{
  "auto_save_evaluated": true
}

Generated transfer transaction:

{
  "auto_generated": true,
  "automation_type": "pay_yourself",
  "auto_save_source_transaction_id": "income-uuid"
}
7.4 ExpenseAnomalyDetectionService.php

Responsibilities:

run anomaly detection on inserted expense transaction
create finance_anomaly_log rows
return triggered anomalies
Core method
public function detectForTransaction(FinanceTransaction $transaction): array

Possible returned anomaly types:

large_expense
category_spike
abnormal_daily_spend
8. Event-driven Flow

Recommended flow for transaction creation:

FinanceTransactionController
    → FinanceTransactionService::create()
        → DB::transaction(...)
        → persist finance_transaction
        → dispatch FinanceTransactionCreated event
            → listener 1: PayYourselfAutomationListener
            → listener 2: ExpenseAnomalyDetectionListener

This keeps logic modular and avoids controller bloat.

9. Controllers

Recommended controllers:

app/Http/Controllers/Api/V1/Finance/
├── FinanceBudgetController.php
├── FinanceBudgetSummaryController.php
├── FinanceForecastController.php
├── FinanceIntelligenceSettingController.php
└── FinanceAnomalyController.php
9.1 FinanceBudgetController

Methods:

index()
store()
show(string $budgetId)
update()
destroy()
9.2 FinanceBudgetSummaryController

Methods:

show(string $budgetId)
monthlySummary(Request $request)
9.3 FinanceForecastController

Methods:

summary(Request $request)
storeSnapshot(Request $request) optional
9.4 FinanceIntelligenceSettingController

Methods:

show()
upsert()
9.5 FinanceAnomalyController

Methods:

index()
show(string $anomalyLogId)
runForTransaction(string $transactionId) optional manual recheck
10. Request Validation
10.1 StoreFinanceBudgetRequest.php
<?php

namespace App\Http\Requests\Finance;

use Illuminate\Foundation\Http\FormRequest;

class StoreFinanceBudgetRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'budget_name' => ['required', 'string', 'max:150'],
            'budget_month' => ['required', 'date_format:Y-m-d'],
            'currency_code' => ['required', 'string', 'max:10'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
            'lines' => ['required', 'array', 'min:1'],
            'lines.*.category_id' => ['nullable', 'uuid'],
            'lines.*.account_id' => ['nullable', 'uuid'],
            'lines.*.planned_amount' => ['required', 'numeric', 'min:0'],
            'lines.*.warning_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.exceeded_percentage' => ['nullable', 'numeric', 'min:0'],
            'lines.*.line_notes' => ['nullable', 'string'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            foreach ($this->input('lines', []) as $index => $line) {
                if (empty($line['category_id']) && empty($line['account_id'])) {
                    $validator->errors()->add("lines.$index", 'Either category_id or account_id is required.');
                }
            }
        });
    }
}
10.2 UpdateFinanceIntelligenceSettingRequest.php
<?php

namespace App\Http\Requests\Finance;

use Illuminate\Foundation\Http\FormRequest;

class UpdateFinanceIntelligenceSettingRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'auto_save_enabled' => ['required', 'boolean'],
            'auto_save_percentage' => ['required', 'numeric', 'min:0', 'max:100'],
            'default_savings_account_id' => ['nullable', 'uuid'],
            'budget_warning_default_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'large_expense_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'category_spike_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'abnormal_daily_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'anomaly_minimum_amount' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}
11. API Resources

Recommended resources:

app/Http/Resources/Finance/
├── FinanceBudgetResource.php
├── FinanceBudgetSummaryResource.php
├── FinanceForecastSummaryResource.php
├── FinanceIntelligenceSettingResource.php
└── FinanceAnomalyResource.php
Example FinanceForecastSummaryResource.php
<?php

namespace App\Http\Resources\Finance;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceForecastSummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'forecast_month' => $this['forecast_month'],
            'current_total_balance' => $this['current_total_balance'],
            'mtd_income' => $this['mtd_income'],
            'mtd_expense' => $this['mtd_expense'],
            'avg_daily_income' => $this['avg_daily_income'],
            'avg_daily_expense' => $this['avg_daily_expense'],
            'projected_income_total' => $this['projected_income_total'],
            'projected_expense_total' => $this['projected_expense_total'],
            'projected_net_cash_flow' => $this['projected_net_cash_flow'],
            'projected_savings_transfer' => $this['projected_savings_transfer'],
            'projected_month_end_balance' => $this['projected_month_end_balance'],
            'forecast_end_of_month_savings' => $this['forecast_end_of_month_savings'],
            'formula_notes' => $this['formula_notes'] ?? [],
        ];
    }
}
12. API Routes

Add to routes/api.php or your v1 finance routes file.

use App\Http\Controllers\Api\V1\Finance\FinanceBudgetController;
use App\Http\Controllers\Api\V1\Finance\FinanceBudgetSummaryController;
use App\Http\Controllers\Api\V1\Finance\FinanceForecastController;
use App\Http\Controllers\Api\V1\Finance\FinanceIntelligenceSettingController;
use App\Http\Controllers\Api\V1\Finance\FinanceAnomalyController;

Route::prefix('v1/finance')->middleware(['auth:sanctum'])->group(function () {

    Route::get('/budgets', [FinanceBudgetController::class, 'index']);
    Route::post('/budgets', [FinanceBudgetController::class, 'store']);
    Route::get('/budgets/{budget}', [FinanceBudgetController::class, 'show']);
    Route::put('/budgets/{budget}', [FinanceBudgetController::class, 'update']);
    Route::delete('/budgets/{budget}', [FinanceBudgetController::class, 'destroy']);

    Route::get('/budgets/{budget}/summary', [FinanceBudgetSummaryController::class, 'show']);
    Route::get('/budgets-summary/monthly', [FinanceBudgetSummaryController::class, 'monthlySummary']);

    Route::get('/forecast/summary', [FinanceForecastController::class, 'summary']);
    Route::post('/forecast/snapshots', [FinanceForecastController::class, 'storeSnapshot']);

    Route::get('/intelligence-settings', [FinanceIntelligenceSettingController::class, 'show']);
    Route::put('/intelligence-settings', [FinanceIntelligenceSettingController::class, 'upsert']);

    Route::get('/anomalies', [FinanceAnomalyController::class, 'index']);
    Route::get('/anomalies/{anomalyLog}', [FinanceAnomalyController::class, 'show']);
    Route::post('/anomalies/run/{transactionId}', [FinanceAnomalyController::class, 'runForTransaction']);
});
13. Example JSON Payloads
13.1 Create budget request
{
  "budget_name": "April 2026 Personal Budget",
  "budget_month": "2026-04-01",
  "currency_code": "USD",
  "is_active": true,
  "notes": "Main monthly budget",
  "lines": [
    {
      "category_id": "1d8b2b50-72f2-4c07-b1f3-c5aa8f7cb111",
      "planned_amount": 300,
      "warning_percentage": 80,
      "exceeded_percentage": 100,
      "line_notes": "Groceries budget"
    },
    {
      "category_id": "af1fd5d2-6b70-4910-b8f8-3c70d4a2e222",
      "planned_amount": 100,
      "warning_percentage": 85,
      "exceeded_percentage": 100,
      "line_notes": "Transport budget"
    },
    {
      "account_id": "8f271ef1-85a8-4040-a15c-fb93d8c93333",
      "planned_amount": 500,
      "warning_percentage": 90,
      "exceeded_percentage": 100,
      "line_notes": "Card spending limit"
    }
  ]
}
13.2 Create budget response
{
  "success": true,
  "message": "Budget created successfully",
  "data": {
    "budget_id": "9bc065ef-1fb3-4e1f-85a1-dcbfce4f9999",
    "budget_name": "April 2026 Personal Budget",
    "budget_month": "2026-04-01",
    "currency_code": "USD",
    "is_active": true
  }
}
13.3 Budget summary response
{
  "success": true,
  "message": "Budget summary retrieved successfully",
  "data": {
    "budget_id": "9bc065ef-1fb3-4e1f-85a1-dcbfce4f9999",
    "budget_name": "April 2026 Personal Budget",
    "budget_month": "2026-04-01",
    "totals": {
      "planned_amount": 900,
      "actual_spent": 640,
      "remaining_budget": 260
    },
    "lines": [
      {
        "budget_line_id": "11111111-1111-1111-1111-111111111111",
        "category_id": "1d8b2b50-72f2-4c07-b1f3-c5aa8f7cb111",
        "account_id": null,
        "planned_amount": 300,
        "actual_spent": 255,
        "remaining_budget": 45,
        "budget_usage_percentage": 85,
        "status": "warning"
      },
      {
        "budget_line_id": "22222222-2222-2222-2222-222222222222",
        "category_id": "af1fd5d2-6b70-4910-b8f8-3c70d4a2e222",
        "account_id": null,
        "planned_amount": 100,
        "actual_spent": 120,
        "remaining_budget": -20,
        "budget_usage_percentage": 120,
        "status": "exceeded"
      }
    ]
  }
}
13.4 Forecast summary response
{
  "success": true,
  "message": "Forecast summary retrieved successfully",
  "data": {
    "forecast_month": "2026-04-01",
    "current_total_balance": 1800,
    "mtd_income": 1200,
    "mtd_expense": 640,
    "avg_daily_income": 100,
    "avg_daily_expense": 53.33,
    "projected_income_total": 3000,
    "projected_expense_total": 1600,
    "projected_net_cash_flow": 1400,
    "projected_savings_transfer": 1500,
    "projected_month_end_balance": 2560,
    "forecast_end_of_month_savings": 1700,
    "formula_notes": [
      "Projected income is based on current month daily average",
      "Projected savings transfer uses recent savings behavior or auto-save percentage fallback"
    ]
  }
}
13.5 Update pay-yourself settings request
{
  "auto_save_enabled": true,
  "auto_save_percentage": 50,
  "default_savings_account_id": "ab3f0906-30bd-45d8-8dd7-2b63af7f5555",
  "budget_warning_default_pct": 80,
  "large_expense_multiplier": 2.0,
  "category_spike_multiplier": 1.8,
  "abnormal_daily_multiplier": 2.0,
  "anomaly_minimum_amount": 20
}
13.6 Settings response
{
  "success": true,
  "message": "Finance intelligence settings updated successfully",
  "data": {
    "auto_save_enabled": true,
    "auto_save_percentage": 50,
    "default_savings_account_id": "ab3f0906-30bd-45d8-8dd7-2b63af7f5555",
    "budget_warning_default_pct": 80,
    "large_expense_multiplier": 2,
    "category_spike_multiplier": 1.8,
    "abnormal_daily_multiplier": 2,
    "anomaly_minimum_amount": 20
  }
}
13.7 Anomaly response
{
  "success": true,
  "message": "Anomaly results retrieved successfully",
  "data": [
    {
      "anomaly_log_id": "4f9a9705-4dbd-4b91-bdf2-7a62c1f4aaaa",
      "transaction_id": "8a598247-6c94-4425-bbd1-2e4fd3bbb999",
      "anomaly_type": "large_expense",
      "anomaly_score": 88,
      "severity": "high",
      "title": "Expense significantly higher than normal",
      "explanation": "This expense is 2.9x higher than your recent average in the same category.",
      "baseline_amount": 45,
      "observed_amount": 130,
      "detected_at": "2026-04-12T14:40:00Z",
      "status": "open"
    }
  ]
}
14. Production-ready Controller Pattern

Use this response format everywhere:

return response()->json([
    'success' => true,
    'message' => 'Budget created successfully',
    'data' => new FinanceBudgetResource($budget),
], 201);

Error format:

return response()->json([
    'success' => false,
    'message' => 'Validation failed',
    'data' => [
        'errors' => $validator->errors(),
    ],
], 422);
15. Pay Yourself Integration Details
Where to hook it

Best implementation:

inside your FinanceTransactionService::store()
after transaction commit
dispatch event
Example event
event(new FinanceTransactionCreated($transaction));
Listener 1

RunPayYourselfAutomation

Listener 2

RunExpenseAnomalyDetection

This avoids recursion and keeps finance transaction creation logic clean.

Preventing loops

When auto-transfer creates a transfer transaction:

mark metadata auto_generated = true
mark automation_type = pay_yourself

Then skip automation if:

if (($transaction->metadata_json['auto_generated'] ?? false) === true) {
    return null;
}

Also skip when:

transaction type is transfer
source account equals savings account
16. Recommended Additional Transaction Fields

If STEP 5 does not already have these, they help a lot:

transaction_type → income, expense, transfer
direction if needed
source_account_id
destination_account_id
status → posted, pending, cancelled
is_system_generated
metadata_json

For pay-yourself transfers, having both:

source_account_id
destination_account_id

is strongly recommended.

17. Suggested Service Implementation Order

Build Step 6 in this order:

Phase 1 — Database
Create all 5 tables
Run migrations
Add models
Phase 2 — Budget Engine
Build budget CRUD
Build BudgetCalculationService
Add budget summary endpoints
Phase 3 — Settings
Build finance intelligence settings upsert/show
Phase 4 — Forecast Engine
Build SavingsForecastService
Add forecast summary endpoint
Add optional snapshot persistence
Phase 5 — Pay Yourself
Build PayYourselfAutomationService
Hook it to income transaction creation event
Add duplicate-prevention logic
Phase 6 — Anomaly Engine
Build ExpenseAnomalyDetectionService
Run detection on expense insert
Save anomaly logs
Add anomaly endpoints
18. Recommended File Structure
app/
├── Http/
│   ├── Controllers/
│   │   └── Api/
│   │       └── V1/
│   │           └── Finance/
│   │               ├── FinanceBudgetController.php
│   │               ├── FinanceBudgetSummaryController.php
│   │               ├── FinanceForecastController.php
│   │               ├── FinanceIntelligenceSettingController.php
│   │               └── FinanceAnomalyController.php
│   ├── Requests/
│   │   └── Finance/
│   │       ├── StoreFinanceBudgetRequest.php
│   │       ├── UpdateFinanceBudgetRequest.php
│   │       └── UpdateFinanceIntelligenceSettingRequest.php
│   └── Resources/
│       └── Finance/
│           ├── FinanceBudgetResource.php
│           ├── FinanceBudgetSummaryResource.php
│           ├── FinanceForecastSummaryResource.php
│           ├── FinanceIntelligenceSettingResource.php
│           └── FinanceAnomalyResource.php
├── Models/
│   ├── FinanceBudget.php
│   ├── FinanceBudgetLine.php
│   ├── FinanceIntelligenceSetting.php
│   ├── FinanceForecastSnapshot.php
│   └── FinanceAnomalyLog.php
├── Services/
│   └── Finance/
│       ├── BudgetCalculationService.php
│       ├── SavingsForecastService.php
│       ├── PayYourselfAutomationService.php
│       ├── ExpenseAnomalyDetectionService.php
│       └── FinanceTransactionService.php
├── Events/
│   └── FinanceTransactionCreated.php
└── Listeners/
    ├── RunPayYourselfAutomation.php
    └── RunExpenseAnomalyDetection.php
19. Recommended API Endpoint List
Budgets
GET /api/v1/finance/budgets
POST /api/v1/finance/budgets
GET /api/v1/finance/budgets/{budget}
PUT /api/v1/finance/budgets/{budget}
DELETE /api/v1/finance/budgets/{budget}
Budget Summary
GET /api/v1/finance/budgets/{budget}/summary
GET /api/v1/finance/budgets-summary/monthly?month=2026-04-01
Forecast
GET /api/v1/finance/forecast/summary?month=2026-04-01
POST /api/v1/finance/forecast/snapshots
Intelligence Settings
GET /api/v1/finance/intelligence-settings
PUT /api/v1/finance/intelligence-settings
Anomalies
GET /api/v1/finance/anomalies
GET /api/v1/finance/anomalies/{anomalyLog}
POST /api/v1/finance/anomalies/run/{transactionId}
20. Final Step 6 Summary
What STEP 6 adds
Budget Tracking
monthly budgets
category/account budget lines
planned vs actual
remaining budget
usage %
safe/warning/exceeded
Forecast Savings
month-end projected balance
projected net cash flow
savings forecast
trend-based calculations
Pay Yourself System
user-level settings
automatic % savings transfer on income
default savings account
duplicate/loop prevention
Expense Anomaly Detection
large single expense detection
category spike detection
abnormal daily spend detection
explanation + severity + score
anomaly history log
'

20)Fastest test path
Run these exact commands in order:
mkdir -p app/Http/Controllers/Api/V1/Finance
nano app/Http/Controllers/Api/V1/Finance/FinanceBudgetController.php
composer dump-autoload
php artisan optimize:clear
php artisan route:list | grep budgets


curl -X POST http://127.0.0.1:8000/api/v1/v1/finance/budgets \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 8|xdjqGTdscKBw1Q2ZoA1ry5dvl5WzysZ8N0pJlmoDe4bb656d" \
  -d '{
    "budget_name": "April 2026 Personal Budget",
    "budget_month": "2026-04-01",
    "currency_code": "USD",
    "is_active": true,
    "notes": "Main monthly budget",
    "lines": [
      {
        "category_id": "1d8b2b50-72f2-4c07-b1f3-c5aa8f7cb111",
        "planned_amount": 300,
        "warning_percentage": 80,
        "exceeded_percentage": 100,
        "line_notes": "Groceries budget"
      },
      {
        "category_id": "af1fd5d2-6b70-4910-b8f8-3c70d4a2e222",
        "planned_amount": 100,
        "warning_percentage": 85,
        "exceeded_percentage": 100,
        "line_notes": "Transport budget"
      },
      {
        "account_id": "8f271ef1-85a8-4040-a15c-fb93d8c93333",
        "planned_amount": 500,
        "warning_percentage": 90,
        "exceeded_percentage": 100,
        "line_notes": "Card spending limit"
      }
    ]
  }'
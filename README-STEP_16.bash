STEP 16 — Unified Dashboard Backend
1. Create Controller + Service

Run:

cd /u01/nix-life-os/backend

php artisan make:controller Api/V1/Dashboard/UnifiedDashboardController
mkdir -p app/Services/Dashboard
nano app/Services/Dashboard/UnifiedDashboardService.php
2. Create Dashboard Service

Create this file:

nano app/Services/Dashboard/UnifiedDashboardService.php

Add:

<?php

namespace App\Services\Dashboard;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

class UnifiedDashboardService
{
    public function getOverview(string $userId): array
    {
        $today = Carbon::today()->toDateString();

        return [
            'finance' => $this->getFinanceKpis($userId),
            'health' => $this->getHealthKpis($userId, $today),
            'projects' => $this->getProjectKpis($userId),
            'daily_summary' => $this->getDailySummary($userId, $today),
        ];
    }

    public function getFinanceKpis(string $userId): array
    {
        $accountSummary = DB::table('finance_accounts')
            ->where('user_id', $userId)
            ->selectRaw("
                COALESCE(SUM(current_balance), 0) as total_balance,
                COUNT(*) as total_accounts
            ")
            ->first();

        $transactionSummary = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->selectRaw("
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as total_income,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0)
                -
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as net_cashflow
            ")
            ->first();

        $monthlySummary = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->whereMonth('transaction_date', now()->month)
            ->whereYear('transaction_date', now()->year)
            ->selectRaw("
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as monthly_income,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as monthly_expenses
            ")
            ->first();

        return [
            'total_balance' => round((float) $accountSummary->total_balance, 2),
            'total_accounts' => (int) $accountSummary->total_accounts,
            'total_income' => round((float) $transactionSummary->total_income, 2),
            'total_expenses' => round((float) $transactionSummary->total_expenses, 2),
            'net_cashflow' => round((float) $transactionSummary->net_cashflow, 2),
            'monthly_income' => round((float) $monthlySummary->monthly_income, 2),
            'monthly_expenses' => round((float) $monthlySummary->monthly_expenses, 2),
            'monthly_savings' => round(
                (float) $monthlySummary->monthly_income - (float) $monthlySummary->monthly_expenses,
                2
            ),
        ];
    }

    public function getHealthKpis(string $userId, string $date): array
    {
        $steps = DB::table('health_step_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', $date)
            ->selectRaw("
                COALESCE(SUM(steps_count), 0) as total_steps,
                COALESCE(SUM(distance_km), 0) as total_distance_km,
                COALESCE(SUM(calories_burned), 0) as calories_burned
            ")
            ->first();

        $hydration = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', $date)
            ->selectRaw("
                COALESCE(SUM(amount_ml), 0) as total_water_ml
            ")
            ->first();

        $nutrition = DB::table('health_meal_logs')
            ->where('user_id', $userId)
            ->whereDate('meal_date', $date)
            ->selectRaw("
                COALESCE(SUM(total_calories), 0) as calories,
                COALESCE(SUM(total_protein_g), 0) as protein_g,
                COALESCE(SUM(total_carbs_g), 0) as carbs_g,
                COALESCE(SUM(total_fat_g), 0) as fat_g,
                COALESCE(SUM(total_sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(total_potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(total_phosphorus_mg), 0) as phosphorus_mg
            ")
            ->first();

        $latestWeight = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->select('weight_kg', 'log_date')
            ->first();

        return [
            'date' => $date,
            'steps' => (int) $steps->total_steps,
            'distance_km' => round((float) $steps->total_distance_km, 2),
            'calories_burned' => round((float) $steps->calories_burned, 2),
            'water_ml' => (int) $hydration->total_water_ml,
            'nutrition' => [
                'calories' => round((float) $nutrition->calories, 2),
                'protein_g' => round((float) $nutrition->protein_g, 2),
                'carbs_g' => round((float) $nutrition->carbs_g, 2),
                'fat_g' => round((float) $nutrition->fat_g, 2),
                'sodium_mg' => round((float) $nutrition->sodium_mg, 2),
                'potassium_mg' => round((float) $nutrition->potassium_mg, 2),
                'phosphorus_mg' => round((float) $nutrition->phosphorus_mg, 2),
            ],
            'latest_weight' => $latestWeight ? [
                'weight_kg' => round((float) $latestWeight->weight_kg, 2),
                'log_date' => $latestWeight->log_date,
            ] : null,
        ];
    }

    public function getProjectKpis(string $userId): array
    {
        $summary = DB::table('projects')
            ->where('user_id', $userId)
            ->selectRaw("
                COUNT(*) as total_projects,
                COUNT(*) FILTER (WHERE status = 'not_started') as not_started,
                COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress,
                COUNT(*) FILTER (WHERE status = 'completed') as completed,
                COUNT(*) FILTER (WHERE status = 'on_hold') as on_hold,
                COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled,
                COALESCE(AVG(progress_percentage), 0) as average_progress
            ")
            ->first();

        $criticalProjects = DB::table('projects')
            ->where('user_id', $userId)
            ->where('priority', 'critical')
            ->count();

        $overdueProjects = DB::table('projects')
            ->where('user_id', $userId)
            ->whereNotNull('target_end_date')
            ->whereDate('target_end_date', '<', now()->toDateString())
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->count();

        return [
            'total_projects' => (int) $summary->total_projects,
            'not_started' => (int) $summary->not_started,
            'in_progress' => (int) $summary->in_progress,
            'completed' => (int) $summary->completed,
            'on_hold' => (int) $summary->on_hold,
            'cancelled' => (int) $summary->cancelled,
            'critical_projects' => (int) $criticalProjects,
            'overdue_projects' => (int) $overdueProjects,
            'average_progress' => round((float) $summary->average_progress, 2),
        ];
    }

    public function getDailySummary(string $userId, string $date): array
    {
        $financeToday = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->whereDate('transaction_date', $date)
            ->selectRaw("
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as income_today,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as expenses_today
            ")
            ->first();

        $projectsUpdatedToday = DB::table('projects')
            ->where('user_id', $userId)
            ->whereDate('updated_at', $date)
            ->count();

        return [
            'date' => $date,
            'income_today' => round((float) $financeToday->income_today, 2),
            'expenses_today' => round((float) $financeToday->expenses_today, 2),
            'projects_updated_today' => (int) $projectsUpdatedToday,
        ];
    }

    public function getFinanceTrend(string $userId): array
    {
        return DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->whereDate('transaction_date', '>=', now()->subDays(30)->toDateString())
            ->selectRaw("
                transaction_date::date as date,
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as income,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as expenses
            ")
            ->groupByRaw('transaction_date::date')
            ->orderBy('date')
            ->get()
            ->map(fn ($row) => [
                'date' => $row->date,
                'income' => round((float) $row->income, 2),
                'expenses' => round((float) $row->expenses, 2),
                'net' => round((float) $row->income - (float) $row->expenses, 2),
            ])
            ->toArray();
    }

    public function getHealthTrend(string $userId): array
    {
        return DB::table('health_step_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', '>=', now()->subDays(30)->toDateString())
            ->selectRaw("
                log_date::date as date,
                COALESCE(SUM(steps_count), 0) as steps,
                COALESCE(SUM(calories_burned), 0) as calories_burned
            ")
            ->groupByRaw('log_date::date')
            ->orderBy('date')
            ->get()
            ->map(fn ($row) => [
                'date' => $row->date,
                'steps' => (int) $row->steps,
                'calories_burned' => round((float) $row->calories_burned, 2),
            ])
            ->toArray();
    }

    public function getProjectProgressTrend(string $userId): array
    {
        return DB::table('projects')
            ->where('user_id', $userId)
            ->selectRaw("
                status,
                COUNT(*) as total,
                COALESCE(AVG(progress_percentage), 0) as average_progress
            ")
            ->groupBy('status')
            ->orderBy('status')
            ->get()
            ->map(fn ($row) => [
                'status' => $row->status,
                'total' => (int) $row->total,
                'average_progress' => round((float) $row->average_progress, 2),
            ])
            ->toArray();
    }
}
3. Create Controller

Open:

nano app/Http/Controllers/Api/V1/Dashboard/UnifiedDashboardController.php

Add:

<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use App\Services\Dashboard\UnifiedDashboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UnifiedDashboardController extends Controller
{
    public function __construct(
        protected UnifiedDashboardService $dashboardService
    ) {}

    public function overview(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Unified dashboard overview loaded successfully.',
            'data' => $this->dashboardService->getOverview($userId),
        ]);
    }

    public function finance(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Finance dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getFinanceKpis($userId),
        ]);
    }

    public function health(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $date = $request->query('date', now()->toDateString());

        return response()->json([
            'success' => true,
            'message' => 'Health dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getHealthKpis($userId, $date),
        ]);
    }

    public function projects(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Project dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getProjectKpis($userId),
        ]);
    }

    public function trends(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Unified dashboard trends loaded successfully.',
            'data' => [
                'finance' => $this->dashboardService->getFinanceTrend($userId),
                'health' => $this->dashboardService->getHealthTrend($userId),
                'projects' => $this->dashboardService->getProjectProgressTrend($userId),
            ],
        ]);
    }
}
4. Add API Routes

Open:

nano routes/api.php

Add this import at the top:

use App\Http\Controllers\Api\V1\Dashboard\UnifiedDashboardController;

Inside your existing authenticated API group, add:

Route::prefix('dashboard')->group(function () {
    Route::get('/overview', [UnifiedDashboardController::class, 'overview']);
    Route::get('/finance', [UnifiedDashboardController::class, 'finance']);
    Route::get('/health', [UnifiedDashboardController::class, 'health']);
    Route::get('/projects', [UnifiedDashboardController::class, 'projects']);
    Route::get('/trends', [UnifiedDashboardController::class, 'trends']);
});

Example structure:

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {

    Route::prefix('dashboard')->group(function () {
        Route::get('/overview', [UnifiedDashboardController::class, 'overview']);
        Route::get('/finance', [UnifiedDashboardController::class, 'finance']);
        Route::get('/health', [UnifiedDashboardController::class, 'health']);
        Route::get('/projects', [UnifiedDashboardController::class, 'projects']);
        Route::get('/trends', [UnifiedDashboardController::class, 'trends']);
    });

});
5. Add Optimized PostgreSQL Indexes

Create migration:

php artisan make:migration add_dashboard_indexes

Open the migration:

nano database/migrations/xxxx_xx_xx_xxxxxx_add_dashboard_indexes.php

Replace with:

<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_accounts_user_id
            ON finance_accounts (user_id)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_finance_transactions_user_type_date
            ON finance_transactions (user_id, transaction_type, transaction_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_step_logs_user_date
            ON health_step_logs (user_id, log_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_hydration_logs_user_date
            ON health_hydration_logs (user_id, log_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_meal_logs_user_date
            ON health_meal_logs (user_id, meal_date)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_health_weight_logs_user_date
            ON health_weight_logs (user_id, log_date DESC)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_projects_user_status_priority
            ON projects (user_id, status, priority)
        ");

        DB::statement("
            CREATE INDEX IF NOT EXISTS idx_projects_user_target_end_date
            ON projects (user_id, target_end_date)
        ");
    }

    public function down(): void
    {
        DB::statement("DROP INDEX IF EXISTS idx_finance_accounts_user_id");
        DB::statement("DROP INDEX IF EXISTS idx_finance_transactions_user_type_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_step_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_hydration_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_meal_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_health_weight_logs_user_date");
        DB::statement("DROP INDEX IF EXISTS idx_projects_user_status_priority");
        DB::statement("DROP INDEX IF EXISTS idx_projects_user_target_end_date");
    }
};

Run:

php artisan migrate
6. Clear Laravel Cache

Run:

php artisan optimize:clear
composer dump-autoload
7. Test Routes

Use your token:

TOKEN="REDACTED_TOKEN"
Test full overview
curl -X GET http://127.0.0.1:8000/api/v1/dashboard/overview \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"

Expected response:

{
  "success": true,
  "message": "Unified dashboard overview loaded successfully.",
  "data": {
    "finance": {
      "total_balance": 0,
      "total_accounts": 0,
      "total_income": 0,
      "total_expenses": 0,
      "net_cashflow": 0,
      "monthly_income": 0,
      "monthly_expenses": 0,
      "monthly_savings": 0
    },
    "health": {
      "date": "2026-04-26",
      "steps": 0,
      "distance_km": 0,
      "calories_burned": 0,
      "water_ml": 0,
      "nutrition": {
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fat_g": 0,
        "sodium_mg": 0,
        "potassium_mg": 0,
        "phosphorus_mg": 0
      },
      "latest_weight": null
    },
    "projects": {
      "total_projects": 0,
      "not_started": 0,
      "in_progress": 0,
      "completed": 0,
      "on_hold": 0,
      "cancelled": 0,
      "critical_projects": 0,
      "overdue_projects": 0,
      "average_progress": 0
    },
    "daily_summary": {
      "date": "2026-04-26",
      "income_today": 0,
      "expenses_today": 0,
      "projects_updated_today": 0
    }
  }
}
Test finance KPIs
curl -X GET http://127.0.0.1:8000/api/v1/dashboard/finance \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
Test health KPIs
curl -X GET "http://127.0.0.1:8000/api/v1/dashboard/health?date=2026-04-26" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
Test project KPIs
curl -X GET http://127.0.0.1:8000/api/v1/dashboard/projects \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
Test trends
curl -X GET http://127.0.0.1:8000/api/v1/dashboard/trends \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN"
8. Important Possible Table Name Fixes

Your project may have slightly different column names depending on previous steps.

If you get errors like:

Undefined table: health_meal_logs

or:

Undefined column: total_calories

then run:

php artisan tinker

Then check your real table names:

DB::select("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name");

Check columns:

DB::select("SELECT column_name FROM information_schema.columns WHERE table_name = 'health_meal_logs'");
DB::select("SELECT column_name FROM information_schema.columns WHERE table_name = 'finance_transactions'");
DB::select("SELECT column_name FROM information_schema.columns WHERE table_name = 'projects'");

Based on your previous Step 12 issue, your nutrition values may be stored in health_meal_log_items instead of directly on health_meal_logs.

If your table is item-based, replace the nutrition query inside getHealthKpis() with this version:

$nutrition = DB::table('health_meal_log_items as mli')
    ->join('health_meal_logs as ml', 'ml.id', '=', 'mli.meal_log_id')
    ->where('ml.user_id', $userId)
    ->whereDate('ml.meal_date', $date)
    ->selectRaw("
        COALESCE(SUM(mli.calories), 0) as calories,
        COALESCE(SUM(mli.protein_g), 0) as protein_g,
        COALESCE(SUM(mli.carbs_g), 0) as carbs_g,
        COALESCE(SUM(mli.fat_g), 0) as fat_g,
        COALESCE(SUM(mli.sodium_mg), 0) as sodium_mg,
        COALESCE(SUM(mli.potassium_mg), 0) as potassium_mg,
        COALESCE(SUM(mli.phosphorus_mg), 0) as phosphorus_mg
    ")
    ->first();

And add this index too:

DB::statement("
    CREATE INDEX IF NOT EXISTS idx_health_meal_log_items_meal_log_id
    ON health_meal_log_items (meal_log_id)
");
9. Final Endpoint List

After this step, your backend has these unified dashboard endpoints:

GET /api/v1/dashboard/overview
GET /api/v1/dashboard/finance
GET /api/v1/dashboard/health?date=YYYY-MM-DD
GET /api/v1/dashboard/projects
GET /api/v1/dashboard/trends
10. Step 16 Result

Step 16 is now covering:

Unified Dashboard Backend
├── Finance Aggregation
│   ├── Total balance
│   ├── Income
│   ├── Expenses
│   ├── Net cashflow
│   └── Monthly savings
│
├── Health Aggregation
│   ├── Steps
│   ├── Distance
│   ├── Calories burned
│   ├── Water intake
│   ├── Nutrition totals
│   └── Latest weight
│
├── Project Aggregation
│   ├── Total projects
│   ├── Status counts
│   ├── Critical projects
│   ├── Overdue projects
│   └── Average progress
│
├── Daily Summary
│   ├── Today income
│   ├── Today expenses
│   └── Projects updated today
│
└── Optimized PostgreSQL Indexes
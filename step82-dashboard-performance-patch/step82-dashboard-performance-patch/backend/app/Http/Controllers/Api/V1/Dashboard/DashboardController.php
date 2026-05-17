<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $userId = (string) $user->id;
        $today = now()->toDateString();
        $monthStart = now()->startOfMonth()->toDateString();
        $monthEnd = now()->endOfMonth()->toDateString();

        $cacheKey = "dashboard_summary_user_{$userId}_{$today}";

        $data = Cache::remember($cacheKey, now()->addSeconds(60), function () use ($userId, $today, $monthStart, $monthEnd) {
            $finance = $this->financeSummary($userId, $monthStart, $monthEnd);
            $health = $this->healthSummary($userId, $today);
            $projects = $this->projectSummary($userId);

            return [
                'finance' => $finance,
                'health' => $health,
                'projects' => $projects,
                'generated_at' => now()->toDateTimeString(),
                'cache_ttl_seconds' => 60,

                // Flat aliases used by current Vue dashboard cards.
                'accounts_count' => $finance['accounts_count'],
                'total_balance' => $finance['total_balance'],
                'income' => $finance['monthly_income'],
                'monthly_income' => $finance['monthly_income'],
                'monthly_expense' => $finance['monthly_expense'],
                'savings_rate' => $finance['savings_rate'],
                'today_steps' => $health['today_steps'],
                'today_calories' => $health['today_calories'],
                'water_intake_ml' => $health['today_water_ml'],
                'current_weight_kg' => $health['latest_weight'],
                'active_projects' => $projects['active_projects'],
                'total_projects' => $projects['total_projects'],
                'completed_tasks' => $projects['completed_tasks'],
                'pending_tasks' => $projects['pending_tasks'],
            ];
        });

        return response()->json([
            'status' => true,
            'success' => true,
            'message' => 'Dashboard summary loaded successfully.',
            'data' => $data,
        ]);
    }

    private function financeSummary(string $userId, string $monthStart, string $monthEnd): array
    {
        $accountsTable = $this->firstExistingTable(['finance_accounts', 'nix_life_os.finance_account', 'finance_account']);
        $transactionsTable = $this->firstExistingTable(['finance_transactions', 'nix_life_os.finance_transaction', 'finance_transaction']);

        $accountsCount = 0;
        $totalBalance = 0.0;
        $monthlyIncome = 0.0;
        $monthlyExpense = 0.0;

        if ($accountsTable) {
            $accountsQuery = DB::table($accountsTable)->where('user_id', $userId);
            $accountsCount = (int) (clone $accountsQuery)->count();
            $totalBalance = (float) (clone $accountsQuery)->sum($this->firstExistingColumn($accountsTable, ['current_balance', 'balance'], 'current_balance'));
        }

        if ($transactionsTable) {
            $typeColumn = $this->firstExistingColumn($transactionsTable, ['transaction_type', 'type'], 'transaction_type');
            $dateColumn = $this->firstExistingColumn($transactionsTable, ['transaction_date', 'date', 'created_at'], 'transaction_date');

            $monthlyIncome = (float) DB::table($transactionsTable)
                ->where('user_id', $userId)
                ->where($typeColumn, 'income')
                ->whereBetween($dateColumn, [$monthStart, $monthEnd])
                ->sum('amount');

            $monthlyExpense = (float) DB::table($transactionsTable)
                ->where('user_id', $userId)
                ->where($typeColumn, 'expense')
                ->whereBetween($dateColumn, [$monthStart, $monthEnd])
                ->sum('amount');
        }

        $savingsRate = $monthlyIncome > 0
            ? round((($monthlyIncome - $monthlyExpense) / $monthlyIncome) * 100, 2)
            : 0;

        return [
            'accounts_count' => $accountsCount,
            'total_balance' => round($totalBalance, 2),
            'monthly_income' => round($monthlyIncome, 2),
            'monthly_expense' => round($monthlyExpense, 2),
            'savings_rate' => $savingsRate,
        ];
    }

    private function healthSummary(string $userId, string $today): array
    {
        $weightTable = $this->firstExistingTable(['health_weight_logs']);
        $stepsTable = $this->firstExistingTable(['health_step_log', 'health_step_logs']);
        $hydrationTable = $this->firstExistingTable(['health_hydration_logs']);
        $nutritionTable = $this->firstExistingTable(['health_nutrition_logs']);

        $latestWeight = null;
        $todaySteps = 0;
        $todayWaterMl = 0;
        $todayCalories = 0;

        if ($weightTable) {
            $dateColumn = $this->firstExistingColumn($weightTable, ['log_date', 'date', 'created_at'], 'log_date');
            $latestWeight = DB::table($weightTable)
                ->where('user_id', $userId)
                ->orderByDesc($dateColumn)
                ->value('weight_kg');
        }

        if ($stepsTable) {
            $dateColumn = $this->firstExistingColumn($stepsTable, ['log_date', 'date', 'created_at'], 'log_date');
            $stepsColumn = $this->firstExistingColumn($stepsTable, ['steps_count', 'steps'], 'steps_count');
            $todaySteps = (int) DB::table($stepsTable)
                ->where('user_id', $userId)
                ->whereDate($dateColumn, $today)
                ->sum($stepsColumn);
        }

        if ($hydrationTable) {
            $dateColumn = $this->firstExistingColumn($hydrationTable, ['log_date', 'date', 'created_at'], 'log_date');
            $todayWaterMl = (int) DB::table($hydrationTable)
                ->where('user_id', $userId)
                ->whereDate($dateColumn, $today)
                ->sum('amount_ml');
        }

        if ($nutritionTable) {
            $dateColumn = $this->firstExistingColumn($nutritionTable, ['log_date', 'meal_date', 'date', 'created_at'], 'log_date');
            $calorieColumn = $this->firstExistingColumn($nutritionTable, ['calories', 'calories_kcal', 'total_calories'], 'calories');
            $todayCalories = (int) DB::table($nutritionTable)
                ->where('user_id', $userId)
                ->whereDate($dateColumn, $today)
                ->sum($calorieColumn);
        }

        return [
            'latest_weight' => $latestWeight !== null ? (float) $latestWeight : null,
            'today_steps' => $todaySteps,
            'today_water_ml' => $todayWaterMl,
            'today_calories' => $todayCalories,
        ];
    }

    private function projectSummary(string $userId): array
    {
        $projectsTable = $this->firstExistingTable(['projects']);
        $tasksTable = $this->firstExistingTable(['project_tasks']);

        $totalProjects = 0;
        $activeProjects = 0;
        $completedTasks = 0;
        $pendingTasks = 0;

        if ($projectsTable) {
            $baseProjects = DB::table($projectsTable)->where('user_id', $userId);
            $totalProjects = (int) (clone $baseProjects)->count();
            $activeProjects = (int) (clone $baseProjects)->whereIn('status', ['active', 'in_progress'])->count();
        }

        if ($tasksTable) {
            $baseTasks = DB::table($tasksTable)->where('user_id', $userId);
            $completedTasks = (int) (clone $baseTasks)->where('status', 'completed')->count();
            $pendingTasks = (int) (clone $baseTasks)->whereIn('status', ['pending', 'todo', 'in_progress'])->count();
        }

        return [
            'total_projects' => $totalProjects,
            'active_projects' => $activeProjects,
            'completed_tasks' => $completedTasks,
            'pending_tasks' => $pendingTasks,
        ];
    }

    private function firstExistingTable(array $tables): ?string
    {
        foreach ($tables as $table) {
            if ($this->tableExists($table)) {
                return $table;
            }
        }

        return null;
    }

    private function tableExists(string $table): bool
    {
        if (str_contains($table, '.')) {
            [$schema, $name] = explode('.', $table, 2);

            return DB::table('information_schema.tables')
                ->where('table_schema', $schema)
                ->where('table_name', $name)
                ->exists();
        }

        return Schema::hasTable($table);
    }

    private function firstExistingColumn(string $table, array $columns, string $fallback): string
    {
        foreach ($columns as $column) {
            if ($this->columnExists($table, $column)) {
                return $column;
            }
        }

        return $fallback;
    }

    private function columnExists(string $table, string $column): bool
    {
        if (str_contains($table, '.')) {
            [$schema, $name] = explode('.', $table, 2);

            return DB::table('information_schema.columns')
                ->where('table_schema', $schema)
                ->where('table_name', $name)
                ->where('column_name', $column)
                ->exists();
        }

        return Schema::hasColumn($table, $column);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Reports summary loaded successfully.',
            'data' => [
                'finance' => $this->financeData($request),
                'health' => $this->healthData($request),
                'productivity' => $this->productivityData($request),
                'generated_at' => now()->toDateTimeString(),
            ],
        ]);
    }

    public function finance(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Finance report loaded successfully.',
            'data' => $this->financeData($request),
        ]);
    }

    public function health(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Health report loaded successfully.',
            'data' => $this->healthData($request),
        ]);
    }

    public function productivity(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Productivity report loaded successfully.',
            'data' => $this->productivityData($request),
        ]);
    }

    private function financeData(Request $request): array
    {
        $userId = $request->user()->id;

        return [
            'accounts_count' => $this->count('finance_accounts', $userId),
            'transactions_count' => $this->count('finance_transactions', $userId),
            'budgets_count' => $this->count('finance_budgets', $userId),
            'total_balance' => $this->sum('finance_accounts', 'current_balance', $userId),
            'monthly_income' => $this->transactionSum($userId, 'income'),
            'monthly_expense' => $this->transactionSum($userId, 'expense'),
        ];
    }

    private function healthData(Request $request): array
    {
        $userId = $request->user()->id;

        return [
            'nutrition_logs_count' => $this->count('health_nutrition_logs', $userId),
            'hydration_logs_count' => $this->count('health_hydration_logs', $userId),
            'weight_logs_count' => $this->count('health_weight_logs', $userId),
            'step_logs_count' => $this->count($this->stepsTable(), $userId),
            'lab_tests_count' => $this->count('health_lab_tests', $userId),
            'medications_count' => $this->count('health_medications', $userId),
        ];
    }

    private function productivityData(Request $request): array
    {
        $userId = $request->user()->id;

        return [
            'tasks_count' => $this->count('productivity_tasks', $userId),
            'goals_count' => $this->count('productivity_goals', $userId),
            'habits_count' => $this->count('productivity_habits', $userId),
            'calendar_events_count' => $this->count('productivity_calendar_events', $userId),
        ];
    }

    private function count(?string $table, string $userId): int
    {
        if (!$table || !Schema::hasTable($table)) {
            return 0;
        }

        return (int) DB::table($table)->where('user_id', $userId)->count();
    }

    private function sum(string $table, string $column, string $userId): float
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, $column)) {
            return 0.0;
        }

        return (float) DB::table($table)->where('user_id', $userId)->sum($column);
    }

    private function transactionSum(string $userId, string $type): float
    {
        if (!Schema::hasTable('finance_transactions')) {
            return 0.0;
        }

        return (float) DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->where('transaction_type', $type)
            ->whereMonth('transaction_date', now()->month)
            ->whereYear('transaction_date', now()->year)
            ->sum('amount');
    }

    private function stepsTable(): ?string
    {
        if (Schema::hasTable('health_step_logs')) {
            return 'health_step_logs';
        }

        if (Schema::hasTable('health_steps_logs')) {
            return 'health_steps_logs';
        }

        return null;
    }
}

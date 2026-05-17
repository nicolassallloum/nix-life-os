<?php

namespace App\Services\Dashboard;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class UnifiedDashboardService
{
    private const CACHE_TTL_SECONDS = 60;

    public function getOverview(string $userId): array
    {
        $today = Carbon::today()->toDateString();

        return Cache::remember("dashboard:overview:{$userId}:{$today}", self::CACHE_TTL_SECONDS, function () use ($userId, $today) {
            return [
                'finance' => $this->getFinanceKpis($userId),
                'health' => $this->getHealthKpis($userId, $today),
                'projects' => $this->getProjectKpis($userId),
                'daily_summary' => $this->getDailySummary($userId, $today),
            ];
        });
    }

    public function getFinanceKpis(string $userId): array
    {
        $monthStart = Carbon::now()->startOfMonth()->toDateString();
        $nextMonthStart = Carbon::now()->addMonthNoOverflow()->startOfMonth()->toDateString();

        $accountSummary = DB::table('finance_accounts')
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->selectRaw('COALESCE(SUM(current_balance), 0) AS total_balance, COUNT(*) AS total_accounts')
            ->first();

        $transactionSummary = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->selectRaw("\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS total_income,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS total_expenses,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0)\n                -\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS net_cashflow\n            ")
            ->first();

        $monthlySummary = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->where('transaction_date', '>=', $monthStart)
            ->where('transaction_date', '<', $nextMonthStart)
            ->selectRaw("\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS monthly_income,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS monthly_expenses\n            ")
            ->first();

        return [
            'total_balance' => round((float) ($accountSummary->total_balance ?? 0), 2),
            'total_accounts' => (int) ($accountSummary->total_accounts ?? 0),
            'total_income' => round((float) ($transactionSummary->total_income ?? 0), 2),
            'total_expenses' => round((float) ($transactionSummary->total_expenses ?? 0), 2),
            'net_cashflow' => round((float) ($transactionSummary->net_cashflow ?? 0), 2),
            'monthly_income' => round((float) ($monthlySummary->monthly_income ?? 0), 2),
            'monthly_expenses' => round((float) ($monthlySummary->monthly_expenses ?? 0), 2),
            'monthly_savings' => round((float) ($monthlySummary->monthly_income ?? 0) - (float) ($monthlySummary->monthly_expenses ?? 0), 2),
        ];
    }

    public function getHealthKpis(string $userId, string $date): array
    {
        $nextDate = Carbon::parse($date)->addDay()->toDateString();

        $steps = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->where('log_date', '>=', $date)
            ->where('log_date', '<', $nextDate)
            ->selectRaw('COALESCE(SUM(steps_count), 0) AS total_steps, COALESCE(SUM(distance_km), 0) AS total_distance_km, COALESCE(SUM(calories_burned), 0) AS calories_burned')
            ->first();

        $hydration = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->where('log_date', '>=', $date)
            ->where('log_date', '<', $nextDate)
            ->selectRaw('COALESCE(SUM(amount_ml), 0) AS total_water_ml')
            ->first();

        $nutrition = DB::table('health_meal_logs')
            ->where('user_id', $userId)
            ->where('meal_date', '>=', $date)
            ->where('meal_date', '<', $nextDate)
            ->selectRaw("\n                COALESCE(SUM(total_calories), 0) AS calories,\n                COALESCE(SUM(total_protein_g), 0) AS protein_g,\n                COALESCE(SUM(total_carbs_g), 0) AS carbs_g,\n                COALESCE(SUM(total_fat_g), 0) AS fat_g,\n                COALESCE(SUM(total_sodium_mg), 0) AS sodium_mg,\n                COALESCE(SUM(total_potassium_mg), 0) AS potassium_mg,\n                COALESCE(SUM(total_phosphorus_mg), 0) AS phosphorus_mg\n            ")
            ->first();

        $latestWeight = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->select('weight_kg', 'log_date')
            ->first();

        return [
            'date' => $date,
            'steps' => (int) ($steps->total_steps ?? 0),
            'distance_km' => round((float) ($steps->total_distance_km ?? 0), 2),
            'calories_burned' => round((float) ($steps->calories_burned ?? 0), 2),
            'water_ml' => (int) ($hydration->total_water_ml ?? 0),
            'nutrition' => [
                'calories' => round((float) ($nutrition->calories ?? 0), 2),
                'protein_g' => round((float) ($nutrition->protein_g ?? 0), 2),
                'carbs_g' => round((float) ($nutrition->carbs_g ?? 0), 2),
                'fat_g' => round((float) ($nutrition->fat_g ?? 0), 2),
                'sodium_mg' => round((float) ($nutrition->sodium_mg ?? 0), 2),
                'potassium_mg' => round((float) ($nutrition->potassium_mg ?? 0), 2),
                'phosphorus_mg' => round((float) ($nutrition->phosphorus_mg ?? 0), 2),
            ],
            'latest_weight' => $latestWeight ? [
                'weight_kg' => round((float) $latestWeight->weight_kg, 2),
                'log_date' => $latestWeight->log_date,
            ] : null,
        ];
    }

    public function getProjectKpis(string $userId): array
    {
        $today = Carbon::today()->toDateString();

        $summary = DB::table('projects')
            ->where('user_id', $userId)
            ->selectRaw("\n                COUNT(*) AS total_projects,\n                COUNT(*) FILTER (WHERE status = 'not_started') AS not_started,\n                COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,\n                COUNT(*) FILTER (WHERE status = 'completed') AS completed,\n                COUNT(*) FILTER (WHERE status = 'on_hold') AS on_hold,\n                COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled,\n                COUNT(*) FILTER (WHERE priority = 'critical') AS critical_projects,\n                COUNT(*) FILTER (WHERE target_end_date IS NOT NULL AND target_end_date < ? AND status NOT IN ('completed', 'cancelled')) AS overdue_projects,\n                COALESCE(AVG(progress_percentage), 0) AS average_progress\n            ", [$today])
            ->first();

        return [
            'total_projects' => (int) ($summary->total_projects ?? 0),
            'not_started' => (int) ($summary->not_started ?? 0),
            'in_progress' => (int) ($summary->in_progress ?? 0),
            'completed' => (int) ($summary->completed ?? 0),
            'on_hold' => (int) ($summary->on_hold ?? 0),
            'cancelled' => (int) ($summary->cancelled ?? 0),
            'critical_projects' => (int) ($summary->critical_projects ?? 0),
            'overdue_projects' => (int) ($summary->overdue_projects ?? 0),
            'average_progress' => round((float) ($summary->average_progress ?? 0), 2),
        ];
    }

    public function getDailySummary(string $userId, string $date): array
    {
        $nextDate = Carbon::parse($date)->addDay()->toDateString();

        $financeToday = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->where('transaction_date', '>=', $date)
            ->where('transaction_date', '<', $nextDate)
            ->selectRaw("\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS income_today,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS expenses_today\n            ")
            ->first();

        $projectsUpdatedToday = DB::table('projects')
            ->where('user_id', $userId)
            ->where('updated_at', '>=', Carbon::parse($date)->startOfDay())
            ->where('updated_at', '<', Carbon::parse($date)->addDay()->startOfDay())
            ->count();

        return [
            'date' => $date,
            'income_today' => round((float) ($financeToday->income_today ?? 0), 2),
            'expenses_today' => round((float) ($financeToday->expenses_today ?? 0), 2),
            'projects_updated_today' => (int) $projectsUpdatedToday,
        ];
    }

    public function getFinanceTrend(string $userId): array
    {
        $startDate = Carbon::now()->subDays(30)->toDateString();

        return DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->where('transaction_date', '>=', $startDate)
            ->selectRaw("\n                transaction_date AS date,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'income'), 0) AS income,\n                COALESCE(SUM(amount) FILTER (WHERE transaction_type = 'expense'), 0) AS expenses\n            ")
            ->groupBy('transaction_date')
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
        $startDate = Carbon::now()->subDays(30)->toDateString();

        return DB::table('health_step_log')
            ->where('user_id', $userId)
            ->where('log_date', '>=', $startDate)
            ->selectRaw('log_date AS date, COALESCE(SUM(steps_count), 0) AS steps, COALESCE(SUM(calories_burned), 0) AS calories_burned')
            ->groupBy('log_date')
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
            ->selectRaw('status, COUNT(*) AS total, COALESCE(AVG(progress_percentage), 0) AS average_progress')
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

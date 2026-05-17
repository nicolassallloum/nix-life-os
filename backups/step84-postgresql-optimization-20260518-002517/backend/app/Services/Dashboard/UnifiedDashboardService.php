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
        $accountSummary = DB::table('finance_account')
            ->where('user_id', $userId)
            ->selectRaw("
                COALESCE(SUM(current_balance), 0) as total_balance,
                COUNT(*) as total_accounts
            ")
            ->first();

        $transactionSummary = DB::table('nix_life_os.finance_transaction')
            ->where('user_id', $userId)
            ->selectRaw("
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0) as total_income,
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as total_expenses,
                COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END), 0)
                -
                COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END), 0) as net_cashflow
            ")
            ->first();

        $monthlySummary = DB::table('nix_life_os.finance_transaction')
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
        $steps = DB::table('nix_life_os.health_step_log')
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
        $financeToday = DB::table('nix_life_os.finance_transaction')
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
        return DB::table('nix_life_os.finance_transaction')
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
        return DB::table('nix_life_os.health_step_log')
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

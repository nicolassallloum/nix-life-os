<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UnifiedDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        $totalBalance = DB::table('finance_account')
            ->where('user_id', $user->id)
            // ->whereNull('deleted_at')
            ->sum('current_balance');

        $monthlyIncome = DB::table('nix_life_os.finance_transaction')
            ->where('user_id', $user->id)
            ->where('transaction_type', 'income')
            ->whereMonth('transaction_date', now()->month)
            ->whereYear('transaction_date', now()->year)
            ->sum('amount');

        $monthlyExpense = DB::table('nix_life_os.finance_transaction')
            ->where('user_id', $user->id)
            ->where('transaction_type', 'expense')
            ->whereMonth('transaction_date', now()->month)
            ->whereYear('transaction_date', now()->year)
            ->sum('amount');

        $savingsRate = $monthlyIncome > 0
            ? round((($monthlyIncome - $monthlyExpense) / $monthlyIncome) * 100)
            : 0;

        $todaySteps = DB::table('nix_life_os.health_step_log')
            ->where('user_id', $user->id)
            ->whereDate('log_date', today())
            ->sum('steps_count');

        $todayCalories = DB::table('nix_life_os.health_meal_log')
            ->where('user_id', $user->id)
            ->whereDate('meal_date', today())
            ->sum('total_calories');

        $todayWaterMl = DB::table('nix_life_os.health_hydration_logs')
            ->where('user_id', $user->id)
            ->whereDate('log_date', today())
            ->sum('amount_ml');

        $weightKg = DB::table('nix_life_os.health_weight_log')
            ->where('user_id', $user->id)
            ->orderByDesc('log_date')
            ->value('weight_kg');

        $totalProjects = DB::table('projects')
            ->where('user_id', $user->id)
            ->count();

        $activeProjects = DB::table('projects')
            ->where('user_id', $user->id)
            ->where('status', 'in_progress')
            ->count();

        $completedProjects = DB::table('projects')
            ->where('user_id', $user->id)
            ->where('status', 'completed')
            ->count();

        $averageProgress = DB::table('projects')
            ->where('user_id', $user->id)
            ->avg('progress_percentage');

        return response()->json([
            'success' => true,
            'data' => [
                'finance' => [
                    'total_balance' => round($totalBalance, 2),
                    'monthly_income' => round($monthlyIncome, 2),
                    'monthly_expense' => round($monthlyExpense, 2),
                    'savings_rate' => $savingsRate,
                ],
                'health' => [
                    'today_steps' => (int) $todaySteps,
                    'today_calories' => (int) $todayCalories,
                    'today_water_ml' => (int) $todayWaterMl,
                    'weight_kg' => $weightKg ? (float) $weightKg : 0,
                ],
                'projects' => [
                    'total_projects' => $totalProjects,
                    'active_projects' => $activeProjects,
                    'completed_projects' => $completedProjects,
                    'average_progress' => round($averageProgress ?? 0),
                ],
            ],
        ]);
    }

    public function kpis(Request $request)
    {
        $user = $request->user();

        $financeRows = DB::table('nix_life_os.finance_transaction')
            ->selectRaw("TO_CHAR(transaction_date, 'Mon DD') as label")
            ->selectRaw("
                SUM(
                    CASE 
                        WHEN transaction_type = 'income' THEN amount
                        WHEN transaction_type = 'expense' THEN -amount
                        ELSE 0
                    END
                ) as value
            ")
            ->where('user_id', $user->id)
            ->whereDate('transaction_date', '>=', now()->subDays(7))
            ->groupByRaw("TO_CHAR(transaction_date, 'Mon DD'), transaction_date")
            ->orderByRaw('transaction_date')
            ->get();

        $stepsRows = DB::table('nix_life_os.health_step_log')
            ->selectRaw("TO_CHAR(log_date, 'Mon DD') as label")
            ->selectRaw("SUM(steps_count) as value")
            ->where('user_id', $user->id)
            ->whereDate('log_date', '>=', now()->subDays(7))
            ->groupByRaw("TO_CHAR(log_date, 'Mon DD'), log_date")
            ->orderByRaw('log_date')
            ->get();

        $calorieRows = DB::table('nix_life_os.health_meal_log')
            ->selectRaw("TO_CHAR(meal_date, 'Mon DD') as label")
            ->selectRaw("SUM(total_calories) as value")
            ->where('user_id', $user->id)
            ->whereDate('meal_date', '>=', now()->subDays(7))
            ->groupByRaw("TO_CHAR(meal_date, 'Mon DD'), meal_date")
            ->orderByRaw('meal_date')
            ->get();

        $projectRows = DB::table('projects')
            ->select('project_name as label', 'progress_percentage as value')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(6)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'finance_chart' => [
                    'labels' => $financeRows->pluck('label'),
                    'values' => $financeRows->pluck('value')->map(fn ($v) => round($v, 2)),
                ],
                'steps_chart' => [
                    'labels' => $stepsRows->pluck('label'),
                    'values' => $stepsRows->pluck('value')->map(fn ($v) => (int) $v),
                ],
                'calories_chart' => [
                    'labels' => $calorieRows->pluck('label'),
                    'values' => $calorieRows->pluck('value')->map(fn ($v) => (int) $v),
                ],
                'projects_chart' => [
                    'labels' => $projectRows->pluck('label'),
                    'values' => $projectRows->pluck('value')->map(fn ($v) => (int) $v),
                ],
            ],
        ]);
    }

    public function recentActivity(Request $request)
    {
        $user = $request->user();

        $activities = collect();

        $financeActivities = DB::table('nix_life_os.finance_transaction')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => 'finance-' . $item->id,
                    'type' => 'finance',
                    'title' => 'Finance transaction recorded',
                    'description' => ucfirst($item->transaction_type) . ' transaction of ' . $item->amount,
                    'activity_date' => $item->created_at,
                ];
            });

        $projectActivities = DB::table('projects')
            ->where('user_id', $user->id)
            ->orderByDesc('updated_at')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => 'project-' . $item->id,
                    'type' => 'project',
                    'title' => 'Project updated',
                    'description' => $item->project_name . ' is now at ' . $item->progress_percentage . '%',
                    'activity_date' => $item->updated_at,
                ];
            });

        $stepActivities = DB::table('nix_life_os.health_step_log')
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => 'steps-' . $item->id,
                    'type' => 'health',
                    'title' => 'Steps logged',
                    'description' => $item->steps_count . ' steps recorded',
                    'activity_date' => $item->created_at,
                ];
            });

        $activities = $activities
            ->merge($financeActivities)
            ->merge($projectActivities)
            ->merge($stepActivities)
            ->sortByDesc('activity_date')
            ->take(10)
            ->values();

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    }
}
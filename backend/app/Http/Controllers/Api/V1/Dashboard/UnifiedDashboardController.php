<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class UnifiedDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();

        $totalBalance = $this->tableExists('finance_accounts')
            ? DB::table('finance_accounts')
                ->where('user_id', $user->id)
                ->sum('current_balance')
            : 0;

        $monthlyIncome = $this->tableExists('finance_transactions')
            ? DB::table('finance_transactions')
                ->where('user_id', $user->id)
                ->where('transaction_type', 'income')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount')
            : 0;

        $monthlyExpense = $this->tableExists('finance_transactions')
            ? DB::table('finance_transactions')
                ->where('user_id', $user->id)
                ->where('transaction_type', 'expense')
                ->whereMonth('transaction_date', now()->month)
                ->whereYear('transaction_date', now()->year)
                ->sum('amount')
            : 0;

        $savingsRate = $monthlyIncome > 0
            ? round((($monthlyIncome - $monthlyExpense) / $monthlyIncome) * 100)
            : 0;

        $todaySteps = $this->tableExists('health_step_logs')
            ? DB::table('health_step_logs')
                ->where('user_id', $user->id)
                ->whereDate('log_date', today())
                ->sum('steps')
            : 0;

        $todayCalories = 0;

        if ($this->tableExists('health_meal_logs')) {
            $todayCalories += (float) DB::table('health_meal_logs')
                ->where('user_id', $user->id)
                ->whereDate('meal_date', today())
                ->sum('total_calories');
        }

        if ($this->tableExists('health_nutrition_logs')) {
            $todayCalories += (float) DB::table('health_nutrition_logs')
                ->where('user_id', $user->id)
                ->whereDate('meal_date', today())
                ->sum('calories');
        }

        $todayWaterMl = $this->tableExists('health_hydration_logs')
            ? DB::table('health_hydration_logs')
                ->where('user_id', $user->id)
                ->whereDate('log_date', today())
                ->sum('amount_ml')
            : 0;

        $weightKg = $this->tableExists('health_weight_logs')
            ? DB::table('health_weight_logs')
                ->where('user_id', $user->id)
                ->orderByDesc('log_date')
                ->value('weight_kg')
            : null;

        $totalProjects = $this->tableExists('projects')
            ? DB::table('projects')
                ->where('user_id', $user->id)
                ->count()
            : 0;

        $activeProjects = $this->tableExists('projects')
            ? DB::table('projects')
                ->where('user_id', $user->id)
                ->where('status', 'in_progress')
                ->count()
            : 0;

        $completedProjects = $this->tableExists('projects')
            ? DB::table('projects')
                ->where('user_id', $user->id)
                ->where('status', 'completed')
                ->count()
            : 0;

        $averageProgress = $this->tableExists('projects')
            ? DB::table('projects')
                ->where('user_id', $user->id)
                ->avg('progress_percentage')
            : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'finance' => [
                    'total_balance' => round((float) $totalBalance, 2),
                    'monthly_income' => round((float) $monthlyIncome, 2),
                    'monthly_expense' => round((float) $monthlyExpense, 2),
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
                    'average_progress' => round((float) ($averageProgress ?? 0)),
                ],
            ],
        ]);
    }

    public function kpis(Request $request)
    {
        $user = $request->user();

        $financeRows = $this->tableExists('finance_transactions')
            ? DB::table('finance_transactions')
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
                ->get()
            : collect();

        $stepsRows = $this->tableExists('health_step_logs')
            ? DB::table('health_step_logs')
                ->selectRaw("TO_CHAR(log_date, 'Mon DD') as label")
                ->selectRaw("SUM(steps) as value")
                ->where('user_id', $user->id)
                ->whereDate('log_date', '>=', now()->subDays(7))
                ->groupByRaw("TO_CHAR(log_date, 'Mon DD'), log_date")
                ->orderByRaw('log_date')
                ->get()
            : collect();

        $calorieRows = collect();

        if ($this->tableExists('health_meal_logs')) {
            $calorieRows = DB::table('health_meal_logs')
                ->selectRaw("TO_CHAR(meal_date, 'Mon DD') as label")
                ->selectRaw("SUM(total_calories) as value")
                ->where('user_id', $user->id)
                ->whereDate('meal_date', '>=', now()->subDays(7))
                ->groupByRaw("TO_CHAR(meal_date, 'Mon DD'), meal_date")
                ->orderByRaw('meal_date')
                ->get();
        } elseif ($this->tableExists('health_nutrition_logs')) {
            $calorieRows = DB::table('health_nutrition_logs')
                ->selectRaw("TO_CHAR(meal_date, 'Mon DD') as label")
                ->selectRaw("SUM(calories) as value")
                ->where('user_id', $user->id)
                ->whereDate('meal_date', '>=', now()->subDays(7))
                ->groupByRaw("TO_CHAR(meal_date, 'Mon DD'), meal_date")
                ->orderByRaw('meal_date')
                ->get();
        }

        $projectRows = $this->tableExists('projects')
            ? DB::table('projects')
                ->select('project_name as label', 'progress_percentage as value')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(6)
                ->get()
            : collect();

        return response()->json([
            'success' => true,
            'data' => [
                'finance_chart' => [
                    'labels' => $financeRows->pluck('label')->values(),
                    'values' => $financeRows->pluck('value')->map(fn ($v) => round((float) $v, 2))->values(),
                ],
                'steps_chart' => [
                    'labels' => $stepsRows->pluck('label')->values(),
                    'values' => $stepsRows->pluck('value')->map(fn ($v) => (int) $v)->values(),
                ],
                'calories_chart' => [
                    'labels' => $calorieRows->pluck('label')->values(),
                    'values' => $calorieRows->pluck('value')->map(fn ($v) => (int) $v)->values(),
                ],
                'projects_chart' => [
                    'labels' => $projectRows->pluck('label')->values(),
                    'values' => $projectRows->pluck('value')->map(fn ($v) => (int) $v)->values(),
                ],
            ],
        ]);
    }

    public function recentActivity(Request $request)
    {
        $user = $request->user();

        $activities = collect();

        if ($this->tableExists('finance_transactions')) {
            $financeActivities = DB::table('finance_transactions')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get()
                ->map(function ($item) {
                    $description = trim((string) ($item->description ?? ''));

                    return [
                        'id' => 'finance-' . $item->id,
                        'type' => 'finance',
                        'title' => 'Finance transaction recorded',
                        'description' => $description !== ''
                            ? $description
                            : ucfirst((string) $item->transaction_type) . ' transaction of ' . number_format((float) $item->amount, 2),
                        'activity_date' => $item->created_at,
                    ];
                });

            $activities = $activities->merge($financeActivities);
        }

        if ($this->tableExists('projects')) {
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
                        'description' => ($item->project_name ?? 'Project') . ' is now at ' . (int) ($item->progress_percentage ?? 0) . '%',
                        'activity_date' => $item->updated_at,
                    ];
                });

            $activities = $activities->merge($projectActivities);
        }

        if ($this->tableExists('health_step_logs')) {
            $stepActivities = DB::table('health_step_logs')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get()
                ->map(function ($item) {
                    return [
                        'id' => 'steps-' . $item->id,
                        'type' => 'health',
                        'title' => 'Steps logged',
                        'description' => number_format((int) ($item->steps ?? 0)) . ' steps recorded',
                        'activity_date' => $item->created_at,
                    ];
                });

            $activities = $activities->merge($stepActivities);
        }

        if ($this->tableExists('health_hydration_logs')) {
            $hydrationActivities = DB::table('health_hydration_logs')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get()
                ->map(function ($item) {
                    return [
                        'id' => 'hydration-' . $item->id,
                        'type' => 'health',
                        'title' => 'Hydration logged',
                        'description' => number_format((float) ($item->amount_ml ?? 0)) . ' ml recorded',
                        'activity_date' => $item->created_at,
                    ];
                });

            $activities = $activities->merge($hydrationActivities);
        }

        if ($this->tableExists('health_nutrition_logs')) {
            $nutritionActivities = DB::table('health_nutrition_logs')
                ->where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get()
                ->map(function ($item) {
                    return [
                        'id' => 'nutrition-' . $item->id,
                        'type' => 'health',
                        'title' => 'Meal logged',
                        'description' => ($item->food_name ?? 'Meal') . ' - ' . number_format((float) ($item->calories ?? 0)) . ' calories',
                        'activity_date' => $item->created_at,
                    ];
                });

            $activities = $activities->merge($nutritionActivities);
        }

        $activities = $activities
            ->filter(fn ($item) => ! empty($item['activity_date']))
            ->sortByDesc('activity_date')
            ->take(10)
            ->values();

        return response()->json([
            'success' => true,
            'data' => $activities,
        ]);
    }

    private function tableExists(string $table): bool
    {
        return Schema::hasTable($table);
    }
}

<?php

namespace App\Services\LifeBalance;

use App\Models\LifeBalanceScore;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LifeBalanceService
{
    public function calculate(string $userId, ?string $date = null): LifeBalanceScore
    {
        $targetDate = $date
            ? Carbon::parse($date)->toDateString()
            : now()->toDateString();

        $finance = $this->calculateFinanceScore($userId, $targetDate);
        $health = $this->calculateHealthScore($userId, $targetDate);
        $productivity = $this->calculateProductivityScore($userId, $targetDate);

        $overallScore = (int) round(
            (
                $finance['score'] +
                $health['score'] +
                $productivity['score']
            ) / 3
        );

        $status = $this->resolveStatus($overallScore);

        $recommendations = $this->buildRecommendations(
            $finance,
            $health,
            $productivity,
            $overallScore
        );

        return LifeBalanceScore::updateOrCreate(
            [
                'user_id' => $userId,
                'target_date' => $targetDate,
            ],
            [
                'finance_score' => $finance['score'],
                'health_score' => $health['score'],
                'productivity_score' => $productivity['score'],
                'overall_score' => $overallScore,
                'status' => $status,
                'finance_breakdown' => $finance,
                'health_breakdown' => $health,
                'productivity_breakdown' => $productivity,
                'recommendations' => $recommendations,
            ]
        );
    }

    private function calculateFinanceScore(string $userId, string $date): array
    {
        $income = 0;
        $expenses = 0;

        if (Schema::hasTable('finance_transactions')) {
            $income = (float) DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->whereDate('transaction_date', $date)
                ->where('transaction_type', 'income')
                ->sum('amount');

            $expenses = (float) DB::table('finance_transactions')
                ->where('user_id', $userId)
                ->whereDate('transaction_date', $date)
                ->where('transaction_type', 'expense')
                ->sum('amount');
        }

        $netCashflow = $income - $expenses;

        $score = 50;

        if ($income > 0) {
            $expenseRatio = $expenses / max($income, 1);

            if ($expenseRatio <= 0.5) {
                $score = 95;
            } elseif ($expenseRatio <= 0.7) {
                $score = 85;
            } elseif ($expenseRatio <= 0.9) {
                $score = 70;
            } elseif ($expenseRatio <= 1) {
                $score = 55;
            } else {
                $score = 35;
            }
        } elseif ($expenses > 0) {
            $score = 40;
        }

        return [
            'score' => $this->clamp($score),
            'income' => round($income, 2),
            'expenses' => round($expenses, 2),
            'net_cashflow' => round($netCashflow, 2),
            'logic' => 'Finance score is based on income, expenses, and daily cashflow.',
        ];
    }

    private function calculateHealthScore(string $userId, string $date): array
    {
        $steps = 0;
        $waterMl = 0;
        $calories = 0;

        if (Schema::hasTable('health_step_logs')) {
            $steps = (int) DB::table('health_step_logs')
                ->where('user_id', $userId)
                ->whereDate('log_date', $date)
                ->sum('steps_count');
        }

        if (Schema::hasTable('health_hydration_logs')) {
            $waterMl = (int) DB::table('health_hydration_logs')
                ->where('user_id', $userId)
                ->whereDate('log_date', $date)
                ->sum('amount_ml');
        }

        if (Schema::hasTable('health_meal_logs')) {
            $calories = (float) DB::table('health_meal_logs')
                ->where('user_id', $userId)
                ->whereDate('meal_date', $date)
                ->sum('total_calories');
        }

        $stepsScore = min(100, ($steps / 7000) * 100);
        $hydrationScore = min(100, ($waterMl / 2000) * 100);

        $calorieScore = 50;

        if ($calories >= 1400 && $calories <= 1900) {
            $calorieScore = 100;
        } elseif ($calories >= 1000 && $calories < 1400) {
            $calorieScore = 75;
        } elseif ($calories > 1900 && $calories <= 2300) {
            $calorieScore = 70;
        } elseif ($calories > 0) {
            $calorieScore = 45;
        }

        $score = (int) round(
            ($stepsScore * 0.35) +
            ($hydrationScore * 0.35) +
            ($calorieScore * 0.30)
        );

        return [
            'score' => $this->clamp($score),
            'steps' => $steps,
            'water_ml' => $waterMl,
            'calories' => round($calories, 2),
            'steps_score' => round($stepsScore, 2),
            'hydration_score' => round($hydrationScore, 2),
            'calorie_score' => round($calorieScore, 2),
            'logic' => 'Health score is based on steps, hydration, and nutrition consistency.',
        ];
    }

    private function calculateProductivityScore(string $userId, string $date): array
    {
        $totalTasks = 0;
        $completedTasks = 0;
        $activeProjects = 0;

        if (Schema::hasTable('project_tasks')) {
            $totalTasks = (int) DB::table('project_tasks')
                ->where('user_id', $userId)
                ->whereDate('created_at', '<=', $date)
                ->count();

            $completedTasks = (int) DB::table('project_tasks')
                ->where('user_id', $userId)
                ->whereDate('created_at', '<=', $date)
                ->whereIn('status', ['done', 'completed'])
                ->count();
        }

        if (Schema::hasTable('projects')) {
            $activeProjects = (int) DB::table('projects')
                ->where('user_id', $userId)
                ->whereIn('status', ['active', 'in_progress'])
                ->count();
        }

        if ($totalTasks === 0) {
            $taskCompletionScore = 50;
        } else {
            $taskCompletionScore = ($completedTasks / max($totalTasks, 1)) * 100;
        }

        $projectFocusScore = match (true) {
            $activeProjects === 0 => 45,
            $activeProjects <= 3 => 100,
            $activeProjects <= 5 => 75,
            default => 55,
        };

        $score = (int) round(
            ($taskCompletionScore * 0.75) +
            ($projectFocusScore * 0.25)
        );

        return [
            'score' => $this->clamp($score),
            'total_tasks' => $totalTasks,
            'completed_tasks' => $completedTasks,
            'active_projects' => $activeProjects,
            'task_completion_score' => round($taskCompletionScore, 2),
            'project_focus_score' => round($projectFocusScore, 2),
            'logic' => 'Productivity score is based on task completion and active project focus.',
        ];
    }

    private function buildRecommendations(
        array $finance,
        array $health,
        array $productivity,
        int $overallScore
    ): array {
        $items = [];

        if ($finance['score'] < 70) {
            $items[] = [
                'module' => 'Finance',
                'message' => 'Reduce daily expenses or review high-spending categories.',
                'priority' => 'high',
            ];
        }

        if ($health['score'] < 70) {
            $items[] = [
                'module' => 'Health',
                'message' => 'Improve hydration, steps, or nutrition consistency today.',
                'priority' => 'high',
            ];
        }

        if ($productivity['score'] < 70) {
            $items[] = [
                'module' => 'Productivity',
                'message' => 'Complete at least one important task or reduce active task overload.',
                'priority' => 'medium',
            ];
        }

        if ($overallScore >= 85) {
            $items[] = [
                'module' => 'Life Balance',
                'message' => 'Excellent balance. Maintain the same daily rhythm.',
                'priority' => 'low',
            ];
        }

        return $items;
    }

    private function resolveStatus(int $score): string
    {
        return match (true) {
            $score >= 85 => 'excellent',
            $score >= 70 => 'balanced',
            $score >= 55 => 'needs_attention',
            default => 'critical',
        };
    }

    private function clamp(float|int $value): int
    {
        return max(0, min(100, (int) round($value)));
    }
}

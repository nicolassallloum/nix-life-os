<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LifeBalanceAiRecommendationService
{
    public function generate(string $userId): array
    {
        $today = Carbon::today();
        $startDate = $today->copy()->subDays(30);

        $finance = $this->financeMetrics($userId, $startDate, $today);
        $health = $this->healthMetrics($userId, $startDate, $today);
        $projects = $this->projectMetrics($userId, $today);
        $productivity = $this->productivityMetrics($userId, $startDate, $today);

        $hasData = $finance['has_data'] || $health['has_data'] || $projects['has_data'] || $productivity['has_data'];

        if (!$hasData) {
            return [
                'has_data' => false,
                'score' => 0,
                'status' => 'empty',
                'priority' => 'low',
                'summary' => 'No enough data is available yet to generate Life Balance AI recommendations. Add finance, health, project, and productivity records to activate insights.',
                'categories' => [
                    'finance' => $this->categoryPayload(0, 'empty', $finance),
                    'health' => $this->categoryPayload(0, 'empty', $health),
                    'projects' => $this->categoryPayload(0, 'empty', $projects),
                    'productivity' => $this->categoryPayload(0, 'empty', $productivity),
                ],
                'recommendations' => [],
                'generated_at' => now()->toISOString(),
            ];
        }

        $score = (int) round(
            ($finance['score'] * 0.25) +
            ($health['score'] * 0.25) +
            ($projects['score'] * 0.25) +
            ($productivity['score'] * 0.25)
        );

        $recommendations = array_values(array_filter(array_merge(
            $this->financeRecommendations($finance),
            $this->healthRecommendations($health),
            $this->projectRecommendations($projects),
            $this->productivityRecommendations($productivity),
            $this->generalRecommendations($score, $finance, $health, $projects, $productivity)
        )));

        usort($recommendations, function (array $a, array $b) {
            return $this->priorityWeight($b['priority']) <=> $this->priorityWeight($a['priority']);
        });

        return [
            'has_data' => true,
            'score' => $score,
            'status' => $this->scoreStatus($score),
            'priority' => $this->overallPriority($score, $recommendations),
            'summary' => $this->summaryText($score, $recommendations),
            'categories' => [
                'finance' => $this->categoryPayload($finance['score'], $this->scoreStatus($finance['score']), $finance),
                'health' => $this->categoryPayload($health['score'], $this->scoreStatus($health['score']), $health),
                'projects' => $this->categoryPayload($projects['score'], $this->scoreStatus($projects['score']), $projects),
                'productivity' => $this->categoryPayload($productivity['score'], $this->scoreStatus($productivity['score']), $productivity),
            ],
            'recommendations' => $recommendations,
            'generated_at' => now()->toISOString(),
        ];
    }

    private function financeMetrics(string $userId, Carbon $startDate, Carbon $today): array
    {
        $accounts = $this->countRows('finance_accounts', $userId);
        $transactions = $this->countRows('finance_transactions', $userId);
        $budgets = $this->countRows('finance_budgets', $userId);

        $income = $this->sumTransactions($userId, 'income', $startDate, $today);
        $expenses = $this->sumTransactions($userId, 'expense', $startDate, $today);
        $expenseRatio = $income > 0 ? round(($expenses / max($income, 1)) * 100, 2) : null;

        $score = 0;
        if ($accounts + $transactions + $budgets > 0) {
            $score = 55;
            if ($accounts > 0) $score += 10;
            if ($transactions >= 5) $score += 10;
            if ($budgets > 0) $score += 10;
            if ($income > 0 && $expenses <= $income) $score += 10;
            if ($income > 0 && $expenses > $income) $score -= 20;
            if ($income <= 0 && $expenses > 0) $score -= 10;
        }

        return [
            'has_data' => ($accounts + $transactions + $budgets) > 0,
            'score' => $this->clampScore($score),
            'accounts' => $accounts,
            'transactions' => $transactions,
            'budgets' => $budgets,
            'income_30_days' => round($income, 2),
            'expenses_30_days' => round($expenses, 2),
            'expense_ratio' => $expenseRatio,
        ];
    }

    private function healthMetrics(string $userId, Carbon $startDate, Carbon $today): array
    {
        $nutritionLogs = $this->countRows('health_nutrition_logs', $userId);
        $hydrationLogs = $this->countRows('health_hydration_logs', $userId);
        $weightLogs = $this->countRows('health_weight_logs', $userId);
        $stepLogs = $this->countRows('health_step_log', $userId);

        $avgWater = $this->averageBetween('health_hydration_logs', 'amount_ml', 'log_date', $userId, $startDate, $today);
        $avgSteps = $this->averageBetween('health_step_log', 'steps_count', 'log_date', $userId, $startDate, $today);
        $avgCalories = $this->averageBetween('health_nutrition_logs', 'calories', 'meal_date', $userId, $startDate, $today);

        $score = 0;
        if ($nutritionLogs + $hydrationLogs + $weightLogs + $stepLogs > 0) {
            $score = 45;
            if ($nutritionLogs >= 3) $score += 15;
            if ($hydrationLogs >= 3) $score += 15;
            if ($weightLogs >= 1) $score += 10;
            if ($stepLogs >= 1) $score += 10;
            if ($avgWater >= 1500) $score += 5;
            if ($avgSteps >= 5000) $score += 5;
        }

        return [
            'has_data' => ($nutritionLogs + $hydrationLogs + $weightLogs + $stepLogs) > 0,
            'score' => $this->clampScore($score),
            'nutrition_logs' => $nutritionLogs,
            'hydration_logs' => $hydrationLogs,
            'weight_logs' => $weightLogs,
            'step_logs' => $stepLogs,
            'average_water_ml_30_days' => round($avgWater, 2),
            'average_steps_30_days' => round($avgSteps, 2),
            'average_calories_30_days' => round($avgCalories, 2),
        ];
    }

    private function projectMetrics(string $userId, Carbon $today): array
    {
        $projects = $this->countRows('projects', $userId);
        $active = $this->countWhere('projects', $userId, 'status', ['active', 'in_progress', 'planning']);
        $completed = $this->countWhere('projects', $userId, 'status', ['completed', 'done']);
        $overdue = 0;
        $averageProgress = 0;

        if (Schema::hasTable('projects')) {
            $query = DB::table('projects')->where('user_id', $userId);

            if (Schema::hasColumn('projects', 'progress_percentage')) {
                $averageProgress = (float) (clone $query)->avg('progress_percentage');
            }

            if (Schema::hasColumn('projects', 'target_end_date') && Schema::hasColumn('projects', 'status')) {
                $overdue = (clone $query)
                    ->whereNotIn('status', ['completed', 'cancelled', 'done'])
                    ->whereNotNull('target_end_date')
                    ->whereDate('target_end_date', '<', $today->toDateString())
                    ->count();
            }
        }

        $score = 0;
        if ($projects > 0) {
            $score = 50 + min(30, (int) round($averageProgress * 0.3));
            if ($completed > 0) $score += 10;
            if ($overdue > 0) $score -= min(30, $overdue * 10);
        }

        return [
            'has_data' => $projects > 0,
            'score' => $this->clampScore($score),
            'projects' => $projects,
            'active_projects' => $active,
            'completed_projects' => $completed,
            'overdue_projects' => $overdue,
            'average_progress' => round($averageProgress, 2),
        ];
    }

    private function productivityMetrics(string $userId, Carbon $startDate, Carbon $today): array
    {
        $tasks = $this->countRows('productivity_tasks', $userId);
        $completedTasks = $this->countWhere('productivity_tasks', $userId, 'status', ['completed', 'done']);
        $habits = $this->countRows('productivity_habits', $userId);
        $activeHabits = $this->countWhere('productivity_habits', $userId, 'status', ['active']);
        $goals = $this->countRows('productivity_goals', $userId);
        $events = $this->countRows('productivity_calendar_events', $userId);
        $overdueTasks = 0;
        $averageGoalProgress = 0;
        $maxEventsPerDay = 0;

        if (Schema::hasTable('productivity_tasks') && Schema::hasColumn('productivity_tasks', 'due_date')) {
            $overdueTasks = DB::table('productivity_tasks')
                ->where('user_id', $userId)
                ->whereNotIn('status', ['completed', 'cancelled', 'done'])
                ->whereNotNull('due_date')
                ->whereDate('due_date', '<', $today->toDateString())
                ->count();
        }

        if (Schema::hasTable('productivity_goals') && Schema::hasColumn('productivity_goals', 'progress_percentage')) {
            $averageGoalProgress = (float) DB::table('productivity_goals')
                ->where('user_id', $userId)
                ->avg('progress_percentage');
        }

        if (Schema::hasTable('productivity_calendar_events') && Schema::hasColumn('productivity_calendar_events', 'start_time')) {
            $maxEventsPerDay = (int) DB::table('productivity_calendar_events')
                ->selectRaw('DATE(start_time) as event_day, COUNT(*) as total')
                ->where('user_id', $userId)
                ->whereBetween('start_time', [$startDate->startOfDay(), $today->copy()->endOfDay()])
                ->groupBy(DB::raw('DATE(start_time)'))
                ->orderByDesc('total')
                ->value('total');
        }

        $completionRate = $tasks > 0 ? round(($completedTasks / $tasks) * 100, 2) : 0;

        $score = 0;
        if ($tasks + $habits + $goals + $events > 0) {
            $score = 45;
            if ($completionRate >= 50) $score += 15;
            if ($activeHabits > 0) $score += 10;
            if ($averageGoalProgress >= 50) $score += 15;
            if ($events > 0) $score += 5;
            if ($overdueTasks > 0) $score -= min(25, $overdueTasks * 8);
            if ($maxEventsPerDay >= 6) $score -= 10;
        }

        return [
            'has_data' => ($tasks + $habits + $goals + $events) > 0,
            'score' => $this->clampScore($score),
            'tasks' => $tasks,
            'completed_tasks' => $completedTasks,
            'task_completion_rate' => $completionRate,
            'overdue_tasks' => $overdueTasks,
            'habits' => $habits,
            'active_habits' => $activeHabits,
            'goals' => $goals,
            'average_goal_progress' => round($averageGoalProgress, 2),
            'calendar_events' => $events,
            'max_events_per_day' => $maxEventsPerDay,
        ];
    }

    private function financeRecommendations(array $metrics): array
    {
        $items = [];

        if (!$metrics['has_data']) {
            $items[] = $this->recommendation('finance', 'medium', 'Start finance tracking', 'No finance records were found for this user.', 'Add accounts, transactions, and budgets so the Life Balance engine can calculate financial stability.');
            return $items;
        }

        if (($metrics['income_30_days'] ?? 0) <= 0 && ($metrics['expenses_30_days'] ?? 0) > 0) {
            $items[] = $this->recommendation('finance', 'high', 'Add income tracking', 'Expenses exist but no income was recorded in the last 30 days.', 'Record income transactions to make spending, savings, and balance recommendations accurate.');
        }

        if (($metrics['expense_ratio'] ?? 0) > 90) {
            $items[] = $this->recommendation('finance', 'high', 'Reduce monthly spending pressure', 'Your 30-day expenses are close to or higher than your recorded income.', 'Review non-essential expenses and create a weekly spending limit.');
        }

        if (($metrics['budgets'] ?? 0) === 0) {
            $items[] = $this->recommendation('finance', 'medium', 'Create at least one active budget', 'No budget records were found.', 'Create monthly budgets for key spending categories to improve financial control.');
        }

        return $items;
    }

    private function healthRecommendations(array $metrics): array
    {
        $items = [];

        if (!$metrics['has_data']) {
            $items[] = $this->recommendation('health', 'medium', 'Start health tracking', 'No health logs were found for this user.', 'Add nutrition, hydration, weight, and step logs to activate health recommendations.');
            return $items;
        }

        if (($metrics['hydration_logs'] ?? 0) < 5) {
            $items[] = $this->recommendation('health', 'medium', 'Improve hydration consistency', 'Hydration logs are limited for the current period.', 'Track water intake daily and aim for a consistent hydration routine.');
        }

        if (($metrics['step_logs'] ?? 0) === 0) {
            $items[] = $this->recommendation('health', 'medium', 'Add daily step logs', 'No step activity was found.', 'Record daily walking activity to improve health and consistency scoring.');
        }

        if (($metrics['nutrition_logs'] ?? 0) < 5) {
            $items[] = $this->recommendation('health', 'medium', 'Track meals more consistently', 'Nutrition data is not yet consistent enough for strong AI analysis.', 'Log meals for at least 5 days per week so nutrition recommendations become more reliable.');
        }

        return $items;
    }

    private function projectRecommendations(array $metrics): array
    {
        $items = [];

        if (!$metrics['has_data']) {
            $items[] = $this->recommendation('projects', 'medium', 'Create project tracking records', 'No projects were found for this user.', 'Add active projects, milestones, and progress updates to include project balance in the score.');
            return $items;
        }

        if (($metrics['average_progress'] ?? 0) < 40) {
            $items[] = $this->recommendation('projects', 'medium', 'Increase project progress updates', 'Average project progress is below the healthy target.', 'Review active projects and update tasks or milestones to move progress forward.');
        }

        if (($metrics['overdue_projects'] ?? 0) > 0) {
            $items[] = $this->recommendation('projects', 'high', 'Review overdue projects', 'One or more projects passed the target end date.', 'Reschedule deadlines or close completed work to keep project balance accurate.');
        }

        return $items;
    }

    private function productivityRecommendations(array $metrics): array
    {
        $items = [];

        if (!$metrics['has_data']) {
            $items[] = $this->recommendation('productivity', 'medium', 'Start productivity tracking', 'No tasks, habits, goals, or calendar events were found.', 'Create tasks, habits, goals, and calendar events to activate productivity scoring.');
            return $items;
        }

        if (($metrics['overdue_tasks'] ?? 0) > 0) {
            $items[] = $this->recommendation('productivity', 'high', 'Resolve overdue tasks', 'There are overdue tasks reducing the productivity score.', 'Complete, reschedule, or cancel overdue tasks before adding new high-priority work.');
        }

        if (($metrics['habits'] ?? 0) === 0) {
            $items[] = $this->recommendation('habits', 'medium', 'Create daily habits', 'No productivity habits were found.', 'Add 1 to 3 daily habits to improve consistency and long-term balance.');
        }

        if (($metrics['goals'] ?? 0) === 0) {
            $items[] = $this->recommendation('goals', 'medium', 'Define measurable goals', 'No productivity goals were found.', 'Create goals with target dates and progress percentages.');
        }

        if (($metrics['max_events_per_day'] ?? 0) >= 6) {
            $items[] = $this->recommendation('calendar', 'medium', 'Reduce calendar overload', 'One day has a high number of scheduled events.', 'Move low-priority events or add focus blocks between meetings.');
        }

        return $items;
    }

    private function generalRecommendations(int $score, array $finance, array $health, array $projects, array $productivity): array
    {
        if ($score >= 80) {
            return [
                $this->recommendation('general', 'low', 'Maintain current balance', 'Your overall Life Balance score is strong.', 'Keep logging data consistently and review the score weekly.'),
            ];
        }

        $lowest = collect([
            'finance' => $finance['score'],
            'health' => $health['score'],
            'projects' => $projects['score'],
            'productivity' => $productivity['score'],
        ])->sort()->keys()->first();

        return [
            $this->recommendation('general', $score < 50 ? 'high' : 'medium', 'Focus on the weakest life area first', "The lowest category is {$lowest}, which is pulling down the overall Life Balance score.", 'Improve one weak category this week instead of changing everything at once.'),
        ];
    }

    private function recommendation(string $category, string $priority, string $title, string $description, string $action): array
    {
        return [
            'category' => $category,
            'priority' => $priority,
            'title' => $title,
            'description' => $description,
            'action' => $action,
        ];
    }

    private function categoryPayload(int $score, string $status, array $metrics): array
    {
        return [
            'score' => $score,
            'status' => $status,
            'metrics' => $metrics,
        ];
    }

    private function countRows(string $table, string $userId): int
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, 'user_id')) {
            return 0;
        }

        return (int) DB::table($table)->where('user_id', $userId)->count();
    }

    private function countWhere(string $table, string $userId, string $column, array $values): int
    {
        if (!Schema::hasTable($table) || !Schema::hasColumn($table, 'user_id') || !Schema::hasColumn($table, $column)) {
            return 0;
        }

        return (int) DB::table($table)
            ->where('user_id', $userId)
            ->whereIn($column, $values)
            ->count();
    }

    private function sumTransactions(string $userId, string $type, Carbon $startDate, Carbon $today): float
    {
        if (!Schema::hasTable('finance_transactions')) {
            return 0.0;
        }

        foreach (['user_id', 'transaction_type', 'amount'] as $column) {
            if (!Schema::hasColumn('finance_transactions', $column)) {
                return 0.0;
            }
        }

        $query = DB::table('finance_transactions')
            ->where('user_id', $userId)
            ->where('transaction_type', $type);

        if (Schema::hasColumn('finance_transactions', 'transaction_date')) {
            $query->whereBetween('transaction_date', [$startDate->toDateString(), $today->toDateString()]);
        }

        return (float) $query->sum('amount');
    }

    private function averageBetween(string $table, string $valueColumn, string $dateColumn, string $userId, Carbon $startDate, Carbon $today): float
    {
        if (!Schema::hasTable($table)) {
            return 0.0;
        }

        foreach (['user_id', $valueColumn, $dateColumn] as $column) {
            if (!Schema::hasColumn($table, $column)) {
                return 0.0;
            }
        }

        return (float) DB::table($table)
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [$startDate->toDateString(), $today->toDateString()])
            ->avg($valueColumn);
    }

    private function scoreStatus(int $score): string
    {
        return match (true) {
            $score <= 0 => 'empty',
            $score < 40 => 'critical',
            $score < 60 => 'needs_attention',
            $score < 80 => 'balanced',
            default => 'excellent',
        };
    }

    private function overallPriority(int $score, array $recommendations): string
    {
        $highest = collect($recommendations)
            ->pluck('priority')
            ->sortByDesc(fn ($priority) => $this->priorityWeight($priority))
            ->first();

        if ($highest) {
            return $highest;
        }

        return $score < 50 ? 'high' : ($score < 70 ? 'medium' : 'low');
    }

    private function priorityWeight(?string $priority): int
    {
        return match ($priority) {
            'critical' => 4,
            'high' => 3,
            'medium' => 2,
            'low' => 1,
            default => 0,
        };
    }

    private function summaryText(int $score, array $recommendations): string
    {
        $count = count($recommendations);

        return match (true) {
            $score >= 80 => "Your Life Balance score is excellent. {$count} recommendation(s) are available to maintain momentum.",
            $score >= 60 => "Your Life Balance score is stable, but {$count} recommendation(s) can improve weak areas.",
            $score >= 40 => "Your Life Balance score needs attention. Review the {$count} recommendation(s) below and start with high-priority items.",
            default => "Your Life Balance score is critical. Focus on the highest-priority recommendation first.",
        };
    }

    private function clampScore(int|float $score): int
    {
        return (int) max(0, min(100, round($score)));
    }
}

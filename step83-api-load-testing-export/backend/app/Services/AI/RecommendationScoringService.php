<?php

namespace App\Services\AI;

use App\Models\AIUserDailyScore;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class RecommendationScoringService
{
    public function calculateForUser(User|string $user, ?Carbon $date = null): array
    {
        $userId = $user instanceof User ? $user->id : $user;
        $date = $date ?? now();

        $finance = $this->calculateFinanceScore($userId, $date);
        $health = $this->calculateHealthScore($userId, $date);
        $productivity = $this->calculateProductivityScore($userId, $date);
        $goals = $this->calculateGoalsScore($userId, $date);
        $habits = $this->calculateHabitsScore($userId, $date);

        $lifeBalanceScore = $this->calculateLifeBalanceScore(
            $finance['score'],
            $health['score'],
            $productivity['score'],
            $goals['score'],
            $habits['score']
        );

        $classification = $this->classifyScore($lifeBalanceScore);

        return [
            'user_id' => $userId,
            'score_date' => $date->toDateString(),
            'finance_score' => $finance['score'],
            'health_score' => $health['score'],
            'productivity_score' => $productivity['score'],
            'goals_score' => $goals['score'],
            'habits_score' => $habits['score'],
            'life_balance_score' => $lifeBalanceScore,
            'classification' => $classification,
            'score_breakdown' => [
                'finance' => $finance,
                'health' => $health,
                'productivity' => $productivity,
                'goals' => $goals,
                'habits' => $habits,
                'life_balance_formula' => [
                    'finance_weight' => 0.30,
                    'health_weight' => 0.30,
                    'productivity_weight' => 0.25,
                    'goals_weight' => 0.10,
                    'habits_weight' => 0.05,
                ],
            ],
            'source_summary' => [
                'generated_at' => now()->toISOString(),
                'engine' => 'rule_based_scoring_v1',
            ],
        ];
    }

    public function calculateAndStoreForUser(User|string $user, ?Carbon $date = null): AIUserDailyScore
    {
        $result = $this->calculateForUser($user, $date);

        return AIUserDailyScore::updateOrCreate(
            [
                'user_id' => $result['user_id'],
                'score_date' => $result['score_date'],
            ],
            [
                'finance_score' => $result['finance_score'],
                'health_score' => $result['health_score'],
                'productivity_score' => $result['productivity_score'],
                'goals_score' => $result['goals_score'],
                'habits_score' => $result['habits_score'],
                'life_balance_score' => $result['life_balance_score'],
                'classification' => $result['classification'],
                'score_breakdown' => $result['score_breakdown'],
                'source_summary' => $result['source_summary'],
                'metadata' => [
                    'service' => self::class,
                    'version' => '1.0',
                ],
            ]
        );
    }

    public function calculateFinanceScore(string $userId, Carbon $date): array
    {
        $baseScore = 100;
        $penalties = [];
        $bonuses = [];
        $metrics = [];

        $monthlyIncome = $this->sumTableAmount(
            'incomes',
            $userId,
            'amount',
            $date->copy()->startOfMonth(),
            $date->copy()->endOfMonth()
        );

        $legacyMonthlyExpenses = $this->sumTableAmount(
            'expenses',
            $userId,
            'amount',
            $date->copy()->startOfMonth(),
            $date->copy()->endOfMonth()
        );

        $financeMonthlyExpenses = $this->sumTableAmount(
            'finance_transactions',
            $userId,
            'amount',
            $date->copy()->startOfMonth(),
            $date->copy()->endOfMonth(),
            [
                ['column' => 'type', 'operator' => '=', 'value' => 'expense'],
            ]
        );

        $monthlyExpenses = $legacyMonthlyExpenses + $financeMonthlyExpenses;

        $metrics['monthly_income'] = $monthlyIncome;
        $metrics['monthly_expenses'] = $monthlyExpenses;

        $expenseIncomeRatio = $monthlyIncome > 0
            ? round(($monthlyExpenses / $monthlyIncome) * 100, 2)
            : null;

        $metrics['expense_income_ratio'] = $expenseIncomeRatio;

        if ($monthlyIncome <= 0 && $monthlyExpenses <= 0) {
            return $this->emptyScoreResult(
                70,
                'finance',
                'No finance activity found. Neutral finance score applied.'
            );
        }

        if ($monthlyIncome <= 0 && $monthlyExpenses > 0) {
            $penalties['expenses_without_income'] = 25;
        }

        if ($expenseIncomeRatio !== null) {
            if ($expenseIncomeRatio > 100) {
                $penalties['expenses_exceed_income'] = 30;
            } elseif ($expenseIncomeRatio > 80) {
                $penalties['high_expense_income_ratio'] = 20;
            } elseif ($expenseIncomeRatio > 60) {
                $penalties['moderate_expense_income_ratio'] = 10;
            } elseif ($expenseIncomeRatio < 40) {
                $bonuses['healthy_expense_income_ratio'] = 5;
            }
        }

        $budgetUsage = $this->calculateBudgetUsagePercentage($userId, $date);

        $metrics['budget_usage_percentage'] = $budgetUsage;

        if ($budgetUsage !== null) {
            if ($budgetUsage > 100) {
                $penalties['budget_exceeded'] = 25;
            } elseif ($budgetUsage >= 80) {
                $penalties['budget_near_limit'] = 10;
            } else {
                $bonuses['budget_under_control'] = 5;
            }
        }

        $accountBalance = $this->calculateTotalFinanceAccountBalance($userId);

        $metrics['total_account_balance'] = $accountBalance;

        if ($accountBalance !== null) {
            if ($accountBalance <= 0) {
                $penalties['low_or_negative_balance'] = 20;
            } elseif ($monthlyExpenses > 0 && $accountBalance < ($monthlyExpenses * 0.25)) {
                $penalties['balance_below_expense_safety_margin'] = 10;
            }
        }

        return $this->buildScoreResult($baseScore, $penalties, $bonuses, $metrics);
    }

    public function calculateHealthScore(string $userId, Carbon $date): array
    {
        $baseScore = 100;
        $penalties = [];
        $bonuses = [];
        $metrics = [];

        $todayStart = $date->copy()->startOfDay();
        $todayEnd = $date->copy()->endOfDay();

        $steps = $this->sumTableAmount(
            'health_step_logs',
            $userId,
            'steps',
            $todayStart,
            $todayEnd
        );

        if ($steps <= 0) {
            $steps = $this->sumTableAmount(
                'step_entries',
                $userId,
                'steps',
                $todayStart,
                $todayEnd
            );
        }

        $stepTarget = 6000;
        $stepPercentage = $stepTarget > 0 ? round(($steps / $stepTarget) * 100, 2) : 0;

        $metrics['daily_steps'] = $steps;
        $metrics['step_target'] = $stepTarget;
        $metrics['daily_steps_percentage'] = $stepPercentage;

        if ($steps <= 0) {
            $penalties['no_steps_logged'] = 12;
        } elseif ($stepPercentage < 50) {
            $penalties['steps_below_50_percent'] = 15;
        } elseif ($stepPercentage < 80) {
            $penalties['steps_below_80_percent'] = 8;
        } else {
            $bonuses['steps_target_progress'] = 5;
        }

        $hydration = $this->sumTableAmount(
            'health_hydration_logs',
            $userId,
            'amount_ml',
            $todayStart,
            $todayEnd
        );

        if ($hydration <= 0) {
            $hydration = $this->sumTableAmount(
                'health_hydration_logs',
                $userId,
                'water_ml',
                $todayStart,
                $todayEnd
            );
        }

        $hydrationTarget = 1500;
        $hydrationPercentage = $hydrationTarget > 0 ? round(($hydration / $hydrationTarget) * 100, 2) : 0;

        $metrics['daily_hydration_ml'] = $hydration;
        $metrics['hydration_target_ml'] = $hydrationTarget;
        $metrics['daily_hydration_percentage'] = $hydrationPercentage;

        if ($this->tableExists('health_hydration_logs')) {
            if ($hydration <= 0) {
                $penalties['no_hydration_logged'] = 8;
            } elseif ($hydrationPercentage < 60) {
                $penalties['hydration_below_target'] = 10;
            } else {
                $bonuses['hydration_logged'] = 4;
            }
        }

        $missedMedicationCount = $this->countTableRecords(
            'health_medication_dose_logs',
            $userId,
            $todayStart,
            $todayEnd,
            [
                ['column' => 'status', 'operator' => '=', 'value' => 'missed'],
            ]
        );

        $metrics['missed_medication_count'] = $missedMedicationCount;

        if ($missedMedicationCount > 0) {
            $penalties['missed_medication'] = min(30, $missedMedicationCount * 10);
        }

        $nutritionLogs7d = $this->countTableRecords(
            'health_nutrition_logs',
            $userId,
            $date->copy()->subDays(6)->startOfDay(),
            $todayEnd
        );

        $metrics['nutrition_log_count_7d'] = $nutritionLogs7d;

        if ($this->tableExists('health_nutrition_logs')) {
            if ($nutritionLogs7d < 4) {
                $penalties['low_nutrition_tracking'] = 8;
            } else {
                $bonuses['nutrition_tracking_consistent'] = 5;
            }
        }

        $weightTrend = $this->calculateWeightTrend7Days($userId, $date);

        $metrics['weight_change_7d_percentage'] = $weightTrend;

        if ($weightTrend !== null && $weightTrend > 2) {
            $penalties['weight_increase_7d'] = 8;
        }

        if (
            !$this->tableExists('health_step_logs')
            && !$this->tableExists('step_entries')
            && !$this->tableExists('health_hydration_logs')
            && !$this->tableExists('health_medication_dose_logs')
            && !$this->tableExists('health_nutrition_logs')
        ) {
            return $this->emptyScoreResult(
                70,
                'health',
                'No health tables found. Neutral health score applied.'
            );
        }

        return $this->buildScoreResult($baseScore, $penalties, $bonuses, $metrics);
    }

    public function calculateProductivityScore(string $userId, Carbon $date): array
    {
        $baseScore = 100;
        $penalties = [];
        $bonuses = [];
        $metrics = [];

        $now = $date->copy();

        $overdueTaskCount = $this->countOverdueTasks($userId, $now);
        $metrics['overdue_task_count'] = $overdueTaskCount;

        if ($overdueTaskCount >= 5) {
            $penalties['too_many_overdue_tasks'] = 25;
        } elseif ($overdueTaskCount >= 3) {
            $penalties['overdue_tasks'] = 15;
        } elseif ($overdueTaskCount > 0) {
            $penalties['some_overdue_tasks'] = 8;
        }

        $taskCompletionRate = $this->calculateTaskCompletionRate7Days($userId, $date);
        $metrics['task_completion_rate_7d'] = $taskCompletionRate;

        if ($taskCompletionRate === null) {
            $penalties['no_task_activity'] = 5;
        } elseif ($taskCompletionRate < 50) {
            $penalties['low_task_completion_rate'] = 18;
        } elseif ($taskCompletionRate < 75) {
            $penalties['moderate_task_completion_rate'] = 8;
        } else {
            $bonuses['strong_task_completion_rate'] = 7;
        }

        $calendarEventsToday = $this->countTableRecords(
            'calendar_events',
            $userId,
            $date->copy()->startOfDay(),
            $date->copy()->endOfDay()
        );

        $metrics['calendar_events_today'] = $calendarEventsToday;

        if ($this->tableExists('calendar_events')) {
            if ($calendarEventsToday > 8) {
                $penalties['calendar_overload'] = 12;
            } elseif ($calendarEventsToday >= 1 && $calendarEventsToday <= 6) {
                $bonuses['reasonable_calendar_load'] = 3;
            }
        }

        if (
            !$this->tableExists('tasks')
            && !$this->tableExists('calendar_events')
        ) {
            return $this->emptyScoreResult(
                70,
                'productivity',
                'No productivity tables found. Neutral productivity score applied.'
            );
        }

        return $this->buildScoreResult($baseScore, $penalties, $bonuses, $metrics);
    }

    public function calculateGoalsScore(string $userId, Carbon $date): array
    {
        $baseScore = 100;
        $penalties = [];
        $bonuses = [];
        $metrics = [];

        if (!$this->tableExists('goals')) {
            return $this->emptyScoreResult(
                70,
                'goals',
                'Goals table not found. Neutral goals score applied.'
            );
        }

        $totalGoals = $this->countUserRecords('goals', $userId);
        $metrics['total_goals'] = $totalGoals;

        if ($totalGoals === 0) {
            return $this->emptyScoreResult(
                70,
                'goals',
                'No goals found. Neutral goals score applied.'
            );
        }

        $completedGoals = $this->countUserRecordsByStatus('goals', $userId, ['completed', 'done']);
        $activeGoals = $this->countUserRecordsByStatus('goals', $userId, ['active', 'in_progress', 'pending']);

        $completionRate = round(($completedGoals / max($totalGoals, 1)) * 100, 2);

        $metrics['completed_goals'] = $completedGoals;
        $metrics['active_goals'] = $activeGoals;
        $metrics['goal_completion_rate'] = $completionRate;

        if ($completionRate >= 70) {
            $bonuses['strong_goal_completion'] = 10;
        } elseif ($completionRate < 25) {
            $penalties['low_goal_completion'] = 15;
        }

        $stalledGoals = $this->countStalledGoals($userId, $date);
        $metrics['stalled_goals'] = $stalledGoals;

        if ($stalledGoals > 0) {
            $penalties['stalled_goals'] = min(20, $stalledGoals * 5);
        }

        $deadlineRiskGoals = $this->countGoalDeadlineRisk($userId, $date);
        $metrics['deadline_risk_goals'] = $deadlineRiskGoals;

        if ($deadlineRiskGoals > 0) {
            $penalties['goal_deadline_risk'] = min(15, $deadlineRiskGoals * 5);
        }

        return $this->buildScoreResult($baseScore, $penalties, $bonuses, $metrics);
    }

    public function calculateHabitsScore(string $userId, Carbon $date): array
    {
        $baseScore = 100;
        $penalties = [];
        $bonuses = [];
        $metrics = [];

        if (!$this->tableExists('habits')) {
            return $this->emptyScoreResult(
                70,
                'habits',
                'Habits table not found. Neutral habits score applied.'
            );
        }

        $totalHabits = $this->countUserRecords('habits', $userId);
        $metrics['total_habits'] = $totalHabits;

        if ($totalHabits === 0) {
            return $this->emptyScoreResult(
                70,
                'habits',
                'No habits found. Neutral habits score applied.'
            );
        }

        $activeHabits = $this->countUserRecordsByStatus('habits', $userId, ['active', 'in_progress', 'pending']);
        $metrics['active_habits'] = $activeHabits;

        $habitCheckIns7d = $this->countTableRecords(
            'productivity_habit_check_ins',
            $userId,
            $date->copy()->subDays(6)->startOfDay(),
            $date->copy()->endOfDay()
        );

        if ($habitCheckIns7d <= 0) {
            $habitCheckIns7d = $this->countTableRecords(
                'habit_logs',
                $userId,
                $date->copy()->subDays(6)->startOfDay(),
                $date->copy()->endOfDay()
            );
        }

        $expectedWeeklyCheckIns = max($activeHabits, 1) * 7;
        $habitConsistencyRate = round(($habitCheckIns7d / $expectedWeeklyCheckIns) * 100, 2);
        $habitConsistencyRate = min(100, $habitConsistencyRate);

        $metrics['habit_check_ins_7d'] = $habitCheckIns7d;
        $metrics['habit_consistency_rate_7d'] = $habitConsistencyRate;

        if ($habitConsistencyRate < 30) {
            $penalties['very_low_habit_consistency'] = 20;
        } elseif ($habitConsistencyRate < 60) {
            $penalties['low_habit_consistency'] = 12;
        } elseif ($habitConsistencyRate >= 80) {
            $bonuses['strong_habit_consistency'] = 8;
        }

        return $this->buildScoreResult($baseScore, $penalties, $bonuses, $metrics);
    }

    public function calculateLifeBalanceScore(
        float $financeScore,
        float $healthScore,
        float $productivityScore,
        float $goalsScore,
        float $habitsScore
    ): float {
        return round(
            ($financeScore * 0.30)
            + ($healthScore * 0.30)
            + ($productivityScore * 0.25)
            + ($goalsScore * 0.10)
            + ($habitsScore * 0.05),
            2
        );
    }

    public function classifyScore(float $score): string
    {
        return match (true) {
            $score >= 85 => AIUserDailyScore::CLASSIFICATION_EXCELLENT,
            $score >= 70 => AIUserDailyScore::CLASSIFICATION_GOOD,
            $score >= 50 => AIUserDailyScore::CLASSIFICATION_NEEDS_ATTENTION,
            $score >= 30 => AIUserDailyScore::CLASSIFICATION_RISK,
            default => AIUserDailyScore::CLASSIFICATION_CRITICAL,
        };
    }

    private function buildScoreResult(
        float $baseScore,
        array $penalties,
        array $bonuses,
        array $metrics
    ): array {
        $score = $baseScore - array_sum($penalties) + array_sum($bonuses);
        $score = max(0, min(100, round($score, 2)));

        return [
            'score' => $score,
            'base_score' => $baseScore,
            'penalties' => $penalties,
            'bonuses' => $bonuses,
            'metrics' => $metrics,
            'data_status' => 'available',
        ];
    }

    private function emptyScoreResult(float $score, string $module, string $reason): array
    {
        return [
            'score' => $score,
            'base_score' => $score,
            'penalties' => [],
            'bonuses' => [],
            'metrics' => [],
            'data_status' => 'empty',
            'module' => $module,
            'reason' => $reason,
        ];
    }

    private function calculateBudgetUsagePercentage(string $userId, Carbon $date): ?float
    {
        if (!$this->tableExists('finance_budgets')) {
            return null;
        }

        $budgetAmountColumn = $this->firstExistingColumn('finance_budgets', [
            'amount',
            'budget_amount',
            'limit_amount',
            'monthly_limit',
        ]);

        if (!$budgetAmountColumn) {
            return null;
        }

        $budgetTotal = $this->sumUserColumn('finance_budgets', $userId, $budgetAmountColumn);

        if ($budgetTotal <= 0) {
            return null;
        }

        $expenses = $this->sumTableAmount(
            'finance_transactions',
            $userId,
            'amount',
            $date->copy()->startOfMonth(),
            $date->copy()->endOfMonth(),
            [
                ['column' => 'type', 'operator' => '=', 'value' => 'expense'],
            ]
        );

        return round(($expenses / $budgetTotal) * 100, 2);
    }

    private function calculateTotalFinanceAccountBalance(string $userId): ?float
    {
        if (!$this->tableExists('finance_accounts')) {
            return null;
        }

        $balanceColumn = $this->firstExistingColumn('finance_accounts', [
            'current_balance',
            'balance',
            'initial_balance',
        ]);

        if (!$balanceColumn) {
            return null;
        }

        return $this->sumUserColumn('finance_accounts', $userId, $balanceColumn);
    }

    private function calculateWeightTrend7Days(string $userId, Carbon $date): ?float
    {
        $table = null;

        if ($this->tableExists('health_weight_logs')) {
            $table = 'health_weight_logs';
        } elseif ($this->tableExists('weight_entries')) {
            $table = 'weight_entries';
        }

        if (!$table) {
            return null;
        }

        $weightColumn = $this->firstExistingColumn($table, [
            'weight_kg',
            'weight',
            'value',
        ]);

        if (!$weightColumn || !$this->hasUserColumn($table)) {
            return null;
        }

        $dateColumn = $this->dateColumn($table);

        $latest = DB::table($table)
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [
                $date->copy()->subDays(6)->startOfDay(),
                $date->copy()->endOfDay(),
            ])
            ->orderByDesc($dateColumn)
            ->value($weightColumn);

        $oldest = DB::table($table)
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [
                $date->copy()->subDays(6)->startOfDay(),
                $date->copy()->endOfDay(),
            ])
            ->orderBy($dateColumn)
            ->value($weightColumn);

        if (!$latest || !$oldest || (float) $oldest <= 0) {
            return null;
        }

        return round((((float) $latest - (float) $oldest) / (float) $oldest) * 100, 2);
    }

    private function countOverdueTasks(string $userId, Carbon $date): int
    {
        if (!$this->tableExists('tasks') || !$this->hasUserColumn('tasks')) {
            return 0;
        }

        $dateColumn = $this->firstExistingColumn('tasks', [
            'due_date',
            'deadline',
            'target_date',
        ]);

        if (!$dateColumn) {
            return 0;
        }

        $query = DB::table('tasks')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, '<', $date->toDateString());

        if (Schema::hasColumn('tasks', 'status')) {
            $query->whereNotIn('status', ['completed', 'done', 'cancelled']);
        }

        return $query->count();
    }

    private function calculateTaskCompletionRate7Days(string $userId, Carbon $date): ?float
    {
        if (!$this->tableExists('tasks') || !$this->hasUserColumn('tasks')) {
            return null;
        }

        $dateColumn = $this->dateColumn('tasks');

        $query = DB::table('tasks')
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [
                $date->copy()->subDays(6)->startOfDay(),
                $date->copy()->endOfDay(),
            ]);

        $total = (clone $query)->count();

        if ($total === 0) {
            return null;
        }

        $completed = 0;

        if (Schema::hasColumn('tasks', 'status')) {
            $completed = (clone $query)
                ->whereIn('status', ['completed', 'done'])
                ->count();
        } elseif (Schema::hasColumn('tasks', 'is_completed')) {
            $completed = (clone $query)
                ->where('is_completed', true)
                ->count();
        }

        return round(($completed / max($total, 1)) * 100, 2);
    }

    private function countStalledGoals(string $userId, Carbon $date): int
    {
        if (!$this->tableExists('goals') || !$this->hasUserColumn('goals')) {
            return 0;
        }

        $updatedColumn = Schema::hasColumn('goals', 'updated_at') ? 'updated_at' : $this->dateColumn('goals');

        $query = DB::table('goals')
            ->where('user_id', $userId)
            ->where($updatedColumn, '<=', $date->copy()->subDays(14));

        if (Schema::hasColumn('goals', 'status')) {
            $query->whereNotIn('status', ['completed', 'done', 'cancelled']);
        }

        return $query->count();
    }

    private function countGoalDeadlineRisk(string $userId, Carbon $date): int
    {
        if (!$this->tableExists('goals') || !$this->hasUserColumn('goals')) {
            return 0;
        }

        $deadlineColumn = $this->firstExistingColumn('goals', [
            'deadline',
            'target_date',
            'due_date',
            'end_date',
        ]);

        if (!$deadlineColumn) {
            return 0;
        }

        $query = DB::table('goals')
            ->where('user_id', $userId)
            ->whereBetween($deadlineColumn, [
                $date->copy()->startOfDay(),
                $date->copy()->addDays(7)->endOfDay(),
            ]);

        if (Schema::hasColumn('goals', 'status')) {
            $query->whereNotIn('status', ['completed', 'done', 'cancelled']);
        }

        return $query->count();
    }

    private function countUserRecords(string $table, string $userId): int
    {
        if (!$this->tableExists($table) || !$this->hasUserColumn($table)) {
            return 0;
        }

        return DB::table($table)
            ->where('user_id', $userId)
            ->count();
    }

    private function countUserRecordsByStatus(string $table, string $userId, array $statuses): int
    {
        if (
            !$this->tableExists($table)
            || !$this->hasUserColumn($table)
            || !Schema::hasColumn($table, 'status')
        ) {
            return 0;
        }

        return DB::table($table)
            ->where('user_id', $userId)
            ->whereIn('status', $statuses)
            ->count();
    }

    private function sumTableAmount(
        string $table,
        string $userId,
        string $amountColumn,
        Carbon $start,
        Carbon $end,
        array $filters = []
    ): float {
        if (
            !$this->tableExists($table)
            || !$this->hasUserColumn($table)
            || !Schema::hasColumn($table, $amountColumn)
        ) {
            return 0.0;
        }

        $dateColumn = $this->dateColumn($table);

        $query = DB::table($table)
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [$start, $end]);

        foreach ($filters as $filter) {
            if (Schema::hasColumn($table, $filter['column'])) {
                $query->where($filter['column'], $filter['operator'], $filter['value']);
            }
        }

        return (float) $query->sum($amountColumn);
    }

    private function countTableRecords(
        string $table,
        string $userId,
        Carbon $start,
        Carbon $end,
        array $filters = []
    ): int {
        if (!$this->tableExists($table) || !$this->hasUserColumn($table)) {
            return 0;
        }

        $dateColumn = $this->dateColumn($table);

        $query = DB::table($table)
            ->where('user_id', $userId)
            ->whereBetween($dateColumn, [$start, $end]);

        foreach ($filters as $filter) {
            if (Schema::hasColumn($table, $filter['column'])) {
                $query->where($filter['column'], $filter['operator'], $filter['value']);
            }
        }

        return $query->count();
    }

    private function sumUserColumn(string $table, string $userId, string $column): float
    {
        if (
            !$this->tableExists($table)
            || !$this->hasUserColumn($table)
            || !Schema::hasColumn($table, $column)
        ) {
            return 0.0;
        }

        return (float) DB::table($table)
            ->where('user_id', $userId)
            ->sum($column);
    }

    private function tableExists(string $table): bool
    {
        return Schema::hasTable($table);
    }

    private function hasUserColumn(string $table): bool
    {
        return Schema::hasColumn($table, 'user_id');
    }

    private function firstExistingColumn(string $table, array $columns): ?string
    {
        if (!$this->tableExists($table)) {
            return null;
        }

        foreach ($columns as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return null;
    }

    private function dateColumn(string $table): string
    {
        $candidates = [
            'entry_date',
            'log_date',
            'recorded_at',
            'date',
            'scheduled_at',
            'due_date',
            'created_at',
        ];

        foreach ($candidates as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return 'created_at';
    }
}

<?php

namespace App\Services;

use App\Models\ProductivityCalendarEvent;
use App\Models\ProductivityGoal;
use App\Models\ProductivityHabit;
use App\Models\ProductivityTask;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ProductivityAIInsightService
{
    public function generateForUser(string $userId): array
    {
        $today = Carbon::today();
        $weekStart = $today->copy()->startOfWeek();
        $weekEnd = $today->copy()->endOfWeek();

        $weeklySummary = $this->weeklySummary($userId, $today, $weekStart, $weekEnd);
        $taskInsights = $this->taskPriorityRecommendations($userId, $today, $weeklySummary);
        $habitInsights = $this->habitConsistencyInsights($userId, $today, $weekStart, $weeklySummary);
        $goalInsights = $this->goalProgressRecommendations($userId, $today, $weekEnd, $weeklySummary);
        $calendarWarnings = $this->calendarOverloadWarnings($userId, $weekStart, $weekEnd, $weeklySummary);

        $score = $this->productivityScore($weeklySummary);
        $hasData = ($weeklySummary['total_tasks'] + $weeklySummary['total_habits'] + $weeklySummary['total_goals'] + $weeklySummary['total_calendar_events']) > 0;

        $recommendations = collect()
            ->merge($taskInsights)
            ->merge($habitInsights)
            ->merge($goalInsights)
            ->merge($calendarWarnings)
            ->values()
            ->toArray();

        if (! $hasData) {
            $recommendations[] = [
                'type' => 'getting_started',
                'severity' => 'info',
                'title' => 'Start tracking your productivity',
                'message' => 'Add tasks, habits, goals, and calendar events to generate personalized AI productivity insights.',
                'action' => 'Create your first productivity task, habit, goal, or calendar event.',
            ];
        }

        return [
            'productivity_score' => $score,
            'score_label' => $this->scoreLabel($score, $hasData),
            'weekly_summary' => $weeklySummary,
            'task_priority_recommendations' => $taskInsights,
            'habit_consistency_insights' => $habitInsights,
            'goal_progress_recommendations' => $goalInsights,
            'calendar_overload_warnings' => $calendarWarnings,
            'recommendations' => $recommendations,
            'has_data' => $hasData,
        ];
    }

    private function weeklySummary(string $userId, Carbon $today, Carbon $weekStart, Carbon $weekEnd): array
    {
        $taskBase = ProductivityTask::query()->where('user_id', $userId);
        $habitBase = ProductivityHabit::query()->where('user_id', $userId);
        $goalBase = ProductivityGoal::query()->where('user_id', $userId);
        $calendarBase = ProductivityCalendarEvent::query()->where('user_id', $userId);

        $totalTasks = (clone $taskBase)->count();
        $completedTasks = (clone $taskBase)
            ->where('status', 'completed')
            ->whereBetween('completed_at', [$weekStart, $weekEnd])
            ->count();
        $pendingTasks = (clone $taskBase)->whereNotIn('status', ['completed', 'cancelled'])->count();
        $overdueTasks = (clone $taskBase)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('due_date', '<', $today)
            ->count();
        $highPriorityOpenTasks = (clone $taskBase)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereIn('priority', ['high', 'critical'])
            ->count();
        $tasksDueToday = (clone $taskBase)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('due_date', $today)
            ->count();

        $totalHabits = (clone $habitBase)->count();
        $activeHabits = (clone $habitBase)->where('status', 'active')->count();
        $habitsCompletedToday = (clone $habitBase)
            ->where('status', 'active')
            ->where(function ($query) use ($today) {
                $query->whereDate('last_completed_at', $today)
                    ->orWhereColumn('completed_count_today', '>=', 'target_count');
            })
            ->count();
        $habitsMissedToday = max($activeHabits - $habitsCompletedToday, 0);
        $habitCheckInsThisWeek = $this->habitCheckInsThisWeek($userId, $weekStart, $weekEnd);

        $totalGoals = (clone $goalBase)->count();
        $activeGoals = (clone $goalBase)->where('status', 'active')->count();
        $completedGoals = (clone $goalBase)->where('status', 'completed')->count();
        $overdueGoals = (clone $goalBase)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('target_date', '<', $today)
            ->count();
        $goalsDueThisWeek = (clone $goalBase)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereBetween('target_date', [$today->toDateString(), $weekEnd->toDateString()])
            ->count();
        $averageGoalProgress = round((float) (clone $goalBase)->avg('progress_percentage'), 2);

        $calendarEventsThisWeek = (clone $calendarBase)
            ->whereBetween('start_time', [$weekStart, $weekEnd])
            ->count();
        $todayCalendarEvents = (clone $calendarBase)->whereDate('start_time', $today)->count();
        $totalCalendarEvents = (clone $calendarBase)->count();

        return [
            'period' => [
                'week_start' => $weekStart->toDateString(),
                'week_end' => $weekEnd->toDateString(),
                'today' => $today->toDateString(),
            ],
            'total_tasks' => $totalTasks,
            'tasks_completed' => $completedTasks,
            'tasks_pending' => $pendingTasks,
            'overdue_tasks' => $overdueTasks,
            'high_priority_open_tasks' => $highPriorityOpenTasks,
            'tasks_due_today' => $tasksDueToday,
            'total_habits' => $totalHabits,
            'active_habits' => $activeHabits,
            'habits_completed_today' => $habitsCompletedToday,
            'habits_missed_today' => $habitsMissedToday,
            'habit_check_ins_this_week' => $habitCheckInsThisWeek,
            'total_goals' => $totalGoals,
            'goals_active' => $activeGoals,
            'goals_completed' => $completedGoals,
            'goals_overdue' => $overdueGoals,
            'goals_due_this_week' => $goalsDueThisWeek,
            'average_goal_progress' => $averageGoalProgress,
            'calendar_events_this_week' => $calendarEventsThisWeek,
            'calendar_events_today' => $todayCalendarEvents,
            'total_calendar_events' => $totalCalendarEvents,
        ];
    }

    private function taskPriorityRecommendations(string $userId, Carbon $today, array $summary): array
    {
        $insights = [];

        $urgentTasks = ProductivityTask::query()
            ->where('user_id', $userId)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->where(function ($query) use ($today) {
                $query->whereIn('priority', ['high', 'critical'])
                    ->orWhereDate('due_date', '<=', $today);
            })
            ->orderByRaw("CASE priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END")
            ->orderBy('due_date')
            ->limit(5)
            ->get(['id', 'title', 'priority', 'status', 'due_date']);

        if ($summary['overdue_tasks'] > 0) {
            $insights[] = [
                'type' => 'task_priority',
                'severity' => 'warning',
                'title' => 'Overdue tasks need attention',
                'message' => "You have {$summary['overdue_tasks']} overdue task(s).",
                'action' => 'Review overdue tasks first and complete or reschedule them today.',
                'items' => $urgentTasks,
            ];
        }

        if ($summary['high_priority_open_tasks'] >= 3) {
            $insights[] = [
                'type' => 'task_priority',
                'severity' => 'warning',
                'title' => 'High-priority workload is increasing',
                'message' => "You have {$summary['high_priority_open_tasks']} open high-priority task(s).",
                'action' => 'Pick the top 3 high-priority tasks and block focused time for them.',
                'items' => $urgentTasks,
            ];
        }

        if ($summary['tasks_due_today'] > 0 && $summary['overdue_tasks'] === 0) {
            $insights[] = [
                'type' => 'task_priority',
                'severity' => 'info',
                'title' => 'Tasks are due today',
                'message' => "You have {$summary['tasks_due_today']} task(s) due today.",
                'action' => 'Complete due-today tasks before starting new work.',
                'items' => $urgentTasks,
            ];
        }

        if ($summary['total_tasks'] === 0) {
            $insights[] = [
                'type' => 'task_priority',
                'severity' => 'info',
                'title' => 'No tasks found',
                'message' => 'No productivity tasks are currently tracked.',
                'action' => 'Create a task list to help the AI prioritize your work.',
                'items' => [],
            ];
        }

        return $insights;
    }

    private function habitConsistencyInsights(string $userId, Carbon $today, Carbon $weekStart, array $summary): array
    {
        $insights = [];
        $activeHabits = $summary['active_habits'];
        $completedToday = $summary['habits_completed_today'];
        $consistencyRate = $activeHabits > 0 ? round(($completedToday / $activeHabits) * 100, 2) : 0;

        $weakHabits = ProductivityHabit::query()
            ->where('user_id', $userId)
            ->where('status', 'active')
            ->where(function ($query) use ($today) {
                $query->whereNull('last_completed_at')
                    ->orWhereDate('last_completed_at', '<', $today);
            })
            ->orderBy('last_completed_at')
            ->limit(5)
            ->get(['id', 'name', 'frequency', 'current_streak', 'best_streak', 'last_completed_at']);

        if ($activeHabits === 0) {
            $insights[] = [
                'type' => 'habit_consistency',
                'severity' => 'info',
                'title' => 'No active habits found',
                'message' => 'Habit tracking is empty or paused.',
                'action' => 'Start with one simple daily habit and check it in consistently.',
                'consistency_rate' => 0,
                'items' => [],
            ];

            return $insights;
        }

        if ($consistencyRate < 50) {
            $insights[] = [
                'type' => 'habit_consistency',
                'severity' => 'warning',
                'title' => 'Habit consistency is low',
                'message' => "Today's habit consistency is {$consistencyRate}%.",
                'action' => 'Focus on the easiest active habit first to rebuild momentum.',
                'consistency_rate' => $consistencyRate,
                'items' => $weakHabits,
            ];
        } elseif ($consistencyRate >= 80) {
            $insights[] = [
                'type' => 'habit_consistency',
                'severity' => 'success',
                'title' => 'Strong habit consistency',
                'message' => "Today's habit consistency is {$consistencyRate}%.",
                'action' => 'Keep the streak going and avoid adding too many new habits at once.',
                'consistency_rate' => $consistencyRate,
                'items' => [],
            ];
        } else {
            $insights[] = [
                'type' => 'habit_consistency',
                'severity' => 'info',
                'title' => 'Habit consistency can improve',
                'message' => "Today's habit consistency is {$consistencyRate}%.",
                'action' => 'Complete missed habits before the end of the day.',
                'consistency_rate' => $consistencyRate,
                'items' => $weakHabits,
            ];
        }

        if ($summary['habit_check_ins_this_week'] === 0 && $activeHabits > 0) {
            $insights[] = [
                'type' => 'habit_consistency',
                'severity' => 'warning',
                'title' => 'No habit check-ins this week',
                'message' => 'Active habits exist, but no weekly check-ins were recorded.',
                'action' => 'Use the habit check-in button after completing each habit.',
                'consistency_rate' => 0,
                'items' => $weakHabits,
            ];
        }

        return $insights;
    }

    private function goalProgressRecommendations(string $userId, Carbon $today, Carbon $weekEnd, array $summary): array
    {
        $insights = [];

        $behindGoals = ProductivityGoal::query()
            ->where('user_id', $userId)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->where(function ($query) use ($today, $weekEnd) {
                $query->whereDate('target_date', '<', $today)
                    ->orWhere(function ($query) use ($today, $weekEnd) {
                        $query->whereBetween('target_date', [$today->toDateString(), $weekEnd->toDateString()])
                            ->where('progress_percentage', '<', 70);
                    })
                    ->orWhere('progress_percentage', '<', 30);
            })
            ->orderBy('target_date')
            ->limit(5)
            ->get(['id', 'title', 'status', 'priority', 'progress_percentage', 'target_date']);

        if ($summary['total_goals'] === 0) {
            $insights[] = [
                'type' => 'goal_progress',
                'severity' => 'info',
                'title' => 'No goals found',
                'message' => 'No productivity goals are currently tracked.',
                'action' => 'Create one measurable goal and connect tasks or habits to it.',
                'items' => [],
            ];

            return $insights;
        }

        if ($summary['goals_overdue'] > 0) {
            $insights[] = [
                'type' => 'goal_progress',
                'severity' => 'warning',
                'title' => 'Overdue goals detected',
                'message' => "You have {$summary['goals_overdue']} overdue goal(s).",
                'action' => 'Update the target date or break each overdue goal into smaller tasks.',
                'items' => $behindGoals,
            ];
        }

        if ($summary['goals_due_this_week'] > 0 && $summary['average_goal_progress'] < 70) {
            $insights[] = [
                'type' => 'goal_progress',
                'severity' => 'warning',
                'title' => 'Goal progress is behind schedule',
                'message' => "You have {$summary['goals_due_this_week']} goal(s) due this week with average progress at {$summary['average_goal_progress']}%.",
                'action' => 'Schedule focused work blocks and update progress after each session.',
                'items' => $behindGoals,
            ];
        }

        if ($summary['average_goal_progress'] >= 75) {
            $insights[] = [
                'type' => 'goal_progress',
                'severity' => 'success',
                'title' => 'Goals are progressing well',
                'message' => "Average goal progress is {$summary['average_goal_progress']}%.",
                'action' => 'Keep updating progress and close completed goals.',
                'items' => [],
            ];
        }

        return $insights;
    }

    private function calendarOverloadWarnings(string $userId, Carbon $weekStart, Carbon $weekEnd, array $summary): array
    {
        $insights = [];

        $busyDays = ProductivityCalendarEvent::query()
            ->selectRaw('DATE(start_time) as event_date, COUNT(*) as total_events')
            ->where('user_id', $userId)
            ->whereBetween('start_time', [$weekStart, $weekEnd])
            ->groupByRaw('DATE(start_time)')
            ->havingRaw('COUNT(*) >= 5')
            ->orderByRaw('DATE(start_time)')
            ->get();

        if ($busyDays->isNotEmpty()) {
            $insights[] = [
                'type' => 'calendar_overload',
                'severity' => 'warning',
                'title' => 'Calendar overload detected',
                'message' => 'One or more days this week have 5 or more scheduled events.',
                'action' => 'Add focus blocks and avoid back-to-back scheduling where possible.',
                'items' => $busyDays,
            ];
        }

        if ($summary['calendar_events_today'] >= 5) {
            $insights[] = [
                'type' => 'calendar_overload',
                'severity' => 'warning',
                'title' => 'Today is heavily scheduled',
                'message' => "You have {$summary['calendar_events_today']} event(s) today.",
                'action' => 'Protect at least one recovery or focus period today.',
                'items' => [],
            ];
        }

        if ($summary['total_calendar_events'] === 0) {
            $insights[] = [
                'type' => 'calendar_overload',
                'severity' => 'info',
                'title' => 'No calendar events found',
                'message' => 'No productivity calendar events are currently scheduled.',
                'action' => 'Schedule focused work blocks for your top tasks and goals.',
                'items' => [],
            ];
        }

        return $insights;
    }

    private function productivityScore(array $summary): int
    {
        $taskScore = $summary['total_tasks'] > 0
            ? max(0, min(100, (($summary['tasks_completed'] / max($summary['total_tasks'], 1)) * 100) - ($summary['overdue_tasks'] * 8)))
            : 0;

        $habitScore = $summary['active_habits'] > 0
            ? max(0, min(100, ($summary['habits_completed_today'] / max($summary['active_habits'], 1)) * 100))
            : 0;

        $goalScore = $summary['total_goals'] > 0
            ? max(0, min(100, (float) $summary['average_goal_progress'] - ($summary['goals_overdue'] * 10)))
            : 0;

        $calendarScore = $summary['total_calendar_events'] > 0
            ? max(0, min(100, 100 - max(0, $summary['calendar_events_today'] - 4) * 12))
            : 70;

        $hasAnyData = ($summary['total_tasks'] + $summary['total_habits'] + $summary['total_goals'] + $summary['total_calendar_events']) > 0;

        if (! $hasAnyData) {
            return 0;
        }

        return (int) round(
            ($taskScore * 0.35)
            + ($habitScore * 0.25)
            + ($goalScore * 0.25)
            + ($calendarScore * 0.15)
        );
    }

    private function scoreLabel(int $score, bool $hasData): string
    {
        if (! $hasData) {
            return 'No Data';
        }

        return match (true) {
            $score >= 85 => 'Excellent',
            $score >= 70 => 'Good',
            $score >= 50 => 'Average',
            $score >= 30 => 'Needs Attention',
            default => 'Low',
        };
    }

    private function habitCheckInsThisWeek(string $userId, Carbon $weekStart, Carbon $weekEnd): int
    {
        if (! Schema::hasTable('productivity_habit_check_ins')) {
            return 0;
        }

        return (int) DB::table('productivity_habit_check_ins')
            ->where('user_id', $userId)
            ->where('status', 'completed')
            ->whereBetween('check_in_date', [$weekStart->toDateString(), $weekEnd->toDateString()])
            ->sum('count');
    }
}

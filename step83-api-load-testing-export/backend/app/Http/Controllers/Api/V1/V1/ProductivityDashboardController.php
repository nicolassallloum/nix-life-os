<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProductivityCalendarEvent;
use App\Models\ProductivityGoal;
use App\Models\ProductivityHabit;
use App\Models\ProductivityTask;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class ProductivityDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();
        $today = Carbon::today();
        $weekStart = $today->copy()->startOfWeek();
        $weekEnd = $today->copy()->endOfWeek();

        $cacheKey = 'productivity_dashboard_user_'.((string) $user->id).'_'.$today->toDateString();

        $data = Cache::remember($cacheKey, now()->addSeconds(60), function () use ($user, $today, $weekStart, $weekEnd) {
            $taskSummary = $this->taskSummary($user->id, $today);
        $habitSummary = $this->habitSummary($user->id, $today);
        $goalSummary = $this->goalSummary($user->id, $today);
        $calendarSummary = $this->calendarSummary($user->id, $today, $weekStart, $weekEnd);
        $charts = $this->charts($user->id, $today);

        $hasData = ($taskSummary['total_tasks'] + $habitSummary['total_habits'] + $goalSummary['total_goals'] + $calendarSummary['total_events']) > 0;

            return [
                'period' => [
                    'date' => $today->toDateString(),
                    'week_start' => $weekStart->toDateString(),
                    'week_end' => $weekEnd->toDateString(),
                ],
                'summary' => [
                    'daily_progress_percentage' => $this->dailyProgress($taskSummary, $habitSummary, $goalSummary, $calendarSummary),
                    'total_open_items' => $taskSummary['open_tasks'] + $goalSummary['active_goals'] + $calendarSummary['upcoming_events'],
                    'total_completed_today' => $taskSummary['completed_today'] + $habitSummary['completed_today'] + $calendarSummary['completed_today'],
                    'has_data' => $hasData,
                    'empty_state' => !$hasData,
                ],
                'tasks' => $taskSummary,
                'habits' => $habitSummary,
                'goals' => $goalSummary,
                'calendar' => $calendarSummary,
                'charts' => $charts,
                'cache_ttl_seconds' => 60,
                'generated_at' => now()->toDateTimeString(),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Productivity dashboard summary loaded successfully.',
            'data' => $data,
        ]);
    }

    private function taskSummary(string $userId, Carbon $today): array
    {
        $base = ProductivityTask::query()->where('user_id', $userId);

        $total = (clone $base)->count();
        $completed = (clone $base)->where('status', 'completed')->count();
        $todo = (clone $base)->where('status', 'todo')->count();
        $inProgress = (clone $base)->where('status', 'in_progress')->count();
        $cancelled = (clone $base)->where('status', 'cancelled')->count();
        $overdue = (clone $base)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('due_date', '<', $today)
            ->count();
        $dueToday = (clone $base)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('due_date', $today)
            ->count();
        $completedToday = (clone $base)
            ->where('status', 'completed')
            ->whereDate('completed_at', $today)
            ->count();

        return [
            'total_tasks' => $total,
            'open_tasks' => max($total - $completed - $cancelled, 0),
            'todo_tasks' => $todo,
            'in_progress_tasks' => $inProgress,
            'completed_tasks' => $completed,
            'cancelled_tasks' => $cancelled,
            'overdue_tasks' => $overdue,
            'due_today' => $dueToday,
            'completed_today' => $completedToday,
            'completion_rate' => $this->percentage($completed, $total),
        ];
    }

    private function habitSummary(string $userId, Carbon $today): array
    {
        $base = ProductivityHabit::query()->where('user_id', $userId);

        $total = (clone $base)->count();
        $active = (clone $base)->where('status', 'active')->count();
        $paused = (clone $base)->where('status', 'paused')->count();
        $completedToday = (clone $base)
            ->where('status', 'active')
            ->where(function ($query) use ($today) {
                $query->whereDate('last_completed_at', $today)
                    ->orWhereColumn('completed_count_today', '>=', 'target_count');
            })
            ->count();
        $missedToday = max($active - $completedToday, 0);
        $bestStreak = (int) (clone $base)->max('best_streak');

        return [
            'total_habits' => $total,
            'active_habits' => $active,
            'paused_habits' => $paused,
            'completed_today' => $completedToday,
            'missed_today' => $missedToday,
            'best_streak' => $bestStreak,
            'consistency_rate' => $this->percentage($completedToday, $active),
        ];
    }

    private function goalSummary(string $userId, Carbon $today): array
    {
        $base = ProductivityGoal::query()->where('user_id', $userId);

        $total = (clone $base)->count();
        $active = (clone $base)->where('status', 'active')->count();
        $completed = (clone $base)->where('status', 'completed')->count();
        $onHold = (clone $base)->where('status', 'on_hold')->count();
        $overdue = (clone $base)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereDate('target_date', '<', $today)
            ->count();
        $dueThisWeek = (clone $base)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereBetween('target_date', [$today->toDateString(), $today->copy()->endOfWeek()->toDateString()])
            ->count();
        $averageProgress = round((float) (clone $base)->avg('progress_percentage'), 2);

        return [
            'total_goals' => $total,
            'active_goals' => $active,
            'completed_goals' => $completed,
            'on_hold_goals' => $onHold,
            'overdue_goals' => $overdue,
            'due_this_week' => $dueThisWeek,
            'average_progress_percentage' => $averageProgress,
            'completion_rate' => $this->percentage($completed, $total),
        ];
    }

    private function calendarSummary(string $userId, Carbon $today, Carbon $weekStart, Carbon $weekEnd): array
    {
        $base = ProductivityCalendarEvent::query()->where('user_id', $userId);

        $total = (clone $base)->count();
        $todayEvents = (clone $base)->whereDate('start_time', $today)->count();
        $weekEvents = (clone $base)->whereBetween('start_time', [$weekStart, $weekEnd])->count();
        $upcomingEvents = (clone $base)->where('status', 'scheduled')->where('start_time', '>=', now())->count();
        $completedToday = (clone $base)->where('status', 'completed')->whereDate('start_time', $today)->count();
        $cancelled = (clone $base)->where('status', 'cancelled')->count();

        $nextEvents = (clone $base)
            ->where('status', 'scheduled')
            ->where('start_time', '>=', now())
            ->orderBy('start_time')
            ->limit(5)
            ->get(['id', 'title', 'event_type', 'status', 'start_time', 'end_time', 'location']);

        return [
            'total_events' => $total,
            'today_events' => $todayEvents,
            'week_events' => $weekEvents,
            'upcoming_events' => $upcomingEvents,
            'completed_today' => $completedToday,
            'cancelled_events' => $cancelled,
            'next_events' => $nextEvents,
        ];
    }

    private function charts(string $userId, Carbon $today): array
    {
        return [
            'tasks_by_status' => $this->countByStatus(ProductivityTask::class, $userId, ['todo', 'in_progress', 'completed', 'cancelled']),
            'goals_by_status' => $this->countByStatus(ProductivityGoal::class, $userId, ['active', 'completed', 'on_hold', 'cancelled']),
            'habit_completion_last_7_days' => $this->habitCompletionLast7Days($userId, $today),
            'calendar_next_7_days' => $this->calendarNext7Days($userId, $today),
        ];
    }

    private function countByStatus(string $modelClass, string $userId, array $statuses): array
    {
        $counts = $modelClass::query()
            ->select('status', DB::raw('COUNT(*) as total'))
            ->where('user_id', $userId)
            ->groupBy('status')
            ->pluck('total', 'status')
            ->toArray();

        return collect($statuses)->map(fn ($status) => [
            'label' => $status,
            'value' => (int) ($counts[$status] ?? 0),
        ])->values()->toArray();
    }

    private function habitCompletionLast7Days(string $userId, Carbon $today): array
    {
        $period = CarbonPeriod::create($today->copy()->subDays(6), $today);

        return collect($period)->map(function (Carbon $date) use ($userId) {
            return [
                'date' => $date->toDateString(),
                'completed' => ProductivityHabit::query()
                    ->where('user_id', $userId)
                    ->where('status', 'active')
                    ->whereDate('last_completed_at', $date)
                    ->count(),
            ];
        })->values()->toArray();
    }

    private function calendarNext7Days(string $userId, Carbon $today): array
    {
        $period = CarbonPeriod::create($today, $today->copy()->addDays(6));

        return collect($period)->map(function (Carbon $date) use ($userId) {
            return [
                'date' => $date->toDateString(),
                'events' => ProductivityCalendarEvent::query()
                    ->where('user_id', $userId)
                    ->whereDate('start_time', $date)
                    ->count(),
            ];
        })->values()->toArray();
    }

    private function dailyProgress(array $taskSummary, array $habitSummary, array $goalSummary, array $calendarSummary): int
    {
        $scores = [];

        if ($taskSummary['total_tasks'] > 0) {
            $scores[] = $taskSummary['completion_rate'];
        }

        if ($habitSummary['active_habits'] > 0) {
            $scores[] = $habitSummary['consistency_rate'];
        }

        if ($goalSummary['total_goals'] > 0) {
            $scores[] = (float) $goalSummary['average_progress_percentage'];
        }

        if ($calendarSummary['today_events'] > 0) {
            $scores[] = $this->percentage($calendarSummary['completed_today'], $calendarSummary['today_events']);
        }

        if (count($scores) === 0) {
            return 0;
        }

        return (int) round(array_sum($scores) / count($scores));
    }

    private function percentage(int|float $value, int|float $total): int
    {
        if ($total <= 0) {
            return 0;
        }

        return (int) round(($value / $total) * 100);
    }
}

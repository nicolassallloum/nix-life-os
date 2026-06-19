<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class UserPointService
{
    public const ACTION_POINTS = [
        'health.steps.add_log' => 5,
        'health.steps.reach_goal' => 20,
        'health.hydration.add_log' => 3,
        'health.hydration.reach_goal' => 15,
        'productivity.task.complete' => 10,
        'projects.project.complete' => 100,
        'ai.happy_win.add' => 15,
        'finance.transaction.add' => 3,
    ];

    public function award(
        string $userId,
        string $module,
        string $actionName,
        ?int $points = null,
        ?string $referenceId = null
    ): array {
        $resolvedPoints = $points ?? $this->pointsFor($module, $actionName);

        if ($resolvedPoints <= 0) {
            return $this->summary($userId);
        }

        return DB::transaction(function () use ($userId, $module, $actionName, $resolvedPoints, $referenceId) {
            $current = DB::table('user_points')
                ->where('user_id', $userId)
                ->lockForUpdate()
                ->first();

            if (! $current) {
                DB::table('user_points')->insert([
                    'user_id' => $userId,
                    'points' => 0,
                    'level' => 1,
                    'total_points' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $current = DB::table('user_points')
                    ->where('user_id', $userId)
                    ->lockForUpdate()
                    ->first();
            }

            $newTotalPoints = (int) $current->total_points + $resolvedPoints;
            $newLevel = $this->calculateLevel($newTotalPoints);
            $pointsIntoCurrentLevel = $this->pointsIntoCurrentLevel($newTotalPoints);

            DB::table('user_points')
                ->where('user_id', $userId)
                ->update([
                    'points' => $pointsIntoCurrentLevel,
                    'level' => $newLevel,
                    'total_points' => $newTotalPoints,
                    'updated_at' => now(),
                ]);

            DB::table('user_point_logs')->insert([
                'user_id' => $userId,
                'module' => $module,
                'action_name' => $actionName,
                'points' => $resolvedPoints,
                'reference_id' => $referenceId,
                'created_at' => now(),
            ]);

            return $this->summary($userId);
        });
    }

    public function ensureUserPoints(string $userId): object
    {
        $points = DB::table('user_points')->where('user_id', $userId)->first();

        if ($points) {
            return $points;
        }

        DB::table('user_points')->insert([
            'user_id' => $userId,
            'points' => 0,
            'level' => 1,
            'total_points' => 0,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return DB::table('user_points')->where('user_id', $userId)->first();
    }

    public function summary(string $userId): array
    {
        if (! Schema::hasTable('user_points')) {
            return $this->emptySummary();
        }

        $points = $this->ensureUserPoints($userId);

        $level = (int) $points->level;
        $currentLevelStart = $this->levelStartPoints($level);
        $nextLevelStart = $this->levelStartPoints($level + 1);
        $levelRange = max(1, $nextLevelStart - $currentLevelStart);
        $progressPoints = max(0, (int) $points->total_points - $currentLevelStart);
        $progressPercent = min(100, round(($progressPoints / $levelRange) * 100));

        return [
            'points' => (int) $points->points,
            'level' => $level,
            'total_points' => (int) $points->total_points,
            'next_level_points' => $nextLevelStart,
            'points_to_next_level' => max(0, $nextLevelStart - (int) $points->total_points),
            'progress_percent' => $progressPercent,
            'achievements' => $this->achievements((int) $points->total_points, $level),
            'earning_ideas' => $this->earningIdeas(),
        ];
    }

    public function logs(string $userId, int $limit = 30): array
    {
        if (! Schema::hasTable('user_point_logs')) {
            return [];
        }

        return DB::table('user_point_logs')
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get()
            ->map(fn ($log) => [
                'id' => $log->id,
                'module' => $log->module,
                'action_name' => $log->action_name,
                'points' => (int) $log->points,
                'reference_id' => $log->reference_id,
                'created_at' => $log->created_at,
            ])
            ->values()
            ->all();
    }

    public function pointsFor(string $module, string $actionName): int
    {
        $key = "{$module}.{$actionName}";

        return self::ACTION_POINTS[$key] ?? 0;
    }

    public function calculateLevel(int $totalPoints): int
    {
        return max(1, (int) floor($totalPoints / 100) + 1);
    }

    private function pointsIntoCurrentLevel(int $totalPoints): int
    {
        return $totalPoints % 100;
    }

    private function levelStartPoints(int $level): int
    {
        return max(0, ($level - 1) * 100);
    }

    private function earningIdeas(): array
    {
        return [
            [
                'module' => 'Health',
                'action' => 'Add daily step log',
                'points' => self::ACTION_POINTS['health.steps.add_log'],
                'description' => 'Record your daily steps to build consistency.',
            ],
            [
                'module' => 'Health',
                'action' => 'Reach daily step goal',
                'points' => self::ACTION_POINTS['health.steps.reach_goal'],
                'description' => 'Complete your daily steps target for a larger reward.',
            ],
            [
                'module' => 'Hydration',
                'action' => 'Add hydration log',
                'points' => self::ACTION_POINTS['health.hydration.add_log'],
                'description' => 'Log water intake during the day.',
            ],
            [
                'module' => 'Hydration',
                'action' => 'Reach hydration goal',
                'points' => self::ACTION_POINTS['health.hydration.reach_goal'],
                'description' => 'Complete your daily water target.',
            ],
            [
                'module' => 'Finance',
                'action' => 'Add finance transaction',
                'points' => self::ACTION_POINTS['finance.transaction.add'],
                'description' => 'Track income, expense, transfer, or savings activity.',
            ],
            [
                'module' => 'Productivity',
                'action' => 'Complete a task',
                'points' => self::ACTION_POINTS['productivity.task.complete'],
                'description' => 'Mark tasks as completed to grow your productivity score.',
            ],
            [
                'module' => 'Projects',
                'action' => 'Complete a project',
                'points' => self::ACTION_POINTS['projects.project.complete'],
                'description' => 'Finish a full project for the highest level reward.',
            ],
            [
                'module' => 'AI',
                'action' => 'Add a happy win',
                'points' => self::ACTION_POINTS['ai.happy_win.add'],
                'description' => 'Record a positive win or achievement for AI life tracking.',
            ],
        ];
    }

    private function achievements(int $totalPoints, int $level): array
    {
        $items = [
            [
                'key' => 'first_points',
                'title' => 'First Points',
                'description' => 'Earn your first points.',
                'unlocked' => $totalPoints > 0,
            ],
            [
                'key' => 'level_2',
                'title' => 'Level 2',
                'description' => 'Reach Level 2.',
                'unlocked' => $level >= 2,
            ],
            [
                'key' => 'level_5',
                'title' => 'Level 5',
                'description' => 'Reach Level 5.',
                'unlocked' => $level >= 5,
            ],
            [
                'key' => 'points_500',
                'title' => '500 Points Club',
                'description' => 'Earn 500 total points.',
                'unlocked' => $totalPoints >= 500,
            ],
            [
                'key' => 'points_1000',
                'title' => '1,000 Points Club',
                'description' => 'Earn 1,000 total points.',
                'unlocked' => $totalPoints >= 1000,
            ],
        ];

        return $items;
    }

    private function emptySummary(): array
    {
        return [
            'points' => 0,
            'level' => 1,
            'total_points' => 0,
            'next_level_points' => 100,
            'points_to_next_level' => 100,
            'progress_percent' => 0,
            'achievements' => [],
            'earning_ideas' => $this->earningIdeas(),
        ];
    }
}

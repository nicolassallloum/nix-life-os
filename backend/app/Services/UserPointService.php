<?php

namespace App\Services;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class UserPointService
{
    private const LEVEL_THRESHOLDS = [
        1 => 0,
        2 => 50000,
        3 => 125000,
        4 => 225000,
        5 => 350000,
        6 => 500000,
        7 => 650000,
        8 => 800000,
        9 => 950000,
        10 => 1000000,
    ];

    public const ACTION_POINTS = [
        'health.steps.add_log' => 5,
        'health.steps.reach_goal' => 20,
        'health.hydration.add_log' => 3,
        'health.hydration.reach_goal' => 15,
        'productivity.task.complete' => 10,
        'productivity.goal.complete' => 25,
        'projects.task.complete' => 10,
        'projects.project.complete' => 100,
        'ai.happy_win.add' => 15,
        'finance.transaction.add' => 3,
    ];

    public function award(
        string $userId,
        string $module,
        string $actionName,
        ?int $points = null,
        ?string $referenceId = null,
        ?string $description = null
    ): array {
        return $this->awardPoints(
            $userId,
            $module,
            $actionName,
            $points,
            $description,
            $referenceId
        );
    }

    public function awardPoints(
        string $userId,
        string $module,
        string $actionName,
        ?int $points = null,
        ?string $description = null,
        ?string $relatedId = null
    ): array {
        if (! Schema::hasTable('user_points') || ! Schema::hasTable('user_point_logs')) {
            return $this->emptySummary();
        }

        $resolvedPoints = $points ?? $this->pointsFor($module, $actionName);

        if ($resolvedPoints <= 0) {
            return $this->summary($userId);
        }

        DB::transaction(function () use ($userId, $module, $actionName, $resolvedPoints, $description, $relatedId) {
            $this->ensureUserPoints($userId);

            if ($relatedId && $this->pointLogExists($userId, $module, $actionName, $relatedId)) {
                return;
            }

            DB::table('user_point_logs')->insert($this->pointLogPayload(
                $userId,
                $module,
                $actionName,
                $resolvedPoints,
                $description ?: $this->defaultDescription($module, $actionName),
                $relatedId
            ));
        });

        return $this->summary($userId);
    }

    public function summary(string $userId): array
    {
        if (! Schema::hasTable('user_points')) {
            return $this->emptySummary();
        }

        $this->ensureUserPoints($userId);
        $this->syncDerivedPointLogs($userId);

        $totalPoints = $this->rebuildUserPointsFromLogs($userId);

        return $this->summaryFromTotal($totalPoints);
    }

    public function logs(string $userId, int $limit = 30): array
    {
        if (! Schema::hasTable('user_point_logs')) {
            return [];
        }

        $select = ['id', 'module', 'action_name', 'points', 'reference_id', 'created_at'];

        foreach (['action_type', 'description', 'related_id'] as $column) {
            if (Schema::hasColumn('user_point_logs', $column)) {
                $select[] = $column;
            }
        }

        return DB::table('user_point_logs')
            ->select($select)
            ->where('user_id', $userId)
            ->orderByDesc('created_at')
            ->limit(min(100, max(1, $limit)))
            ->get()
            ->map(fn ($log) => [
                'id' => $log->id,
                'module' => $log->module,
                'action_name' => $log->action_name,
                'action_type' => $log->action_type ?? $log->action_name,
                'description' => $log->description ?? $this->defaultDescription($log->module, $log->action_name),
                'points' => (int) $log->points,
                'reference_id' => $log->reference_id ?? null,
                'related_id' => $log->related_id ?? ($log->reference_id ?? null),
                'created_at' => $log->created_at,
            ])
            ->values()
            ->all();
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

    public function pointsFor(string $module, string $actionName): int
    {
        return self::ACTION_POINTS["{$module}.{$actionName}"] ?? 0;
    }

    public function calculateLevel(int $totalPoints): int
    {
        $level = 1;

        foreach (self::LEVEL_THRESHOLDS as $thresholdLevel => $requiredPoints) {
            if ($totalPoints >= $requiredPoints) {
                $level = $thresholdLevel;
            }
        }

        return min(10, max(1, $level));
    }

    public function levelSummary(int $totalPoints): array
    {
        $currentLevel = $this->calculateLevel($totalPoints);
        $currentThreshold = self::LEVEL_THRESHOLDS[$currentLevel];

        if ($currentLevel >= 10) {
            return [
                'current_level' => 10,
                'current_threshold' => self::LEVEL_THRESHOLDS[10],
                'next_level' => null,
                'next_threshold' => null,
                'remaining_points' => 0,
                'progress_percent' => 100,
                'label' => 'Max Level Reached',
            ];
        }

        $nextLevel = $currentLevel + 1;
        $nextThreshold = self::LEVEL_THRESHOLDS[$nextLevel];
        $range = max(1, $nextThreshold - $currentThreshold);
        $progress = max(0, $totalPoints - $currentThreshold);

        return [
            'current_level' => $currentLevel,
            'current_threshold' => $currentThreshold,
            'next_level' => $nextLevel,
            'next_threshold' => $nextThreshold,
            'remaining_points' => max(0, $nextThreshold - $totalPoints),
            'progress_percent' => min(100, (int) round(($progress / $range) * 100)),
            'label' => "Level {$currentLevel}",
        ];
    }

    private function summaryFromTotal(int $totalPoints): array
    {
        $level = $this->levelSummary($totalPoints);
        $currentPoints = max(0, $totalPoints - (int) $level['current_threshold']);

        return [
            'current_points' => $currentPoints,
            'points' => $currentPoints,
            'level' => (int) $level['current_level'],
            'current_level' => (int) $level['current_level'],
            'total_points' => $totalPoints,
            'current_threshold' => (int) $level['current_threshold'],
            'next_level' => $level['next_level'],
            'next_threshold' => $level['next_threshold'],
            'next_level_points' => $level['next_threshold'],
            'points_to_next_level' => (int) $level['remaining_points'],
            'remaining_points' => (int) $level['remaining_points'],
            'progress_percent' => (int) $level['progress_percent'],
            'progress_percentage' => (int) $level['progress_percent'],
            'level_label' => $level['label'],
            'level_summary' => $level,
            'achievements' => $this->achievements($totalPoints, (int) $level['current_level']),
            'earning_ideas' => $this->earningIdeas(),
        ];
    }

    private function rebuildUserPointsFromLogs(string $userId): int
    {
        $current = DB::table('user_points')->where('user_id', $userId)->first();

        $logTotal = Schema::hasTable('user_point_logs')
            ? (int) DB::table('user_point_logs')->where('user_id', $userId)->sum('points')
            : 0;

        if ($current && (int) $current->total_points > $logTotal && Schema::hasTable('user_point_logs')) {
            $legacyExists = DB::table('user_point_logs')
                ->where('user_id', $userId)
                ->where('module', 'profile')
                ->where('action_name', 'legacy.points.import')
                ->exists();

            if (! $legacyExists) {
                $legacyPoints = (int) $current->total_points - $logTotal;

                if ($legacyPoints > 0) {
                    DB::table('user_point_logs')->insert($this->pointLogPayload(
                        $userId,
                        'profile',
                        'legacy.points.import',
                        $legacyPoints,
                        'Imported existing lifetime points into points history.',
                        'legacy:user_points'
                    ));

                    $logTotal += $legacyPoints;
                }
            }
        }

        $level = $this->calculateLevel($logTotal);
        $pointsIntoLevel = max(0, $logTotal - self::LEVEL_THRESHOLDS[$level]);

        DB::table('user_points')
            ->where('user_id', $userId)
            ->update([
                'points' => $pointsIntoLevel,
                'level' => $level,
                'total_points' => $logTotal,
                'updated_at' => now(),
            ]);

        return $logTotal;
    }

    private function syncDerivedPointLogs(string $userId): void
    {
        if (! Schema::hasTable('user_point_logs')) {
            return;
        }

        $sources = [
            [
                'table' => 'tasks',
                'module' => 'productivity',
                'action' => 'task.complete',
                'points' => self::ACTION_POINTS['productivity.task.complete'],
                'description' => 'Completed a productivity task.',
            ],
            [
                'table' => 'productivity_tasks',
                'module' => 'productivity',
                'action' => 'task.complete',
                'points' => self::ACTION_POINTS['productivity.task.complete'],
                'description' => 'Completed a productivity task.',
            ],
            [
                'table' => 'project_tasks',
                'module' => 'projects',
                'action' => 'task.complete',
                'points' => self::ACTION_POINTS['projects.task.complete'],
                'description' => 'Completed a project task.',
            ],
            [
                'table' => 'project_goals',
                'module' => 'projects',
                'action' => 'project.complete',
                'points' => self::ACTION_POINTS['projects.project.complete'],
                'description' => 'Completed a project goal.',
            ],
            [
                'table' => 'productivity_goals',
                'module' => 'productivity',
                'action' => 'goal.complete',
                'points' => self::ACTION_POINTS['productivity.goal.complete'],
                'description' => 'Completed a productivity goal.',
            ],
        ];

        foreach ($sources as $source) {
            $this->syncCompletedRowsFromTable($userId, $source);
        }
    }

    private function syncCompletedRowsFromTable(string $userId, array $source): void
    {
        $table = $source['table'];

        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, 'id') || ! Schema::hasColumn($table, 'user_id')) {
            return;
        }

        $query = DB::table($table)
            ->select(['id'])
            ->where('user_id', $userId)
            ->orderBy('id');

        if (! $this->applyCompletionFilter($query, $table)) {
            return;
        }

        $query->limit(5000)->get()->each(function ($row) use ($userId, $source, $table) {
            $referenceId = "{$table}:{$row->id}";

            if ($this->pointLogExists($userId, $source['module'], $source['action'], $referenceId)) {
                return;
            }

            DB::table('user_point_logs')->insert($this->pointLogPayload(
                $userId,
                $source['module'],
                $source['action'],
                (int) $source['points'],
                $source['description'],
                $referenceId
            ));
        });
    }

    private function applyCompletionFilter(Builder $query, string $table): bool
    {
        $hasFilter = false;

        $query->where(function (Builder $q) use ($table, &$hasFilter) {
            if (Schema::hasColumn($table, 'status')) {
                $q->orWhereIn('status', ['completed', 'complete', 'done', 'finished']);
                $hasFilter = true;
            }

            if (Schema::hasColumn($table, 'completed_at')) {
                $q->orWhereNotNull('completed_at');
                $hasFilter = true;
            }

            if (Schema::hasColumn($table, 'is_completed')) {
                $q->orWhere('is_completed', true);
                $hasFilter = true;
            }

            if (Schema::hasColumn($table, 'done')) {
                $q->orWhere('done', true);
                $hasFilter = true;
            }
        });

        return $hasFilter;
    }

    private function pointLogExists(string $userId, string $module, string $actionName, string $relatedId): bool
    {
        $query = DB::table('user_point_logs')
            ->where('user_id', $userId)
            ->where('module', $module)
            ->where('action_name', $actionName);

        if (Schema::hasColumn('user_point_logs', 'related_id')) {
            $query->where(function (Builder $q) use ($relatedId) {
                $q->where('related_id', $relatedId)
                    ->orWhere('reference_id', $relatedId);
            });
        } else {
            $query->where('reference_id', $relatedId);
        }

        return $query->exists();
    }

    private function pointLogPayload(
        string $userId,
        string $module,
        string $actionName,
        int $points,
        ?string $description,
        ?string $relatedId
    ): array {
        $payload = [
            'user_id' => $userId,
            'module' => $module,
            'action_name' => $actionName,
            'points' => $points,
            'reference_id' => $relatedId,
            'created_at' => now(),
        ];

        if (Schema::hasColumn('user_point_logs', 'action_type')) {
            $payload['action_type'] = $actionName;
        }

        if (Schema::hasColumn('user_point_logs', 'description')) {
            $payload['description'] = $description;
        }

        if (Schema::hasColumn('user_point_logs', 'related_id')) {
            $payload['related_id'] = $relatedId;
        }

        if (Schema::hasColumn('user_point_logs', 'updated_at')) {
            $payload['updated_at'] = now();
        }

        return $payload;
    }

    private function defaultDescription(string $module, string $actionName): string
    {
        return ucfirst($module) . ' activity: ' . str_replace('.', ' ', $actionName);
    }

    private function achievements(int $totalPoints, int $level): array
    {
        return [
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
                'action' => 'Complete a project task',
                'points' => self::ACTION_POINTS['projects.task.complete'],
                'description' => 'Finish project work to earn project points.',
            ],
            [
                'module' => 'Projects',
                'action' => 'Complete a project goal',
                'points' => self::ACTION_POINTS['projects.project.complete'],
                'description' => 'Complete a full project goal for the highest reward.',
            ],
            [
                'module' => 'AI',
                'action' => 'Add a happy win',
                'points' => self::ACTION_POINTS['ai.happy_win.add'],
                'description' => 'Record a positive win or achievement for AI life tracking.',
            ],
        ];
    }

    private function emptySummary(): array
    {
        return $this->summaryFromTotal(0);
    }
}

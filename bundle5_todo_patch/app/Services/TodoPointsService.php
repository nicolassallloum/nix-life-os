<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TodoPointsService
{
    public const FINISHED_STATUS = 'finished';

    public const TASK_TYPES = [
        'general',
        'monthly',
        'weekly',
        'daily',
    ];

    public function summary(int $userId): array
    {
        $typePoints = $this->taskTypePoints($userId);

        return [
            'total_completed_points' => $this->totalCompletedPoints($userId),
            'general_points' => $typePoints['general'] ?? 0,
            'monthly_points' => $typePoints['monthly'] ?? 0,
            'weekly_points' => $typePoints['weekly'] ?? 0,
            'daily_points' => $typePoints['daily'] ?? 0,
            'points_by_task_type' => $typePoints,
            'project_points' => $this->projectPoints($userId),
        ];
    }

    public function totalCompletedPoints(int $userId): int
    {
        return (int) DB::table('todo_tasks')
            ->where('user_id', $userId)
            ->where('status', self::FINISHED_STATUS)
            ->sum(DB::raw('COALESCE(points, 0)'));
    }

    public function taskTypePoints(int $userId): array
    {
        $points = array_fill_keys(self::TASK_TYPES, 0);

        $rows = DB::table('todo_tasks')
            ->select('task_type', DB::raw('COALESCE(SUM(COALESCE(points, 0)), 0) AS total_points'))
            ->where('user_id', $userId)
            ->where('status', self::FINISHED_STATUS)
            ->whereIn('task_type', self::TASK_TYPES)
            ->groupBy('task_type')
            ->get();

        foreach ($rows as $row) {
            $points[$row->task_type] = (int) $row->total_points;
        }

        return $points;
    }

    public function projectPoints(int $userId): array
    {
        $query = DB::table('todo_tasks')
            ->where('todo_tasks.user_id', $userId)
            ->where('todo_tasks.status', self::FINISHED_STATUS)
            ->whereNotNull('todo_tasks.project_id')
            ->groupBy('todo_tasks.project_id')
            ->orderByDesc(DB::raw('SUM(COALESCE(todo_tasks.points, 0))'));

        if (Schema::hasTable('todo_projects')) {
            $query
                ->leftJoin('todo_projects', 'todo_projects.id', '=', 'todo_tasks.project_id')
                ->addSelect('todo_tasks.project_id')
                ->addSelect(DB::raw('MAX(todo_projects.name) AS project_name'))
                ->addSelect(DB::raw('COALESCE(SUM(COALESCE(todo_tasks.points, 0)), 0) AS total_points'));
        } else {
            $query
                ->addSelect('todo_tasks.project_id')
                ->addSelect(DB::raw('NULL AS project_name'))
                ->addSelect(DB::raw('COALESCE(SUM(COALESCE(todo_tasks.points, 0)), 0) AS total_points'));
        }

        return $query->get()->map(fn ($row) => [
            'project_id' => (int) $row->project_id,
            'project_name' => $row->project_name,
            'points' => (int) $row->total_points,
        ])->values()->all();
    }

    public function projectSummary(int $userId, int $projectId): array
    {
        $totalTasks = DB::table('todo_tasks')
            ->where('user_id', $userId)
            ->where('project_id', $projectId)
            ->count();

        $finishedTasks = DB::table('todo_tasks')
            ->where('user_id', $userId)
            ->where('project_id', $projectId)
            ->where('status', self::FINISHED_STATUS)
            ->count();

        $projectPoints = (int) DB::table('todo_tasks')
            ->where('user_id', $userId)
            ->where('project_id', $projectId)
            ->where('status', self::FINISHED_STATUS)
            ->sum(DB::raw('COALESCE(points, 0)'));

        return [
            'project_total_points' => $projectPoints,
            'total_tasks' => (int) $totalTasks,
            'finished_tasks' => (int) $finishedTasks,
            'completion_percentage' => $totalTasks > 0 ? round(($finishedTasks / $totalTasks) * 100, 2) : 0,
        ];
    }
}

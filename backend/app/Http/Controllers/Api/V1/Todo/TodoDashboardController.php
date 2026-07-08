<?php

namespace App\Http\Controllers\Api\V1\Todo;

use App\Http\Controllers\Controller;
use App\Models\TodoProject;
use App\Models\TodoTask;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TodoDashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $taskBase = TodoTask::query()->where('user_id', $userId);

        $totalTasks = (clone $taskBase)->count();
        $finishedTasks = (clone $taskBase)->where('status', TodoTask::STATUS_FINISHED)->count();
        $pendingTasks = (clone $taskBase)->where('status', TodoTask::STATUS_PENDING)->count();
        $inProgressTasks = (clone $taskBase)->where('status', TodoTask::STATUS_IN_PROGRESS)->count();

        $completionPercentage = $totalTasks > 0
            ? round(($finishedTasks / $totalTasks) * 100, 2)
            : 0;

        $tasksByType = (clone $taskBase)
            ->selectRaw('task_type, COUNT(*) as total')
            ->groupBy('task_type')
            ->pluck('total', 'task_type');

        $pointsByType = (clone $taskBase)
            ->where('status', TodoTask::STATUS_FINISHED)
            ->selectRaw('task_type, COALESCE(SUM(points), 0) as total')
            ->groupBy('task_type')
            ->pluck('total', 'task_type');

        $totalPoints = (int) (clone $taskBase)
            ->where('status', TodoTask::STATUS_FINISHED)
            ->sum('points');

        $activeProjects = TodoProject::query()
            ->where('user_id', $userId)
            ->where('status', TodoProject::STATUS_ACTIVE)
            ->count();

        $completedProjects = TodoProject::query()
            ->where('user_id', $userId)
            ->where('status', TodoProject::STATUS_COMPLETED)
            ->count();

        $projectProgressSummary = TodoProject::query()
            ->where('user_id', $userId)
            ->withCount([
                'tasks as total_tasks',
                'tasks as finished_tasks' => function ($query) {
                    $query->where('status', TodoTask::STATUS_FINISHED);
                },
            ])
            ->withSum([
                'tasks as project_points' => function ($query) {
                    $query->where('status', TodoTask::STATUS_FINISHED);
                },
            ], 'points')
            ->orderByDesc('created_at')
            ->get()
            ->map(function (TodoProject $project) {
                $totalTasks = (int) ($project->total_tasks ?? 0);
                $finishedTasks = (int) ($project->finished_tasks ?? 0);

                return [
                    'id' => $project->id,
                    'name' => $project->name,
                    'status' => $project->status,
                    'total_tasks' => $totalTasks,
                    'finished_tasks' => $finishedTasks,
                    'completion_percentage' => $totalTasks > 0
                        ? round(($finishedTasks / $totalTasks) * 100, 2)
                        : 0,
                    'project_points' => (int) ($project->project_points ?? 0),
                ];
            })
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Todo dashboard loaded successfully.',
            'data' => [
                'total_tasks' => $totalTasks,
                'finished_tasks' => $finishedTasks,
                'pending_tasks' => $pendingTasks,
                'in_progress_tasks' => $inProgressTasks,
                'completion_percentage' => $completionPercentage,
                'total_points' => $totalPoints,

                'monthly_tasks' => (int) ($tasksByType[TodoTask::TYPE_MONTHLY] ?? 0),
                'weekly_tasks' => (int) ($tasksByType[TodoTask::TYPE_WEEKLY] ?? 0),
                'daily_tasks' => (int) ($tasksByType[TodoTask::TYPE_DAILY] ?? 0),
                'general_tasks' => (int) ($tasksByType[TodoTask::TYPE_GENERAL] ?? 0),

                'active_projects' => $activeProjects,
                'completed_projects' => $completedProjects,
                'project_progress_summary' => $projectProgressSummary,

                'monthly_points' => (int) ($pointsByType[TodoTask::TYPE_MONTHLY] ?? 0),
                'weekly_points' => (int) ($pointsByType[TodoTask::TYPE_WEEKLY] ?? 0),
                'daily_points' => (int) ($pointsByType[TodoTask::TYPE_DAILY] ?? 0),
                'general_points' => (int) ($pointsByType[TodoTask::TYPE_GENERAL] ?? 0),
            ],
        ]);
    }
}

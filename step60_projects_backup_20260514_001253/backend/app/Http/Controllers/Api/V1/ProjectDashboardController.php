<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Throwable;

class ProjectDashboardController extends Controller
{
    public function summary(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'message' => 'Unauthenticated.',
                ], 401);
            }

            $userId = $user->id;

            $baseProjects = Project::query()
                ->where('user_id', $userId);

            $totalProjects = (clone $baseProjects)->count();

            $activeProjects = (clone $baseProjects)
                ->where('status', 'in_progress')
                ->count();

            $completedProjects = (clone $baseProjects)
                ->where('status', 'completed')
                ->count();

            $averageProgress = (clone $baseProjects)
                ->avg('progress_percentage');

            $overdueTasks = ProjectTask::query()
                ->join('projects', 'projects.id', '=', 'project_tasks.project_id')
                ->where('projects.user_id', $userId)
                ->whereNotIn('project_tasks.status', ['completed', 'cancelled'])
                ->whereNotNull('project_tasks.due_date')
                ->whereDate('project_tasks.due_date', '<', now()->toDateString())
                ->count();

            $statusChart = (clone $baseProjects)
                ->select('status', DB::raw('COUNT(*) as total'))
                ->groupBy('status')
                ->orderBy('status')
                ->get()
                ->map(function ($item) {
                    return [
                        'label' => $this->formatLabel($item->status),
                        'status' => $item->status,
                        'value' => (int) $item->total,
                    ];
                })
                ->values();

            $priorityChart = (clone $baseProjects)
                ->select('priority', DB::raw('COUNT(*) as total'))
                ->groupBy('priority')
                ->orderBy('priority')
                ->get()
                ->map(function ($item) {
                    return [
                        'label' => $this->formatLabel($item->priority),
                        'priority' => $item->priority,
                        'value' => (int) $item->total,
                    ];
                })
                ->values();

            $progressCards = (clone $baseProjects)
                ->withCount([
                    'tasks as total_tasks',
                    'tasks as completed_tasks' => function ($query) {
                        $query->where('status', 'completed');
                    },
                ])
                ->latest()
                ->limit(8)
                ->get()
                ->map(function ($project) {
                    return [
                        'id' => $project->id,
                        'project_name' => $project->project_name,
                        'project_code' => $project->project_code,
                        'status' => $project->status,
                        'priority' => $project->priority,
                        'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                        'total_tasks' => (int) ($project->total_tasks ?? 0),
                        'completed_tasks' => (int) ($project->completed_tasks ?? 0),
                        'target_end_date' => $project->target_end_date
                            ? $project->target_end_date->toDateString()
                            : null,
                    ];
                })
                ->values();

            $recentProjects = (clone $baseProjects)
                ->latest()
                ->limit(10)
                ->get()
                ->map(function ($project) {
                    return [
                        'id' => $project->id,
                        'project_name' => $project->project_name,
                        'project_code' => $project->project_code,
                        'status' => $project->status,
                        'priority' => $project->priority,
                        'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                        'start_date' => $project->start_date
                            ? $project->start_date->toDateString()
                            : null,
                        'target_end_date' => $project->target_end_date
                            ? $project->target_end_date->toDateString()
                            : null,
                    ];
                })
                ->values();

            return response()->json([
                'success' => true,
                'message' => 'Projects dashboard loaded successfully.',
                'data' => [
                    'summary' => [
                        'total_projects' => $totalProjects,
                        'active_projects' => $activeProjects,
                        'completed_projects' => $completedProjects,
                        'overdue_tasks' => $overdueTasks,
                        'average_progress' => round((float) ($averageProgress ?? 0), 2),
                    ],
                    'progress_cards' => $progressCards,
                    'recent_projects' => $recentProjects,
                    'charts' => [
                        'status' => $statusChart,
                        'priority' => $priorityChart,
                    ],
                ],
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Projects dashboard failed to load.',
                'error' => config('app.debug') ? $exception->getMessage() : 'Server Error',
            ], 500);
        }
    }

    private function formatLabel(?string $value): string
    {
        if (!$value) {
            return 'Unknown';
        }

        return ucwords(str_replace('_', ' ', $value));
    }
}

<?php

namespace App\Services\Projects;

use App\Models\Project;
use App\Models\ProjectMilestone;
use App\Models\ProjectStatusUpdate;
use App\Models\ProjectTask;
use Illuminate\Support\Facades\DB;

class ProjectProgressService
{
    public function recalculate(Project $project): array
    {
        return DB::transaction(function () use ($project) {
            $project = $project->fresh();

            $tasks = $project->tasks()->get();
            $milestones = $project->milestones()->get();

            $totalTasks = $tasks->count();
            $completedTasks = $tasks->whereIn('status', ['completed', 'done'])->count();
            $pendingTasks = $tasks->whereIn('status', ['todo', 'pending', 'not_started'])->count();
            $inProgressTasks = $tasks->where('status', 'in_progress')->count();
            $blockedTasks = $tasks->whereIn('status', ['blocked'])->count();
            $cancelledTasks = $tasks->where('status', 'cancelled')->count();

            $overdueTasks = $tasks
                ->filter(fn ($task) => $task->is_overdue)
                ->count();

            $taskProgress = $totalTasks > 0
                ? round((float) $tasks->avg('progress_percentage'), 2)
                : 0;

            $milestoneWeightTotal = (float) $milestones->sum('weight');

            $milestoneProgress = 0;

            if ($milestones->count() > 0 && $milestoneWeightTotal > 0) {
                $weightedTotal = $milestones->sum(function ($milestone) {
                    return ((float) $milestone->progress_percentage) * ((float) $milestone->weight);
                });

                $milestoneProgress = round($weightedTotal / $milestoneWeightTotal, 2);
            }

            if ($totalTasks > 0 && $milestones->count() > 0) {
                $projectProgress = round(($taskProgress * 0.7) + ($milestoneProgress * 0.3), 2);
            } elseif ($totalTasks > 0) {
                $projectProgress = $taskProgress;
            } elseif ($milestones->count() > 0) {
                $projectProgress = $milestoneProgress;
            } else {
                $projectProgress = 0;
            }

            $newStatus = $this->calculateProjectStatus(
                totalTasks: $totalTasks,
                completedTasks: $completedTasks,
                blockedTasks: $blockedTasks,
                inProgressTasks: $inProgressTasks,
                progress: $projectProgress,
                milestones: $milestones
            );

            $oldStatus = $project->status;
            $oldProgress = (float) ($project->progress_percentage ?? 0);

            $actualEndDate = $newStatus === 'completed'
                ? ($project->actual_end_date ?? now()->toDateString())
                : null;

            $project->update([
                'progress_percentage' => $projectProgress,
                'status' => $newStatus,
                'actual_end_date' => $actualEndDate,
            ]);

            if ($oldStatus !== $newStatus || round($oldProgress, 2) !== round($projectProgress, 2)) {
                ProjectStatusUpdate::create([
                    'project_id' => $project->id,
                    'update_title' => 'Project progress recalculated',
                    'update_description' => 'Project progress and status were recalculated automatically.',
                    'old_status' => $oldStatus,
                    'new_status' => $newStatus,
                    'old_progress_percentage' => (int) round($oldProgress),
                    'new_progress_percentage' => (int) round($projectProgress),
                    'update_type' => 'auto_calculation',
                    'metadata' => [
                        'total_tasks' => $totalTasks,
                        'completed_tasks' => $completedTasks,
                        'pending_tasks' => $pendingTasks,
                        'in_progress_tasks' => $inProgressTasks,
                        'blocked_tasks' => $blockedTasks,
                        'cancelled_tasks' => $cancelledTasks,
                        'overdue_tasks' => $overdueTasks,
                        'task_progress' => $taskProgress,
                        'milestone_progress' => $milestoneProgress,
                    ],
                ]);
            }

            return $this->buildProgressPayload($project->fresh());
        });
    }

    public function updateTaskProgress(ProjectTask $task, int $progressPercentage, ?string $status = null): array
    {
        return DB::transaction(function () use ($task, $progressPercentage, $status) {
            $oldStatus = $task->status;
            $oldProgress = (float) $task->progress_percentage;

            $newStatus = $status ?: $this->statusFromProgress($progressPercentage);

            if ($progressPercentage >= 100) {
                $newStatus = 'done';
            }

            $task->update([
                'progress_percentage' => $progressPercentage,
                'status' => $newStatus,
                'completed_date' => $newStatus === 'completed' ? now()->toDateString() : null,
            ]);

            ProjectStatusUpdate::create([
                'project_id' => $task->project_id,
                'task_id' => $task->id,
                'update_title' => 'Task progress updated',
                'update_description' => 'Task progress or status was updated.',
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'old_progress_percentage' => (int) round($oldProgress),
                'new_progress_percentage' => $progressPercentage,
                'update_type' => 'task_progress',
                'metadata' => [
                    'task_id' => $task->id,
                    'task_title' => $task->task_title,
                ],
            ]);

            return $this->recalculate($task->project->fresh());
        });
    }

    public function buildProgressPayload(Project $project): array
    {
        $project->load([
            'tasks' => fn ($query) => $query->orderBy('task_order')->orderBy('created_at'),
            'milestones' => fn ($query) => $query->orderBy('target_date')->orderBy('created_at'),
            'statusUpdates' => fn ($query) => $query->latest()->limit(15),
        ]);

        $tasks = $project->tasks;
        $milestones = $project->milestones;

        $totalTasks = $tasks->count();
        $completedTasks = $tasks->whereIn('status', ['completed', 'done'])->count();
        $pendingTasks = $tasks->whereIn('status', ['todo', 'pending', 'not_started'])->count();
        $inProgressTasks = $tasks->where('status', 'in_progress')->count();
        $blockedTasks = $tasks->where('status', 'blocked')->count();
        $cancelledTasks = $tasks->where('status', 'cancelled')->count();
        $overdueTasks = $tasks->filter(fn ($task) => $task->is_overdue)->count();

        $totalMilestones = $milestones->count();
        $completedMilestones = $milestones->where('status', 'completed')->count();
        $pendingMilestones = $milestones->where('status', 'pending')->count();
        $inProgressMilestones = $milestones->where('status', 'in_progress')->count();
        $blockedMilestones = $milestones->where('status', 'blocked')->count();

        return [
            'project' => [
                'id' => $project->id,
                'project_name' => $project->project_name,
                'project_code' => $project->project_code,
                'status' => $project->status,
                'priority' => $project->priority,
                'progress_percentage' => (float) ($project->progress_percentage ?? 0),
                'start_date' => optional($project->start_date)->format('Y-m-d'),
                'target_end_date' => optional($project->target_end_date)->format('Y-m-d'),
                'actual_end_date' => optional($project->actual_end_date)->format('Y-m-d'),
            ],
            'summary' => [
                'total_tasks' => $totalTasks,
                'completed_tasks' => $completedTasks,
                'pending_tasks' => $pendingTasks,
                'in_progress_tasks' => $inProgressTasks,
                'blocked_tasks' => $blockedTasks,
                'cancelled_tasks' => $cancelledTasks,
                'overdue_tasks' => $overdueTasks,
                'total_milestones' => $totalMilestones,
                'completed_milestones' => $completedMilestones,
                'pending_milestones' => $pendingMilestones,
                'in_progress_milestones' => $inProgressMilestones,
                'blocked_milestones' => $blockedMilestones,
                'empty_progress_state' => $totalTasks === 0 && $totalMilestones === 0,
            ],
            'charts' => [
                'tasks_by_status' => [
                    ['status' => 'todo', 'label' => 'To Do', 'value' => $pendingTasks],
                    ['status' => 'in_progress', 'label' => 'In Progress', 'value' => $inProgressTasks],
                    ['status' => 'blocked', 'label' => 'Blocked', 'value' => $blockedTasks],
                    ['status' => 'done', 'label' => 'Done', 'value' => $completedTasks],
                    ['status' => 'cancelled', 'label' => 'Cancelled', 'value' => $cancelledTasks],
                ],
                'milestones_by_status' => [
                    ['status' => 'pending', 'label' => 'Pending', 'value' => $pendingMilestones],
                    ['status' => 'in_progress', 'label' => 'In Progress', 'value' => $inProgressMilestones],
                    ['status' => 'blocked', 'label' => 'Blocked', 'value' => $blockedMilestones],
                    ['status' => 'completed', 'label' => 'Completed', 'value' => $completedMilestones],
                ],
            ],
            'tasks' => $tasks,
            'milestones' => $milestones,
            'recent_updates' => $project->statusUpdates,
            'status_history' => $project->statusUpdates,
        ];
    }

    private function calculateProjectStatus(
        int $totalTasks,
        int $completedTasks,
        int $blockedTasks,
        int $inProgressTasks,
        float $progress,
        $milestones
    ): string {
        if ($totalTasks === 0 && $milestones->count() === 0) {
            return 'not_started';
        }

        if ($progress >= 100) {
            return 'completed';
        }

        if ($blockedTasks > 0 || $milestones->where('status', 'blocked')->count() > 0) {
            return 'on_hold';
        }

        if ($inProgressTasks > 0 || $milestones->where('status', 'in_progress')->count() > 0 || $progress > 0) {
            return 'in_progress';
        }

        return 'not_started';
    }

    private function statusFromProgress(int $progressPercentage): string
    {
        if ($progressPercentage >= 100) {
            return 'completed';
        }

        if ($progressPercentage > 0) {
            return 'in_progress';
        }

        return 'todo';
    }
}

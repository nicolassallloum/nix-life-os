<?php

namespace App\Services\Projects;

use App\Models\Project;
use App\Models\ProjectStatusUpdate;
use App\Models\ProjectTask;
use Illuminate\Support\Facades\DB;

class ProjectProgressService
{
    public function recalculate(Project $project): array
    {
        return DB::transaction(function () use ($project) {
            $oldProgress = (int) ($project->progress_percentage ?? 0);
            $oldStatus = $project->status;

            $taskScore = $this->calculateTaskScore($project);
            $milestoneScore = $this->calculateMilestoneScore($project);

            /*
             * Progress Formula:
             * Tasks      = 70%
             * Milestones = 30%
             */
            $finalProgress = round(($taskScore * 0.70) + ($milestoneScore * 0.30));

            $newStatus = $this->resolveProjectStatus($finalProgress, $project);

            $project->update([
                'progress_percentage' => $finalProgress,
                'status' => $newStatus,
                'completed_at' => $finalProgress >= 100 ? now() : null,
            ]);

            ProjectStatusUpdate::create([
                'project_id' => $project->id,
                'update_title' => 'Project progress recalculated',
                'update_description' => 'Progress was automatically recalculated based on tasks and milestones.',
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'old_progress_percentage' => $oldProgress,
                'new_progress_percentage' => $finalProgress,
                'update_type' => 'auto_calculation',
                'metadata' => [
                    'task_score' => $taskScore,
                    'milestone_score' => $milestoneScore,
                    'formula' => 'tasks_70_percent_milestones_30_percent',
                ],
            ]);

            return [
                'project_id' => $project->id,
                'old_progress_percentage' => $oldProgress,
                'new_progress_percentage' => $finalProgress,
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'task_score' => $taskScore,
                'milestone_score' => $milestoneScore,
            ];
        });
    }

    public function updateTaskProgress(ProjectTask $task, int $progressPercentage, ?string $status = null): array
    {
        return DB::transaction(function () use ($task, $progressPercentage, $status) {
            $project = $task->project;

            $oldProgress = (int) ($task->progress_percentage ?? 0);
            $oldStatus = $task->status;

            $newStatus = $status ?: $this->resolveTaskStatus($progressPercentage);

            $task->update([
                'progress_percentage' => $progressPercentage,
                'status' => $newStatus,
                'completed_at' => $progressPercentage >= 100 ? now() : null,
            ]);

            ProjectStatusUpdate::create([
                'project_id' => $project->id,
                'task_id' => $task->id,
                'update_title' => 'Task progress updated',
                'update_description' => 'Task progress was updated and project progress was recalculated.',
                'old_status' => $oldStatus,
                'new_status' => $newStatus,
                'old_progress_percentage' => $oldProgress,
                'new_progress_percentage' => $progressPercentage,
                'update_type' => 'task_progress',
                'metadata' => [
                    'task_id' => $task->id,
                    'task_name' => $task->task_name ?? null,
                ],
            ]);

            $projectProgress = $this->recalculate($project->fresh());

            return [
                'task_id' => $task->id,
                'old_task_progress' => $oldProgress,
                'new_task_progress' => $progressPercentage,
                'old_task_status' => $oldStatus,
                'new_task_status' => $newStatus,
                'project_progress' => $projectProgress,
            ];
        });
    }

    private function calculateTaskScore(Project $project): float
    {
        $tasks = $project->tasks()->get();

        if ($tasks->isEmpty()) {
            return 0;
        }

        $totalWeight = 0;
        $weightedProgress = 0;

        foreach ($tasks as $task) {
            $weight = (float) ($task->weight ?? 1);
            $progress = $this->normalizeProgressByStatus(
                $task->progress_percentage,
                $task->status
            );

            $totalWeight += $weight;
            $weightedProgress += ($progress * $weight);
        }

        return $totalWeight > 0 ? round($weightedProgress / $totalWeight, 2) : 0;
    }

    private function calculateMilestoneScore(Project $project): float
    {
        $milestones = $project->milestones()->get();

        if ($milestones->isEmpty()) {
            return 0;
        }

        $totalWeight = 0;
        $weightedProgress = 0;

        foreach ($milestones as $milestone) {
            $weight = (float) ($milestone->weight ?? 1);
            $progress = $this->normalizeProgressByStatus(
                $milestone->progress_percentage,
                $milestone->status
            );

            $totalWeight += $weight;
            $weightedProgress += ($progress * $weight);
        }

        return $totalWeight > 0 ? round($weightedProgress / $totalWeight, 2) : 0;
    }

    private function normalizeProgressByStatus(?int $progress, ?string $status): int
    {
        return match ($status) {
            'completed' => 100,
            'in_progress' => max($progress ?? 50, 1),
            'blocked' => $progress ?? 0,
            'cancelled' => $progress ?? 0,
            default => $progress ?? 0,
        };
    }

    private function resolveTaskStatus(int $progressPercentage): string
    {
        if ($progressPercentage >= 100) {
            return 'completed';
        }

        if ($progressPercentage > 0) {
            return 'in_progress';
        }

        return 'pending';
    }

    private function resolveProjectStatus(int $progressPercentage, Project $project): string
    {
        if ($progressPercentage >= 100) {
            return 'completed';
        }

        if ($project->tasks()->where('status', 'blocked')->exists()) {
            return 'blocked';
        }

        if ($progressPercentage > 0) {
            return 'in_progress';
        }

        return 'not_started';
    }
}
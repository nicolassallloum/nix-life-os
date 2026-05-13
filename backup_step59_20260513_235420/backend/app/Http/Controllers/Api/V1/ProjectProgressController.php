<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;

class ProjectProgressController extends Controller
{
    public function show(Project $project)
    {
        $project->load([
            'tasks',
            'milestones',
            'statusUpdates' => fn ($query) => $query->latest()->limit(10),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project progress retrieved successfully.',
            'data' => [
                'project_id' => $project->id,
                'project_name' => $project->project_name,
                'status' => $project->status,
                'progress_percentage' => $project->progress_percentage,
                'tasks' => $project->tasks,
                'milestones' => $project->milestones,
                'latest_status_updates' => $project->statusUpdates,
            ],
        ]);
    }

    public function recalculate(Project $project, ProjectProgressService $service)
    {
        $result = $service->recalculate($project);

        return response()->json([
            'success' => true,
            'message' => 'Project progress recalculated successfully.',
            'data' => $result,
        ]);
    }

    public function updateTaskProgress(
        Request $request,
        ProjectTask $task,
        ProjectProgressService $service
    ) {
        $validated = $request->validate([
            'progress_percentage' => ['required', 'integer', 'min:0', 'max:100'],
            'status' => ['nullable', 'string', 'in:pending,in_progress,completed,blocked,cancelled'],
        ]);

        $result = $service->updateTaskProgress(
            $task,
            $validated['progress_percentage'],
            $validated['status'] ?? null
        );

        return response()->json([
            'success' => true,
            'message' => 'Task progress updated successfully.',
            'data' => $result,
        ]);
    }
}
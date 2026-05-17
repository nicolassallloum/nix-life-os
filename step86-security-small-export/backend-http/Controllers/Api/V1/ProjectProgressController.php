<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectProgressController extends Controller
{
    public function show(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'success' => true,
            'message' => 'Project progress retrieved successfully.',
            'data' => $service->buildProgressPayload($project),
        ]);
    }

    public function recalculate(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        return response()->json([
            'success' => true,
            'message' => 'Project progress recalculated successfully.',
            'data' => $service->recalculate($project),
        ]);
    }

    public function updateTaskProgress(
        Request $request,
        Project $project,
        ProjectTask $task,
        ProjectProgressService $service
    ) {
        $this->authorizeProject($request, $project);

        abort_if(
            $task->project_id !== $project->id || $task->user_id !== $request->user()->id,
            403,
            'Unauthorized task access.'
        );

        $validated = $request->validate([
            'progress_percentage' => ['required', 'integer', 'min:0', 'max:100'],
            'status' => ['nullable', Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled'])],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Task progress updated successfully.',
            'data' => $service->updateTaskProgress(
                $task,
                (int) $validated['progress_percentage'],
                $validated['status'] ?? null
            ),
        ]);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if(
            $project->user_id !== $request->user()->id,
            403,
            'Unauthorized project access.'
        );
    }
}

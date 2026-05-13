<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectStatusUpdate;
use App\Services\Projects\ProjectProgressService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectStatusUpdateController extends Controller
{
    public function index(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'type' => ['nullable', Rule::in(['manual', 'task_progress', 'milestone_progress', 'auto_calculation', 'status_change'])],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
        ]);

        $updates = ProjectStatusUpdate::query()
            ->where('project_id', $project->id)
            ->when($validated['type'] ?? null, fn ($query, $type) => $query->where('update_type', $type))
            ->latest()
            ->paginate($validated['per_page'] ?? 20);

        return response()->json([
            'success' => true,
            'message' => 'Project status updates retrieved successfully.',
            'data' => $updates->items(),
            'meta' => [
                'current_page' => $updates->currentPage(),
                'last_page' => $updates->lastPage(),
                'per_page' => $updates->perPage(),
                'total' => $updates->total(),
            ],
        ]);
    }

    public function store(Request $request, Project $project, ProjectProgressService $service)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'update_title' => ['required', 'string', 'max:255'],
            'update_description' => ['nullable', 'string'],
            'new_status' => ['nullable', Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled'])],
            'new_progress_percentage' => ['nullable', 'integer', 'min:0', 'max:100'],
            'metadata' => ['nullable', 'array'],
        ]);

        $oldStatus = $project->status;
        $oldProgress = (int) round((float) ($project->progress_percentage ?? 0));

        $update = ProjectStatusUpdate::create([
            'project_id' => $project->id,
            'update_title' => $validated['update_title'],
            'update_description' => $validated['update_description'] ?? null,
            'old_status' => $oldStatus,
            'new_status' => $validated['new_status'] ?? $oldStatus,
            'old_progress_percentage' => $oldProgress,
            'new_progress_percentage' => $validated['new_progress_percentage'] ?? $oldProgress,
            'update_type' => 'manual',
            'metadata' => $validated['metadata'] ?? null,
        ]);

        $projectPayload = [];

        if (isset($validated['new_status'])) {
            $projectPayload['status'] = $validated['new_status'];
        }

        if (array_key_exists('new_progress_percentage', $validated)) {
            $projectPayload['progress_percentage'] = $validated['new_progress_percentage'];
        }

        if (($projectPayload['status'] ?? null) === 'completed') {
            $projectPayload['progress_percentage'] = 100;
            $projectPayload['actual_end_date'] = now()->toDateString();
        }

        if (!empty($projectPayload)) {
            $project->update($projectPayload);
        }

        return response()->json([
            'success' => true,
            'message' => 'Project status update created successfully.',
            'data' => [
                'status_update' => $update->fresh(),
                'project_progress' => $service->buildProgressPayload($project->fresh()),
            ],
        ], 201);
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

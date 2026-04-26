<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectResource;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectController extends Controller
{
    public function index(Request $request)
    {
        $projects = Project::query()
            ->where('user_id', $request->user()->id)
            ->withCount('tasks')
            ->when($request->status, fn ($query) => $query->where('status', $request->status))
            ->when($request->priority, fn ($query) => $query->where('priority', $request->priority))
            ->latest()
            ->paginate($request->get('per_page', 15));

        return ProjectResource::collection($projects);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'project_name' => ['required', 'string', 'max:255'],
            'project_code' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],

            'status' => [
                'nullable',
                Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled']),
            ],

            'priority' => [
                'nullable',
                Rule::in(['low', 'medium', 'high', 'critical']),
            ],

            'start_date' => ['nullable', 'date'],
            'target_end_date' => ['nullable', 'date'],
            'actual_end_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'not_started';
        $validated['priority'] = $validated['priority'] ?? 'medium';
        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

        $project = Project::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Project created successfully.',
            'data' => new ProjectResource($project),
        ], 201);
    }

    public function show(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $project->load(['tasks' => function ($query) {
            $query->orderBy('task_order')->orderBy('created_at');
        }]);

        return response()->json([
            'success' => true,
            'data' => new ProjectResource($project),
        ]);
    }

    public function update(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'project_name' => ['sometimes', 'required', 'string', 'max:255'],
            'project_code' => ['nullable', 'string', 'max:100'],
            'description' => ['nullable', 'string'],

            'status' => [
                'sometimes',
                Rule::in(['not_started', 'in_progress', 'on_hold', 'completed', 'cancelled']),
            ],

            'priority' => [
                'sometimes',
                Rule::in(['low', 'medium', 'high', 'critical']),
            ],

            'start_date' => ['nullable', 'date'],
            'target_end_date' => ['nullable', 'date'],
            'actual_end_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        if (($validated['status'] ?? null) === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['actual_end_date'] = $validated['actual_end_date'] ?? now()->toDateString();
        }

        $project->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Project updated successfully.',
            'data' => new ProjectResource($project->fresh()),
        ]);
    }

    public function destroy(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $project->delete();

        return response()->json([
            'success' => true,
            'message' => 'Project deleted successfully.',
        ]);
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if($project->user_id !== $request->user()->id, 403, 'Unauthorized project access.');
    }
}
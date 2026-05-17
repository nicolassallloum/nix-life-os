<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectResource;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectController extends Controller
{
    private array $statuses = [
        'not_started',
        'in_progress',
        'on_hold',
        'completed',
        'cancelled',
    ];

    private array $priorities = [
        'low',
        'medium',
        'high',
        'critical',
    ];

    public function index(Request $request)
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $projects = Project::query()
            ->where('user_id', $request->user()->id)
            ->withCount('tasks')
            ->when($validated['search'] ?? null, function ($query, $search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('project_name', 'ILIKE', "%{$search}%")
                        ->orWhere('project_code', 'ILIKE', "%{$search}%")
                        ->orWhere('description', 'ILIKE', "%{$search}%");
                });
            })
            ->when($validated['status'] ?? null, function ($query, $status) {
                $query->where('status', $status);
            })
            ->when($validated['priority'] ?? null, function ($query, $priority) {
                $query->where('priority', $priority);
            })
            ->orderByDesc('created_at')
            ->paginate($validated['per_page'] ?? 15);

        return ProjectResource::collection($projects)
            ->additional([
                'success' => true,
                'message' => 'Projects loaded successfully.',
            ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'project_name' => ['required', 'string', 'max:255'],
            'project_code' => [
                'nullable',
                'string',
                'max:100',
                Rule::unique('projects', 'project_code')
                    ->where(fn ($query) => $query->where('user_id', $request->user()->id)),
            ],
            'description' => ['nullable', 'string'],

            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],

            'start_date' => ['nullable', 'date'],
            'target_end_date' => ['nullable', 'date'],
            'actual_end_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateProjectDates($validated);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'not_started';
        $validated['priority'] = $validated['priority'] ?? 'medium';
        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

        if ($validated['status'] === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['actual_end_date'] = $validated['actual_end_date'] ?? now()->toDateString();
        }

        $project = Project::create($validated)->loadCount('tasks');

        return response()->json([
            'success' => true,
            'message' => 'Project created successfully.',
            'data' => new ProjectResource($project),
        ], 201);
    }

    public function show(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $project->loadCount('tasks');

        $project->load([
            'tasks' => function ($query) {
                $query->orderBy('task_order')->orderBy('created_at');
            },
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project loaded successfully.',
            'data' => new ProjectResource($project),
        ]);
    }

    public function update(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'project_name' => ['sometimes', 'required', 'string', 'max:255'],
            'project_code' => [
                'nullable',
                'string',
                'max:100',
                Rule::unique('projects', 'project_code')
                    ->ignore($project->id)
                    ->where(fn ($query) => $query->where('user_id', $request->user()->id)),
            ],
            'description' => ['nullable', 'string'],

            'status' => ['sometimes', Rule::in($this->statuses)],
            'priority' => ['sometimes', Rule::in($this->priorities)],

            'start_date' => ['nullable', 'date'],
            'target_end_date' => ['nullable', 'date'],
            'actual_end_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateProjectDates($validated, $project);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        if (($validated['status'] ?? null) === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['actual_end_date'] = $validated['actual_end_date'] ?? now()->toDateString();
        }

        if (($validated['status'] ?? null) !== 'completed' && array_key_exists('actual_end_date', $validated)) {
            $validated['actual_end_date'] = $validated['actual_end_date'] ?: null;
        }

        $project->update($validated);

        $project = $project->fresh()->loadCount('tasks');

        return response()->json([
            'success' => true,
            'message' => 'Project updated successfully.',
            'data' => new ProjectResource($project),
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
        abort_if(
            $project->user_id !== $request->user()->id,
            403,
            'Unauthorized project access.'
        );
    }

    private function validateProjectDates(array $validated, ?Project $project = null)
    {
        $startDate = $validated['start_date']
            ?? optional($project?->start_date)->format('Y-m-d');

        $targetEndDate = array_key_exists('target_end_date', $validated)
            ? $validated['target_end_date']
            : optional($project?->target_end_date)->format('Y-m-d');

        $actualEndDate = array_key_exists('actual_end_date', $validated)
            ? $validated['actual_end_date']
            : optional($project?->actual_end_date)->format('Y-m-d');

        if (!empty($startDate) && !empty($targetEndDate) && $targetEndDate < $startDate) {
            return response()->json([
                'message' => 'The target end date must be a date after or equal to start date.',
                'errors' => [
                    'target_end_date' => [
                        'The target end date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        if (!empty($startDate) && !empty($actualEndDate) && $actualEndDate < $startDate) {
            return response()->json([
                'message' => 'The actual end date must be a date after or equal to start date.',
                'errors' => [
                    'actual_end_date' => [
                        'The actual end date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        return null;
    }
}
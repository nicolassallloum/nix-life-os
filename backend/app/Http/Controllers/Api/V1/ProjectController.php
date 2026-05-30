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
        try {
            $userId = (string) $request->user()->id;

            $projects = \DB::table('projects')
                ->where('user_id', $userId)
                ->orderByDesc('created_at')
                ->paginate((int) $request->get('per_page', 10));

            return response()->json([
                'success' => true,
                'data' => $projects,
            ]);
        } catch (\Throwable $e) {
            \Log::error('Projects index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Projects index failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request)
    {
        $this->normalizeProjectPayload($request);

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
        $this->normalizeProjectPayload($request);

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


    private function normalizeProjectPayload(Request $request): void
    {
        $data = $request->all();

        if (!array_key_exists('project_name', $data) && array_key_exists('name', $data)) {
            $data['project_name'] = $data['name'];
        }

        if (!array_key_exists('project_code', $data) && array_key_exists('code', $data)) {
            $data['project_code'] = $data['code'];
        }

        if (($data['status'] ?? null) === 'active') {
            $data['status'] = 'in_progress';
        }

        if (($data['status'] ?? null) === 'done') {
            $data['status'] = 'completed';
        }

        $request->merge($data);
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
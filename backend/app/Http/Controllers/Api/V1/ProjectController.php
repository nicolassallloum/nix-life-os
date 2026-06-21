<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectResource;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
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
            $validated = $request->validate([
                'search' => ['nullable', 'string', 'max:255'],
                'status' => ['nullable', Rule::in($this->statuses)],
                'priority' => ['nullable', Rule::in($this->priorities)],
                'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
                'page' => ['nullable', 'integer', 'min:1'],
            ]);

            $userId = (string) $request->user()->id;

            $query = DB::table('projects')
                ->where('user_id', $userId);

            if (!empty($validated['search'])) {
                $search = $validated['search'];

                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('project_name', 'ILIKE', "%{$search}%")
                        ->orWhere('project_code', 'ILIKE', "%{$search}%")
                        ->orWhere('description', 'ILIKE', "%{$search}%");
                });
            }

            if (!empty($validated['status'])) {
                $query->where('status', $validated['status']);
            }

            if (!empty($validated['priority'])) {
                $query->where('priority', $validated['priority']);
            }

            $projects = $query
                ->orderByDesc('created_at')
                ->paginate((int) ($validated['per_page'] ?? 10));

            return response()->json([
                'success' => true,
                'message' => 'Projects loaded successfully.',
                'data' => $projects,
            ]);
        } catch (\Throwable $e) {
            Log::error('Projects index failed', [
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
        try {
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
                'number_of_tasks' => ['nullable', 'integer', 'min:0', 'max:100'],
                'task_count' => ['nullable', 'integer', 'min:0', 'max:100'],
                'tasks_count' => ['nullable', 'integer', 'min:0', 'max:100'],
            ]);

            $dateValidationResponse = $this->validateProjectDates($validated);

            if ($dateValidationResponse) {
                return $dateValidationResponse;
            }

            $validated['user_id'] = (string) $request->user()->id;
            $validated['status'] = $validated['status'] ?? 'not_started';
            $validated['priority'] = $validated['priority'] ?? 'medium';
            $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

            if ($validated['status'] === 'completed') {
                $validated['progress_percentage'] = 100;
                $validated['actual_end_date'] = $validated['actual_end_date'] ?? now()->toDateString();
            }

            $taskCount = (int) (
                $validated['number_of_tasks']
                ?? $validated['task_count']
                ?? $validated['tasks_count']
                ?? 0
            );

            unset($validated['number_of_tasks'], $validated['task_count'], $validated['tasks_count']);

            $project = Project::create($validated);

            if ($taskCount > 0) {
                $this->createInitialTasks($project, $taskCount, (string) $request->user()->id);
            }

            $project = $project->fresh();

            return response()->json([
                'success' => true,
                'message' => $taskCount > 0
                    ? "Project created successfully with {$taskCount} task(s)."
                    : 'Project created successfully.',
                'data' => new ProjectResource($project),
                'tasks_created' => $taskCount,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Projects store failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project creation failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function show(Request $request, Project $project)
    {
        try {
            $this->authorizeProject($request, $project);

            return response()->json([
                'success' => true,
                'message' => 'Project loaded successfully.',
                'data' => new ProjectResource($project),
            ]);
        } catch (\Throwable $e) {
            Log::error('Projects show failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project show failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, Project $project)
    {
        try {
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

            $project = $project->fresh();

            return response()->json([
                'success' => true,
                'message' => 'Project updated successfully.',
                'data' => new ProjectResource($project),
            ]);
        } catch (\Throwable $e) {
            Log::error('Projects update failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project update failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, Project $project)
    {
        try {
            $this->authorizeProject($request, $project);

            $project->delete();

            return response()->json([
                'success' => true,
                'message' => 'Project deleted successfully.',
            ]);
        } catch (\Throwable $e) {
            Log::error('Projects delete failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project delete failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
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

        if (!array_key_exists('number_of_tasks', $data) && array_key_exists('tasks', $data) && is_numeric($data['tasks'])) {
            $data['number_of_tasks'] = (int) $data['tasks'];
        }

        if (!array_key_exists('number_of_tasks', $data) && array_key_exists('taskCount', $data)) {
            $data['number_of_tasks'] = (int) $data['taskCount'];
        }

        if (($data['status'] ?? null) === 'active') {
            $data['status'] = 'in_progress';
        }

        if (($data['status'] ?? null) === 'done') {
            $data['status'] = 'completed';
        }

        $request->merge($data);
    }

    private function createInitialTasks(Project $project, int $taskCount, string $userId): void
    {
        if (! Schema::hasTable('project_tasks')) {
            return;
        }

        $now = now();
        $columns = Schema::getColumnListing('project_tasks');

        $titleColumn = $this->firstExistingProjectTaskColumn($columns, [
            'task_title',
            'title',
            'task_name',
            'name',
        ]);

        if (! $titleColumn) {
            throw new \RuntimeException('No starter task title column found in project_tasks table.');
        }

        $descriptionColumn = $this->firstExistingProjectTaskColumn($columns, [
            'task_description',
            'description',
            'details',
        ]);

        $baseTaskName = preg_replace('/[^A-Za-z0-9]+/', '_', trim((string) $project->project_name));
        $baseTaskName = trim((string) $baseTaskName, '_') ?: 'Project';

        for ($i = 1; $i <= $taskCount; $i++) {
            $insert = [];

            if (in_array('id', $columns, true)) {
                $insert['id'] = (string) Str::uuid();
            }

            if (in_array('user_id', $columns, true)) {
                $insert['user_id'] = $userId;
            }

            if (in_array('project_id', $columns, true)) {
                $insert['project_id'] = (string) $project->id;
            }

            $insert[$titleColumn] = "{$baseTaskName}_Task_{$i}";

            if ($descriptionColumn) {
                $insert[$descriptionColumn] = null;
            }

            if (in_array('priority', $columns, true)) {
                $insert['priority'] = 'medium';
            }

            if (in_array('status', $columns, true)) {
                $insert['status'] = 'todo';
            }

            if (in_array('start_date', $columns, true)) {
                $insert['start_date'] = null;
            }

            if (in_array('due_date', $columns, true)) {
                $insert['due_date'] = null;
            }

            if (in_array('completed_at', $columns, true)) {
                $insert['completed_at'] = null;
            }

            if (in_array('completed_date', $columns, true)) {
                $insert['completed_date'] = null;
            }

            if (in_array('assigned_to', $columns, true)) {
                $insert['assigned_to'] = null;
            }

            if (in_array('notes', $columns, true)) {
                $insert['notes'] = null;
            }

            if (in_array('task_order', $columns, true)) {
                $insert['task_order'] = $i;
            }

            if (in_array('progress_percentage', $columns, true)) {
                $insert['progress_percentage'] = 0;
            }

            if (in_array('weight', $columns, true)) {
                $insert['weight'] = 1;
            }

            if (in_array('metadata', $columns, true)) {
                $insert['metadata'] = null;
            }

            if (in_array('created_at', $columns, true)) {
                $insert['created_at'] = $now;
            }

            if (in_array('updated_at', $columns, true)) {
                $insert['updated_at'] = $now;
            }

            DB::table('project_tasks')->insert($insert);
        }
    }

    private function firstExistingProjectTaskColumn(array $columns, array $candidates): ?string
    {
        foreach ($candidates as $candidate) {
            if (in_array($candidate, $columns, true)) {
                return $candidate;
            }
        }

        return null;
    }

    private function authorizeProject(Request $request, Project $project): void
    {
        abort_if(
            (string) $project->user_id !== (string) $request->user()->id,
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
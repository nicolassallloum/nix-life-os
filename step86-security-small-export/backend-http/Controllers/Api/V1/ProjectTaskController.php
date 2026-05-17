<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProjectTaskResource;
use App\Models\Project;
use App\Models\ProjectTask;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectTaskController extends Controller
{
    private array $statuses = [
        'todo',
        'in_progress',
        'blocked',
        'completed',
        'cancelled',
    ];

    private array $priorities = [
        'low',
        'medium',
        'high',
        'critical',
    ];

    public function index(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:255'],
            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],
            'overdue' => ['nullable', 'boolean'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:100'],
            'page' => ['nullable', 'integer', 'min:1'],
        ]);

        $tasks = ProjectTask::query()
            ->where('project_id', $project->id)
            ->where('user_id', $request->user()->id)
            ->when($validated['search'] ?? null, function ($query, $search) {
                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('task_title', 'ILIKE', "%{$search}%")
                        ->orWhere('task_description', 'ILIKE', "%{$search}%");
                });
            })
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['priority'] ?? null, fn ($query, $priority) => $query->where('priority', $priority))
            ->when(array_key_exists('overdue', $validated) && $validated['overdue'], function ($query) {
                $query
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->whereNotNull('due_date')
                    ->whereDate('due_date', '<', now()->toDateString());
            })
            ->orderBy('task_order')
            ->orderByRaw('due_date IS NULL')
            ->orderBy('due_date')
            ->latest()
            ->paginate($validated['per_page'] ?? 15);

        return ProjectTaskResource::collection($tasks)
            ->additional([
                'success' => true,
                'message' => 'Project tasks loaded successfully.',
            ]);
    }

    public function store(Request $request, Project $project)
    {
        $this->authorizeProject($request, $project);

        $validated = $request->validate([
            'task_title' => ['required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => ['nullable', Rule::in($this->statuses)],
            'priority' => ['nullable', Rule::in($this->priorities)],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateTaskDates($validated);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        $validated['project_id'] = $project->id;
        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'todo';
        $validated['priority'] = $validated['priority'] ?? 'medium';
        $validated['task_order'] = $validated['task_order'] ?? $this->nextTaskOrder($project);
        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

        if ($validated['status'] === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();
        }

        $task = ProjectTask::create($validated);

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task created successfully.',
            'data' => new ProjectTaskResource($task->fresh()),
        ], 201);
    }

    public function show(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        return response()->json([
            'success' => true,
            'message' => 'Project task loaded successfully.',
            'data' => new ProjectTaskResource($task),
        ]);
    }

    public function update(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        $validated = $request->validate([
            'task_title' => ['sometimes', 'required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => ['sometimes', Rule::in($this->statuses)],
            'priority' => ['sometimes', Rule::in($this->priorities)],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $dateValidationResponse = $this->validateTaskDates($validated, $task);

        if ($dateValidationResponse) {
            return $dateValidationResponse;
        }

        if (($validated['status'] ?? null) === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();
        }

        if (($validated['status'] ?? null) && $validated['status'] !== 'completed') {
            $validated['completed_date'] = null;

            if (!array_key_exists('progress_percentage', $validated) && $task->status === 'completed') {
                $validated['progress_percentage'] = 0;
            }
        }

        $task->update($validated);

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task updated successfully.',
            'data' => new ProjectTaskResource($task->fresh()),
        ]);
    }

    public function destroy(Request $request, Project $project, ProjectTask $task)
    {
        $this->authorizeProject($request, $project);
        $this->authorizeTaskBelongsToProject($request, $project, $task);

        $task->delete();

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task deleted successfully.',
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

    private function authorizeTaskBelongsToProject(Request $request, Project $project, ProjectTask $task): void
    {
        abort_if(
            $task->project_id !== $project->id || $task->user_id !== $request->user()->id,
            403,
            'Unauthorized task access.'
        );
    }

    private function nextTaskOrder(Project $project): int
    {
        return ((int) $project->tasks()->max('task_order')) + 1;
    }

    private function validateTaskDates(array $validated, ?ProjectTask $task = null)
    {
        $startDate = array_key_exists('start_date', $validated)
            ? $validated['start_date']
            : optional($task?->start_date)->format('Y-m-d');

        $dueDate = array_key_exists('due_date', $validated)
            ? $validated['due_date']
            : optional($task?->due_date)->format('Y-m-d');

        $completedDate = array_key_exists('completed_date', $validated)
            ? $validated['completed_date']
            : optional($task?->completed_date)->format('Y-m-d');

        if (!empty($startDate) && !empty($dueDate) && $dueDate < $startDate) {
            return response()->json([
                'message' => 'The due date must be a date after or equal to start date.',
                'errors' => [
                    'due_date' => [
                        'The due date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        if (!empty($startDate) && !empty($completedDate) && $completedDate < $startDate) {
            return response()->json([
                'message' => 'The completed date must be a date after or equal to start date.',
                'errors' => [
                    'completed_date' => [
                        'The completed date must be a date after or equal to start date.',
                    ],
                ],
            ], 422);
        }

        return null;
    }

    private function refreshProjectProgress(Project $project): void
    {
        $tasks = $project->tasks()->get();

        if ($tasks->count() === 0) {
            $project->update([
                'progress_percentage' => 0,
                'status' => 'not_started',
                'actual_end_date' => null,
            ]);

            return;
        }

        $avgProgress = round((float) $tasks->avg('progress_percentage'), 2);
        $completedTasks = $tasks->where('status', 'completed')->count();

        if ($completedTasks === $tasks->count()) {
            $status = 'completed';
            $actualEndDate = $project->actual_end_date ?? now()->toDateString();
            $avgProgress = 100;
        } elseif ($tasks->where('status', 'blocked')->count() > 0) {
            $status = 'on_hold';
            $actualEndDate = null;
        } elseif ($tasks->where('status', 'in_progress')->count() > 0) {
            $status = 'in_progress';
            $actualEndDate = null;
        } else {
            $status = 'not_started';
            $actualEndDate = null;
        }

        $project->update([
            'progress_percentage' => $avgProgress,
            'status' => $status,
            'actual_end_date' => $actualEndDate,
        ]);
    }
}

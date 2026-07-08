<?php

namespace App\Http\Controllers\Api\V1\Todo;

use App\Http\Controllers\Controller;
use App\Http\Requests\Todo\StoreTodoTaskRequest;
use App\Http\Requests\Todo\UpdateTodoTaskRequest;
use App\Models\TodoTask;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class TodoTaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $filters = $request->validate([
            'task_type' => ['nullable', Rule::in(TodoTask::TYPES)],
            'status' => ['nullable', Rule::in(TodoTask::STATUSES)],
            'priority' => ['nullable', Rule::in(TodoTask::PRIORITIES)],
            'project_id' => ['nullable', 'integer', Rule::exists('todo_projects', 'id')->where('user_id', $userId)],
        ]);

        $query = TodoTask::query()
            ->with('project')
            ->where('user_id', $userId);

        foreach (['task_type', 'status', 'priority', 'project_id'] as $filter) {
            if (array_key_exists($filter, $filters) && $filters[$filter] !== null && $filters[$filter] !== '') {
                $query->where($filter, $filters[$filter]);
            }
        }

        $tasks = $query
            ->orderBy('sort_order')
            ->orderBy('due_date')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (TodoTask $task) => $this->formatTask($task))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Todo tasks loaded successfully.',
            'data' => $tasks,
        ]);
    }

    public function store(StoreTodoTaskRequest $request): JsonResponse
    {
        $userId = $request->user()->id;
        $data = $request->validated();

        $data['user_id'] = $userId;
        $data['task_type'] = $data['task_type'] ?? TodoTask::TYPE_GENERAL;
        $data['status'] = $data['status'] ?? TodoTask::STATUS_PENDING;
        $data['priority'] = $data['priority'] ?? TodoTask::PRIORITY_MEDIUM;
        $data['points'] = $data['points'] ?? 0;
        $data['sort_order'] = $data['sort_order'] ?? $this->nextSortOrder($userId, $data['task_type']);

        $this->applyStatusCompletionRules($data, null);

        $task = TodoTask::create($data)->load('project');

        return response()->json([
            'success' => true,
            'message' => 'Todo task created successfully.',
            'data' => $this->formatTask($task),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $task = TodoTask::query()
            ->with('project')
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $task) {
            return $this->notFound('Todo task not found.');
        }

        return response()->json([
            'success' => true,
            'message' => 'Todo task loaded successfully.',
            'data' => $this->formatTask($task),
        ]);
    }

    public function update(UpdateTodoTaskRequest $request, int $id): JsonResponse
    {
        $task = TodoTask::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $task) {
            return $this->notFound('Todo task not found.');
        }

        $data = $request->validated();

        $this->applyStatusCompletionRules($data, $task);

        $task->update($data);
        $task->load('project');

        return response()->json([
            'success' => true,
            'message' => 'Todo task updated successfully.',
            'data' => $this->formatTask($task),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $task = TodoTask::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $task) {
            return $this->notFound('Todo task not found.');
        }

        $task->delete();

        return response()->json([
            'success' => true,
            'message' => 'Todo task deleted successfully.',
        ]);
    }

    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(TodoTask::STATUSES)],
        ]);

        $task = TodoTask::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $task) {
            return $this->notFound('Todo task not found.');
        }

        $this->applyStatusCompletionRules($data, $task);

        $task->update($data);
        $task->load('project');

        return response()->json([
            'success' => true,
            'message' => 'Todo task status updated successfully.',
            'data' => $this->formatTask($task),
        ]);
    }

    public function move(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'task_type' => ['required', Rule::in(TodoTask::TYPES)],
            'sort_order' => ['required', 'integer', 'min:0'],
        ]);

        $task = TodoTask::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $task) {
            return $this->notFound('Todo task not found.');
        }

        $task->update($data);
        $task->load('project');

        return response()->json([
            'success' => true,
            'message' => 'Todo task moved successfully.',
            'data' => $this->formatTask($task),
        ]);
    }

    public function reorder(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $data = $request->validate([
            'tasks' => ['required', 'array', 'min:1'],
            'tasks.*.id' => ['required', 'integer', 'distinct'],
            'tasks.*.sort_order' => ['required', 'integer', 'min:0'],
        ]);

        $taskIds = collect($data['tasks'])->pluck('id')->values();

        $ownedTaskCount = TodoTask::query()
            ->where('user_id', $userId)
            ->whereIn('id', $taskIds)
            ->count();

        if ($ownedTaskCount !== $taskIds->count()) {
            return response()->json([
                'success' => false,
                'message' => 'One or more tasks were not found for the authenticated user.',
            ], 422);
        }

        DB::transaction(function () use ($data, $userId) {
            foreach ($data['tasks'] as $taskData) {
                TodoTask::query()
                    ->where('user_id', $userId)
                    ->whereKey($taskData['id'])
                    ->update(['sort_order' => $taskData['sort_order']]);
            }
        });

        $tasks = TodoTask::query()
            ->with('project')
            ->where('user_id', $userId)
            ->whereIn('id', $taskIds)
            ->orderBy('sort_order')
            ->orderBy('due_date')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (TodoTask $task) => $this->formatTask($task))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Todo tasks reordered successfully.',
            'data' => $tasks,
        ]);
    }

    private function notFound(string $message): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'error' => [
                'code' => 'NOT_FOUND',
                'status' => 404,
            ],
        ], 404);
    }

    private function applyStatusCompletionRules(array &$data, ?TodoTask $task): void
    {
        if (! array_key_exists('status', $data)) {
            return;
        }

        if ($data['status'] === TodoTask::STATUS_FINISHED) {
            $data['completed_at'] = $data['completed_at'] ?? $task?->completed_at ?? now();
            return;
        }

        if (in_array($data['status'], [TodoTask::STATUS_PENDING, TodoTask::STATUS_IN_PROGRESS], true)) {
            $data['completed_at'] = null;
        }
    }

    private function nextSortOrder($userId, string $taskType): int
    {
        return ((int) TodoTask::query()
            ->where('user_id', $userId)
            ->where('task_type', $taskType)
            ->max('sort_order')) + 1;
    }

    private function formatTask(TodoTask $task): array
    {
        return [
            'id' => $task->id,
            'user_id' => $task->user_id,
            'project_id' => $task->project_id,
            'title' => $task->title,
            'description' => $task->description,
            'task_type' => $task->task_type,
            'status' => $task->status,
            'priority' => $task->priority,
            'points' => (int) $task->points,
            'due_date' => $task->due_date ? $task->due_date->toDateString() : null,
            'completed_at' => $task->completed_at,
            'sort_order' => (int) $task->sort_order,
            'notes' => $task->notes,
            'project' => $task->relationLoaded('project') && $task->project
                ? [
                    'id' => $task->project->id,
                    'name' => $task->project->name,
                    'status' => $task->project->status,
                ]
                : null,
            'created_at' => $task->created_at,
            'updated_at' => $task->updated_at,
        ];
    }
}

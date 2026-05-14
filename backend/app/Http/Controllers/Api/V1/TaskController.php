<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreTaskRequest;
use App\Http\Requests\UpdateTaskRequest;
use App\Models\Task;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Task::query()
            ->where('user_id', $request->user()->id)
            ->orderByRaw("
                CASE
                    WHEN status = 'pending' THEN 1
                    WHEN status = 'in_progress' THEN 2
                    WHEN status = 'completed' THEN 3
                    ELSE 4
                END
            ")
            ->orderByRaw("
                CASE
                    WHEN priority = 'high' THEN 1
                    WHEN priority = 'medium' THEN 2
                    WHEN priority = 'low' THEN 3
                    ELSE 4
                END
            ")
            ->orderBy('due_date')
            ->orderByDesc('created_at');

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('priority') && $request->priority !== 'all') {
            $query->where('priority', $request->priority);
        }

        if ($request->filled('search')) {
            $search = trim($request->search);

            $query->where(function ($q) use ($search) {
                $q->where('title', 'ILIKE', "%{$search}%")
                    ->orWhere('description', 'ILIKE', "%{$search}%");
            });
        }

        $tasks = $query->get();

        return response()->json([
            'success' => true,
            'message' => 'Tasks loaded successfully.',
            'data' => $tasks,
            'summary' => [
                'total' => $tasks->count(),
                'pending' => $tasks->where('status', 'pending')->count(),
                'in_progress' => $tasks->where('status', 'in_progress')->count(),
                'completed' => $tasks->where('status', 'completed')->count(),
                'overdue' => $tasks->where('is_overdue', true)->count(),
            ],
        ]);
    }

    public function store(StoreTaskRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $status = $validated['status'] ?? 'pending';

        $task = Task::create([
            'user_id' => $request->user()->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'status' => $status,
            'priority' => $validated['priority'] ?? 'medium',
            'due_date' => $validated['due_date'] ?? null,
            'completed_at' => $status === 'completed' ? now() : null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Task created successfully.',
            'data' => $task->fresh(),
        ], 201);
    }

    public function show(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskOwner($request, $task);

        return response()->json([
            'success' => true,
            'message' => 'Task loaded successfully.',
            'data' => $task,
        ]);
    }

    public function update(UpdateTaskRequest $request, Task $task): JsonResponse
    {
        $this->authorizeTaskOwner($request, $task);

        $validated = $request->validated();

        if (array_key_exists('status', $validated)) {
            if ($validated['status'] === 'completed') {
                $validated['completed_at'] = $task->completed_at ?? now();
            }

            if (in_array($validated['status'], ['pending', 'in_progress'], true)) {
                $validated['completed_at'] = null;
            }
        }

        $task->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Task updated successfully.',
            'data' => $task->fresh(),
        ]);
    }

    public function destroy(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskOwner($request, $task);

        $task->delete();

        return response()->json([
            'success' => true,
            'message' => 'Task deleted successfully.',
        ]);
    }

    public function complete(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskOwner($request, $task);

        $task->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Task completed successfully.',
            'data' => $task->fresh(),
        ]);
    }

    public function reopen(Request $request, Task $task): JsonResponse
    {
        $this->authorizeTaskOwner($request, $task);

        $task->update([
            'status' => 'pending',
            'completed_at' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Task reopened successfully.',
            'data' => $task->fresh(),
        ]);
    }

    private function authorizeTaskOwner(Request $request, Task $task): void
    {
        abort_if(
            (string) $task->user_id !== (string) $request->user()->id,
            403,
            'You are not allowed to access this task.'
        );
    }
}

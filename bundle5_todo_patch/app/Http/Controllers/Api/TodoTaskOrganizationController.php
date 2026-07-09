<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TodoTask;
use App\Services\TodoPointsService;
use App\Services\TodoTaskOrderingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class TodoTaskOrganizationController extends Controller
{
    public function __construct(
        protected TodoTaskOrderingService $orderingService,
        protected TodoPointsService $pointsService,
    ) {
    }

    public function grouped(Request $request): JsonResponse
    {
        $userId = (int) $request->user()->id;

        return response()->json($this->groupedPayload($userId));
    }

    public function move(Request $request, TodoTask $task): JsonResponse
    {
        $userId = (int) $request->user()->id;

        $validated = $request->validate([
            'task_type' => ['required', 'string', 'in:general,monthly,weekly,daily'],
            'sort_order' => ['required', 'integer', 'min:0'],
        ]);

        $this->orderingService->moveTask(
            $userId,
            $task,
            $validated['task_type'],
            (int) $validated['sort_order']
        );

        return response()->json($this->groupedPayload($userId));
    }

    public function reorder(Request $request): JsonResponse
    {
        $userId = (int) $request->user()->id;

        $validated = $request->validate([
            'task_type' => ['required', 'string', 'in:general,monthly,weekly,daily'],
            'tasks' => ['required', 'array'],
            'tasks.*.id' => ['required', 'integer'],
            'tasks.*.sort_order' => ['required', 'integer', 'min:0'],
        ]);

        $orderedTaskIds = collect($validated['tasks'])
            ->sortBy('sort_order')
            ->pluck('id')
            ->values()
            ->all();

        $this->orderingService->reorderSection($userId, $validated['task_type'], $orderedTaskIds);

        return response()->json($this->groupedPayload($userId));
    }

    public function updateStatus(Request $request, TodoTask $task): JsonResponse
    {
        $userId = (int) $request->user()->id;

        abort_unless((int) $task->user_id === $userId, 403);

        $validated = $request->validate([
            'status' => ['required', 'string', 'in:pending,in_progress,finished'],
        ]);

        $task->forceFill([
            'status' => $validated['status'],
            'completed_at' => $validated['status'] === TodoPointsService::FINISHED_STATUS ? now() : null,
        ])->save();

        return response()->json($this->groupedPayload($userId));
    }

    public function update(Request $request, TodoTask $task): JsonResponse
    {
        $userId = (int) $request->user()->id;

        abort_unless((int) $task->user_id === $userId, 403);

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'nullable', 'string'],
            'task_type' => ['sometimes', 'string', 'in:general,monthly,weekly,daily'],
            'status' => ['sometimes', 'string', 'in:pending,in_progress,finished'],
            'points' => ['sometimes', 'integer', 'min:0'],
            'due_date' => ['sometimes', 'nullable', 'date'],
            'project_id' => ['sometimes', 'nullable', 'integer'],
        ]);

        if (array_key_exists('status', $validated)) {
            $validated['completed_at'] = $validated['status'] === TodoPointsService::FINISHED_STATUS ? now() : null;
        }

        $task->forceFill($validated)->save();

        if (array_key_exists('task_type', $validated)) {
            $this->orderingService->normalizeSection($userId, $validated['task_type']);
        }

        return response()->json($this->groupedPayload($userId));
    }

    protected function groupedPayload(int $userId): array
    {
        return [
            'tasks' => $this->groupedTasks($userId),
            'points_summary' => $this->pointsService->summary($userId),
        ];
    }

    protected function groupedTasks(int $userId): array
    {
        $grouped = [
            'general' => [],
            'monthly' => [],
            'weekly' => [],
            'daily' => [],
        ];

        foreach (array_keys($grouped) as $taskType) {
            $query = DB::table('todo_tasks')
                ->where('todo_tasks.user_id', $userId)
                ->where('todo_tasks.task_type', $taskType)
                ->orderBy('todo_tasks.sort_order')
                ->orderByRaw('todo_tasks.due_date ASC NULLS LAST')
                ->orderByDesc('todo_tasks.created_at');

            if (Schema::hasTable('todo_projects') && Schema::hasColumn('todo_tasks', 'project_id')) {
                $query->leftJoin('todo_projects', 'todo_projects.id', '=', 'todo_tasks.project_id');

                $projectNameSelect = 'NULL AS project_name';
                if (Schema::hasColumn('todo_projects', 'name')) {
                    $projectNameSelect = 'todo_projects.name AS project_name';
                } elseif (Schema::hasColumn('todo_projects', 'title')) {
                    $projectNameSelect = 'todo_projects.title AS project_name';
                }

                $query->select('todo_tasks.*', DB::raw($projectNameSelect));
            } else {
                $query->select('todo_tasks.*', DB::raw('NULL AS project_name'));
            }

            $grouped[$taskType] = $query->get()->map(fn ($task) => [
                'id' => (int) $task->id,
                'title' => $task->title ?? $task->name ?? 'Untitled task',
                'description' => $task->description ?? null,
                'task_type' => $task->task_type ?? $taskType,
                'status' => $task->status ?? 'pending',
                'points' => (int) ($task->points ?? 0),
                'sort_order' => (int) ($task->sort_order ?? 0),
                'due_date' => $task->due_date ?? null,
                'project_id' => isset($task->project_id) ? (int) $task->project_id : null,
                'project_name' => $task->project_name ?? null,
                'completed_at' => $task->completed_at ?? null,
                'created_at' => $task->created_at ?? null,
                'updated_at' => $task->updated_at ?? null,
            ])->values()->all();
        }

        return $grouped;
    }
}

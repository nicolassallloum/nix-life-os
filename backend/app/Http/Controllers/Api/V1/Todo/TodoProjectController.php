<?php

namespace App\Http\Controllers\Api\V1\Todo;

use App\Http\Controllers\Controller;
use App\Http\Requests\Todo\StoreTodoProjectRequest;
use App\Http\Requests\Todo\UpdateTodoProjectRequest;
use App\Models\TodoProject;
use App\Models\TodoTask;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TodoProjectController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $projects = $this->projectQuery($request->user()->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (TodoProject $project) => $this->formatProject($project))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Todo projects loaded successfully.',
            'data' => $projects,
        ]);
    }

    public function store(StoreTodoProjectRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['user_id'] = $request->user()->id;

        $project = TodoProject::create($data);

        $project = $this->projectQuery($request->user()->id)
            ->whereKey($project->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Todo project created successfully.',
            'data' => $this->formatProject($project),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $project = $this->projectQuery($request->user()->id)
            ->with([
                'tasks' => function ($query) {
                    $query
                        ->orderBy('sort_order')
                        ->orderBy('due_date')
                        ->orderByDesc('created_at');
                },
            ])
            ->whereKey($id)
            ->first();

        if (! $project) {
            return $this->notFound('Todo project not found.');
        }

        return response()->json([
            'success' => true,
            'message' => 'Todo project loaded successfully.',
            'data' => $this->formatProject($project, true),
        ]);
    }

    public function update(UpdateTodoProjectRequest $request, int $id): JsonResponse
    {
        $project = TodoProject::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $project) {
            return $this->notFound('Todo project not found.');
        }

        $project->update($request->validated());

        $project = $this->projectQuery($request->user()->id)
            ->whereKey($project->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Todo project updated successfully.',
            'data' => $this->formatProject($project),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $project = TodoProject::query()
            ->where('user_id', $request->user()->id)
            ->whereKey($id)
            ->first();

        if (! $project) {
            return $this->notFound('Todo project not found.');
        }

        TodoTask::query()
            ->where('user_id', $request->user()->id)
            ->where('project_id', $project->id)
            ->update(['project_id' => null]);

        $project->delete();

        return response()->json([
            'success' => true,
            'message' => 'Todo project deleted successfully.',
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

    private function projectQuery($userId)
    {
        return TodoProject::query()
            ->where('user_id', $userId)
            ->withCount([
                'tasks as total_tasks',
                'tasks as finished_tasks' => function ($query) {
                    $query->where('status', TodoTask::STATUS_FINISHED);
                },
            ])
            ->withSum([
                'tasks as total_project_points' => function ($query) {
                    $query->where('status', TodoTask::STATUS_FINISHED);
                },
            ], 'points');
    }

    private function formatProject(TodoProject $project, bool $includeTasks = false): array
    {
        $totalTasks = (int) ($project->total_tasks ?? 0);
        $finishedTasks = (int) ($project->finished_tasks ?? 0);
        $completionPercentage = $totalTasks > 0
            ? round(($finishedTasks / $totalTasks) * 100, 2)
            : 0;

        $data = [
            'id' => $project->id,
            'user_id' => $project->user_id,
            'name' => $project->name,
            'description' => $project->description,
            'status' => $project->status,
            'start_date' => $project->start_date ? $project->start_date->toDateString() : null,
            'end_date' => $project->end_date ? $project->end_date->toDateString() : null,
            'total_tasks' => $totalTasks,
            'finished_tasks' => $finishedTasks,
            'completion_percentage' => $completionPercentage,
            'total_project_points' => (int) ($project->total_project_points ?? 0),
            'created_at' => $project->created_at,
            'updated_at' => $project->updated_at,
        ];

        if ($includeTasks && $project->relationLoaded('tasks')) {
            $data['tasks'] = $project->tasks
                ->map(fn (TodoTask $task) => [
                    'id' => $task->id,
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
                    'created_at' => $task->created_at,
                    'updated_at' => $task->updated_at,
                ])
                ->values();
        }

        return $data;
    }
}

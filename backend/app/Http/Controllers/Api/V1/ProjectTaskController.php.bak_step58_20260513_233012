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
    public function index(Request $request)
    {
        $tasks = ProjectTask::query()
            ->where('user_id', $request->user()->id)
            ->when($request->project_id, fn ($query) => $query->where('project_id', $request->project_id))
            ->when($request->status, fn ($query) => $query->where('status', $request->status))
            ->when($request->priority, fn ($query) => $query->where('priority', $request->priority))
            ->orderBy('task_order')
            ->latest()
            ->paginate($request->get('per_page', 15));

        return ProjectTaskResource::collection($tasks);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'project_id' => ['required', 'uuid', 'exists:projects,id'],

            'task_title' => ['required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => [
                'nullable',
                Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled']),
            ],

            'priority' => [
                'nullable',
                Rule::in(['low', 'medium', 'high', 'critical']),
            ],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        $project = Project::where('id', $validated['project_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $validated['user_id'] = $request->user()->id;
        $validated['status'] = $validated['status'] ?? 'todo';
        $validated['priority'] = $validated['priority'] ?? 'medium';
        $validated['task_order'] = $validated['task_order'] ?? 1;
        $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

        $task = ProjectTask::create($validated);

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task created successfully.',
            'data' => new ProjectTaskResource($task),
        ], 201);
    }

    public function show(Request $request, ProjectTask $projectTask)
    {
        $this->authorizeTask($request, $projectTask);

        return response()->json([
            'success' => true,
            'data' => new ProjectTaskResource($projectTask),
        ]);
    }

    public function update(Request $request, ProjectTask $projectTask)
    {
        $this->authorizeTask($request, $projectTask);

        $validated = $request->validate([
            'task_title' => ['sometimes', 'required', 'string', 'max:255'],
            'task_description' => ['nullable', 'string'],

            'status' => [
                'sometimes',
                Rule::in(['todo', 'in_progress', 'blocked', 'completed', 'cancelled']),
            ],

            'priority' => [
                'sometimes',
                Rule::in(['low', 'medium', 'high', 'critical']),
            ],

            'task_order' => ['nullable', 'integer', 'min:1'],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_date' => ['nullable', 'date'],

            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'metadata' => ['nullable', 'array'],
        ]);

        if (($validated['status'] ?? null) === 'completed') {
            $validated['progress_percentage'] = 100;
            $validated['completed_date'] = $validated['completed_date'] ?? now()->toDateString();
        }

        $projectTask->update($validated);

        $this->refreshProjectProgress($projectTask->project);

        return response()->json([
            'success' => true,
            'message' => 'Project task updated successfully.',
            'data' => new ProjectTaskResource($projectTask->fresh()),
        ]);
    }

    public function destroy(Request $request, ProjectTask $projectTask)
    {
        $this->authorizeTask($request, $projectTask);

        $project = $projectTask->project;

        $projectTask->delete();

        $this->refreshProjectProgress($project);

        return response()->json([
            'success' => true,
            'message' => 'Project task deleted successfully.',
        ]);
    }

    private function authorizeTask(Request $request, ProjectTask $projectTask): void
    {
        abort_if($projectTask->user_id !== $request->user()->id, 403, 'Unauthorized task access.');
    }

    private function refreshProjectProgress(Project $project): void
    {
        $tasks = $project->tasks()->get();

        if ($tasks->count() === 0) {
            $project->update([
                'progress_percentage' => 0,
                'status' => 'not_started',
            ]);

            return;
        }

        $avgProgress = round($tasks->avg('progress_percentage'), 2);

        $completedTasks = $tasks->where('status', 'completed')->count();

        if ($completedTasks === $tasks->count()) {
            $status = 'completed';
            $actualEndDate = $project->actual_end_date ?? now()->toDateString();
        } elseif ($tasks->where('status', 'in_progress')->count() > 0) {
            $status = 'in_progress';
            $actualEndDate = $project->actual_end_date;
        } elseif ($tasks->where('status', 'blocked')->count() > 0) {
            $status = 'on_hold';
            $actualEndDate = $project->actual_end_date;
        } else {
            $status = 'not_started';
            $actualEndDate = $project->actual_end_date;
        }

        $project->update([
            'progress_percentage' => $avgProgress,
            'status' => $status,
            'actual_end_date' => $actualEndDate,
        ]);
    }
}
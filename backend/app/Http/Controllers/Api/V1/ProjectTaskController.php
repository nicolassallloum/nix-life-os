<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\ProjectTask;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProjectTaskController extends Controller
{
    public function index(Request $request)
    {
        $tasks = ProjectTask::with('project:id,name,title')
            ->where('user_id', $request->user()->id)
            ->when($request->project_id, fn ($q) => $q->where('project_id', $request->project_id))
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->orderByRaw("CASE WHEN due_date IS NULL THEN 1 ELSE 0 END")
            ->orderBy('due_date')
            ->paginate(30);

        return response()->json([
            'success' => true,
            'data' => $tasks,
        ]);
    }

    public function byProject(Request $request, Project $project)
    {
        abort_if($project->user_id !== $request->user()->id, 403);

        $tasks = ProjectTask::where('user_id', $request->user()->id)
            ->where('project_id', $project->id)
            ->orderBy('status')
            ->orderBy('due_date')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $tasks,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'project_id' => ['required', 'exists:projects,id'],
            'title' => ['required', 'string', 'max:200'],
            'description' => ['nullable', 'string'],
            'priority' => ['nullable', Rule::in(['low', 'medium', 'high', 'critical'])],
            'status' => ['nullable', Rule::in(['todo', 'in_progress', 'done', 'blocked'])],
            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'assigned_to' => ['nullable', 'string', 'max:150'],
            'notes' => ['nullable', 'string'],
        ]);

        $project = Project::where('id', $validated['project_id'])
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $task = ProjectTask::create([
            ...$validated,
            'user_id' => $request->user()->id,
            'project_id' => $project->id,
            'priority' => $validated['priority'] ?? 'medium',
            'status' => $validated['status'] ?? 'todo',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Project task created successfully.',
            'data' => $task,
        ], 201);
    }

    public function show(Request $request, ProjectTask $task)
    {
        abort_if($task->user_id !== $request->user()->id, 403);

        return response()->json([
            'success' => true,
            'data' => $task->load('project'),
        ]);
    }

    public function update(Request $request, ProjectTask $task)
    {
        abort_if($task->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'project_id' => ['sometimes', 'required', 'exists:projects,id'],
            'title' => ['sometimes', 'required', 'string', 'max:200'],
            'description' => ['nullable', 'string'],
            'priority' => ['nullable', Rule::in(['low', 'medium', 'high', 'critical'])],
            'status' => ['nullable', Rule::in(['todo', 'in_progress', 'done', 'blocked'])],
            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'assigned_to' => ['nullable', 'string', 'max:150'],
            'notes' => ['nullable', 'string'],
        ]);

        if (isset($validated['project_id'])) {
            Project::where('id', $validated['project_id'])
                ->where('user_id', $request->user()->id)
                ->firstOrFail();
        }

        $task->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Project task updated successfully.',
            'data' => $task,
        ]);
    }

    public function destroy(Request $request, ProjectTask $task)
    {
        abort_if($task->user_id !== $request->user()->id, 403);

        $task->delete();

        return response()->json([
            'success' => true,
            'message' => 'Project task deleted successfully.',
        ]);
    }
}
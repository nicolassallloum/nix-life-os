<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProjectTaskStep;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class ProjectTaskStepController extends Controller
{
    private array $statuses = [
        'todo',
        'in_progress',
        'done',
        'blocked',
        'cancelled',
    ];

    public function index(Request $request, $project, $task)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->authorizeProjectAndTask($userId, $project, $task);

            $steps = ProjectTaskStep::query()
                ->where('user_id', $userId)
                ->where('project_id', $projectRow->id)
                ->where('project_task_id', $task)
                ->orderBy('step_order')
                ->orderBy('created_at')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Project task steps loaded successfully.',
                'data' => $steps,
            ]);
        } catch (\Throwable $e) {
            Log::error('Project task steps index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task steps index failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request, $project, $task)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->authorizeProjectAndTask($userId, $project, $task);

            $validated = $request->validate([
                'title' => ['required', 'string', 'max:255'],
                'description' => ['nullable', 'string'],
                'status' => ['nullable', Rule::in($this->statuses)],
                'step_order' => ['nullable', 'integer', 'min:0'],
                'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
                'due_date' => ['nullable', 'date'],
                'completed_at' => ['nullable', 'date'],
                'metadata' => ['nullable', 'array'],
            ]);

            $validated['user_id'] = $userId;
            $validated['project_id'] = $projectRow->id;
            $validated['project_task_id'] = $task;
            $validated['status'] = $validated['status'] ?? 'todo';
            $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

            if (!isset($validated['step_order'])) {
                $validated['step_order'] = (int) ProjectTaskStep::where('project_task_id', $task)->max('step_order') + 1;
            }

            if ($validated['status'] === 'done') {
                $validated['progress_percentage'] = 100;
                $validated['completed_at'] = $validated['completed_at'] ?? now();
            }

            $step = ProjectTaskStep::create($validated);

            $this->recalculateTaskAndProjectProgress($projectRow->id, $task, $userId);

            return response()->json([
                'success' => true,
                'message' => 'Project task step created successfully.',
                'data' => $step,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Project task steps store failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task step creation failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $project, $task, $step)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->authorizeProjectAndTask($userId, $project, $task);
            $stepModel = $this->authorizeStep($userId, $projectRow->id, $task, $step);

            $validated = $request->validate([
                'title' => ['sometimes', 'required', 'string', 'max:255'],
                'description' => ['nullable', 'string'],
                'status' => ['sometimes', Rule::in($this->statuses)],
                'step_order' => ['nullable', 'integer', 'min:0'],
                'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
                'due_date' => ['nullable', 'date'],
                'completed_at' => ['nullable', 'date'],
                'metadata' => ['nullable', 'array'],
            ]);

            if (($validated['status'] ?? null) === 'done') {
                $validated['progress_percentage'] = 100;
                $validated['completed_at'] = $validated['completed_at'] ?? now();
            }

            if (($validated['status'] ?? null) !== 'done' && array_key_exists('completed_at', $validated)) {
                $validated['completed_at'] = $validated['completed_at'] ?: null;
            }

            $stepModel->update($validated);

            $this->recalculateTaskAndProjectProgress($projectRow->id, $task, $userId);

            return response()->json([
                'success' => true,
                'message' => 'Project task step updated successfully.',
                'data' => $stepModel->fresh(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project task steps update failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task step update failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, $project, $task, $step)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->authorizeProjectAndTask($userId, $project, $task);
            $stepModel = $this->authorizeStep($userId, $projectRow->id, $task, $step);

            $stepModel->delete();

            $this->recalculateTaskAndProjectProgress($projectRow->id, $task, $userId);

            return response()->json([
                'success' => true,
                'message' => 'Project task step deleted successfully.',
            ]);
        } catch (\Throwable $e) {
            Log::error('Project task steps delete failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project task step delete failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    private function authorizeProjectAndTask(string $userId, string $project, string $task)
    {
        $projectRow = DB::table('projects')
            ->where('id', $project)
            ->where('user_id', $userId)
            ->first();

        abort_if(!$projectRow, 403, 'Unauthorized project access.');

        $taskExists = DB::table('project_tasks')
            ->where('id', $task)
            ->where('project_id', $projectRow->id)
            ->where('user_id', $userId)
            ->exists();

        abort_if(!$taskExists, 403, 'Unauthorized project task access.');

        return $projectRow;
    }

    private function authorizeStep(string $userId, string $projectId, string $task, string $step): ProjectTaskStep
    {
        $stepModel = ProjectTaskStep::query()
            ->where('id', $step)
            ->where('user_id', $userId)
            ->where('project_id', $projectId)
            ->where('project_task_id', $task)
            ->first();

        abort_if(!$stepModel, 403, 'Unauthorized project task step access.');

        return $stepModel;
    }

    private function recalculateTaskAndProjectProgress(string $projectId, string $taskId, string $userId): void
    {
        $stepCount = DB::table('project_task_steps')
            ->where('project_task_id', $taskId)
            ->where('user_id', $userId)
            ->count();

        if ($stepCount > 0) {
            $doneCount = DB::table('project_task_steps')
                ->where('project_task_id', $taskId)
                ->where('user_id', $userId)
                ->where('status', 'done')
                ->count();

            $taskProgress = round(($doneCount / $stepCount) * 100, 2);

            DB::table('project_tasks')
                ->where('id', $taskId)
                ->where('user_id', $userId)
                ->update([
                    'progress_percentage' => $taskProgress,
                    'status' => $taskProgress >= 100 ? 'done' : ($taskProgress > 0 ? 'in_progress' : 'todo'),
                    'completed_at' => $taskProgress >= 100 ? now() : null,
                    'updated_at' => now(),
                ]);
        }

        $taskCount = DB::table('project_tasks')
            ->where('project_id', $projectId)
            ->where('user_id', $userId)
            ->count();

        if ($taskCount > 0) {
            $avgProgress = DB::table('project_tasks')
                ->where('project_id', $projectId)
                ->where('user_id', $userId)
                ->avg('progress_percentage');

            $projectProgress = round((float) $avgProgress, 2);

            DB::table('projects')
                ->where('id', $projectId)
                ->where('user_id', $userId)
                ->update([
                    'progress_percentage' => $projectProgress,
                    'status' => $projectProgress >= 100 ? 'completed' : ($projectProgress > 0 ? 'in_progress' : 'not_started'),
                    'actual_end_date' => $projectProgress >= 100 ? now()->toDateString() : null,
                    'updated_at' => now(),
                ]);
        }
    }
}

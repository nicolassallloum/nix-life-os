<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProjectGoal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class ProjectGoalController extends Controller
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

    public function index(Request $request, $project)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->getAuthorizedProject($userId, $project);

            $validated = $request->validate([
                'search' => ['nullable', 'string', 'max:255'],
                'status' => ['nullable', Rule::in($this->statuses)],
                'priority' => ['nullable', Rule::in($this->priorities)],
            ]);

            $query = DB::table('project_goals')
                ->where('user_id', $userId)
                ->where('project_id', $projectRow->id);

            if (!empty($validated['search'])) {
                $search = $validated['search'];
                $query->where(function ($subQuery) use ($search) {
                    $subQuery
                        ->where('title', 'ILIKE', "%{$search}%")
                        ->orWhere('description', 'ILIKE', "%{$search}%");
                });
            }

            if (!empty($validated['status'])) {
                $query->where('status', $validated['status']);
            }

            if (!empty($validated['priority'])) {
                $query->where('priority', $validated['priority']);
            }

            return response()->json([
                'success' => true,
                'message' => 'Project goals loaded successfully.',
                'data' => $query
                    ->orderByRaw('CASE WHEN due_date IS NULL THEN 1 ELSE 0 END')
                    ->orderBy('due_date')
                    ->orderByDesc('created_at')
                    ->get(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project goals index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project goals index failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request, $project)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->getAuthorizedProject($userId, $project);

            $validated = $request->validate([
                'title' => ['required', 'string', 'max:255'],
                'description' => ['nullable', 'string'],
                'status' => ['nullable', Rule::in($this->statuses)],
                'priority' => ['nullable', Rule::in($this->priorities)],
                'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
                'start_date' => ['nullable', 'date'],
                'due_date' => ['nullable', 'date'],
                'completed_at' => ['nullable', 'date'],
                'metadata' => ['nullable', 'array'],
            ]);

            $validated['user_id'] = $userId;
            $validated['project_id'] = $projectRow->id;
            $validated['status'] = $validated['status'] ?? 'not_started';
            $validated['priority'] = $validated['priority'] ?? 'medium';
            $validated['progress_percentage'] = $validated['progress_percentage'] ?? 0;

            if ($validated['status'] === 'completed') {
                $validated['progress_percentage'] = 100;
                $validated['completed_at'] = $validated['completed_at'] ?? now();
            }

            $goal = ProjectGoal::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Project goal created successfully.',
                'data' => $goal,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Project goals store failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project goal creation failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, $project, $goal)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->getAuthorizedProject($userId, $project);

            $goalModel = ProjectGoal::query()
                ->where('id', $goal)
                ->where('user_id', $userId)
                ->where('project_id', $projectRow->id)
                ->firstOrFail();

            $validated = $request->validate([
                'title' => ['sometimes', 'required', 'string', 'max:255'],
                'description' => ['nullable', 'string'],
                'status' => ['sometimes', Rule::in($this->statuses)],
                'priority' => ['sometimes', Rule::in($this->priorities)],
                'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
                'start_date' => ['nullable', 'date'],
                'due_date' => ['nullable', 'date'],
                'completed_at' => ['nullable', 'date'],
                'metadata' => ['nullable', 'array'],
            ]);

            if (($validated['status'] ?? null) === 'completed') {
                $validated['progress_percentage'] = 100;
                $validated['completed_at'] = $validated['completed_at'] ?? now();
            }

            if (($validated['status'] ?? null) !== 'completed' && array_key_exists('completed_at', $validated)) {
                $validated['completed_at'] = $validated['completed_at'] ?: null;
            }

            $goalModel->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Project goal updated successfully.',
                'data' => $goalModel->fresh(),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project goals update failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project goal update failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, $project, $goal)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->getAuthorizedProject($userId, $project);

            $goalModel = ProjectGoal::query()
                ->where('id', $goal)
                ->where('user_id', $userId)
                ->where('project_id', $projectRow->id)
                ->firstOrFail();

            $goalModel->delete();

            return response()->json([
                'success' => true,
                'message' => 'Project goal deleted successfully.',
            ]);
        } catch (\Throwable $e) {
            Log::error('Project goals delete failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project goal delete failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    private function getAuthorizedProject(string $userId, string $project)
    {
        $projectRow = DB::table('projects')
            ->where('id', $project)
            ->where('user_id', $userId)
            ->first();

        abort_if(!$projectRow, 403, 'Unauthorized project access.');

        return $projectRow;
    }
}

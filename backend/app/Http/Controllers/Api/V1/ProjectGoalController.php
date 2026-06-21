<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProjectGoal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
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

    private array $linkedModules = [
        'manual',
        'health_steps',
        'steps',
    ];

    private array $linkedMetrics = [
        'manual',
        'steps',
        'kilometers',
        'distance_km',
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

            $query = ProjectGoal::query()
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

            $goals = $query
                ->orderByRaw('CASE WHEN due_date IS NULL THEN 1 ELSE 0 END')
                ->orderBy('due_date')
                ->orderByDesc('created_at')
                ->get()
                ->map(fn (ProjectGoal $goal) => $this->refreshLinkedGoal($goal))
                ->values();

            return response()->json([
                'success' => true,
                'message' => 'Project goals loaded successfully.',
                'data' => $goals,
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

            $validated = $request->validate($this->validationRules(false));

            $validated['user_id'] = $userId;
            $validated['project_id'] = $projectRow->id;
            $validated['status'] = $validated['status'] ?? 'not_started';
            $validated['priority'] = $validated['priority'] ?? 'medium';

            $validated = $this->normalizeGoalPayload($validated, $userId);

            $goal = ProjectGoal::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Project goal created successfully.',
                'data' => $this->refreshLinkedGoal($goal),
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

            $validated = $request->validate($this->validationRules(true));

            $merged = array_merge($goalModel->toArray(), $validated);
            $validated = array_intersect_key(
                $this->normalizeGoalPayload($merged, $userId),
                array_flip([
                    'title',
                    'description',
                    'status',
                    'priority',
                    'progress_percentage',
                    'target_value',
                    'current_value',
                    'unit',
                    'linked_module',
                    'linked_metric',
                    'last_progress_sync_at',
                    'start_date',
                    'due_date',
                    'completed_at',
                    'metadata',
                ])
            );

            $goalModel->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Project goal updated successfully.',
                'data' => $this->refreshLinkedGoal($goalModel->fresh()),
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

    public function recalculate(Request $request, $project, $goal)
    {
        try {
            $userId = (string) $request->user()->id;
            $projectRow = $this->getAuthorizedProject($userId, $project);

            $goalModel = ProjectGoal::query()
                ->where('id', $goal)
                ->where('user_id', $userId)
                ->where('project_id', $projectRow->id)
                ->firstOrFail();

            return response()->json([
                'success' => true,
                'message' => 'Project goal progress recalculated successfully.',
                'data' => $this->refreshLinkedGoal($goalModel),
            ]);
        } catch (\Throwable $e) {
            Log::error('Project goals recalculation failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Project goal recalculation failed.',
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

    private function validationRules(bool $isUpdate): array
    {
        $titleRule = $isUpdate
            ? ['sometimes', 'required', 'string', 'max:255']
            : ['required', 'string', 'max:255'];

        return [
            'title' => $titleRule,
            'description' => ['nullable', 'string'],
            'status' => [$isUpdate ? 'sometimes' : 'nullable', Rule::in($this->statuses)],
            'priority' => [$isUpdate ? 'sometimes' : 'nullable', Rule::in($this->priorities)],
            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],

            'target_value' => ['nullable', 'numeric', 'min:0'],
            'current_value' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:50'],
            'linked_module' => ['nullable', Rule::in($this->linkedModules)],
            'linked_metric' => ['nullable', Rule::in($this->linkedMetrics)],

            'start_date' => ['nullable', 'date'],
            'due_date' => ['nullable', 'date'],
            'completed_at' => ['nullable', 'date'],
            'metadata' => ['nullable', 'array'],
        ];
    }

    private function normalizeGoalPayload(array $payload, string $userId): array
    {
        $payload['linked_module'] = $this->normalizeLinkedModule($payload['linked_module'] ?? null);
        $payload['linked_metric'] = $this->normalizeLinkedMetric($payload['linked_metric'] ?? null);
        $payload['target_value'] = isset($payload['target_value']) ? (float) $payload['target_value'] : null;

        if ($payload['linked_module']) {
            $payload['current_value'] = $this->linkedCurrentValue(
                $userId,
                $payload['linked_module'],
                $payload['linked_metric']
            );
            $payload['last_progress_sync_at'] = now();
        } else {
            $payload['current_value'] = isset($payload['current_value'])
                ? (float) $payload['current_value']
                : (float) ($payload['current_value'] ?? 0);
        }

        $payload['progress_percentage'] = $this->calculateProgress(
            $payload['current_value'] ?? 0,
            $payload['target_value'] ?? null,
            $payload['progress_percentage'] ?? 0
        );

        if ((float) $payload['progress_percentage'] >= 100) {
            $payload['status'] = 'completed';
            $payload['completed_at'] = $payload['completed_at'] ?? now();
        } elseif (($payload['status'] ?? null) === 'completed') {
            $payload['progress_percentage'] = 100;
            $payload['completed_at'] = $payload['completed_at'] ?? now();
        } elseif (! isset($payload['status']) || $payload['status'] === 'not_started') {
            $payload['status'] = ((float) $payload['progress_percentage'] > 0) ? 'in_progress' : 'not_started';
        }

        return $payload;
    }

    private function refreshLinkedGoal(ProjectGoal $goal): ProjectGoal
    {
        if (! $goal->linked_module) {
            return $goal;
        }

        $payload = $this->normalizeGoalPayload($goal->toArray(), (string) $goal->user_id);

        $goal->update([
            'current_value' => $payload['current_value'],
            'progress_percentage' => $payload['progress_percentage'],
            'status' => $payload['status'],
            'completed_at' => $payload['completed_at'] ?? $goal->completed_at,
            'last_progress_sync_at' => now(),
        ]);

        return $goal->fresh();
    }

    private function normalizeLinkedModule(?string $module): ?string
    {
        if (!$module || $module === 'manual') {
            return null;
        }

        if ($module === 'steps') {
            return 'health_steps';
        }

        return $module;
    }

    private function normalizeLinkedMetric(?string $metric): string
    {
        if (!$metric || $metric === 'manual') {
            return 'kilometers';
        }

        if ($metric === 'distance_km') {
            return 'kilometers';
        }

        return $metric;
    }

    private function linkedCurrentValue(string $userId, ?string $module, string $metric): float
    {
        if ($module !== 'health_steps' || ! Schema::hasTable('health_step_logs')) {
            return 0;
        }

        $column = $metric === 'steps' ? 'steps' : 'kilometers';

        if (! Schema::hasColumn('health_step_logs', $column)) {
            return 0;
        }

        return round((float) DB::table('health_step_logs')
            ->where('user_id', $userId)
            ->sum($column), 3);
    }

    private function calculateProgress(float $currentValue, ?float $targetValue, float $fallbackProgress): float
    {
        if (!$targetValue || $targetValue <= 0) {
            return round(max(0, min(100, $fallbackProgress)), 2);
        }

        return round(max(0, min(100, ($currentValue / $targetValue) * 100)), 2);
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

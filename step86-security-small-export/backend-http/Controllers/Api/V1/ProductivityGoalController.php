<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProductivityGoal;
use App\Models\ProductivityHabit;
use App\Models\ProductivityTask;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class ProductivityGoalController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = ProductivityGoal::query()
            ->where('user_id', $user->id)
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('priority')) {
            $query->where('priority', $request->string('priority'));
        }

        if ($request->filled('category')) {
            $query->where('category', $request->string('category'));
        }

        if ($request->filled('search')) {
            $search = $request->string('search');

            $query->where(function ($subQuery) use ($search) {
                $subQuery
                    ->where('title', 'ILIKE', "%{$search}%")
                    ->orWhere('description', 'ILIKE', "%{$search}%")
                    ->orWhere('category', 'ILIKE', "%{$search}%");
            });
        }

        return response()->json([
            'success' => true,
            'message' => 'Goals loaded successfully.',
            'data' => $query->get(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateGoal($request);

        $status = $validated['status'] ?? 'active';
        $progress = $this->normalizeProgress($validated['progress_percentage'] ?? 0);

        if ($status === 'completed') {
            $progress = 100;
        }

        $goal = ProductivityGoal::query()->create([
            'user_id' => $request->user()->id,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'status' => $status,
            'category' => $validated['category'] ?? null,
            'priority' => $validated['priority'] ?? 'medium',
            'progress_percentage' => $progress,
            'target_date' => $validated['target_date'] ?? null,
            'completed_at' => $status === 'completed' ? now() : null,
            'metadata' => $this->metadataFromRequest($validated),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Goal created successfully.',
            'data' => $goal->fresh(),
        ], 201);
    }

    public function show(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        return response()->json([
            'success' => true,
            'message' => 'Goal loaded successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function update(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $validated = $this->validateGoal($request, false);

        $status = $validated['status'] ?? $goal->status;
        $progress = array_key_exists('progress_percentage', $validated)
            ? $this->normalizeProgress($validated['progress_percentage'])
            : (float) $goal->progress_percentage;

        if ($status === 'completed') {
            $progress = 100;
        }

        $completedAt = $goal->completed_at;

        if ($status === 'completed' && !$completedAt) {
            $completedAt = now();
        }

        if ($status !== 'completed') {
            $completedAt = null;
        }

        $goal->fill([
            'title' => $validated['title'] ?? $goal->title,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : $goal->description,
            'status' => $status,
            'category' => array_key_exists('category', $validated) ? $validated['category'] : $goal->category,
            'priority' => $validated['priority'] ?? $goal->priority,
            'progress_percentage' => $progress,
            'target_date' => array_key_exists('target_date', $validated) ? $validated['target_date'] : $goal->target_date,
            'completed_at' => $completedAt,
            'metadata' => array_replace_recursive($goal->metadata ?? [], $this->metadataFromRequest($validated)),
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Goal updated successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function destroy(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $goal->delete();

        return response()->json([
            'success' => true,
            'message' => 'Goal deleted successfully.',
        ]);
    }

    public function updateProgress(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $validated = $request->validate([
            'progress_percentage' => ['required', 'numeric', 'min:0', 'max:100'],
        ]);

        $progress = $this->normalizeProgress($validated['progress_percentage']);

        $goal->forceFill([
            'progress_percentage' => $progress,
            'status' => $progress >= 100 ? 'completed' : ($goal->status === 'completed' ? 'active' : $goal->status),
            'completed_at' => $progress >= 100 ? now() : null,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Goal progress updated successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function complete(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $goal->forceFill([
            'status' => 'completed',
            'progress_percentage' => 100,
            'completed_at' => now(),
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Goal marked as completed successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function reopen(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $goal->forceFill([
            'status' => 'active',
            'completed_at' => null,
            'progress_percentage' => min((float) $goal->progress_percentage, 99),
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Goal reopened successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function linkTask(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $validated = $request->validate([
            'task_id' => ['required', 'uuid'],
        ]);

        $taskExists = ProductivityTask::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $validated['task_id'])
            ->exists();

        abort_if(!$taskExists, 404, 'Task not found.');

        $metadata = $goal->metadata ?? [];
        $linkedTaskIds = $metadata['linked_task_ids'] ?? [];

        if (!in_array($validated['task_id'], $linkedTaskIds, true)) {
            $linkedTaskIds[] = $validated['task_id'];
        }

        $metadata['linked_task_ids'] = array_values($linkedTaskIds);

        $goal->forceFill([
            'metadata' => $metadata,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Task linked to goal successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function unlinkTask(Request $request, ProductivityGoal $goal, string $taskId)
    {
        $this->authorizeGoal($request, $goal);

        $metadata = $goal->metadata ?? [];
        $linkedTaskIds = $metadata['linked_task_ids'] ?? [];

        $metadata['linked_task_ids'] = array_values(array_filter(
            $linkedTaskIds,
            fn ($id) => $id !== $taskId
        ));

        $goal->forceFill([
            'metadata' => $metadata,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Task unlinked from goal successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function linkHabit(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $validated = $request->validate([
            'habit_id' => ['required', 'uuid'],
        ]);

        $habitExists = ProductivityHabit::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $validated['habit_id'])
            ->exists();

        abort_if(!$habitExists, 404, 'Habit not found.');

        $metadata = $goal->metadata ?? [];
        $linkedHabitIds = $metadata['linked_habit_ids'] ?? [];

        if (!in_array($validated['habit_id'], $linkedHabitIds, true)) {
            $linkedHabitIds[] = $validated['habit_id'];
        }

        $metadata['linked_habit_ids'] = array_values($linkedHabitIds);

        $goal->forceFill([
            'metadata' => $metadata,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Habit linked to goal successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function unlinkHabit(Request $request, ProductivityGoal $goal, string $habitId)
    {
        $this->authorizeGoal($request, $goal);

        $metadata = $goal->metadata ?? [];
        $linkedHabitIds = $metadata['linked_habit_ids'] ?? [];

        $metadata['linked_habit_ids'] = array_values(array_filter(
            $linkedHabitIds,
            fn ($id) => $id !== $habitId
        ));

        $goal->forceFill([
            'metadata' => $metadata,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Habit unlinked from goal successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    public function recalculateProgress(Request $request, ProductivityGoal $goal)
    {
        $this->authorizeGoal($request, $goal);

        $metadata = $goal->metadata ?? [];

        $linkedTaskIds = $metadata['linked_task_ids'] ?? [];
        $linkedHabitIds = $metadata['linked_habit_ids'] ?? [];

        $scores = [];

        if (count($linkedTaskIds) > 0) {
            $totalTasks = ProductivityTask::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('id', $linkedTaskIds)
                ->count();

            $completedTasks = ProductivityTask::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('id', $linkedTaskIds)
                ->where('status', 'completed')
                ->count();

            if ($totalTasks > 0) {
                $scores[] = round(($completedTasks / $totalTasks) * 100, 2);
            }
        }

        if (count($linkedHabitIds) > 0) {
            $totalHabits = ProductivityHabit::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('id', $linkedHabitIds)
                ->count();

            $completedHabits = ProductivityHabit::query()
                ->where('user_id', $request->user()->id)
                ->whereIn('id', $linkedHabitIds)
                ->where(function ($query) {
                    $query
                        ->whereColumn('completed_count_today', '>=', 'target_count')
                        ->orWhereDate('last_completed_at', Carbon::today());
                })
                ->count();

            if ($totalHabits > 0) {
                $scores[] = round(($completedHabits / $totalHabits) * 100, 2);
            }
        }

        $progress = count($scores) > 0
            ? round(array_sum($scores) / count($scores), 2)
            : (float) $goal->progress_percentage;

        $goal->forceFill([
            'progress_percentage' => $progress,
            'status' => $progress >= 100 ? 'completed' : ($goal->status === 'completed' ? 'active' : $goal->status),
            'completed_at' => $progress >= 100 ? now() : null,
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Goal progress recalculated successfully.',
            'data' => $goal->fresh(),
        ]);
    }

    private function validateGoal(Request $request, bool $creating = true): array
    {
        $required = $creating ? 'required' : 'sometimes';

        return $request->validate([
            'title' => [$required, 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['nullable', Rule::in(['active', 'completed', 'on_hold', 'cancelled'])],
            'category' => ['nullable', 'string', 'max:100'],
            'priority' => ['nullable', Rule::in(['low', 'medium', 'high', 'critical'])],
            'progress_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'target_date' => ['nullable', 'date'],
            'metadata' => ['nullable', 'array'],
            'linked_task_ids' => ['nullable', 'array'],
            'linked_task_ids.*' => ['uuid'],
            'linked_habit_ids' => ['nullable', 'array'],
            'linked_habit_ids.*' => ['uuid'],
        ]);
    }

    private function metadataFromRequest(array $validated): array
    {
        $metadata = $validated['metadata'] ?? [];

        if (array_key_exists('linked_task_ids', $validated)) {
            $metadata['linked_task_ids'] = array_values($validated['linked_task_ids'] ?? []);
        }

        if (array_key_exists('linked_habit_ids', $validated)) {
            $metadata['linked_habit_ids'] = array_values($validated['linked_habit_ids'] ?? []);
        }

        return $metadata;
    }

    private function normalizeProgress(int|float|string $progress): float
    {
        return round(min(max((float) $progress, 0), 100), 2);
    }

    private function authorizeGoal(Request $request, ProductivityGoal $goal): void
    {
        abort_if($goal->user_id !== $request->user()->id, 404, 'Goal not found.');
    }
}

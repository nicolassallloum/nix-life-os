<?php

namespace App\Services;

use App\Models\TodoTask;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TodoTaskOrderingService
{
    public const TASK_TYPES = ['general', 'monthly', 'weekly', 'daily'];

    public function normalizeSection(int $userId, string $taskType): void
    {
        $this->validateTaskType($taskType);

        $tasks = $this->orderedSection($userId, $taskType)->get();

        $this->persistSequentialOrder($tasks->all());
    }

    public function moveTask(int $userId, TodoTask $task, string $targetType, int $targetIndex): void
    {
        $this->validateTaskType($targetType);

        DB::transaction(function () use ($userId, $task, $targetType, $targetIndex) {
            if ((int) $task->user_id !== $userId) {
                throw ValidationException::withMessages([
                    'task' => 'This task does not belong to the current user.',
                ]);
            }

            $sourceType = $task->task_type ?: 'general';
            $this->validateTaskType($sourceType);

            $targetTasks = $this->orderedSection($userId, $targetType)
                ->where('id', '!=', $task->id)
                ->get()
                ->all();

            $insertIndex = max(0, min($targetIndex, count($targetTasks)));

            $task->forceFill([
                'task_type' => $targetType,
            ])->save();

            $freshTask = $task->fresh();
            array_splice($targetTasks, $insertIndex, 0, [$freshTask]);

            $this->persistSequentialOrder($targetTasks);

            if ($sourceType !== $targetType) {
                $this->normalizeSection($userId, $sourceType);
            }
        });
    }

    public function reorderSection(int $userId, string $taskType, array $orderedTaskIds): void
    {
        $this->validateTaskType($taskType);

        DB::transaction(function () use ($userId, $taskType, $orderedTaskIds) {
            $ids = collect($orderedTaskIds)
                ->map(fn ($id) => (int) $id)
                ->filter()
                ->unique()
                ->values();

            if ($ids->isEmpty()) {
                return;
            }

            $tasks = TodoTask::query()
                ->where('user_id', $userId)
                ->where('task_type', $taskType)
                ->whereIn('id', $ids)
                ->get()
                ->keyBy('id');

            if ($tasks->count() !== $ids->count()) {
                throw ValidationException::withMessages([
                    'tasks' => 'All reordered tasks must belong to the current user and same task section.',
                ]);
            }

            $orderedTasks = $ids->map(fn ($id) => $tasks->get($id))->all();
            $this->persistSequentialOrder($orderedTasks);
            $this->normalizeSection($userId, $taskType);
        });
    }

    public function orderedSection(int $userId, string $taskType)
    {
        return TodoTask::query()
            ->where('user_id', $userId)
            ->where('task_type', $taskType)
            ->orderBy('sort_order')
            ->orderByRaw('due_date ASC NULLS LAST')
            ->orderByDesc('created_at');
    }

    protected function persistSequentialOrder(array $tasks): void
    {
        foreach ($tasks as $index => $task) {
            $task->forceFill(['sort_order' => $index])->save();
        }
    }

    protected function validateTaskType(string $taskType): void
    {
        if (! in_array($taskType, self::TASK_TYPES, true)) {
            throw ValidationException::withMessages([
                'task_type' => 'Invalid task type.',
            ]);
        }
    }
}

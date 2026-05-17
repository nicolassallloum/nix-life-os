<?php

namespace App\Services;

use App\Models\AutomationRule;
use App\Models\AutomationTriggerLog;
use App\Models\Notification;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AutomationEngineService
{
    public function runForUser(string $userId): array
    {
        $rules = AutomationRule::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->get();

        $results = [];

        foreach ($rules as $rule) {
            try {
                $result = $this->evaluateRule($rule);
                $results[] = $result;
            } catch (\Throwable $e) {
                Log::error('Automation rule failed', [
                    'rule_id' => $rule->id,
                    'error' => $e->getMessage(),
                ]);

                AutomationTriggerLog::create([
                    'automation_rule_id' => $rule->id,
                    'user_id' => $rule->user_id,
                    'status' => 'failed',
                    'evaluated_data' => [
                        'error' => $e->getMessage(),
                    ],
                    'message' => 'Automation failed.',
                ]);

                $results[] = [
                    'rule_id' => $rule->id,
                    'status' => 'failed',
                    'message' => $e->getMessage(),
                ];
            }
        }

        return $results;
    }

    public function evaluateRule(AutomationRule $rule): array
    {
        $shouldTrigger = false;
        $evaluatedData = [];

        switch ($rule->trigger_type) {
            case 'missing_log':
                [$shouldTrigger, $evaluatedData] = $this->evaluateMissingLog($rule);
                break;

            case 'threshold_exceeded':
                [$shouldTrigger, $evaluatedData] = $this->evaluateThresholdExceeded($rule);
                break;

            case 'due_today':
                [$shouldTrigger, $evaluatedData] = $this->evaluateDueToday($rule);
                break;

            case 'scheduled_time':
                [$shouldTrigger, $evaluatedData] = $this->evaluateScheduledTime($rule);
                break;

            default:
                $shouldTrigger = false;
                $evaluatedData = [
                    'reason' => 'Unsupported trigger type.',
                    'trigger_type' => $rule->trigger_type,
                ];
        }

        if (!$shouldTrigger) {
            AutomationTriggerLog::create([
                'automation_rule_id' => $rule->id,
                'user_id' => $rule->user_id,
                'status' => 'skipped',
                'evaluated_data' => $evaluatedData,
                'message' => 'Rule conditions not met.',
            ]);

            return [
                'rule_id' => $rule->id,
                'rule_name' => $rule->rule_name,
                'status' => 'skipped',
                'evaluated_data' => $evaluatedData,
            ];
        }

        $this->performAction($rule, $evaluatedData);

        $rule->update([
            'last_triggered_at' => now(),
        ]);

        AutomationTriggerLog::create([
            'automation_rule_id' => $rule->id,
            'user_id' => $rule->user_id,
            'status' => 'triggered',
            'evaluated_data' => $evaluatedData,
            'message' => 'Automation triggered successfully.',
        ]);

        return [
            'rule_id' => $rule->id,
            'rule_name' => $rule->rule_name,
            'status' => 'triggered',
            'evaluated_data' => $evaluatedData,
        ];
    }

    private function evaluateMissingLog(AutomationRule $rule): array
    {
        $conditions = $rule->conditions ?? [];

        $table = $conditions['table'] ?? null;
        $dateColumn = $conditions['date_column'] ?? 'log_date';
        $targetDate = $conditions['target_date'] ?? now()->toDateString();

        if (!$table) {
            return [
                false,
                [
                    'reason' => 'Missing table in conditions.',
                ],
            ];
        }

        $count = DB::table($table)
            ->where('user_id', $rule->user_id)
            ->whereDate($dateColumn, $targetDate)
            ->count();

        return [
            $count === 0,
            [
                'table' => $table,
                'date_column' => $dateColumn,
                'target_date' => $targetDate,
                'records_found' => $count,
            ],
        ];
    }

    private function evaluateThresholdExceeded(AutomationRule $rule): array
    {
        $conditions = $rule->conditions ?? [];

        $table = $conditions['table'] ?? null;
        $metricColumn = $conditions['metric_column'] ?? null;
        $operator = $conditions['operator'] ?? '>';
        $value = $conditions['value'] ?? null;
        $dateColumn = $conditions['date_column'] ?? null;
        $targetDate = $conditions['target_date'] ?? now()->toDateString();

        if (!$table || !$metricColumn || $value === null) {
            return [
                false,
                [
                    'reason' => 'Missing threshold configuration.',
                ],
            ];
        }

        $query = DB::table($table)
            ->where('user_id', $rule->user_id);

        if ($dateColumn) {
            $query->whereDate($dateColumn, $targetDate);
        }

        $actualValue = (float) $query->sum($metricColumn);

        $triggered = match ($operator) {
            '>' => $actualValue > $value,
            '>=' => $actualValue >= $value,
            '<' => $actualValue < $value,
            '<=' => $actualValue <= $value,
            '=' => $actualValue == $value,
            default => false,
        };

        return [
            $triggered,
            [
                'table' => $table,
                'metric_column' => $metricColumn,
                'operator' => $operator,
                'expected_value' => $value,
                'actual_value' => $actualValue,
                'target_date' => $targetDate,
            ],
        ];
    }

    private function evaluateDueToday(AutomationRule $rule): array
    {
        $conditions = $rule->conditions ?? [];

        $table = $conditions['table'] ?? null;
        $dueColumn = $conditions['due_column'] ?? 'due_date';
        $statusColumn = $conditions['status_column'] ?? 'status';
        $completedStatuses = $conditions['completed_statuses'] ?? ['done', 'completed'];

        if (!$table) {
            return [
                false,
                [
                    'reason' => 'Missing table in due_today rule.',
                ],
            ];
        }

        $items = DB::table($table)
            ->where('user_id', $rule->user_id)
            ->whereDate($dueColumn, now()->toDateString())
            ->whereNotIn($statusColumn, $completedStatuses)
            ->get();

        return [
            $items->count() > 0,
            [
                'table' => $table,
                'due_column' => $dueColumn,
                'items_due_today' => $items->count(),
                'items' => $items->take(5)->toArray(),
            ],
        ];
    }

    private function evaluateScheduledTime(AutomationRule $rule): array
    {
        $conditions = $rule->conditions ?? [];

        $scheduledTime = $conditions['time'] ?? null;
        $cooldownMinutes = $conditions['cooldown_minutes'] ?? 1440;

        if (!$scheduledTime) {
            return [
                false,
                [
                    'reason' => 'Missing scheduled time.',
                ],
            ];
        }

        $nowTime = now()->format('H:i');

        $alreadyTriggeredRecently = $rule->last_triggered_at
            && $rule->last_triggered_at->greaterThan(now()->subMinutes($cooldownMinutes));

        $shouldTrigger = $nowTime >= $scheduledTime && !$alreadyTriggeredRecently;

        return [
            $shouldTrigger,
            [
                'scheduled_time' => $scheduledTime,
                'current_time' => $nowTime,
                'cooldown_minutes' => $cooldownMinutes,
                'already_triggered_recently' => $alreadyTriggeredRecently,
            ],
        ];
    }

    private function performAction(AutomationRule $rule, array $evaluatedData): void
    {
        $payload = $rule->action_payload ?? [];

        if ($rule->action_type === 'create_notification') {
            Notification::create([
                'user_id' => $rule->user_id,
                'title' => $payload['title'] ?? $rule->rule_name,
                'message' => $payload['message'] ?? 'Smart automation reminder.',
                'notification_type' => $payload['notification_type'] ?? 'reminder',
                'priority' => $payload['priority'] ?? 'medium',
                'data' => [
                    'automation_rule_id' => $rule->id,
                    'module' => $rule->module,
                    'trigger_type' => $rule->trigger_type,
                    'evaluated_data' => $evaluatedData,
                ],
                'is_read' => false,
            ]);
        }
    }
}

<?php

namespace App\Services\AI;

use App\Models\AIRecommendation;
use App\Models\AIRecommendationRule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class RecommendationRuleService
{
    public function __construct(
        protected RecommendationScoringService $scoringService
    ) {
    }

    public function generateForUser(User|string $user, ?Carbon $date = null): array
    {
        $userId = $user instanceof User ? $user->id : $user;
        $date = $date ?? now();

        $scoreResult = $this->scoringService->calculateForUser($userId, $date);

        $metrics = $this->buildEvaluationMetrics($scoreResult);

        $rules = $this->loadActiveRules();

        $generated = [];
        $skipped = [];
        $failed = [];

        DB::transaction(function () use (
            $rules,
            $userId,
            $date,
            $scoreResult,
            $metrics,
            &$generated,
            &$skipped,
            &$failed
        ) {
            foreach ($rules as $rule) {
                try {
                    $evaluation = $this->evaluateRule($rule, $metrics);

                    if (!$evaluation['matched']) {
                        $skipped[] = [
                            'rule_code' => $rule->rule_code,
                            'reason' => $evaluation['reason'],
                            'metric_value' => $evaluation['metric_value'],
                        ];

                        continue;
                    }

                    $payload = $this->buildRecommendationPayload(
                        rule: $rule,
                        userId: $userId,
                        date: $date,
                        scoreResult: $scoreResult,
                        metrics: $metrics,
                        evaluation: $evaluation
                    );

                    $existing = $this->findExistingRecommendation(
                        userId: $userId,
                        duplicateKey: $payload['duplicate_key']
                    );

                    if ($existing) {
                        $skipped[] = [
                            'rule_code' => $rule->rule_code,
                            'reason' => 'duplicate_recommendation',
                            'duplicate_key' => $payload['duplicate_key'],
                            'recommendation_id' => $existing->id,
                        ];

                        continue;
                    }

                    $recommendation = AIRecommendation::create($payload);

                    $generated[] = [
                        'recommendation_id' => $recommendation->id,
                        'rule_code' => $rule->rule_code,
                        'title' => $recommendation->title,
                        'module' => $recommendation->module,
                        'recommendation_type' => $recommendation->recommendation_type,
                        'severity' => $recommendation->severity,
                        'priority' => $recommendation->priority,
                        'confidence_score' => $recommendation->confidence_score,
                        'impact_score' => $recommendation->impact_score,
                        'duplicate_key' => $recommendation->duplicate_key,
                    ];
                } catch (\Throwable $exception) {
                    $failed[] = [
                        'rule_code' => $rule->rule_code,
                        'error' => $exception->getMessage(),
                    ];
                }
            }
        });

        return [
            'user_id' => $userId,
            'score_date' => $date->toDateString(),
            'rules_loaded' => $rules->count(),
            'generated_count' => count($generated),
            'skipped_count' => count($skipped),
            'failed_count' => count($failed),
            'generated' => $generated,
            'skipped' => $skipped,
            'failed' => $failed,
            'score_summary' => [
                'finance_score' => $scoreResult['finance_score'],
                'health_score' => $scoreResult['health_score'],
                'productivity_score' => $scoreResult['productivity_score'],
                'goals_score' => $scoreResult['goals_score'],
                'habits_score' => $scoreResult['habits_score'],
                'life_balance_score' => $scoreResult['life_balance_score'],
                'classification' => $scoreResult['classification'],
            ],
        ];
    }

    public function generateForAllUsers(?Carbon $date = null): array
    {
        $date = $date ?? now();

        $summary = [
            'date' => $date->toDateString(),
            'total_users' => 0,
            'total_generated' => 0,
            'total_skipped' => 0,
            'total_failed' => 0,
            'users' => [],
        ];

        User::query()
            ->where(function ($query) {
                if (method_exists(User::class, 'getTable')) {
                    return $query;
                }

                return $query;
            })
            ->orderBy('id')
            ->chunk(100, function ($users) use ($date, &$summary) {
                foreach ($users as $user) {
                    $result = $this->generateForUser($user, $date);

                    $summary['total_users']++;
                    $summary['total_generated'] += $result['generated_count'];
                    $summary['total_skipped'] += $result['skipped_count'];
                    $summary['total_failed'] += $result['failed_count'];

                    $summary['users'][] = [
                        'user_id' => $user->id,
                        'generated_count' => $result['generated_count'],
                        'skipped_count' => $result['skipped_count'],
                        'failed_count' => $result['failed_count'],
                        'classification' => $result['score_summary']['classification'],
                        'life_balance_score' => $result['score_summary']['life_balance_score'],
                    ];
                }
            });

        return $summary;
    }

    public function loadActiveRules(): Collection
    {
        return AIRecommendationRule::query()
            ->active()
            ->currentlyValid()
            ->orderBy('priority')
            ->orderBy('module')
            ->orderBy('rule_code')
            ->get();
    }

    public function evaluateRule(AIRecommendationRule $rule, array $metrics): array
    {
        $conditionKey = $rule->condition_key;
        $operator = $rule->operator;
        $threshold = $rule->threshold_value !== null
            ? (float) $rule->threshold_value
            : null;

        if (!$conditionKey || !$operator) {
            return [
                'matched' => false,
                'reason' => 'missing_condition_key_or_operator',
                'condition_key' => $conditionKey,
                'operator' => $operator,
                'threshold_value' => $threshold,
                'metric_value' => null,
            ];
        }

        $metricExists = array_key_exists($conditionKey, $metrics);
        $metricValue = $metricExists ? $metrics[$conditionKey] : null;

        if (!$metricExists) {
            return [
                'matched' => false,
                'reason' => 'metric_not_found',
                'condition_key' => $conditionKey,
                'operator' => $operator,
                'threshold_value' => $threshold,
                'metric_value' => null,
            ];
        }

        $matched = $this->compareValues($metricValue, $operator, $threshold, $rule);

        return [
            'matched' => $matched,
            'reason' => $matched ? 'matched' : 'condition_not_met',
            'condition_key' => $conditionKey,
            'operator' => $operator,
            'threshold_value' => $threshold,
            'metric_value' => $metricValue,
        ];
    }

    protected function buildRecommendationPayload(
        AIRecommendationRule $rule,
        string $userId,
        Carbon $date,
        array $scoreResult,
        array $metrics,
        array $evaluation
    ): array {
        $periodKey = $this->buildPeriodKey($date);
        $duplicateKey = $this->buildDuplicateKey($userId, $rule, $periodKey);

        $templateVariables = $this->buildTemplateVariables(
            rule: $rule,
            scoreResult: $scoreResult,
            metrics: $metrics,
            evaluation: $evaluation,
            periodKey: $periodKey
        );

        return [
            'user_id' => $userId,
            'rule_id' => $rule->id,
            'module' => $rule->module,
            'recommendation_type' => $rule->recommendation_type,
            'title' => $this->renderTemplate($rule->title_template, $templateVariables),
            'message' => $this->renderTemplate($rule->message_template, $templateVariables),
            'action_text' => $this->renderTemplate($rule->action_template, $templateVariables),
            'severity' => $rule->severity,
            'priority' => $rule->priority,
            'confidence_score' => $this->calculateConfidenceScore($rule, $evaluation, $scoreResult),
            'impact_score' => $this->calculateImpactScore($rule, $evaluation, $scoreResult),
            'status' => AIRecommendation::STATUS_PENDING,
            'period_key' => $periodKey,
            'duplicate_key' => $duplicateKey,
            'source_data' => [
                'rule' => [
                    'id' => $rule->id,
                    'rule_code' => $rule->rule_code,
                    'rule_name' => $rule->rule_name,
                    'condition_key' => $rule->condition_key,
                    'operator' => $rule->operator,
                    'threshold_value' => $rule->threshold_value,
                ],
                'evaluation' => $evaluation,
                'metrics_snapshot' => $this->filterImportantMetrics($metrics),
            ],
            'score_breakdown' => $scoreResult['score_breakdown'] ?? [],
            'metadata' => [
                'engine' => 'rule_engine_v1',
                'generated_by' => self::class,
                'generated_date' => $date->toDateString(),
                'classification' => $scoreResult['classification'] ?? null,
                'life_balance_score' => $scoreResult['life_balance_score'] ?? null,
            ],
            'generated_at' => now(),
            'expires_at' => $this->calculateExpiryDate($rule, $date),
        ];
    }

    protected function buildEvaluationMetrics(array $scoreResult): array
    {
        $metrics = [
            'finance_score' => $scoreResult['finance_score'] ?? null,
            'health_score' => $scoreResult['health_score'] ?? null,
            'productivity_score' => $scoreResult['productivity_score'] ?? null,
            'goals_score' => $scoreResult['goals_score'] ?? null,
            'habits_score' => $scoreResult['habits_score'] ?? null,
            'life_balance_score' => $scoreResult['life_balance_score'] ?? null,
            'classification' => $scoreResult['classification'] ?? null,
        ];

        $breakdown = $scoreResult['score_breakdown'] ?? [];

        foreach ($breakdown as $module => $moduleData) {
            if (!is_array($moduleData)) {
                continue;
            }

            if (isset($moduleData['score'])) {
                $metrics[$module . '_module_score'] = $moduleData['score'];
            }

            if (isset($moduleData['data_status'])) {
                $metrics[$module . '_data_status'] = $moduleData['data_status'];
            }

            if (isset($moduleData['metrics']) && is_array($moduleData['metrics'])) {
                foreach ($moduleData['metrics'] as $key => $value) {
                    $metrics[$key] = $value;
                    $metrics[$module . '_' . $key] = $value;
                }
            }

            if (isset($moduleData['penalties']) && is_array($moduleData['penalties'])) {
                foreach ($moduleData['penalties'] as $key => $value) {
                    $metrics[$key] = $value;
                    $metrics[$module . '_' . $key] = $value;
                }
            }

            if (isset($moduleData['bonuses']) && is_array($moduleData['bonuses'])) {
                foreach ($moduleData['bonuses'] as $key => $value) {
                    $metrics[$key] = $value;
                    $metrics[$module . '_' . $key] = $value;
                }
            }
        }

        return $metrics;
    }

    protected function compareValues(
        mixed $metricValue,
        string $operator,
        ?float $threshold,
        AIRecommendationRule $rule
    ): bool {
        return match ($operator) {
            '>' => is_numeric($metricValue) && $threshold !== null && (float) $metricValue > $threshold,
            '>=' => is_numeric($metricValue) && $threshold !== null && (float) $metricValue >= $threshold,
            '<' => is_numeric($metricValue) && $threshold !== null && (float) $metricValue < $threshold,
            '<=' => is_numeric($metricValue) && $threshold !== null && (float) $metricValue <= $threshold,
            '=' => $this->compareEquals($metricValue, $threshold),
            '!=' => !$this->compareEquals($metricValue, $threshold),
            'between' => $this->compareBetween($metricValue, $rule),
            'not_between' => !$this->compareBetween($metricValue, $rule),
            'contains' => $this->compareContains($metricValue, $rule),
            'not_contains' => !$this->compareContains($metricValue, $rule),
            'exists' => $metricValue !== null,
            'not_exists' => $metricValue === null,
            default => false,
        };
    }

    protected function compareEquals(mixed $metricValue, ?float $threshold): bool
    {
        if ($threshold === null) {
            return $metricValue === null;
        }

        if (is_numeric($metricValue)) {
            return (float) $metricValue === $threshold;
        }

        return (string) $metricValue === (string) $threshold;
    }

    protected function compareBetween(mixed $metricValue, AIRecommendationRule $rule): bool
    {
        if (!is_numeric($metricValue)) {
            return false;
        }

        $payload = $rule->condition_payload ?? [];

        $min = $payload['min'] ?? $payload['lower_limit'] ?? null;
        $max = $payload['max'] ?? $payload['upper_limit'] ?? null;

        if ($min === null || $max === null) {
            return false;
        }

        return (float) $metricValue >= (float) $min
            && (float) $metricValue <= (float) $max;
    }

    protected function compareContains(mixed $metricValue, AIRecommendationRule $rule): bool
    {
        $payload = $rule->condition_payload ?? [];

        $expected = $payload['contains'] ?? $payload['value'] ?? null;

        if ($expected === null) {
            return false;
        }

        if (is_array($metricValue)) {
            return in_array($expected, $metricValue, true);
        }

        return str_contains(
            strtolower((string) $metricValue),
            strtolower((string) $expected)
        );
    }

    protected function buildTemplateVariables(
        AIRecommendationRule $rule,
        array $scoreResult,
        array $metrics,
        array $evaluation,
        string $periodKey
    ): array {
        $variables = array_merge($metrics, [
            'rule_code' => $rule->rule_code,
            'rule_name' => $rule->rule_name,
            'module' => $rule->module,
            'module_label' => $this->humanize($rule->module),
            'recommendation_type' => $rule->recommendation_type,
            'severity' => $rule->severity,
            'priority' => $rule->priority,
            'condition_key' => $rule->condition_key,
            'operator' => $rule->operator,
            'threshold_value' => $rule->threshold_value,
            'metric_value' => $evaluation['metric_value'] ?? null,
            'period_key' => $periodKey,
            'score_date' => $scoreResult['score_date'] ?? now()->toDateString(),
            'classification' => $scoreResult['classification'] ?? null,
            'life_balance_score' => $scoreResult['life_balance_score'] ?? null,
        ]);

        foreach ($variables as $key => $value) {
            if (is_float($value)) {
                $variables[$key] = round($value, 2);
            }

            if (is_array($value)) {
                $variables[$key] = json_encode($value);
            }

            if ($value === null) {
                $variables[$key] = 'N/A';
            }
        }

        return $variables;
    }

    protected function renderTemplate(?string $template, array $variables): ?string
    {
        if ($template === null) {
            return null;
        }

        $rendered = $template;

        foreach ($variables as $key => $value) {
            $rendered = str_replace(
                '{' . $key . '}',
                (string) $value,
                $rendered
            );
        }

        return $rendered;
    }

    protected function buildPeriodKey(Carbon $date): string
    {
        return $date->format('Y-m-d');
    }

    protected function buildDuplicateKey(
        string $userId,
        AIRecommendationRule $rule,
        string $periodKey
    ): string {
        return implode(':', [
            $userId,
            $rule->rule_code,
            $periodKey,
        ]);
    }

    protected function findExistingRecommendation(
        string $userId,
        string $duplicateKey
    ): ?AIRecommendation {
        return AIRecommendation::withTrashed()
            ->where('user_id', $userId)
            ->where('duplicate_key', $duplicateKey)
            ->first();
    }

    protected function calculateConfidenceScore(
        AIRecommendationRule $rule,
        array $evaluation,
        array $scoreResult
    ): float {
        $score = (float) $rule->base_confidence_score;

        $metricValue = $evaluation['metric_value'] ?? null;
        $threshold = $evaluation['threshold_value'] ?? null;

        if (is_numeric($metricValue) && is_numeric($threshold)) {
            $distance = abs((float) $metricValue - (float) $threshold);

            if ($distance >= 50) {
                $score += 5;
            } elseif ($distance >= 20) {
                $score += 3;
            }
        }

        if (($scoreResult['classification'] ?? null) === 'critical') {
            $score += 3;
        }

        return round(max(0, min(100, $score)), 2);
    }

    protected function calculateImpactScore(
        AIRecommendationRule $rule,
        array $evaluation,
        array $scoreResult
    ): float {
        $score = (float) $rule->base_impact_score;

        if ($rule->severity === AIRecommendationRule::SEVERITY_CRITICAL) {
            $score += 5;
        }

        if ($rule->priority === 1) {
            $score += 5;
        }

        if (($scoreResult['life_balance_score'] ?? 100) < 50) {
            $score += 5;
        }

        return round(max(0, min(100, $score)), 2);
    }

    protected function calculateExpiryDate(AIRecommendationRule $rule, Carbon $date): Carbon
    {
        return match ($rule->severity) {
            AIRecommendationRule::SEVERITY_CRITICAL => $date->copy()->addDays(3)->endOfDay(),
            AIRecommendationRule::SEVERITY_HIGH => $date->copy()->addDays(5)->endOfDay(),
            AIRecommendationRule::SEVERITY_MEDIUM => $date->copy()->addDays(7)->endOfDay(),
            AIRecommendationRule::SEVERITY_LOW => $date->copy()->addDays(14)->endOfDay(),
            AIRecommendationRule::SEVERITY_POSITIVE => $date->copy()->addDays(7)->endOfDay(),
            default => $date->copy()->addDays(7)->endOfDay(),
        };
    }

    protected function filterImportantMetrics(array $metrics): array
    {
        $importantKeys = [
            'finance_score',
            'health_score',
            'productivity_score',
            'goals_score',
            'habits_score',
            'life_balance_score',
            'classification',
            'budget_usage_percentage',
            'expense_income_ratio',
            'available_balance_percentage',
            'monthly_savings_amount',
            'daily_steps_percentage',
            'daily_hydration_percentage',
            'missed_medication_count',
            'weight_change_7d_percentage',
            'nutrition_log_count_7d',
            'overdue_task_count',
            'task_completion_rate_7d',
            'calendar_events_today',
            'goal_days_without_update',
            'goal_days_until_deadline',
            'habit_missed_count_7d',
            'habit_streak_at_risk',
            'daily_tasks_completed_percentage',
            'health_consistency_7d',
        ];

        return collect($metrics)
            ->only($importantKeys)
            ->toArray();
    }

    protected function humanize(?string $value): string
    {
        if (!$value) {
            return 'N/A';
        }

        return ucwords(str_replace('_', ' ', $value));
    }
}

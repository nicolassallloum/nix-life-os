<?php

namespace App\Services\Health;

use Carbon\Carbon;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HealthAIInsightService
{
    public function generateForUser(string $userId): array
    {
        $today = Carbon::today();
        $startDate = $today->copy()->subDays(30);
        $labStartDate = $today->copy()->subMonths(6);

        $nutritionLogs = $this->rows(
            table: 'health_nutrition_logs',
            userId: $userId,
            startDate: $startDate,
            dateCandidates: ['meal_date', 'log_date', 'date', 'created_at'],
            orderCandidates: ['meal_date', 'log_date', 'created_at']
        );

        $hydrationLogs = $this->rows(
            table: 'health_hydration_logs',
            userId: $userId,
            startDate: $startDate,
            dateCandidates: ['log_date', 'hydration_date', 'date', 'created_at'],
            orderCandidates: ['log_date', 'hydration_date', 'created_at']
        );

        $weightLogs = $this->rows(
            table: 'health_weight_logs',
            userId: $userId,
            startDate: $startDate,
            dateCandidates: ['log_date', 'weight_date', 'date', 'created_at'],
            orderCandidates: ['log_date', 'weight_date', 'created_at']
        );

        $stepTable = $this->firstExistingTable(['health_step_logs', 'health_steps_logs', 'health_step_log']);

        $stepLogs = $stepTable
            ? $this->rows(
                table: $stepTable,
                userId: $userId,
                startDate: $startDate,
                dateCandidates: ['log_date', 'steps_date', 'date', 'created_at'],
                orderCandidates: ['log_date', 'steps_date', 'created_at']
            )
            : collect();

        $labTests = $this->rows(
            table: 'health_lab_tests',
            userId: $userId,
            startDate: $labStartDate,
            dateCandidates: ['test_date', 'result_date', 'created_at'],
            orderCandidates: ['test_date', 'result_date', 'created_at']
        );

        $medications = $this->activeMedications($userId, $today);
        $reminders = $this->activeMedicationReminders($userId);

        $insights = collect()
            ->merge($this->nutritionInsights($nutritionLogs))
            ->merge($this->hydrationInsights($hydrationLogs))
            ->merge($this->weightInsights($weightLogs))
            ->merge($this->stepsInsights($stepLogs))
            ->merge($this->medicationInsights($medications, $reminders))
            ->merge($this->labInsights($labTests))
            ->merge($this->kidneyFriendlyRecommendations($nutritionLogs, $hydrationLogs, $labTests))
            ->values();

        $hasHealthData = $nutritionLogs->isNotEmpty()
            || $hydrationLogs->isNotEmpty()
            || $weightLogs->isNotEmpty()
            || $stepLogs->isNotEmpty()
            || $labTests->isNotEmpty()
            || $medications->isNotEmpty()
            || $reminders->isNotEmpty();

        return [
            'summary' => [
                'total_insights' => $insights->count(),
                'critical_warnings' => $insights->whereIn('severity', ['critical', 'danger'])->count(),
                'warnings' => $insights->where('severity', 'warning')->count(),
                'recommendations' => $insights->whereIn('severity', ['info', 'success'])->count(),
                'has_health_data' => $hasHealthData,
                'generated_at' => now()->toISOString(),
            ],
            'insights' => $insights->all(),
            'empty_state' => $hasHealthData ? null : [
                'title' => 'No health data yet',
                'message' => 'Start tracking nutrition, hydration, weight, steps, medications, or lab results to receive Health AI insights.',
            ],
        ];
    }

    private function nutritionInsights(Collection $logs): array
    {
        if ($logs->isEmpty()) {
            return [];
        }

        $todayLogs = $logs->filter(fn ($log) => $this->dateIsToday($this->value($log, ['meal_date', 'log_date', 'date', 'created_at'])));
        $dailyLogs = $todayLogs->isNotEmpty() ? $todayLogs : $logs->take(10);

        $totalSodium = $dailyLogs->sum(fn ($log) => $this->number($this->value($log, ['sodium_mg', 'sodium'])));
        $totalPotassium = $dailyLogs->sum(fn ($log) => $this->number($this->value($log, ['potassium_mg', 'potassium'])));
        $totalPhosphorus = $dailyLogs->sum(fn ($log) => $this->number($this->value($log, ['phosphorus_mg', 'phosphorus'])));
        $totalProtein = $dailyLogs->sum(fn ($log) => $this->number($this->value($log, ['protein_g', 'protein'])));

        $highestSodium = $logs
            ->sortByDesc(fn ($log) => $this->number($this->value($log, ['sodium_mg', 'sodium'])))
            ->first();

        $insights = [];

        if ($highestSodium && $this->number($this->value($highestSodium, ['sodium_mg', 'sodium'])) >= 400) {
            $sodium = $this->number($this->value($highestSodium, ['sodium_mg', 'sodium']));
            $foodName = $this->value($highestSodium, ['food_name', 'name', 'meal_name']) ?: 'This food';

            $insights[] = $this->insight(
                'nutrition_warning',
                $sodium >= 600 || $totalSodium >= 1500 ? 'warning' : 'info',
                'High sodium food detected',
                sprintf('%s contains about %s mg sodium. High sodium intake can make kidney-friendly eating harder to control.', $foodName, number_format($sodium, 0)),
                'Reduce salty snacks and processed foods, avoid adding table salt, and choose fresh lower-sodium options when possible.',
                'nutrition',
                [
                    'food_name' => $foodName,
                    'sodium_mg' => $this->round($sodium),
                    'daily_sodium_mg' => $this->round($totalSodium),
                ]
            );
        }

        if ($totalProtein > 70) {
            $insights[] = $this->insight(
                'nutrition_warning',
                'warning',
                'Protein intake may be high',
                sprintf('Recent logged protein is about %s g.', number_format($totalProtein, 1)),
                'Keep protein portions controlled and follow your renal dietitian or doctor’s personalized protein target.',
                'nutrition',
                ['protein_g' => $this->round($totalProtein)]
            );
        }

        if ($totalPotassium > 2000 || $totalPhosphorus > 800) {
            $insights[] = $this->insight(
                'nutrition_warning',
                'warning',
                'Kidney-related minerals need attention',
                sprintf('Recent logs show about %s mg potassium and %s mg phosphorus.', number_format($totalPotassium, 0), number_format($totalPhosphorus, 0)),
                'Review high-potassium and high-phosphorus foods with your healthcare provider or renal dietitian.',
                'nutrition',
                [
                    'potassium_mg' => $this->round($totalPotassium),
                    'phosphorus_mg' => $this->round($totalPhosphorus),
                ]
            );
        }

        if (empty($insights)) {
            $insights[] = $this->insight(
                'nutrition_warning',
                'success',
                'Nutrition logs look controlled',
                'Your recent nutrition logs do not show a major sodium, potassium, phosphorus, or protein warning.',
                'Continue logging meals consistently so trends remain visible.',
                'nutrition'
            );
        }

        return $insights;
    }

    private function hydrationInsights(Collection $logs): array
    {
        if ($logs->isEmpty()) {
            return [];
        }

        $todayTotal = $logs
            ->filter(fn ($log) => $this->dateIsToday($this->value($log, ['log_date', 'hydration_date', 'date', 'created_at'])))
            ->sum(fn ($log) => $this->number($this->value($log, ['amount_ml', 'water_ml', 'quantity_ml', 'ml'])));

        if ($todayTotal <= 0) {
            $latest = $logs->first();
            $latestDate = $this->dateString($this->value($latest, ['log_date', 'hydration_date', 'date', 'created_at']));

            $todayTotal = $logs
                ->filter(fn ($log) => $this->dateString($this->value($log, ['log_date', 'hydration_date', 'date', 'created_at'])) === $latestDate)
                ->sum(fn ($log) => $this->number($this->value($log, ['amount_ml', 'water_ml', 'quantity_ml', 'ml'])));
        }

        if ($todayTotal < 1000) {
            return [
                $this->insight(
                    'hydration_advice',
                    'info',
                    'Hydration below common daily target',
                    sprintf('Your recent logged fluid intake is about %s ml.', number_format($todayTotal, 0)),
                    'Drink fluids gradually during the day, but follow your doctor’s fluid limit if you have a restriction.',
                    'hydration',
                    ['amount_ml' => $this->round($todayTotal)]
                ),
            ];
        }

        if ($todayTotal > 3000) {
            return [
                $this->insight(
                    'hydration_advice',
                    'warning',
                    'High fluid intake logged',
                    sprintf('Your recent logged fluid intake is about %s ml.', number_format($todayTotal, 0)),
                    'For CKD or heart-related conditions, confirm your safe daily fluid limit with your healthcare provider.',
                    'hydration',
                    ['amount_ml' => $this->round($todayTotal)]
                ),
            ];
        }

        return [
            $this->insight(
                'hydration_advice',
                'success',
                'Hydration logging is on track',
                sprintf('Your recent logged fluid intake is about %s ml.', number_format($todayTotal, 0)),
                'Continue tracking fluids and follow your doctor’s fluid limit if applicable.',
                'hydration',
                ['amount_ml' => $this->round($todayTotal)]
            ),
        ];
    }

    private function weightInsights(Collection $logs): array
    {
        if ($logs->count() < 2) {
            return [];
        }

        $latest = $logs->first();
        $previous = $logs->skip(1)->first();

        $latestWeight = $this->number($this->value($latest, ['weight_kg', 'weight']));
        $previousWeight = $this->number($this->value($previous, ['weight_kg', 'weight']));

        if ($latestWeight <= 0 || $previousWeight <= 0) {
            return [];
        }

        $change = $latestWeight - $previousWeight;

        if (abs($change) < 0.3) {
            return [
                $this->insight(
                    'weight_trend',
                    'success',
                    'Weight is stable',
                    sprintf('Your latest weight changed by %s kg compared with the previous log.', number_format($change, 2)),
                    'Keep monitoring your weight trend consistently.',
                    'weight',
                    ['change_kg' => $this->round($change)]
                ),
            ];
        }

        if ($change >= 1.5) {
            return [
                $this->insight(
                    'weight_trend',
                    'warning',
                    'Recent weight increase detected',
                    sprintf('Your latest weight increased by about %s kg compared with the previous log.', number_format($change, 2)),
                    'Review sodium intake and fluid balance. If the gain is sudden or linked to swelling, contact your healthcare provider.',
                    'weight',
                    ['change_kg' => $this->round($change)]
                ),
            ];
        }

        return [
            $this->insight(
                'weight_trend',
                $change < 0 ? 'success' : 'info',
                $change < 0 ? 'Positive weight progress' : 'Small weight increase detected',
                sprintf('Your latest weight changed by %s kg compared with the previous log.', number_format($change, 2)),
                $change < 0
                    ? 'Continue your current plan if you feel well and your healthcare provider agrees with your weight goal.'
                    : 'Keep tracking and review calories, sodium, and activity if the increase continues.',
                'weight',
                ['change_kg' => $this->round($change)]
            ),
        ];
    }

    private function stepsInsights(Collection $logs): array
    {
        if ($logs->isEmpty()) {
            return [];
        }

        $recent = $logs->take(7);
        $averageSteps = $recent->avg(fn ($log) => $this->number($this->value($log, ['steps', 'steps_count']))) ?: 0;
        $latest = $logs->first();
        $goal = $this->number($this->value($latest, ['goal_steps', 'steps_goal', 'daily_steps_goal'])) ?: 6000;

        if ($averageSteps < 3000) {
            return [
                $this->insight(
                    'steps_insight',
                    'info',
                    'Low activity level detected',
                    sprintf('Your recent average is about %s steps per day.', number_format($averageSteps, 0)),
                    'Try short light walks if approved by your doctor, and increase activity gradually.',
                    'steps',
                    ['average_steps' => $this->round($averageSteps), 'goal_steps' => $this->round($goal)]
                ),
            ];
        }

        if ($averageSteps >= $goal) {
            return [
                $this->insight(
                    'steps_insight',
                    'success',
                    'Steps goal is on track',
                    sprintf('Your recent average is about %s steps per day.', number_format($averageSteps, 0)),
                    'Continue your current activity routine while avoiding overexertion.',
                    'steps',
                    ['average_steps' => $this->round($averageSteps), 'goal_steps' => $this->round($goal)]
                ),
            ];
        }

        return [
            $this->insight(
                'steps_insight',
                'info',
                'Steps are below your goal',
                sprintf('Your recent average is about %s steps per day against a goal of %s.', number_format($averageSteps, 0), number_format($goal, 0)),
                'Add small walking sessions during the day if you feel well and your doctor allows it.',
                'steps',
                ['average_steps' => $this->round($averageSteps), 'goal_steps' => $this->round($goal)]
            ),
        ];
    }

    private function medicationInsights(Collection $medications, Collection $reminders): array
    {
        if ($medications->isEmpty() && $reminders->isEmpty()) {
            return [];
        }

        $message = $reminders->isNotEmpty()
            ? sprintf('You have %s active medication reminder(s).', $reminders->count())
            : sprintf('You have %s active medication record(s).', $medications->count());

        return [
            $this->insight(
                'medication_reminder',
                'info',
                'Medication tracking reminder',
                $message,
                'Follow the medication timing and dose prescribed by your doctor. Do not change or stop medication without medical advice.',
                'medications',
                [
                    'active_medications' => $medications->count(),
                    'active_reminders' => $reminders->count(),
                ]
            ),
        ];
    }

    private function labInsights(Collection $labTests): array
    {
        if ($labTests->isEmpty()) {
            return [];
        }

        $insights = [];
        $latest = $labTests->first();

        $kidneyMarkers = [
            'creatinine' => ['label' => 'Creatinine', 'high' => 1.3, 'severity' => 'warning'],
            'urea' => ['label' => 'Urea', 'high' => 50, 'severity' => 'warning'],
            'potassium' => ['label' => 'Potassium', 'high' => 5.2, 'severity' => 'critical'],
            'phosphorus' => ['label' => 'Phosphorus', 'high' => 4.5, 'severity' => 'warning'],
            'sodium' => ['label' => 'Sodium', 'low' => 135, 'high' => 145, 'severity' => 'warning'],
        ];

        foreach ($kidneyMarkers as $field => $rule) {
            $value = $this->number($this->value($latest, [$field]));

            if ($value <= 0) {
                continue;
            }

            $isHigh = isset($rule['high']) && $value > $rule['high'];
            $isLow = isset($rule['low']) && $value < $rule['low'];

            if ($isHigh || $isLow) {
                $insights[] = $this->insight(
                    'lab_result_trend',
                    $rule['severity'],
                    $rule['label'] . ' result needs review',
                    sprintf('Your latest %s value is %s.', strtolower($rule['label']), number_format($value, 2)),
                    'Review this lab trend with your healthcare provider. This insight is not a diagnosis.',
                    'labs',
                    ['marker' => $field, 'value' => $this->round($value)]
                );

                break;
            }
        }

        $egfr = $this->number($this->value($latest, ['egfr', 'e_gfr']));
        if ($egfr > 0 && $egfr < 30) {
            $insights[] = $this->insight(
                'lab_result_trend',
                'warning',
                'eGFR result needs follow-up',
                sprintf('Your latest eGFR value is %s.', number_format($egfr, 2)),
                'Discuss this result with your nephrologist or healthcare provider for personalized guidance.',
                'labs',
                ['marker' => 'egfr', 'value' => $this->round($egfr)]
            );
        }

        $hemoglobin = $this->number($this->value($latest, ['hemoglobin', 'hgb']));
        if ($hemoglobin > 0 && $hemoglobin < 12) {
            $insights[] = $this->insight(
                'lab_result_trend',
                'info',
                'Hemoglobin may need monitoring',
                sprintf('Your latest hemoglobin value is %s.', number_format($hemoglobin, 2)),
                'Keep monitoring this value and review it with your healthcare provider, especially if you feel tired or dizzy.',
                'labs',
                ['marker' => 'hemoglobin', 'value' => $this->round($hemoglobin)]
            );
        }

        if (empty($insights)) {
            $insights[] = $this->insight(
                'lab_result_trend',
                'success',
                'Latest lab logs reviewed',
                'No major kidney-related warning was detected from the latest structured lab values.',
                'Continue tracking lab results and review them with your healthcare provider.',
                'labs'
            );
        }

        return $insights;
    }

    private function kidneyFriendlyRecommendations(Collection $nutritionLogs, Collection $hydrationLogs, Collection $labTests): array
    {
        if ($nutritionLogs->isEmpty() && $hydrationLogs->isEmpty() && $labTests->isEmpty()) {
            return [];
        }

        $recentSodium = $nutritionLogs->take(10)->sum(fn ($log) => $this->number($this->value($log, ['sodium_mg', 'sodium'])));
        $latestLab = $labTests->first();

        $potassium = $latestLab ? $this->number($this->value($latestLab, ['potassium'])) : 0;
        $phosphorus = $latestLab ? $this->number($this->value($latestLab, ['phosphorus'])) : 0;

        $message = 'Focus on sodium control, balanced portions, and consistent tracking.';

        if ($recentSodium >= 1000 || $potassium > 5.2 || $phosphorus > 4.5) {
            $message = 'Your recent data suggests extra attention to sodium, potassium, phosphorus, and portion control.';
        }

        return [
            $this->insight(
                'kidney_recommendation',
                'info',
                'Kidney-friendly recommendation',
                $message,
                'Choose fresh meals, limit processed foods, control protein portions, and follow your renal dietitian or doctor’s personalized plan.',
                'kidney_health',
                [
                    'recent_sodium_mg' => $this->round($recentSodium),
                    'latest_potassium' => $potassium > 0 ? $this->round($potassium) : null,
                    'latest_phosphorus' => $phosphorus > 0 ? $this->round($phosphorus) : null,
                ]
            ),
        ];
    }

    private function activeMedications(string $userId, Carbon $today): Collection
    {
        if (! Schema::hasTable('health_medications')) {
            return collect();
        }

        $query = DB::table('health_medications');
        $this->applyUserFilter($query, 'health_medications', $userId);

        if (Schema::hasColumn('health_medications', 'deleted_at')) {
            $query->whereNull('deleted_at');
        }

        if (Schema::hasColumn('health_medications', 'status')) {
            $query->where(function (Builder $builder) {
                $builder->whereNull('status')
                    ->orWhereIn('status', ['active', 'ACTIVE', 'ongoing', 'ONGOING']);
            });
        }

        if (Schema::hasColumn('health_medications', 'end_date')) {
            $query->where(function (Builder $builder) use ($today) {
                $builder->whereNull('end_date')
                    ->orWhereDate('end_date', '>=', $today->toDateString());
            });
        }

        $this->applyOrdering($query, 'health_medications', ['created_at', 'medication_name', 'name']);

        return $query->limit(100)->get();
    }

    private function activeMedicationReminders(string $userId): Collection
    {
        if (! Schema::hasTable('health_medication_reminders')) {
            return collect();
        }

        $query = DB::table('health_medication_reminders');
        $this->applyUserFilter($query, 'health_medication_reminders', $userId);

        if (Schema::hasColumn('health_medication_reminders', 'is_active')) {
            $query->where('is_active', true);
        }

        $this->applyOrdering($query, 'health_medication_reminders', ['reminder_time', 'scheduled_time', 'time', 'created_at']);

        return $query->limit(100)->get();
    }

    private function rows(
        string $table,
        string $userId,
        ?Carbon $startDate = null,
        array $dateCandidates = [],
        array $orderCandidates = []
    ): Collection {
        if (! Schema::hasTable($table)) {
            return collect();
        }

        $query = DB::table($table);
        $this->applyUserFilter($query, $table, $userId);

        $dateColumn = $this->firstExistingColumn($table, $dateCandidates);

        if ($startDate && $dateColumn) {
            $query->whereDate($dateColumn, '>=', $startDate->toDateString());
        }

        $this->applyOrdering($query, $table, $orderCandidates ?: $dateCandidates);

        return $query->limit(200)->get();
    }

    private function applyUserFilter(Builder $query, string $table, string $userId): void
    {
        if (Schema::hasColumn($table, 'user_id')) {
            $query->where('user_id', $userId);
        }
    }

    private function applyOrdering(Builder $query, string $table, array $candidates): void
    {
        foreach ($candidates as $column) {
            if (Schema::hasColumn($table, $column)) {
                $query->orderByDesc($column);
                return;
            }
        }

        if (Schema::hasColumn($table, 'id')) {
            $query->orderByDesc('id');
        }
    }

    private function firstExistingTable(array $tables): ?string
    {
        foreach ($tables as $table) {
            if (Schema::hasTable($table)) {
                return $table;
            }
        }

        return null;
    }

    private function firstExistingColumn(string $table, array $columns): ?string
    {
        foreach ($columns as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return null;
    }

    private function insight(
        string $type,
        string $severity,
        string $title,
        string $message,
        string $recommendation,
        string $source,
        array $metrics = []
    ): array {
        return [
            'type' => $type,
            'severity' => $severity,
            'title' => $title,
            'message' => $message,
            'recommendation' => $recommendation,
            'source' => $source,
            'metrics' => $metrics,
            'created_at' => now()->toISOString(),
        ];
    }

    private function value(mixed $item, array $keys): mixed
    {
        foreach ($keys as $key) {
            if (is_array($item) && array_key_exists($key, $item)) {
                return $item[$key];
            }

            if (is_object($item) && property_exists($item, $key)) {
                return $item->{$key};
            }
        }

        return null;
    }

    private function number(mixed $value): float
    {
        if ($value === null || $value === '') {
            return 0.0;
        }

        return (float) $value;
    }

    private function round(mixed $value): float
    {
        return round($this->number($value), 2);
    }

    private function dateIsToday(mixed $value): bool
    {
        $date = $this->dateString($value);

        return $date !== null && $date === Carbon::today()->toDateString();
    }

    private function dateString(mixed $value): ?string
    {
        if (! $value) {
            return null;
        }

        try {
            return Carbon::parse($value)->toDateString();
        } catch (\Throwable) {
            return null;
        }
    }
}

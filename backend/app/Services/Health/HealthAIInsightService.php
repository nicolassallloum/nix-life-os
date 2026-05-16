<?php

namespace App\Services\Health;

use App\Models\HealthHydrationLog;
use App\Models\HealthLabTest;
use App\Models\HealthMedication;
use App\Models\HealthMedicationReminder;
use App\Models\HealthNutritionLog;
use App\Models\HealthStepLog;
use App\Models\HealthWeightLog;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class HealthAIInsightService
{
    public function generateForUser(string $userId): array
    {
        $today = Carbon::today();
        $startDate = $today->copy()->subDays(30);

        $nutritionLogs = HealthNutritionLog::query()
            ->where('user_id', $userId)
            ->whereDate('meal_date', '>=', $startDate)
            ->orderByDesc('meal_date')
            ->orderByDesc('created_at')
            ->get();

        $hydrationLogs = HealthHydrationLog::query()
            ->where('user_id', $userId)
            ->whereDate('log_date', '>=', $startDate)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->get();

        $weightLogs = HealthWeightLog::query()
            ->where('user_id', $userId)
            ->whereDate('log_date', '>=', $startDate)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->get();

        $stepLogs = HealthStepLog::query()
            ->where('user_id', $userId)
            ->whereDate('log_date', '>=', $startDate)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->get();

        $labTests = HealthLabTest::query()
            ->where('user_id', $userId)
            ->whereDate('test_date', '>=', $today->copy()->subMonths(6))
            ->orderByDesc('test_date')
            ->orderByDesc('created_at')
            ->get();

        $medications = HealthMedication::query()
            ->where('user_id', $userId)
            ->where(function ($query) use ($today) {
                $query->whereNull('status')
                    ->orWhereIn('status', ['active', 'ACTIVE', 'ongoing', 'ONGOING']);
            })
            ->where(function ($query) use ($today) {
                $query->whereNull('end_date')
                    ->orWhereDate('end_date', '>=', $today);
            })
            ->orderByDesc('created_at')
            ->get();

        $reminders = HealthMedicationReminder::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->orderBy('reminder_time')
            ->get();

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

        $todayLogs = $logs->filter(fn ($log) => Carbon::parse($log->meal_date)->isToday());
        $dailyLogs = $todayLogs->isNotEmpty() ? $todayLogs : $logs->take(10);

        $totalSodium = $dailyLogs->sum(fn ($log) => $this->number($log->sodium));
        $totalPotassium = $dailyLogs->sum(fn ($log) => $this->number($log->potassium));
        $totalPhosphorus = $dailyLogs->sum(fn ($log) => $this->number($log->phosphorus));
        $totalProtein = $dailyLogs->sum(fn ($log) => $this->number($log->protein));

        $highestSodium = $logs->sortByDesc(fn ($log) => $this->number($log->sodium))->first();
        $insights = [];

        if ($highestSodium && $this->number($highestSodium->sodium) >= 400) {
            $insights[] = $this->insight(
                'nutrition_warning',
                $this->number($highestSodium->sodium) >= 600 || $totalSodium >= 1500 ? 'warning' : 'info',
                'High sodium food detected',
                sprintf(
                    '%s contains about %s mg sodium. High sodium intake can make kidney-friendly eating harder to control.',
                    $highestSodium->food_name,
                    number_format($this->number($highestSodium->sodium), 0)
                ),
                'Reduce salty snacks and processed foods, avoid adding table salt, and choose fresh lower-sodium options when possible.',
                'nutrition',
                [
                    'food_name' => $highestSodium->food_name,
                    'sodium_mg' => $this->round($highestSodium->sodium),
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
                sprintf(
                    'Recent logs show about %s mg potassium and %s mg phosphorus.',
                    number_format($totalPotassium, 0),
                    number_format($totalPhosphorus, 0)
                ),
                'Review high-potassium and high-phosphorus foods with your healthcare provider or renal dietitian.',
                'nutrition',
                [
                    'potassium_mg' => $this->round($totalPotassium),
                    'phosphorus_mg' => $this->round($totalPhosphorus),
                ]
            );
        }

        if ($totalSodium < 400 && $totalProtein <= 70 && $totalPotassium <= 2000 && $totalPhosphorus <= 800) {
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
            ->filter(fn ($log) => Carbon::parse($log->log_date)->isToday())
            ->sum(fn ($log) => $this->number($log->amount_ml));

        if ($todayTotal <= 0) {
            $latestDate = optional($logs->first()->log_date)->format('Y-m-d') ?: Carbon::parse($logs->first()->log_date)->toDateString();
            $todayTotal = $logs
                ->filter(fn ($log) => Carbon::parse($log->log_date)->toDateString() === $latestDate)
                ->sum(fn ($log) => $this->number($log->amount_ml));
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
        $latestWeight = $this->number($latest->weight_kg);
        $previousWeight = $this->number($previous->weight_kg);
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
        $averageSteps = $recent->avg(fn ($log) => $this->number($log->steps_count)) ?: 0;
        $latest = $logs->first();
        $goal = $this->number($latest->goal_steps) ?: 6000;

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
            $value = $this->number($latest->{$field});
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

        if ($this->number($latest->egfr) > 0 && $this->number($latest->egfr) < 30) {
            $insights[] = $this->insight(
                'lab_result_trend',
                'warning',
                'eGFR result needs follow-up',
                sprintf('Your latest eGFR value is %s.', number_format($this->number($latest->egfr), 2)),
                'Discuss this result with your nephrologist or healthcare provider for personalized guidance.',
                'labs',
                ['marker' => 'egfr', 'value' => $this->round($latest->egfr)]
            );
        }

        if ($this->number($latest->hemoglobin) > 0 && $this->number($latest->hemoglobin) < 12) {
            $insights[] = $this->insight(
                'lab_result_trend',
                'info',
                'Hemoglobin may need monitoring',
                sprintf('Your latest hemoglobin value is %s.', number_format($this->number($latest->hemoglobin), 2)),
                'Keep monitoring this value and review it with your healthcare provider, especially if you feel tired or dizzy.',
                'labs',
                ['marker' => 'hemoglobin', 'value' => $this->round($latest->hemoglobin)]
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

        $recentSodium = $nutritionLogs->take(10)->sum(fn ($log) => $this->number($log->sodium));
        $latestLab = $labTests->first();
        $potassium = $latestLab ? $this->number($latestLab->potassium) : 0;
        $phosphorus = $latestLab ? $this->number($latestLab->phosphorus) : 0;

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
}

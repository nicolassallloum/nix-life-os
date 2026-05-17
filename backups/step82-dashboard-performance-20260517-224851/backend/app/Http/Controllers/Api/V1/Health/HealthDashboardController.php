<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HealthDashboardController extends Controller
{
    public function summary(Request $request)
    {
        $user = $request->user();
        $userId = $user->id;
        $today = now()->toDateString();

        $steps = $this->buildStepsSummary($userId, $today);
        $weight = $this->buildWeightSummary($userId);
        $nutrition = $this->buildNutritionSummary($userId, $today);
        $hydration = $this->buildHydrationSummary($userId, $today);
        $sleep = $this->buildSleepSummary($userId);
        $mood = $this->buildMoodSummary($userId);
        $medications = $this->buildMedicationSummary($userId);
        $labTests = $this->buildLabTestSummary($userId);
        $alerts = $this->buildAlertSummary($userId);

        return response()->json([
            'success' => true,
            'message' => 'Health dashboard loaded successfully.',
            'data' => [
                'date' => $today,
                'steps' => $steps,
                'weight' => $weight,
                'nutrition' => $nutrition,
                'hydration' => $hydration,
                'sleep' => $sleep,
                'mood' => $mood,
                'medications' => $medications,
                'lab_tests' => $labTests,
                'alerts' => $alerts,
            ],
        ]);
    }

    private function buildStepsSummary(string $userId, string $today): array
    {
        $default = [
            'today_steps' => 0,
            'goal_steps' => 10000,
            'progress_percent' => 0,
            'goal_completed' => false,
            'latest_log_date' => null,
        ];

        if (! Schema::hasTable('health_step_log')) {
            return $default;
        }

        $profileGoal = 10000;

        if (Schema::hasTable('health_profile')) {
            $profile = DB::table('health_profile')
                ->where('user_id', $userId)
                ->first();

            if ($profile && isset($profile->daily_steps_goal)) {
                $profileGoal = (int) $profile->daily_steps_goal;
            }
        }

        $todayLog = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->whereDate('log_date', $today)
            ->first();

        $latestLog = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->orderByDesc('log_date')
            ->first();

        $steps = (int) ($todayLog->steps_count ?? 0);
        $goal = (int) ($todayLog->goal_steps ?? $profileGoal);

        return [
            'today_steps' => $steps,
            'goal_steps' => $goal,
            'progress_percent' => $goal > 0 ? round(($steps / $goal) * 100, 2) : 0,
            'goal_completed' => $goal > 0 && $steps >= $goal,
            'latest_log_date' => $latestLog?->log_date,
        ];
    }

    private function buildWeightSummary(string $userId): array
    {
        $default = [
            'latest_weight_kg' => null,
            'target_weight_kg' => null,
            'latest_date' => null,
            'bmi' => null,
            'trend_direction' => 'no_data',
        ];

        if (! Schema::hasTable('health_weight_logs')) {
            return $default;
        }

        $logs = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->orderBy('log_date')
            ->get();

        if ($logs->isEmpty()) {
            return $default;
        }

        $first = $logs->first();
        $latest = $logs->last();
        $change = ((float) $latest->weight_kg) - ((float) $first->weight_kg);

        return [
            'latest_weight_kg' => (float) $latest->weight_kg,
            'target_weight_kg' => null,
            'latest_date' => $latest->log_date,
            'bmi' => $latest->bmi !== null ? (float) $latest->bmi : null,
            'trend_direction' => match (true) {
                $change > 0 => 'increasing',
                $change < 0 => 'decreasing',
                default => 'stable',
            },
        ];
    }

    private function buildNutritionSummary(string $userId, string $today): array
    {
        $summary = [
            'calories' => 0,
            'protein_g' => 0,
            'sodium_mg' => 0,
            'potassium_mg' => 0,
            'phosphorus_mg' => 0,
            'warnings' => [],
        ];

        if (Schema::hasTable('health_nutrition_logs')) {
            $row = DB::table('health_nutrition_logs')
                ->where('user_id', $userId)
                ->whereDate('meal_date', $today)
                ->selectRaw('
                    COALESCE(SUM(calories), 0) as calories,
                    COALESCE(SUM(protein), 0) as protein_g,
                    COALESCE(SUM(sodium), 0) as sodium_mg,
                    COALESCE(SUM(potassium), 0) as potassium_mg,
                    COALESCE(SUM(phosphorus), 0) as phosphorus_mg
                ')
                ->first();

            if ($row) {
                $summary['calories'] += (float) $row->calories;
                $summary['protein_g'] += (float) $row->protein_g;
                $summary['sodium_mg'] += (float) $row->sodium_mg;
                $summary['potassium_mg'] += (float) $row->potassium_mg;
                $summary['phosphorus_mg'] += (float) $row->phosphorus_mg;
            }
        }

        if (Schema::hasTable('health_meal_logs')) {
            $row = DB::table('health_meal_logs')
                ->where('user_id', $userId)
                ->whereDate('meal_date', $today)
                ->selectRaw('
                    COALESCE(SUM(total_calories), 0) as calories,
                    COALESCE(SUM(total_protein_g), 0) as protein_g,
                    COALESCE(SUM(total_sodium_mg), 0) as sodium_mg,
                    COALESCE(SUM(total_potassium_mg), 0) as potassium_mg,
                    COALESCE(SUM(total_phosphorus_mg), 0) as phosphorus_mg
                ')
                ->first();

            if ($row) {
                $summary['calories'] += (float) $row->calories;
                $summary['protein_g'] += (float) $row->protein_g;
                $summary['sodium_mg'] += (float) $row->sodium_mg;
                $summary['potassium_mg'] += (float) $row->potassium_mg;
                $summary['phosphorus_mg'] += (float) $row->phosphorus_mg;
            }
        }

        $summary['warnings'] = $this->buildNutritionWarnings($summary);

        return $summary;
    }

    private function buildHydrationSummary(string $userId, string $today): array
    {
        $goalMl = 1500;

        if (! Schema::hasTable('health_hydration_logs')) {
            return [
                'today_ml' => 0,
                'goal_ml' => $goalMl,
                'progress_percent' => 0,
                'entries_count' => 0,
            ];
        }

        $row = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', $today)
            ->selectRaw('COALESCE(SUM(amount_ml), 0) as total_ml, COUNT(*) as entries_count')
            ->first();

        $totalMl = (float) ($row->total_ml ?? 0);

        return [
            'today_ml' => $totalMl,
            'goal_ml' => $goalMl,
            'progress_percent' => $goalMl > 0 ? round(($totalMl / $goalMl) * 100, 2) : 0,
            'entries_count' => (int) ($row->entries_count ?? 0),
        ];
    }

    private function buildSleepSummary(string $userId): array
    {
        $default = [
            'latest_sleep_hours' => null,
            'sleep_quality' => null,
            'latest_date' => null,
            'weekly_average_hours' => 0,
        ];

        if (! Schema::hasTable('health_sleep_logs')) {
            return $default;
        }

        $latest = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->orderByDesc('sleep_date')
            ->first();

        $weekStart = now()->subDays(6)->toDateString();

        $weeklyAverageMinutes = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->whereDate('sleep_date', '>=', $weekStart)
            ->avg('duration_minutes');

        return [
            'latest_sleep_hours' => $latest ? round(((float) $latest->duration_minutes) / 60, 2) : null,
            'sleep_quality' => $latest?->quality_score,
            'latest_date' => $latest?->sleep_date,
            'weekly_average_hours' => $weeklyAverageMinutes ? round(((float) $weeklyAverageMinutes) / 60, 2) : 0,
        ];
    }

    private function buildMoodSummary(string $userId): array
    {
        $default = [
            'latest_mood' => null,
            'mood_score' => null,
            'latest_date' => null,
        ];

        if (! Schema::hasTable('health_mood_logs')) {
            return $default;
        }

        $latest = DB::table('health_mood_logs')
            ->where('user_id', $userId)
            ->orderByDesc('mood_date')
            ->first();

        if (! $latest) {
            return $default;
        }

        return [
            'latest_mood' => $latest->mood_label,
            'mood_score' => (int) $latest->mood_score,
            'latest_date' => $latest->mood_date,
        ];
    }

    private function buildMedicationSummary(string $userId): array
    {
        $summary = [
            'active_count' => 0,
            'today_pending_count' => 0,
            'today_taken_count' => 0,
            'today_skipped_count' => 0,
        ];

        if (Schema::hasTable('health_medications')) {
            $summary['active_count'] = DB::table('health_medications')
                ->where('user_id', $userId)
                ->where('status', 'active')
                ->whereNull('deleted_at')
                ->count();
        }

        if (Schema::hasTable('health_medication_dose_logs')) {
            $today = now()->toDateString();

            $logs = DB::table('health_medication_dose_logs')
                ->where('user_id', $userId)
                ->whereDate('scheduled_for', $today)
                ->selectRaw("
                    COALESCE(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END), 0) as pending_count,
                    COALESCE(SUM(CASE WHEN status IN ('taken', 'late') THEN 1 ELSE 0 END), 0) as taken_count,
                    COALESCE(SUM(CASE WHEN status = 'skipped' THEN 1 ELSE 0 END), 0) as skipped_count
                ")
                ->first();

            $summary['today_pending_count'] = (int) ($logs->pending_count ?? 0);
            $summary['today_taken_count'] = (int) ($logs->taken_count ?? 0);
            $summary['today_skipped_count'] = (int) ($logs->skipped_count ?? 0);
        }

        return $summary;
    }

    private function buildLabTestSummary(string $userId): array
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return [
                'latest' => [],
                'abnormal_count' => 0,
            ];
        }

        $latest = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->orderByDesc('test_date')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get();

        $abnormalCount = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->where('is_abnormal', true)
            ->count();

        return [
            'latest' => $latest,
            'abnormal_count' => $abnormalCount,
        ];
    }

    private function buildAlertSummary(string $userId): array
    {
        if (! Schema::hasTable('health_alerts')) {
            return [
                'active_count' => 0,
                'critical_count' => 0,
                'warning_count' => 0,
                'unread_count' => 0,
            ];
        }

        return [
            'active_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->count(),
            'critical_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'critical')->count(),
            'warning_count' => DB::table('health_alerts')->where('user_id', $userId)->where('status', 'active')->where('severity', 'warning')->count(),
            'unread_count' => DB::table('health_alerts')->where('user_id', $userId)->whereNull('read_at')->count(),
        ];
    }

    private function buildNutritionWarnings(array $summary): array
    {
        $limits = [
            'protein_g' => ['label' => 'Protein', 'limit' => 45],
            'sodium_mg' => ['label' => 'Sodium', 'limit' => 2000],
            'potassium_mg' => ['label' => 'Potassium', 'limit' => 2000],
            'phosphorus_mg' => ['label' => 'Phosphorus', 'limit' => 800],
        ];

        $warnings = [];

        foreach ($limits as $key => $config) {
            $value = (float) ($summary[$key] ?? 0);
            $limit = (float) $config['limit'];

            if ($limit <= 0) {
                continue;
            }

            $percent = ($value / $limit) * 100;

            if ($percent >= 100) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $config['label'],
                    'status' => 'exceeded',
                    'message' => "{$config['label']} limit exceeded.",
                    'percentage' => round($percent, 2),
                ];
            } elseif ($percent >= 80) {
                $warnings[] = [
                    'nutrient' => $key,
                    'label' => $config['label'],
                    'status' => 'warning',
                    'message' => "{$config['label']} is close to daily limit.",
                    'percentage' => round($percent, 2),
                ];
            }
        }

        return $warnings;
    }
}

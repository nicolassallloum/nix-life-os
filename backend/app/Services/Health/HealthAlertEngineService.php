<?php

namespace App\Services\Health;

use App\Models\HealthAlert;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class HealthAlertEngineService
{
    public function runForUser(string $userId, ?string $date = null): array
    {
        $date = $date ? Carbon::parse($date)->toDateString() : now()->toDateString();

        $created = [];

        $checks = [
            $this->checkHighSodium($userId, $date),
            $this->checkHighPotassium($userId, $date),
            $this->checkHighPhosphorus($userId, $date),
            $this->checkLowHydration($userId, $date),
            $this->checkRapidWeightChange($userId, $date),
            $this->checkMissedMedication($userId, $date),
            $this->checkAbnormalLabResults($userId, $date),
            $this->checkLowStepActivity($userId, $date),
            $this->checkPoorSleepTrend($userId, $date),
            $this->checkRepeatedPatterns($userId, $date),
        ];

        foreach ($checks as $alert) {
            if ($alert) {
                $created[] = $alert;
            }
        }

        return $created;
    }

    private function createAlertOnce(array $data): ?HealthAlert
    {
        if (!Schema::hasTable('health_alerts')) {
            return null;
        }

        $exists = HealthAlert::where('user_id', $data['user_id'])
            ->where('alert_type', $data['alert_type'])
            ->whereDate('alert_date', $data['alert_date'])
            ->where('source_table', $data['source_table'] ?? null)
            ->where('source_id', $data['source_id'] ?? null)
            ->whereIn('status', ['active', 'read'])
            ->exists();

        if ($exists) {
            return null;
        }

        return HealthAlert::create($data);
    }

    private function checkHighSodium(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_nutrition_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_nutrition_logs', ['meal_date', 'log_date', 'date', 'created_at']);
        $sodiumColumn = $this->firstExistingColumn('health_nutrition_logs', ['sodium_mg', 'sodium']);

        if (!$dateColumn || !$sodiumColumn) {
            return null;
        }

        $total = DB::table('health_nutrition_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($sodiumColumn);

        if ($total < 1800) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'HIGH_SODIUM',
            'category' => 'nutrition',
            'severity' => $total >= 2300 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'High sodium intake detected',
            'message' => "Your sodium intake reached {$total} mg today.",
            'alert_date' => $date,
            'source_table' => 'health_nutrition_logs',
            'metadata' => [
                'total_sodium' => $total,
                'warning_threshold' => 1800,
                'critical_threshold' => 2300,
            ],
        ]);
    }

    private function checkHighPotassium(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_nutrition_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_nutrition_logs', ['meal_date', 'log_date', 'date', 'created_at']);
        $potassiumColumn = $this->firstExistingColumn('health_nutrition_logs', ['potassium_mg', 'potassium']);

        if (!$dateColumn || !$potassiumColumn) {
            return null;
        }

        $total = DB::table('health_nutrition_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($potassiumColumn);

        if ($total < 2000) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'HIGH_POTASSIUM',
            'category' => 'nutrition',
            'severity' => $total >= 2500 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'High potassium intake detected',
            'message' => "Your potassium intake reached {$total} mg today.",
            'alert_date' => $date,
            'source_table' => 'health_nutrition_logs',
            'metadata' => [
                'total_potassium' => $total,
                'warning_threshold' => 2000,
                'critical_threshold' => 2500,
            ],
        ]);
    }

    private function checkHighPhosphorus(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_nutrition_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_nutrition_logs', ['meal_date', 'log_date', 'date', 'created_at']);
        $phosphorusColumn = $this->firstExistingColumn('health_nutrition_logs', ['phosphorus_mg', 'phosphorus']);

        if (!$dateColumn || !$phosphorusColumn) {
            return null;
        }

        $total = DB::table('health_nutrition_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($phosphorusColumn);

        if ($total < 800) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'HIGH_PHOSPHORUS',
            'category' => 'nutrition',
            'severity' => $total >= 1000 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'High phosphorus intake detected',
            'message' => "Your phosphorus intake reached {$total} mg today.",
            'alert_date' => $date,
            'source_table' => 'health_nutrition_logs',
            'metadata' => [
                'total_phosphorus' => $total,
                'warning_threshold' => 800,
                'critical_threshold' => 1000,
            ],
        ]);
    }

    private function checkLowHydration(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_hydration_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_hydration_logs', ['log_date', 'hydration_date', 'date', 'created_at']);
        $amountColumn = $this->firstExistingColumn('health_hydration_logs', ['amount_ml', 'water_ml', 'quantity_ml']);

        if (!$dateColumn || !$amountColumn) {
            return null;
        }

        $goalMl = 2000;

        $total = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($amountColumn);

        $percent = $goalMl > 0 ? ($total / $goalMl) * 100 : 0;

        if ($percent >= 70) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'LOW_HYDRATION',
            'category' => 'hydration',
            'severity' => $percent < 40 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'Low hydration detected',
            'message' => "You consumed {$total} ml of water today.",
            'alert_date' => $date,
            'source_table' => 'health_hydration_logs',
            'metadata' => [
                'total_water_ml' => $total,
                'goal_ml' => $goalMl,
                'goal_percent' => round($percent, 2),
            ],
        ]);
    }

    private function checkRapidWeightChange(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_weight_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_weight_logs', ['log_date', 'weight_date', 'date', 'created_at']);
        $weightColumn = $this->firstExistingColumn('health_weight_logs', ['weight_kg', 'weight']);

        if (!$dateColumn || !$weightColumn) {
            return null;
        }

        $latest = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, '<=', $date)
            ->orderByDesc($dateColumn)
            ->first();

        if (!$latest) {
            return null;
        }

        $previous = DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, '<=', Carbon::parse($date)->subDays(3)->toDateString())
            ->orderByDesc($dateColumn)
            ->first();

        if (!$previous) {
            return null;
        }

        $difference = round($latest->{$weightColumn} - $previous->{$weightColumn}, 2);

        if (abs($difference) < 1.5) {
            return null;
        }

        $type = $difference > 0 ? 'RAPID_WEIGHT_GAIN' : 'RAPID_WEIGHT_LOSS';
        $title = $difference > 0 ? 'Rapid weight increase detected' : 'Rapid weight decrease detected';

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => $type,
            'category' => 'weight',
            'severity' => abs($difference) >= 2.5 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => $title,
            'message' => "Your weight changed by {$difference} kg within the recent period.",
            'alert_date' => $date,
            'source_table' => 'health_weight_logs',
            'source_id' => $latest->id ?? null,
            'metadata' => [
                'difference_kg' => $difference,
                'latest_weight' => $latest->{$weightColumn},
                'previous_weight' => $previous->{$weightColumn},
            ],
        ]);
    }

    private function checkMissedMedication(string $userId, string $date): ?HealthAlert
    {
        $table = $this->firstExistingTable([
            'health_medication_doses',
            'medication_doses',
            'health_medication_reminder_doses',
        ]);

        if (!$table) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn($table, ['scheduled_at', 'dose_time', 'reminder_time', 'created_at']);
        $statusColumn = $this->firstExistingColumn($table, ['status']);

        if (!$dateColumn || !$statusColumn) {
            return null;
        }

        $missedCount = DB::table($table)
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->whereIn($statusColumn, ['missed', 'pending'])
            ->count();

        if ($missedCount === 0) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'MISSED_MEDICATION',
            'category' => 'medication',
            'severity' => $missedCount >= 2 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'Missed medication dose detected',
            'message' => "You have {$missedCount} missed medication dose(s).",
            'alert_date' => $date,
            'source_table' => $table,
            'metadata' => [
                'missed_count' => $missedCount,
            ],
        ]);
    }

    private function checkAbnormalLabResults(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_lab_tests')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_lab_tests', ['test_date', 'lab_date', 'created_at']);
        $valueColumn = $this->firstExistingColumn('health_lab_tests', ['result_value', 'value', 'result']);

        if (!$dateColumn || !$valueColumn) {
            return null;
        }

        $minColumn = $this->firstExistingColumn('health_lab_tests', ['normal_min', 'min_value', 'reference_min']);
        $maxColumn = $this->firstExistingColumn('health_lab_tests', ['normal_max', 'max_value', 'reference_max']);

        if (!$minColumn || !$maxColumn) {
            return null;
        }

        $result = DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->where(function ($query) use ($valueColumn, $minColumn, $maxColumn) {
                $query->whereColumn($valueColumn, '<', $minColumn)
                    ->orWhereColumn($valueColumn, '>', $maxColumn);
            })
            ->first();

        if (!$result) {
            return null;
        }

        $testName = $result->test_name ?? $result->name ?? 'Lab test';

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'ABNORMAL_LAB_RESULT',
            'category' => 'lab_test',
            'severity' => 'critical',
            'status' => 'active',
            'title' => 'Abnormal lab result detected',
            'message' => "{$testName} result is outside the configured normal range.",
            'alert_date' => $date,
            'source_table' => 'health_lab_tests',
            'source_id' => $result->id ?? null,
            'metadata' => [
                'test_name' => $testName,
                'result_value' => $result->{$valueColumn},
                'normal_min' => $result->{$minColumn},
                'normal_max' => $result->{$maxColumn},
            ],
        ]);
    }

    private function checkLowStepActivity(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_step_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_step_logs', ['log_date', 'step_date', 'date', 'created_at']);
        $stepsColumn = $this->firstExistingColumn('health_step_logs', ['steps', 'step_count', 'total_steps']);

        if (!$dateColumn || !$stepsColumn) {
            return null;
        }

        $goal = 6000;

        $total = DB::table('health_step_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($stepsColumn);

        if ($total >= ($goal * 0.5)) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'LOW_STEP_ACTIVITY',
            'category' => 'activity',
            'severity' => $total < ($goal * 0.25) ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'Low step activity detected',
            'message' => "You recorded {$total} steps today.",
            'alert_date' => $date,
            'source_table' => 'health_step_logs',
            'metadata' => [
                'steps' => $total,
                'goal' => $goal,
            ],
        ]);
    }

    private function checkPoorSleepTrend(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_sleep_logs')) {
            return null;
        }

        $dateColumn = $this->firstExistingColumn('health_sleep_logs', ['sleep_date', 'log_date', 'date', 'created_at']);
        $hoursColumn = $this->firstExistingColumn('health_sleep_logs', ['hours', 'sleep_hours', 'duration_hours', 'total_hours']);

        if (!$dateColumn || !$hoursColumn) {
            return null;
        }

        $hours = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->whereDate($dateColumn, $date)
            ->sum($hoursColumn);

        if ($hours >= 6 || $hours <= 0) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'POOR_SLEEP_TREND',
            'category' => 'sleep',
            'severity' => $hours < 4 ? 'critical' : 'warning',
            'status' => 'active',
            'title' => 'Poor sleep detected',
            'message' => "You slept {$hours} hours.",
            'alert_date' => $date,
            'source_table' => 'health_sleep_logs',
            'metadata' => [
                'sleep_hours' => $hours,
            ],
        ]);
    }

    private function checkRepeatedPatterns(string $userId, string $date): ?HealthAlert
    {
        if (!Schema::hasTable('health_alerts')) {
            return null;
        }

        $startDate = Carbon::parse($date)->subDays(6)->toDateString();

        $pattern = HealthAlert::where('user_id', $userId)
            ->whereBetween('alert_date', [$startDate, $date])
            ->whereIn('alert_type', [
                'HIGH_SODIUM',
                'HIGH_POTASSIUM',
                'HIGH_PHOSPHORUS',
                'LOW_HYDRATION',
                'MISSED_MEDICATION',
                'LOW_STEP_ACTIVITY',
                'POOR_SLEEP_TREND',
            ])
            ->select('alert_type', DB::raw('COUNT(*) as total'))
            ->groupBy('alert_type')
            ->havingRaw('COUNT(*) >= 3')
            ->first();

        if (!$pattern) {
            return null;
        }

        return $this->createAlertOnce([
            'user_id' => $userId,
            'alert_type' => 'REPEATED_UNHEALTHY_PATTERN',
            'category' => 'pattern',
            'severity' => 'warning',
            'status' => 'active',
            'title' => 'Repeated unhealthy pattern detected',
            'message' => "{$pattern->alert_type} occurred {$pattern->total} times during the last 7 days.",
            'alert_date' => $date,
            'source_table' => 'health_alerts',
            'metadata' => [
                'repeated_alert_type' => $pattern->alert_type,
                'count_7_days' => $pattern->total,
            ],
        ]);
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
        if (!Schema::hasTable($table)) {
            return null;
        }

        foreach ($columns as $column) {
            if (Schema::hasColumn($table, $column)) {
                return $column;
            }
        }

        return null;
    }
}
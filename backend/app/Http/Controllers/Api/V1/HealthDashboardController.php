<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class HealthDashboardController extends Controller
{
    private function columns(string $schema, string $table): array
    {
        return DB::table('information_schema.columns')
            ->where('table_schema', $schema)
            ->where('table_name', $table)
            ->pluck('column_name')
            ->toArray();
    }

    private function firstExistingColumn(array $columns, array $candidates): ?string
    {
        foreach ($candidates as $candidate) {
            if (in_array($candidate, $columns, true)) {
                return $candidate;
            }
        }

        return null;
    }

    public function summary(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthenticated.',
                ], 401);
            }

            $userId = (string) $user->id;
            $today = now()->toDateString();

            /*
            |--------------------------------------------------------------------------
            | Steps
            |--------------------------------------------------------------------------
            */
            $stepColumns = $this->columns('nix_life_os', 'health_step_log');

            $stepDateColumn = $this->firstExistingColumn($stepColumns, [
                'log_date',
                'entry_date',
                'step_date',
                'date',
                'created_at',
            ]);

            $stepValueColumn = $this->firstExistingColumn($stepColumns, [
                'steps',
                'step_count',
                'steps_count',
                'total_steps',
                'daily_steps',
                'value',
                'count',
            ]);

            $todaySteps = 0;

            if ($stepDateColumn && $stepValueColumn) {
                $todaySteps = DB::table('nix_life_os.health_step_log')
                    ->where('user_id', $userId)
                    ->whereDate($stepDateColumn, $today)
                    ->sum($stepValueColumn);
            }

            /*
            |--------------------------------------------------------------------------
            | Hydration
            |--------------------------------------------------------------------------
            */
            $hydrationColumns = $this->columns('public', 'health_hydration_logs');

            $hydrationDateColumn = $this->firstExistingColumn($hydrationColumns, [
                'log_date',
                'entry_date',
                'hydration_date',
                'date',
                'created_at',
            ]);

            $hydrationValueColumn = $this->firstExistingColumn($hydrationColumns, [
                'amount_ml',
                'water_ml',
                'quantity_ml',
                'ml',
                'amount',
            ]);

            $todayWater = 0;

            if ($hydrationDateColumn && $hydrationValueColumn) {
                $todayWater = DB::table('public.health_hydration_logs')
                    ->where('user_id', $userId)
                    ->whereDate($hydrationDateColumn, $today)
                    ->sum($hydrationValueColumn);
            }

            /*
            |--------------------------------------------------------------------------
            | Weight
            |--------------------------------------------------------------------------
            */
            $weightColumns = $this->columns('public', 'health_weight_logs');

            $weightDateColumn = $this->firstExistingColumn($weightColumns, [
                'log_date',
                'entry_date',
                'weight_date',
                'date',
                'created_at',
            ]);

            $weightColumn = $this->firstExistingColumn($weightColumns, [
                'weight_kg',
                'weight',
                'kg',
            ]);

            $currentWeight = 0;

            if ($weightDateColumn && $weightColumn) {
                $currentWeight = DB::table('public.health_weight_logs')
                    ->where('user_id', $userId)
                    ->orderByDesc($weightDateColumn)
                    ->value($weightColumn);
            }

            /*
            |--------------------------------------------------------------------------
            | Sleep
            |--------------------------------------------------------------------------
            */
            $sleepColumns = $this->columns('public', 'health_sleep_logs');

            $sleepDateColumn = $this->firstExistingColumn($sleepColumns, [
                'sleep_date',
                'entry_date',
                'log_date',
                'date',
                'created_at',
            ]);

            $sleepDurationColumn = $this->firstExistingColumn($sleepColumns, [
                'duration_minutes',
                'sleep_minutes',
                'minutes',
                'duration_hours',
                'hours',
            ]);

            $lastSleepValue = 0;
            $lastSleepHours = 0;

            if ($sleepDateColumn && $sleepDurationColumn) {
                $lastSleepValue = DB::table('public.health_sleep_logs')
                    ->where('user_id', $userId)
                    ->orderByDesc($sleepDateColumn)
                    ->value($sleepDurationColumn);

                if ($sleepDurationColumn === 'duration_minutes' || str_contains($sleepDurationColumn, 'minutes')) {
                    $lastSleepHours = $lastSleepValue ? round($lastSleepValue / 60, 2) : 0;
                } else {
                    $lastSleepHours = $lastSleepValue ? (float) $lastSleepValue : 0;
                }
            }

            /*
            |--------------------------------------------------------------------------
            | Mood
            |--------------------------------------------------------------------------
            */
            $moodColumns = $this->columns('public', 'health_mood_logs');

            $moodDateColumn = $this->firstExistingColumn($moodColumns, [
                'mood_date',
                'entry_date',
                'log_date',
                'date',
                'created_at',
            ]);

            $moodColumn = $this->firstExistingColumn($moodColumns, [
                'mood_label',
                'mood',
                'label',
                'status',
            ]);

            $todayMood = '-';

            if ($moodDateColumn && $moodColumn) {
                $todayMood = DB::table('public.health_mood_logs')
                    ->where('user_id', $userId)
                    ->whereDate($moodDateColumn, $today)
                    ->orderByDesc('created_at')
                    ->value($moodColumn) ?? '-';
            }

            /*
            |--------------------------------------------------------------------------
            | Medications
            |--------------------------------------------------------------------------
            */
            $activeMedications = DB::table('public.health_medications')
                ->where('user_id', $userId)
                ->where('status', 'active')
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'today_steps' => (int) $todaySteps,
                    'today_water_ml' => (int) $todayWater,
                    'current_weight_kg' => $currentWeight ? (float) $currentWeight : 0,
                    'last_sleep_hours' => $lastSleepHours,
                    'today_mood' => $todayMood,
                    'active_medications' => $activeMedications,
                ],
                // 'meta' => [
                //     'steps_column_used' => $stepValueColumn,
                //     'steps_date_column_used' => $stepDateColumn,
                //     'hydration_column_used' => $hydrationValueColumn,
                //     'hydration_date_column_used' => $hydrationDateColumn,
                //     'weight_column_used' => $weightColumn,
                //     'sleep_duration_column_used' => $sleepDurationColumn,
                //     'mood_column_used' => $moodColumn,
                // ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Health dashboard summary failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Health dashboard summary failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
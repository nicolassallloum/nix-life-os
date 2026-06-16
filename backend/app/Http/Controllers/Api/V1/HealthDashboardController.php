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
            $stepColumns = $this->columns('public', 'health_step_logs');

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
                $todaySteps = DB::table('public.health_step_logs')
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
            | Nutrition Today
            |--------------------------------------------------------------------------
            */
            $nutritionColumns = $this->columns('public', 'health_nutrition_logs');

            $nutritionDateColumn = $this->firstExistingColumn($nutritionColumns, [
                'meal_date',
                'log_date',
                'entry_date',
                'date',
                'created_at',
            ]);

            $todayCalories = 0;
            $todayProtein = 0;
            $todaySodium = 0;
            $todayPotassium = 0;
            $todayPhosphorus = 0;

            if ($nutritionDateColumn) {
                $nutritionQuery = DB::table('public.health_nutrition_logs')
                    ->where('user_id', $userId)
                    ->whereDate($nutritionDateColumn, $today);

                $todayCalories = in_array('calories', $nutritionColumns, true)
                    ? (clone $nutritionQuery)->sum('calories')
                    : 0;

                $todayProtein = in_array('protein_g', $nutritionColumns, true)
                    ? (clone $nutritionQuery)->sum('protein_g')
                    : ((in_array('protein', $nutritionColumns, true)) ? (clone $nutritionQuery)->sum('protein') : 0);

                $todaySodium = in_array('sodium_mg', $nutritionColumns, true)
                    ? (clone $nutritionQuery)->sum('sodium_mg')
                    : ((in_array('sodium', $nutritionColumns, true)) ? (clone $nutritionQuery)->sum('sodium') : 0);

                $todayPotassium = in_array('potassium_mg', $nutritionColumns, true)
                    ? (clone $nutritionQuery)->sum('potassium_mg')
                    : ((in_array('potassium', $nutritionColumns, true)) ? (clone $nutritionQuery)->sum('potassium') : 0);

                $todayPhosphorus = in_array('phosphorus_mg', $nutritionColumns, true)
                    ? (clone $nutritionQuery)->sum('phosphorus_mg')
                    : ((in_array('phosphorus', $nutritionColumns, true)) ? (clone $nutritionQuery)->sum('phosphorus') : 0);
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

            /*
            |--------------------------------------------------------------------------
            | User Goals
            |--------------------------------------------------------------------------
            */
            $goals = DB::table('public.health_user_goals')
                ->where('user_id', $userId)
                ->first();

            if (!$goals) {
                DB::table('public.health_user_goals')->insert([
                    'user_id' => $userId,
                    'daily_steps_goal' => 8000,
                    'daily_calories_goal' => 1800,
                    'daily_water_goal_ml' => 2000,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                $goals = DB::table('public.health_user_goals')
                    ->where('user_id', $userId)
                    ->first();
            }

            $percent = function ($value, $goal): int {
                if (!$goal || (float) $goal <= 0) {
                    return 0;
                }

                return min(100, (int) round(((float) $value / (float) $goal) * 100));
            };

            return response()->json([
                'success' => true,
                'data' => [
                    'today_steps' => (int) $todaySteps,
                    'today_water_ml' => (int) $todayWater,
                    'today_calories' => (int) $todayCalories,
                    'today_protein_g' => round((float) $todayProtein, 2),
                    'today_sodium_mg' => round((float) $todaySodium, 2),
                    'today_potassium_mg' => round((float) $todayPotassium, 2),
                    'today_phosphorus_mg' => round((float) $todayPhosphorus, 2),

                    'current_weight_kg' => $currentWeight ? (float) $currentWeight : 0,
                    'last_sleep_hours' => $lastSleepHours,
                    'today_mood' => $todayMood,
                    'active_medications' => $activeMedications,

                    'goals' => [
                        'daily_steps_goal' => (int) ($goals->daily_steps_goal ?? 8000),
                        'target_weight_kg' => $goals->target_weight_kg !== null ? (float) $goals->target_weight_kg : null,
                        'daily_calories_goal' => (int) ($goals->daily_calories_goal ?? 1800),
                        'daily_water_goal_ml' => (int) ($goals->daily_water_goal_ml ?? 2000),
                        'protein_limit_g' => $goals->protein_limit_g !== null ? (float) $goals->protein_limit_g : null,
                        'sodium_limit_mg' => $goals->sodium_limit_mg !== null ? (float) $goals->sodium_limit_mg : null,
                        'potassium_limit_mg' => $goals->potassium_limit_mg !== null ? (float) $goals->potassium_limit_mg : null,
                        'phosphorus_limit_mg' => $goals->phosphorus_limit_mg !== null ? (float) $goals->phosphorus_limit_mg : null,
                    ],

                    'progress' => [
                        'steps_percent' => $percent($todaySteps, $goals->daily_steps_goal ?? 8000),
                        'water_percent' => $percent($todayWater, $goals->daily_water_goal_ml ?? 2000),
                        'calories_percent' => $percent($todayCalories, $goals->daily_calories_goal ?? 1800),
                        'protein_percent' => $percent($todayProtein, $goals->protein_limit_g ?? null),
                        'sodium_percent' => $percent($todaySodium, $goals->sodium_limit_mg ?? null),
                        'potassium_percent' => $percent($todayPotassium, $goals->potassium_limit_mg ?? null),
                        'phosphorus_percent' => $percent($todayPhosphorus, $goals->phosphorus_limit_mg ?? null),
                    ],
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
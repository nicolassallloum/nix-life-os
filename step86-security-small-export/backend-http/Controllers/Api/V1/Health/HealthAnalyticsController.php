<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class HealthAnalyticsController extends Controller
{
    public function daily(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'target_date' => ['required', 'date'],
        ]);

        $targetDate = $validated['target_date'];

        $payload = [
            'user_id' => (string) $user->id,
            'target_date' => $targetDate,
            'profile' => $this->buildProfile($user),
            'weight_logs' => $this->getRecentWeightLogs($user->id, $targetDate),
            'nutrition' => $this->getNutritionSummary($user->id, $targetDate),
            'hydration' => $this->getHydrationSummary($user->id, $targetDate),
            'steps' => $this->getStepsSummary($user->id, $targetDate),
        ];

        try {
            $baseUrl = rtrim(config('services.health_analytics.url'), '/');

            $response = Http::timeout(15)
                ->acceptJson()
                ->post($baseUrl . '/api/v1/analytics/health/daily', $payload);

            if (!$response->successful()) {
                Log::error('Health analytics service failed', [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);

                return response()->json([
                    'success' => false,
                    'message' => 'Health analytics service returned an error.',
                    'details' => $response->json(),
                ], 502);
            }

            return response()->json([
                'success' => true,
                'message' => 'Health analytics generated successfully.',
                'data' => $response->json(),
            ]);

        } catch (\Throwable $e) {
            Log::error('Health analytics service unavailable', [
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Health analytics service is unavailable.',
                'error' => $e->getMessage(),
            ], 503);
        }
    }

    private function buildProfile($user): array
    {
        /*
         | You can later replace this with a real health_profiles table.
         | For now, these values match your known Step 10 CKD profile.
         */
        return [
            'weight_kg' => 64,
            'height_cm' => 155,
            'age' => 29,
            'gender' => 'male',
            'activity_level' => 'light',
            'ckd_safe_mode' => true,
            'sodium_limit_mg' => 2000,
            'fluid_min_ml' => 1500,
            'fluid_max_ml' => 2500,
        ];
    }

    private function getRecentWeightLogs(string $userId, string $targetDate): array
    {
        if (!DB::getSchemaBuilder()->hasTable('health_weight_logs')) {
            return [];
        }

        return DB::table('health_weight_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', '<=', $targetDate)
            ->orderByDesc('log_date')
            ->limit(14)
            ->get()
            ->reverse()
            ->values()
            ->map(function ($row) {
                return [
                    'log_date' => (string) $row->log_date,
                    'weight_kg' => (float) $row->weight_kg,
                ];
            })
            ->toArray();
    }

    private function getNutritionSummary(string $userId, string $targetDate): ?array
    {
        if (
            !DB::getSchemaBuilder()->hasTable('health_meal_logs') ||
            !DB::getSchemaBuilder()->hasTable('health_meal_log_items')
        ) {
            return null;
        }

        $row = DB::table('health_meal_logs as ml')
            ->join('health_meal_log_items as mli', 'mli.meal_log_id', '=', 'ml.id')
            ->where('ml.user_id', $userId)
            ->whereDate('ml.log_date', $targetDate)
            ->selectRaw('
                COALESCE(SUM(mli.calories), 0) as calories,
                COALESCE(SUM(mli.protein_g), 0) as protein_g,
                COALESCE(SUM(mli.carbs_g), 0) as carbs_g,
                COALESCE(SUM(mli.fat_g), 0) as fat_g,
                COALESCE(SUM(mli.sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(mli.potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(mli.phosphorus_mg), 0) as phosphorus_mg,
                COALESCE(SUM(mli.sugar_g), 0) as sugar_g,
                COALESCE(SUM(mli.fiber_g), 0) as fiber_g
            ')
            ->first();

        if (!$row) {
            return null;
        }

        return [
            'log_date' => $targetDate,
            'calories' => (float) $row->calories,
            'protein_g' => (float) $row->protein_g,
            'carbs_g' => (float) $row->carbs_g,
            'fat_g' => (float) $row->fat_g,
            'sodium_mg' => (float) $row->sodium_mg,
            'potassium_mg' => (float) $row->potassium_mg,
            'phosphorus_mg' => (float) $row->phosphorus_mg,
            'sugar_g' => (float) $row->sugar_g,
            'fiber_g' => (float) $row->fiber_g,
        ];
    }
    private function getHydrationSummary(string $userId, string $targetDate): ?array
    {
        if (!DB::getSchemaBuilder()->hasTable('health_hydration_logs')) {
            return null;
        }

        $row = DB::table('health_hydration_logs')
            ->where('user_id', $userId)
            ->whereDate('log_date', $targetDate)
            ->selectRaw('
                ? as log_date,
                COALESCE(SUM(amount_ml), 0) as total_fluids_ml,
                COALESCE(SUM(CASE WHEN LOWER(drink_type) = \'water\' THEN amount_ml ELSE 0 END), 0) as water_ml,
                COALESCE(SUM(CASE WHEN LOWER(drink_type) <> \'water\' THEN amount_ml ELSE 0 END), 0) as other_drinks_ml
            ', [$targetDate])
            ->first();

        if (!$row) {
            return null;
        }

        return [
            'log_date' => $targetDate,
            'total_fluids_ml' => (float) $row->total_fluids_ml,
            'water_ml' => (float) $row->water_ml,
            'other_drinks_ml' => (float) $row->other_drinks_ml,
        ];
    }

    private function getStepsSummary(string $userId, string $targetDate): ?array
    {
        if (!DB::getSchemaBuilder()->hasTable('health_step_log')) {
            return null;
        }

        $row = DB::table('health_step_log')
            ->where('user_id', $userId)
            ->whereDate('log_date', $targetDate)
            ->selectRaw('
                ? as log_date,
                COALESCE(SUM(steps_count), 0) as steps,
                COALESCE(SUM(distance_km), 0) as distance_km,
                COALESCE(SUM(active_minutes), 0) as active_minutes
            ', [$targetDate])
            ->first();

        if (!$row) {
            return null;
        }

        return [
            'log_date' => $targetDate,
            'steps' => (int) $row->steps,
            'distance_km' => (float) $row->distance_km,
            'active_minutes' => (int) $row->active_minutes,
        ];
    }
}

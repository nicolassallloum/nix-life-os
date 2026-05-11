<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class HealthDashboardController extends Controller
{
    public function summary(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Health dashboard loaded successfully.',
            'data' => [
                'steps' => [
                    'today_steps' => 0,
                    'goal_steps' => 10000,
                    'progress_percent' => 0,
                ],
                'weight' => [
                    'latest_weight_kg' => null,
                    'target_weight_kg' => null,
                ],
                'nutrition' => [
                    'calories' => 0,
                    'protein_g' => 0,
                    'sodium_mg' => 0,
                    'potassium_mg' => 0,
                    'phosphorus_mg' => 0,
                ],
                'hydration' => [
                    'today_ml' => 0,
                    'goal_ml' => 1500,
                    'progress_percent' => 0,
                ],
                'sleep' => [
                    'latest_sleep_hours' => null,
                    'sleep_quality' => null,
                ],
                'mood' => [
                    'latest_mood' => null,
                    'mood_score' => null,
                ],
                'medications' => [
                    'active_count' => 0,
                ],
                'lab_tests' => [
                    'latest' => [],
                ],
            ],
        ]);
    }
}
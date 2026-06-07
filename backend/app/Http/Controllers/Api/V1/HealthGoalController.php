<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthUserGoal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthGoalController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $goal = HealthUserGoal::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'daily_steps_goal' => 8000,
                'target_weight_kg' => null,
                'daily_calories_goal' => 1800,
                'daily_water_goal_ml' => 2000,
                'protein_limit_g' => null,
                'carbs_limit_g' => null,
                'fat_limit_g' => null,
                'sugar_limit_g' => null,
                'sodium_limit_mg' => null,
                'potassium_limit_mg' => null,
                'phosphorus_limit_mg' => null,
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $goal,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'daily_steps_goal' => ['nullable', 'integer', 'min:0', 'max:100000'],
            'target_weight_kg' => ['nullable', 'numeric', 'min:20', 'max:300'],
            'daily_calories_goal' => ['nullable', 'integer', 'min:500', 'max:10000'],
            'daily_water_goal_ml' => ['nullable', 'integer', 'min:0', 'max:10000'],

            'protein_limit_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'carbs_limit_g' => ['nullable', 'numeric', 'min:0', 'max:1000'],
            'fat_limit_g' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'sugar_limit_g' => ['nullable', 'numeric', 'min:0', 'max:500'],

            'sodium_limit_mg' => ['nullable', 'numeric', 'min:0', 'max:20000'],
            'potassium_limit_mg' => ['nullable', 'numeric', 'min:0', 'max:20000'],
            'phosphorus_limit_mg' => ['nullable', 'numeric', 'min:0', 'max:20000'],
        ]);

        $goal = HealthUserGoal::firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'daily_steps_goal' => 8000,
                'daily_calories_goal' => 1800,
                'daily_water_goal_ml' => 2000,
            ]
        );

        $goal->fill($validated);
        $goal->save();

        return response()->json([
            'success' => true,
            'message' => 'Health goals updated successfully.',
            'data' => $goal,
        ]);
    }
}

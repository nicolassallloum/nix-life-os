<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthNutritionProfileResource;
use App\Models\HealthNutritionProfile;
use Illuminate\Http\Request;

class HealthNutritionProfileController extends Controller
{
    public function index(Request $request)
    {
        $profile = HealthNutritionProfile::where('user_id', $request->user()->id)
            ->where('is_active', true)
            ->first();

        return response()->json([
            'success' => true,
            'data' => $profile ? new HealthNutritionProfileResource($profile) : null,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'profile_name' => ['nullable', 'string', 'max:255'],
            'daily_calories_min' => ['nullable', 'integer', 'min:0'],
            'daily_calories_max' => ['nullable', 'integer', 'min:0'],
            'daily_protein_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_carbs_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_fat_max_g' => ['nullable', 'numeric', 'min:0'],
            'daily_sodium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_potassium_max_mg' => ['nullable', 'numeric', 'min:0'],
            'daily_phosphorus_max_mg' => ['nullable', 'numeric', 'min:0'],
            'is_ckd_safe_mode' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
        ]);

        HealthNutritionProfile::where('user_id', $request->user()->id)
            ->update(['is_active' => false]);

        $profile = HealthNutritionProfile::create([
            ...$data,
            'user_id' => $request->user()->id,
            'profile_name' => $data['profile_name'] ?? 'CKD Daily Nutrition Profile',
            'is_active' => true,
            'is_ckd_safe_mode' => $data['is_ckd_safe_mode'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition profile saved successfully.',
            'data' => new HealthNutritionProfileResource($profile),
        ], 201);
    }
}
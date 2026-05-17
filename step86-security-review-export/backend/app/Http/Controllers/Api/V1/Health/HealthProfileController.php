<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthProfileResource;
use App\Http\Resources\HealthStepLogResource;
use App\Models\HealthProfile;
use Illuminate\Http\Request;

class HealthProfileController extends Controller
{
    public function show(Request $request)
    {
        $userId = $request->user()?->getKey();

        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'Authenticated user ID not found.',
            ], 401);
        }

        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $userId],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Health profile loaded successfully.',
            'data' => new HealthProfileResource($profile),
        ]);
    }

    public function update(Request $request)
    {
        $userId = $request->user()?->getKey();

        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'Authenticated user ID not found.',
            ], 401);
        }

        $validated = $request->validate([
            'daily_steps_goal' => ['required', 'integer', 'min:500', 'max:100000'],
            'stride_length_cm' => ['required', 'numeric', 'min:30', 'max:150'],
            'distance_unit' => ['nullable', 'string', 'in:km'],
        ]);

        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $userId],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        $profile->update([
            'daily_steps_goal' => $validated['daily_steps_goal'],
            'stride_length_cm' => $validated['stride_length_cm'],
            'distance_unit' => $validated['distance_unit'] ?? 'km',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Health profile updated successfully.',
            'data' => new HealthProfileResource($profile),
        ]);
    }
}
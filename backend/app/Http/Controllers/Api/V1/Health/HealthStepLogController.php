<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthStepLogResource;
use App\Models\HealthProfile;
use App\Models\HealthStepLog;
use Carbon\Carbon;
use Illuminate\Http\Request;

class HealthStepLogController extends Controller
{
    public function index(Request $request)
    {
        $userId = $this->getAuthenticatedUserId($request);

        if (!$userId) {
            return $this->unauthorizedResponse();
        }

        $days = (int) $request->query('days', 30);

        if ($days < 1 || $days > 365) {
            $days = 30;
        }

        $logs = HealthStepLog::where('user_id', $userId)
            ->whereDate('log_date', '>=', now()->subDays($days - 1)->toDateString())
            ->orderBy('log_date', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => "Last {$days} days step logs loaded successfully.",
            'data' => HealthStepLogResource::collection($logs),
        ]);
    }

    public function store(Request $request)
    {
        $userId = $this->getAuthenticatedUserId($request);

        if (!$userId) {
            return $this->unauthorizedResponse();
        }

        $validated = $request->validate([
            'log_date' => ['required', 'date'],
            'steps_count' => ['required', 'integer', 'min:0', 'max:200000'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $profile = HealthProfile::firstOrCreate(
            ['user_id' => $userId],
            [
                'daily_steps_goal' => 8000,
                'stride_length_cm' => 75.00,
                'distance_unit' => 'km',
            ]
        );

        $steps = (int) $validated['steps_count'];
        $goalSteps = (int) $profile->daily_steps_goal;

        $distanceKm = $this->calculateDistanceKm(
            $steps,
            (float) $profile->stride_length_cm
        );

        $goalPercentage = $this->calculateGoalPercentage($steps, $goalSteps);

        $log = HealthStepLog::updateOrCreate(
            [
                'user_id' => $userId,
                'log_date' => Carbon::parse($validated['log_date'])->toDateString(),
            ],
            [
                'steps_count' => $steps,
                'distance_km' => $distanceKm,
                'goal_steps' => $goalSteps,
                'goal_percentage' => $goalPercentage,
                'goal_completed' => $steps >= $goalSteps,
                'notes' => $validated['notes'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Step log saved successfully.',
            'data' => new HealthStepLogResource($log),
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $userId = $this->getAuthenticatedUserId($request);

        if (!$userId) {
            return $this->unauthorizedResponse();
        }

        $log = HealthStepLog::where('user_id', $userId)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Step log loaded successfully.',
            'data' => new HealthStepLogResource($log),
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $userId = $this->getAuthenticatedUserId($request);

        if (!$userId) {
            return $this->unauthorizedResponse();
        }

        $log = HealthStepLog::where('user_id', $userId)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Step log deleted successfully.',
        ]);
    }

    public function summary(Request $request)
    {
        $userId = $this->getAuthenticatedUserId($request);

        if (!$userId) {
            return $this->unauthorizedResponse();
        }

        $days = (int) $request->query('days', 30);

        if ($days < 1 || $days > 365) {
            $days = 30;
        }

        $logs = HealthStepLog::where('user_id', $userId)
            ->whereDate('log_date', '>=', now()->subDays($days - 1)->toDateString())
            ->get();

        $totalSteps = (int) $logs->sum('steps_count');
        $totalDistance = (float) $logs->sum('distance_km');
        $completedDays = $logs->where('goal_completed', true)->count();
        $loggedDays = $logs->count();

        return response()->json([
            'success' => true,
            'message' => 'Steps summary loaded successfully.',
            'data' => [
                'days_range' => $days,
                'logged_days' => $loggedDays,
                'total_steps' => $totalSteps,
                'average_steps' => $loggedDays > 0 ? round($totalSteps / $loggedDays) : 0,
                'total_distance_km' => round($totalDistance, 3),
                'average_distance_km' => $loggedDays > 0 ? round($totalDistance / $loggedDays, 3) : 0,
                'goal_completed_days' => $completedDays,
                'goal_completion_rate' => $loggedDays > 0
                    ? round(($completedDays / $loggedDays) * 100, 2)
                    : 0,
            ],
        ]);
    }

    private function getAuthenticatedUserId(Request $request): ?string
    {
        $user = $request->user();

        if (!$user) {
            return null;
        }

        return $user->getKey();
    }

    private function unauthorizedResponse()
    {
        return response()->json([
            'success' => false,
            'message' => 'Authenticated user ID not found.',
        ], 401);
    }

    private function calculateDistanceKm(int $steps, float $strideLengthCm): float
    {
        return round(($steps * $strideLengthCm) / 100000, 3);
    }

    private function calculateGoalPercentage(int $steps, int $goalSteps): float
    {
        if ($goalSteps <= 0) {
            return 0;
        }

        return round(($steps / $goalSteps) * 100, 2);
    }
}
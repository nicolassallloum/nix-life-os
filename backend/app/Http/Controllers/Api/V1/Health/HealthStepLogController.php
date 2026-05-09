<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthProfile;
use App\Models\HealthStepLog;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HealthStepLogController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $logs = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereDate('log_date', '>=', now()->subDays(30)->toDateString())
            ->orderByDesc('log_date')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Steps logs retrieved successfully.',
            'data' => $logs,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'steps_count' => ['required', 'integer', 'min:0', 'max:200000'],
            'log_date' => ['required', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $logDate = Carbon::parse($validated['log_date'])->toDateString();

        $existingLog = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereDate('log_date', $logDate)
            ->first();

        if ($existingLog) {
            return response()->json([
                'success' => false,
                'message' => 'A step log already exists for this date. Please edit the existing log.',
                'errors' => [
                    'log_date' => ['A step log already exists for this date.'],
                ],
            ], 422);
        }

        $profile = $this->getOrCreateHealthProfile($user->id);

        $steps = (int) $validated['steps_count'];
        $goalSteps = (int) ($profile->daily_steps_goal ?? 10000);
        $strideLengthCm = (float) ($profile->stride_length_cm ?? 75);

        $distanceKm = $this->calculateDistanceKm($steps, $strideLengthCm);
        $goalPercentage = $this->calculateGoalPercentage($steps, $goalSteps);

        $log = HealthStepLog::create([
            'user_id' => $user->id,
            'log_date' => $logDate,
            'steps_count' => $steps,
            'distance_km' => $distanceKm,
            'goal_steps' => $goalSteps,
            'goal_percentage' => $goalPercentage,
            'goal_completed' => $steps >= $goalSteps,
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Step log saved successfully.',
            'data' => $log,
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Step log not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Step log loaded successfully.',
            'data' => $log,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $user = $request->user();

        $validated = $request->validate([
            'steps_count' => ['required', 'integer', 'min:0', 'max:200000'],
            'log_date' => ['required', 'date'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $log = HealthStepLog::query()
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Step log not found.',
            ], 404);
        }

        $logDate = Carbon::parse($validated['log_date'])->toDateString();

        $duplicateLog = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereDate('log_date', $logDate)
            ->where('id', '!=', $id)
            ->first();

        if ($duplicateLog) {
            return response()->json([
                'success' => false,
                'message' => 'Another step log already exists for this date.',
                'errors' => [
                    'log_date' => ['Another step log already exists for this date.'],
                ],
            ], 422);
        }

        $profile = $this->getOrCreateHealthProfile($user->id);

        $steps = (int) $validated['steps_count'];
        $goalSteps = (int) ($profile->daily_steps_goal ?? 10000);
        $strideLengthCm = (float) ($profile->stride_length_cm ?? 75);

        $distanceKm = $this->calculateDistanceKm($steps, $strideLengthCm);
        $goalPercentage = $this->calculateGoalPercentage($steps, $goalSteps);

        DB::table('health_step_log')
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->update([
                'log_date' => $logDate,
                'steps_count' => $steps,
                'distance_km' => $distanceKm,
                'goal_steps' => $goalSteps,
                'goal_percentage' => $goalPercentage,
                'goal_completed' => $steps >= $goalSteps,
                'notes' => $validated['notes'] ?? null,
                'updated_at' => now(),
            ]);

        $updatedLog = HealthStepLog::query()
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Step log updated successfully.',
            'data' => $updatedLog,
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Step log not found.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Step log deleted successfully.',
        ]);
    }

    public function summary(Request $request)
    {
        $user = $request->user();

        $today = now()->toDateString();
        $weekStart = now()->startOfWeek()->toDateString();
        $weekEnd = now()->endOfWeek()->toDateString();
        $monthStart = now()->startOfMonth()->toDateString();
        $monthEnd = now()->endOfMonth()->toDateString();

        $todayLog = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereDate('log_date', $today)
            ->first();

        $weekly = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereBetween('log_date', [$weekStart, $weekEnd])
            ->selectRaw('COALESCE(SUM(steps_count), 0) as total_steps')
            ->selectRaw('COALESCE(SUM(goal_steps), 0) as total_goal')
            ->first();

        $monthly = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereBetween('log_date', [$monthStart, $monthEnd])
            ->selectRaw('COALESCE(SUM(steps_count), 0) as total_steps')
            ->selectRaw('COALESCE(SUM(goal_steps), 0) as total_goal')
            ->first();

        $last30Days = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->whereDate('log_date', '>=', now()->subDays(30)->toDateString())
            ->orderBy('log_date')
            ->get();

        $weeklySteps = (int) ($weekly->total_steps ?? 0);
        $weeklyGoal = (int) ($weekly->total_goal ?? 0);

        $monthlySteps = (int) ($monthly->total_steps ?? 0);
        $monthlyGoal = (int) ($monthly->total_goal ?? 0);

        return response()->json([
            'success' => true,
            'message' => 'Steps summary loaded successfully.',
            'data' => [
                'today' => [
                    'date' => $today,
                    'steps_count' => (int) ($todayLog->steps_count ?? 0),
                    'goal_steps' => (int) ($todayLog->goal_steps ?? 0),
                    'goal_percentage' => (float) ($todayLog->goal_percentage ?? 0),
                    'goal_completed' => (bool) ($todayLog->goal_completed ?? false),
                ],
                'weekly' => [
                    'start_date' => $weekStart,
                    'end_date' => $weekEnd,
                    'total_steps' => $weeklySteps,
                    'total_goal' => $weeklyGoal,
                    'goal_percentage' => $this->calculateGoalPercentage($weeklySteps, $weeklyGoal),
                ],
                'monthly' => [
                    'start_date' => $monthStart,
                    'end_date' => $monthEnd,
                    'total_steps' => $monthlySteps,
                    'total_goal' => $monthlyGoal,
                    'goal_percentage' => $this->calculateGoalPercentage($monthlySteps, $monthlyGoal),
                ],
                'chart' => $last30Days->map(function ($item) {
                    return [
                        'date' => $item->log_date,
                        'steps_count' => (int) $item->steps_count,
                        'goal_steps' => (int) $item->goal_steps,
                        'goal_percentage' => (float) $item->goal_percentage,
                    ];
                })->values(),
            ],
        ]);
    }

    private function getOrCreateHealthProfile(string $userId): HealthProfile
    {
        return HealthProfile::firstOrCreate(
            ['user_id' => $userId],
            [
                'daily_steps_goal' => 10000,
                'stride_length_cm' => 75,
            ]
        );
    }

    private function calculateDistanceKm(int $steps, float $strideLengthCm): float
    {
        if ($steps <= 0 || $strideLengthCm <= 0) {
            return 0;
        }

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

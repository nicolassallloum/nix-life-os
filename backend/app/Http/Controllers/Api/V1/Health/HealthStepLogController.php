<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthStepLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthStepLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $logs = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->when($request->filled('from'), fn ($q) => $q->whereDate('log_date', '>=', $request->from))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('log_date', '<=', $request->to))
            ->orderByDesc('log_date')
            ->get();

        $goalSteps = $this->dailyStepsGoal($user->id);

        return response()->json([
            'success' => true,
            'message' => 'Steps logs retrieved successfully.',
            'data' => $logs->map(fn ($log) => $this->serializeLog($log, $goalSteps))->values(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'log_date' => [
                'required',
                'date',
                Rule::unique('health_step_logs', 'log_date')
                    ->where(fn ($q) => $q->where('user_id', $user->id)),
            ],
            'steps' => ['nullable', 'integer', 'min:0', 'max:200000'],
            'steps_count' => ['nullable', 'integer', 'min:0', 'max:200000'],
            'kilometers' => ['nullable', 'numeric', 'min:0'],
            'calories_burned' => ['nullable', 'integer', 'min:0'],
            'source' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $steps = (int) ($validated['steps'] ?? $validated['steps_count'] ?? 0);
        $kilometers = array_key_exists('kilometers', $validated) && $validated['kilometers'] !== null
            ? round((float) $validated['kilometers'], 2)
            : round($steps * 0.000762, 2);

        $caloriesBurned = array_key_exists('calories_burned', $validated) && $validated['calories_burned'] !== null
            ? (int) $validated['calories_burned']
            : (int) round($steps * 0.04);

        $log = HealthStepLog::create([
            'user_id' => $user->id,
            'log_date' => Carbon::parse($validated['log_date'])->toDateString(),
            'steps' => $steps,
            'kilometers' => $kilometers,
            'calories_burned' => $caloriesBurned,
            'source' => $validated['source'] ?? 'manual',
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Step log saved successfully.',
            'data' => $this->serializeLog($log, $this->dailyStepsGoal($user->id)),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->where('id', $id)
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
            'data' => $this->serializeLog($log, $this->dailyStepsGoal($user->id)),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Step log not found.',
            ], 404);
        }

        $validated = $request->validate([
            'log_date' => [
                'required',
                'date',
                Rule::unique('health_step_logs', 'log_date')
                    ->where(fn ($q) => $q->where('user_id', $user->id))
                    ->ignore($log->id),
            ],
            'steps' => ['nullable', 'integer', 'min:0', 'max:200000'],
            'steps_count' => ['nullable', 'integer', 'min:0', 'max:200000'],
            'kilometers' => ['nullable', 'numeric', 'min:0'],
            'calories_burned' => ['nullable', 'integer', 'min:0'],
            'source' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $steps = (int) ($validated['steps'] ?? $validated['steps_count'] ?? $log->steps ?? 0);
        $kilometers = array_key_exists('kilometers', $validated) && $validated['kilometers'] !== null
            ? round((float) $validated['kilometers'], 2)
            : round($steps * 0.000762, 2);

        $caloriesBurned = array_key_exists('calories_burned', $validated) && $validated['calories_burned'] !== null
            ? (int) $validated['calories_burned']
            : (int) round($steps * 0.04);

        $log->update([
            'log_date' => Carbon::parse($validated['log_date'])->toDateString(),
            'steps' => $steps,
            'kilometers' => $kilometers,
            'calories_burned' => $caloriesBurned,
            'source' => $validated['source'] ?? $log->source ?? 'manual',
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Step log updated successfully.',
            'data' => $this->serializeLog($log->fresh(), $this->dailyStepsGoal($user->id)),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->where('id', $id)
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

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        $today = Carbon::today();
        $weekStart = Carbon::now()->startOfWeek();
        $weekEnd = Carbon::now()->endOfWeek();
        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();

        $base = HealthStepLog::query()->where('user_id', $user->id);

        $todayLog = (clone $base)
            ->whereDate('log_date', $today->toDateString())
            ->first();

        $weekly = (clone $base)
            ->whereBetween('log_date', [$weekStart->toDateString(), $weekEnd->toDateString()])
            ->selectRaw('COALESCE(SUM(steps), 0) as steps')
            ->selectRaw('COALESCE(SUM(kilometers), 0) as kilometers')
            ->selectRaw('COALESCE(SUM(calories_burned), 0) as calories_burned')
            ->first();

        $monthly = (clone $base)
            ->whereBetween('log_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->selectRaw('COALESCE(SUM(steps), 0) as steps')
            ->selectRaw('COALESCE(SUM(kilometers), 0) as kilometers')
            ->selectRaw('COALESCE(SUM(calories_burned), 0) as calories_burned')
            ->first();

        $allTime = (clone $base)
            ->selectRaw('COALESCE(SUM(steps), 0) as steps')
            ->selectRaw('COALESCE(SUM(kilometers), 0) as kilometers')
            ->selectRaw('COALESCE(SUM(calories_burned), 0) as calories_burned')
            ->first();

        $daysRange = (int) ($request->input('days') ?: $request->input('range') ?: 30);
        $daysRange = max(1, min($daysRange, 365));
        $rangeStart = Carbon::today()->subDays($daysRange - 1);

        $rangeLogs = (clone $base)
            ->whereDate('log_date', '>=', $rangeStart->toDateString())
            ->get();

        $loggedDays = $rangeLogs->count();
        $totalSteps = (int) $rangeLogs->sum('steps');
        $totalDistanceKm = round((float) $rangeLogs->sum('kilometers'), 2);
        $goalSteps = $this->dailyStepsGoal($user->id);
        $goalCompletedDays = $rangeLogs->filter(fn ($log) => (int) ($log->steps ?? 0) >= $goalSteps)->count();

        return response()->json([
            'success' => true,
            'message' => 'Steps summary loaded successfully.',
            'data' => [
                'days_range' => $daysRange,
                'logged_days' => $loggedDays,
                'total_steps' => $totalSteps,
                'average_steps' => $loggedDays > 0 ? (int) round($totalSteps / $loggedDays) : 0,
                'total_distance_km' => $totalDistanceKm,
                'average_distance_km' => $loggedDays > 0 ? round($totalDistanceKm / $loggedDays, 2) : 0,
                'goal_completed_days' => $goalCompletedDays,
                'goal_completion_rate' => $loggedDays > 0 ? round(($goalCompletedDays / $loggedDays) * 100) : 0,
                'today' => [
                    'steps' => (int) ($todayLog->steps ?? 0),
                    'steps_count' => (int) ($todayLog->steps ?? 0),
                    'kilometers' => round((float) ($todayLog->kilometers ?? 0), 2),
                    'distance_km' => round((float) ($todayLog->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($todayLog->calories_burned ?? 0),
                ],
                'weekly' => [
                    'steps' => (int) ($weekly->steps ?? 0),
                    'steps_count' => (int) ($weekly->steps ?? 0),
                    'kilometers' => round((float) ($weekly->kilometers ?? 0), 2),
                    'distance_km' => round((float) ($weekly->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($weekly->calories_burned ?? 0),
                ],
                'monthly' => [
                    'steps' => (int) ($monthly->steps ?? 0),
                    'steps_count' => (int) ($monthly->steps ?? 0),
                    'kilometers' => round((float) ($monthly->kilometers ?? 0), 2),
                    'distance_km' => round((float) ($monthly->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($monthly->calories_burned ?? 0),
                ],
                'all_time' => [
                    'steps' => (int) ($allTime->steps ?? 0),
                    'steps_count' => (int) ($allTime->steps ?? 0),
                    'kilometers' => round((float) ($allTime->kilometers ?? 0), 2),
                    'distance_km' => round((float) ($allTime->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($allTime->calories_burned ?? 0),
                ],
            ],
        ]);
    }

    private function serializeLog(HealthStepLog $log, int $goalSteps): array
    {
        $steps = (int) ($log->steps ?? 0);
        $distanceKm = round((float) ($log->kilometers ?? 0), 2);
        $goalPercentage = $goalSteps > 0 ? round(($steps / $goalSteps) * 100) : 0;

        return [
            'id' => $log->id,
            'user_id' => $log->user_id,
            'log_date' => optional($log->log_date)->format('Y-m-d') ?: $log->log_date,
            'steps' => $steps,
            'steps_count' => $steps,
            'kilometers' => $distanceKm,
            'distance_km' => $distanceKm,
            'calories_burned' => (int) ($log->calories_burned ?? 0),
            'goal_steps' => $goalSteps,
            'goal_percentage' => min(100, $goalPercentage),
            'goal_completed' => $steps >= $goalSteps,
            'source' => $log->source,
            'notes' => $log->notes,
            'created_at' => $log->created_at,
            'updated_at' => $log->updated_at,
        ];
    }

    private function dailyStepsGoal(string $userId): int
    {
        try {
            $goal = \Illuminate\Support\Facades\DB::table('health_user_goals')
                ->where('user_id', $userId)
                ->value('daily_steps_goal');

            return (int) ($goal ?: 8000);
        } catch (\Throwable $e) {
            return 8000;
        }
    }
}

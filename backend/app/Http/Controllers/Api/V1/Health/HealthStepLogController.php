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

        return response()->json([
            'success' => true,
            'message' => 'Steps logs retrieved successfully.',
            'data' => $logs,
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
            'data' => $log,
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
            'data' => $log,
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
            'data' => $log->fresh(),
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

        return response()->json([
            'success' => true,
            'message' => 'Steps summary loaded successfully.',
            'data' => [
                'today' => [
                    'steps' => (int) ($todayLog->steps ?? 0),
                    'steps_count' => (int) ($todayLog->steps ?? 0),
                    'kilometers' => round((float) ($todayLog->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($todayLog->calories_burned ?? 0),
                ],
                'weekly' => [
                    'steps' => (int) ($weekly->steps ?? 0),
                    'steps_count' => (int) ($weekly->steps ?? 0),
                    'kilometers' => round((float) ($weekly->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($weekly->calories_burned ?? 0),
                ],
                'monthly' => [
                    'steps' => (int) ($monthly->steps ?? 0),
                    'steps_count' => (int) ($monthly->steps ?? 0),
                    'kilometers' => round((float) ($monthly->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($monthly->calories_burned ?? 0),
                ],
                'all_time' => [
                    'steps' => (int) ($allTime->steps ?? 0),
                    'steps_count' => (int) ($allTime->steps ?? 0),
                    'kilometers' => round((float) ($allTime->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($allTime->calories_burned ?? 0),
                ],
            ],
        ]);
    }
}

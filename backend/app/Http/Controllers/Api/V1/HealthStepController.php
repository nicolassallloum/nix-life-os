<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthStepLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthStepController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $logs = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->when($request->filled('from'), fn ($q) => $q->whereDate('log_date', '>=', $request->from))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('log_date', '<=', $request->to))
            ->orderByDesc('log_date')
            ->paginate((int) $request->get('per_page', 30));

        return response()->json([
            'success' => true,
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
            'steps' => ['required', 'integer', 'min:0'],
            'kilometers' => ['nullable', 'numeric', 'min:0'],
            'calories_burned' => ['nullable', 'integer', 'min:0'],
            'source' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
        ]);

        $validated['user_id'] = $user->id;
        $validated['kilometers'] = $validated['kilometers'] ?? round(((int) $validated['steps']) * 0.000762, 2);
        $validated['calories_burned'] = $validated['calories_burned'] ?? round(((int) $validated['steps']) * 0.04);

        $log = HealthStepLog::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Steps log created successfully.',
            'data' => $log,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->findOrFail($id);

        $validated = $request->validate([
            'log_date' => [
                'required',
                'date',
                Rule::unique('health_step_logs', 'log_date')
                    ->where(fn ($q) => $q->where('user_id', $user->id))
                    ->ignore($log->id),
            ],
            'steps' => ['required', 'integer', 'min:0'],
            'kilometers' => ['nullable', 'numeric', 'min:0'],
            'calories_burned' => ['nullable', 'integer', 'min:0'],
            'source' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
        ]);

        $validated['kilometers'] = $validated['kilometers'] ?? round(((int) $validated['steps']) * 0.000762, 2);
        $validated['calories_burned'] = $validated['calories_burned'] ?? round(((int) $validated['steps']) * 0.04);

        $log->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Steps log updated successfully.',
            'data' => $log->fresh(),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $log = HealthStepLog::query()
            ->where('user_id', $user->id)
            ->findOrFail($id);

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Steps log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        $today = Carbon::today();
        $weekStart = Carbon::now()->startOfWeek();
        $monthStart = Carbon::now()->startOfMonth();

        $base = HealthStepLog::query()->where('user_id', $user->id);

        $sumRange = function ($from = null) use ($base) {
            $query = clone $base;

            if ($from) {
                $query->whereDate('log_date', '>=', $from);
            }

            return [
                'steps' => (int) $query->sum('steps'),
                'kilometers' => round((float) $query->sum('kilometers'), 2),
                'calories_burned' => (int) $query->sum('calories_burned'),
            ];
        };

        $todayQuery = clone $base;
        $todayData = $todayQuery->whereDate('log_date', $today)->first();

        return response()->json([
            'success' => true,
            'data' => [
                'today' => [
                    'steps' => (int) ($todayData->steps ?? 0),
                    'kilometers' => round((float) ($todayData->kilometers ?? 0), 2),
                    'calories_burned' => (int) ($todayData->calories_burned ?? 0),
                ],
                'weekly' => $sumRange($weekStart),
                'monthly' => $sumRange($monthStart),
                'all_time' => $sumRange(),
            ],
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthHydrationLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthHydrationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $query = HealthHydrationLog::query()
            ->where('user_id', $userId)
            ->orderByDesc('log_date')
            ->orderByDesc('log_time')
            ->orderByDesc('id');

        if ($request->filled('from')) {
            $query->whereDate('log_date', '>=', $request->query('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('log_date', '<=', $request->query('to'));
        }

        if ($request->filled('hydration_type')) {
            $query->where('hydration_type', $request->query('hydration_type'));
        }

        return response()->json([
            'success' => true,
            'data' => $query->limit(200)->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $log = HealthHydrationLog::create([
            'user_id' => $request->user()->id,
            'hydration_type' => $validated['hydration_type'],
            'quantity_ml' => $validated['quantity_ml'],
            'log_date' => $validated['log_date'],
            'log_time' => $validated['log_time'] ?? now()->format('H:i:s'),
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log created successfully.',
            'data' => $log,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)->findOrFail($id);

        $validated = $this->validatePayload($request, true);

        $log->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log updated successfully.',
            'data' => $log->fresh(),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)->findOrFail($id);
        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $today = Carbon::today();
        $weekStart = Carbon::now()->startOfWeek();
        $monthStart = Carbon::now()->startOfMonth();

        $dailyTotal = $this->sumFromDate($userId, $today);
        $weeklyTotal = $this->sumFromDate($userId, $weekStart);
        $monthlyTotal = $this->sumFromDate($userId, $monthStart);
        $allTimeTotal = HealthHydrationLog::where('user_id', $userId)->sum('quantity_ml');

        return response()->json([
            'success' => true,
            'data' => [
                'daily_total_ml' => (int) $dailyTotal,
                'weekly_total_ml' => (int) $weeklyTotal,
                'monthly_total_ml' => (int) $monthlyTotal,
                'all_time_total_ml' => (int) $allTimeTotal,
                'daily_total_liters' => round($dailyTotal / 1000, 2),
                'weekly_total_liters' => round($weeklyTotal / 1000, 2),
                'monthly_total_liters' => round($monthlyTotal / 1000, 2),
                'all_time_total_liters' => round($allTimeTotal / 1000, 2),
            ],
        ]);
    }

    public function charts(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'data' => [
                'daily' => $this->groupByType($userId, Carbon::today()),
                'weekly' => $this->groupByType($userId, Carbon::now()->startOfWeek()),
                'monthly' => $this->groupByType($userId, Carbon::now()->startOfMonth()),
                'all_time' => $this->groupByType($userId),
            ],
        ]);
    }

    private function validatePayload(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'hydration_type' => [$required, 'string', Rule::in(HealthHydrationLog::TYPES)],
            'quantity_ml' => [$required, 'integer', 'min:1', 'max:10000'],
            'log_date' => [$required, 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);
    }

    private function sumFromDate(int $userId, Carbon $fromDate): int
    {
        return (int) HealthHydrationLog::where('user_id', $userId)
            ->whereDate('log_date', '>=', $fromDate->toDateString())
            ->sum('quantity_ml');
    }

    private function groupByType(int $userId, ?Carbon $fromDate = null): array
    {
        $query = HealthHydrationLog::query()
            ->where('user_id', $userId)
            ->selectRaw('hydration_type, SUM(quantity_ml) as total_ml')
            ->groupBy('hydration_type')
            ->orderBy('hydration_type');

        if ($fromDate) {
            $query->whereDate('log_date', '>=', $fromDate->toDateString());
        }

        $existing = $query->get()->keyBy('hydration_type');

        return collect(HealthHydrationLog::TYPES)
            ->map(function (string $type) use ($existing) {
                return [
                    'hydration_type' => $type,
                    'total_ml' => (int) optional($existing->get($type))->total_ml,
                ];
            })
            ->values()
            ->all();
    }
}

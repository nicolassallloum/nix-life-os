<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreHealthHydrationLogRequest;
use App\Http\Requests\UpdateHealthHydrationLogRequest;
use App\Http\Resources\HealthHydrationLogResource;
use App\Models\HealthHydrationLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HealthHydrationLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthHydrationLog::query()
            ->where('user_id', $user->id);

        if ($request->filled('date')) {
            $query->whereDate('log_date', $request->date);
        }

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        if ($request->filled('drink_type')) {
            $query->where('drink_type', $request->drink_type);
        }

        $logs = $query
            ->orderByDesc('log_date')
            ->orderByDesc('log_time')
            ->paginate($request->integer('per_page', 15));

        return response()->json([
            'success' => true,
            'message' => 'Hydration logs retrieved successfully.',
            'data' => HealthHydrationLogResource::collection($logs),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
                'last_page' => $logs->lastPage(),
            ],
        ]);
    }

    public function store(StoreHealthHydrationLogRequest $request): JsonResponse
    {
        $user = $request->user();

        $log = HealthHydrationLog::create([
            'user_id' => $user->id,
            'log_date' => $request->log_date,
            'log_time' => $request->log_time ?? now()->format('H:i'),
            'drink_type' => $request->drink_type,
            'amount_ml' => $request->amount_ml,
            'is_ckd_safe' => $request->boolean('is_ckd_safe', true),
            'source' => $request->source ?? 'manual',
            'notes' => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log created successfully.',
            'data' => new HealthHydrationLogResource($log),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log retrieved successfully.',
            'data' => new HealthHydrationLogResource($log),
        ]);
    }

    public function update(UpdateHealthHydrationLogRequest $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->update($request->validated());

        return response()->json([
            'success' => true,
            'message' => 'Hydration log updated successfully.',
            'data' => new HealthHydrationLogResource($log),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log deleted successfully.',
        ]);
    }

    public function dailySummary(Request $request): JsonResponse
    {
        $user = $request->user();

        $date = $request->get('date', now()->toDateString());

        $totalMl = HealthHydrationLog::where('user_id', $user->id)
            ->whereDate('log_date', $date)
            ->sum('amount_ml');

        $breakdown = HealthHydrationLog::select(
                'drink_type',
                DB::raw('SUM(amount_ml) as total_ml'),
                DB::raw('COUNT(*) as entries_count')
            )
            ->where('user_id', $user->id)
            ->whereDate('log_date', $date)
            ->groupBy('drink_type')
            ->orderByDesc('total_ml')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Daily hydration summary retrieved successfully.',
            'data' => [
                'date' => $date,
                'total_ml' => (float) $totalMl,
                'total_liters' => round($totalMl / 1000, 2),
                'breakdown' => $breakdown->map(function ($item) {
                    return [
                        'drink_type' => $item->drink_type,
                        'total_ml' => (float) $item->total_ml,
                        'entries_count' => (int) $item->entries_count,
                    ];
                }),
            ],
        ]);
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        $user = $request->user();

        $startDate = $request->get('start_date', now()->startOfWeek()->toDateString());
        $endDate = $request->get('end_date', now()->endOfWeek()->toDateString());

        $rows = HealthHydrationLog::select(
                'log_date',
                DB::raw('SUM(amount_ml) as total_ml'),
                DB::raw('COUNT(*) as entries_count')
            )
            ->where('user_id', $user->id)
            ->whereBetween('log_date', [$startDate, $endDate])
            ->groupBy('log_date')
            ->orderBy('log_date')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Weekly hydration summary retrieved successfully.',
            'data' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
                'days' => $rows->map(function ($item) {
                    return [
                        'log_date' => Carbon::parse($item->log_date)->format('Y-m-d'),
                        'total_ml' => (float) $item->total_ml,
                        'total_liters' => round($item->total_ml / 1000, 2),
                        'entries_count' => (int) $item->entries_count,
                    ];
                }),
            ],
        ]);
    }

    public function quickAdd(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'amount_ml' => ['required', 'numeric', 'min:1', 'max:5000'],
            'drink_type' => ['nullable', 'string', 'max:50', 'in:water,tea,coffee,juice,soup,milk,other'],
            'log_date' => ['nullable', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
        ]);

        $log = HealthHydrationLog::create([
            'user_id' => $request->user()->id,
            'log_date' => $validated['log_date'] ?? now()->toDateString(),
            'log_time' => $validated['log_time'] ?? now()->format('H:i'),
            'drink_type' => $validated['drink_type'] ?? 'water',
            'amount_ml' => $validated['amount_ml'],
            'is_ckd_safe' => true,
            'source' => 'quick_add',
            'notes' => 'Quick add hydration entry',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Quick hydration entry added successfully.',
            'data' => new HealthHydrationLogResource($log),
        ], 201);
    }
}
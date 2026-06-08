<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthHydrationLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class HealthHydrationController extends Controller
{
    private const TYPES = [
        'Water',
        'Coffee',
        'Tea',
        'Juice',
        'Soft Drink',
        'Soup',
        'Other',
    ];

    private const TYPE_MAP = [
        'Water' => 'water',
        'Coffee' => 'coffee',
        'Tea' => 'tea',
        'Juice' => 'juice',
        'Soft Drink' => 'soft_drink',
        'Soup' => 'soup',
        'Other' => 'other',
    ];

    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $query = HealthHydrationLog::query()
            ->where('user_id', $userId)
            ->orderByDesc($this->dateColumn())
            ->orderByDesc('created_at');

        return response()->json([
            'success' => true,
            'data' => $query->limit(200)->get(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'hydration_type' => ['required', 'string', Rule::in(self::TYPES)],
            'quantity_ml' => ['required', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['required', 'date'],
            'log_time' => ['nullable'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $drinkType = self::TYPE_MAP[$validated['hydration_type']] ?? 'other';

        $payload = [
            'user_id' => $request->user()->id,
            'notes' => $validated['notes'] ?? null,
        ];

        if (Schema::hasColumn('health_hydration_logs', 'hydration_type')) {
            $payload['hydration_type'] = $validated['hydration_type'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'drink_type')) {
            $payload['drink_type'] = $drinkType;
        }

        if (Schema::hasColumn('health_hydration_logs', 'quantity_ml')) {
            $payload['quantity_ml'] = $validated['quantity_ml'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'amount_ml')) {
            $payload['amount_ml'] = $validated['quantity_ml'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'water_ml')) {
            $payload['water_ml'] = $validated['quantity_ml'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'log_date')) {
            $payload['log_date'] = $validated['log_date'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'date')) {
            $payload['date'] = $validated['log_date'];
        }

        if (Schema::hasColumn('health_hydration_logs', 'log_time')) {
            $time = $validated['log_time'] ?? now()->format('H:i:s');
            $payload['log_time'] = strlen($time) <= 8
                ? Carbon::parse($validated['log_date'] . ' ' . $time)
                : $time;
        }

        if (Schema::hasColumn('health_hydration_logs', 'source')) {
            $payload['source'] = 'manual';
        }

        if (Schema::hasColumn('health_hydration_logs', 'is_ckd_safe')) {
            $payload['is_ckd_safe'] = true;
        }

        $log = HealthHydrationLog::create($payload);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log created successfully.',
            'data' => $log,
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $log = HealthHydrationLog::where('user_id', $request->user()->id)->findOrFail($id);

        $validated = $request->validate([
            'hydration_type' => ['sometimes', 'string', Rule::in(self::TYPES)],
            'quantity_ml' => ['sometimes', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['sometimes', 'date'],
            'log_time' => ['nullable'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $payload = [];

        if (array_key_exists('hydration_type', $validated)) {
            $drinkType = self::TYPE_MAP[$validated['hydration_type']] ?? 'other';

            if (Schema::hasColumn('health_hydration_logs', 'hydration_type')) {
                $payload['hydration_type'] = $validated['hydration_type'];
            }

            if (Schema::hasColumn('health_hydration_logs', 'drink_type')) {
                $payload['drink_type'] = $drinkType;
            }
        }

        if (array_key_exists('quantity_ml', $validated)) {
            foreach (['quantity_ml', 'amount_ml', 'water_ml'] as $column) {
                if (Schema::hasColumn('health_hydration_logs', $column)) {
                    $payload[$column] = $validated['quantity_ml'];
                }
            }
        }

        if (array_key_exists('log_date', $validated)) {
            if (Schema::hasColumn('health_hydration_logs', 'log_date')) {
                $payload['log_date'] = $validated['log_date'];
            }

            if (Schema::hasColumn('health_hydration_logs', 'date')) {
                $payload['date'] = $validated['log_date'];
            }
        }

        if (array_key_exists('log_time', $validated) && Schema::hasColumn('health_hydration_logs', 'log_time')) {
            $date = $validated['log_date'] ?? $log->log_date ?? $log->date ?? now()->toDateString();
            $time = $validated['log_time'] ?: now()->format('H:i:s');
            $payload['log_time'] = Carbon::parse($date . ' ' . $time);
        }

        if (array_key_exists('notes', $validated)) {
            $payload['notes'] = $validated['notes'];
        }

        $log->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Hydration log updated successfully.',
            'data' => $log->fresh(),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
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
        $allTimeTotal = $this->baseQuery($userId)->sum($this->amountColumn());

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

    private function sumFromDate(string $userId, Carbon $fromDate): int
    {
        return (int) $this->baseQuery($userId)
            ->whereDate($this->dateColumn(), '>=', $fromDate->toDateString())
            ->sum($this->amountColumn());
    }

    private function groupByType(string $userId, ?Carbon $fromDate = null): array
    {
        $typeColumn = $this->typeColumn();
        $amountColumn = $this->amountColumn();

        $query = $this->baseQuery($userId)
            ->selectRaw("$typeColumn as hydration_type, SUM($amountColumn) as total_ml")
            ->groupBy($typeColumn)
            ->orderBy($typeColumn);

        if ($fromDate) {
            $query->whereDate($this->dateColumn(), '>=', $fromDate->toDateString());
        }

        $rows = $query->get();

        $totals = [];
        foreach ($rows as $row) {
            $label = $this->normalizeTypeLabel((string) $row->hydration_type);
            $totals[$label] = ($totals[$label] ?? 0) + (int) $row->total_ml;
        }

        return collect(self::TYPES)
            ->map(fn (string $type) => [
                'hydration_type' => $type,
                'total_ml' => (int) ($totals[$type] ?? 0),
            ])
            ->values()
            ->all();
    }

    private function baseQuery(string $userId)
    {
        return HealthHydrationLog::query()->where('user_id', $userId);
    }

    private function amountColumn(): string
    {
        if (Schema::hasColumn('health_hydration_logs', 'quantity_ml')) {
            return 'quantity_ml';
        }

        if (Schema::hasColumn('health_hydration_logs', 'amount_ml')) {
            return 'amount_ml';
        }

        return 'water_ml';
    }

    private function typeColumn(): string
    {
        if (Schema::hasColumn('health_hydration_logs', 'hydration_type')) {
            return 'hydration_type';
        }

        return 'drink_type';
    }

    private function dateColumn(): string
    {
        if (Schema::hasColumn('health_hydration_logs', 'log_date')) {
            return 'log_date';
        }

        return 'date';
    }

    private function normalizeTypeLabel(string $value): string
    {
        $value = strtolower(trim($value));

        return match ($value) {
            'water' => 'Water',
            'coffee' => 'Coffee',
            'tea' => 'Tea',
            'juice' => 'Juice',
            'soft_drink', 'soft drink', 'soda' => 'Soft Drink',
            'soup' => 'Soup',
            default => 'Other',
        };
    }
}

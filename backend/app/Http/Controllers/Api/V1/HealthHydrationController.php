<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class HealthHydrationController extends Controller
{
    private string $table = 'health_hydration_logs';

    private array $types = ['Water', 'Coffee', 'Tea', 'Juice', 'Soft Drink', 'Soup', 'Other'];

    public function index(Request $request): JsonResponse
    {
        $rows = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->orderByDesc('log_date')
            ->orderByDesc('created_at')
            ->limit(200)
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Hydration logs retrieved successfully.',
            'data' => $rows,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->normalizeIncomingPayload($request);

        $validated = $request->validate([
            'hydration_type' => ['required', 'string', Rule::in($this->types)],
            'quantity_ml' => ['required', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $date = date('Y-m-d', strtotime($validated['log_date']));
        $time = $validated['log_time'] ?? date('H:i');
        $quantity = (int) $validated['quantity_ml'];
        $type = $validated['hydration_type'];
        $drinkType = strtolower(str_replace(' ', '_', $type));

        $payload = [];
        $this->put($payload, 'id', (string) Str::uuid());
        $this->put($payload, 'user_id', $request->user()->id);
        $this->put($payload, 'hydration_type', $type);
        $this->put($payload, 'drink_type', $drinkType);
        $this->put($payload, 'quantity_ml', $quantity);
        $this->put($payload, 'amount_ml', $quantity);
        $this->put($payload, 'water_ml', $drinkType === 'water' ? $quantity : 0);
        $this->put($payload, 'log_date', $date);
        $this->put($payload, 'log_time', $time . ':00');
        $this->put($payload, 'is_ckd_safe', true);
        $this->put($payload, 'source', 'manual');
        $this->put($payload, 'notes', $validated['notes'] ?? null);
        $this->put($payload, 'created_at', now());
        $this->put($payload, 'updated_at', now());

        DB::table($this->table)->insert($payload);

        $row = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log created successfully.',
            'data' => $row,
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $this->normalizeIncomingPayload($request);

        $validated = $request->validate([
            'hydration_type' => ['sometimes', 'required', 'string', Rule::in($this->types)],
            'quantity_ml' => ['sometimes', 'required', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['sometimes', 'required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $payload = [];

        if (isset($validated['hydration_type'])) {
            $type = $validated['hydration_type'];
            $drinkType = strtolower(str_replace(' ', '_', $type));
            $this->put($payload, 'hydration_type', $type);
            $this->put($payload, 'drink_type', $drinkType);
        }

        if (isset($validated['quantity_ml'])) {
            $quantity = (int) $validated['quantity_ml'];
            $this->put($payload, 'quantity_ml', $quantity);
            $this->put($payload, 'amount_ml', $quantity);
            $this->put($payload, 'water_ml', $quantity);
        }

        if (isset($validated['log_date'])) {
            $this->put($payload, 'log_date', date('Y-m-d', strtotime($validated['log_date'])));
        }

        if (isset($validated['log_time'])) {
            $this->put($payload, 'log_time', $validated['log_time'] . ':00');
        }

        if (array_key_exists('notes', $validated)) {
            $this->put($payload, 'notes', $validated['notes']);
        }

        $this->put($payload, 'updated_at', now());

        $updated = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->update($payload);

        return response()->json([
            'success' => (bool) $updated,
            'message' => $updated ? 'Hydration log updated successfully.' : 'Hydration log not found.',
        ], $updated ? 200 : 404);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $deleted = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->delete();

        return response()->json([
            'success' => (bool) $deleted,
            'message' => $deleted ? 'Hydration log deleted successfully.' : 'Hydration log not found.',
        ], $deleted ? 200 : 404);
    }

    public function summary(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Hydration summary retrieved successfully.',
            'data' => [
                'today_ml' => $todayMl = $this->sum($userId, date('Y-m-d')),
                'week_ml' => $weekMl = $this->sum($userId, now()->startOfWeek()->toDateString()),
                'month_ml' => $monthMl = $this->sum($userId, now()->startOfMonth()->toDateString()),
                'all_time_ml' => $allTimeMl = $this->sum($userId, null),
                'target_ml' => $targetMl = $this->targetMl($userId),

                'daily_total_ml' => $todayMl,
                'weekly_total_ml' => $weekMl,
                'monthly_total_ml' => $monthMl,
                'all_time_total_ml' => $allTimeMl,

                'daily_total_liters' => round($todayMl / 1000, 2),
                'weekly_total_liters' => round($weekMl / 1000, 2),
                'monthly_total_liters' => round($monthMl / 1000, 2),
                'all_time_total_liters' => round($allTimeMl / 1000, 2),

                'daily_goal_ml' => $targetMl,
                'goal_ml' => $targetMl,
            ],
        ]);
    }

    public function charts(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Hydration charts retrieved successfully.',
            'data' => [
                'daily_by_type' => $this->byType($userId, date('Y-m-d')),
                'weekly_by_type' => $this->byType($userId, now()->startOfWeek()->toDateString()),
                'monthly_by_type' => $this->byType($userId, now()->startOfMonth()->toDateString()),
                'all_time_by_type' => $this->byType($userId, null),
            ],
        ]);
    }

    private function sum(string $userId, ?string $fromDate): int
    {
        $query = DB::table($this->table)->where('user_id', $userId);

        if ($fromDate) {
            $query->where('log_date', '>=', $fromDate);
        }

        return (int) $query->sum(Schema::hasColumn($this->table, 'quantity_ml') ? 'quantity_ml' : 'amount_ml');
    }

    private function byType(string $userId, ?string $fromDate): array
    {
        $typeColumn = Schema::hasColumn($this->table, 'hydration_type') ? 'hydration_type' : 'drink_type';
        $amountColumn = Schema::hasColumn($this->table, 'quantity_ml') ? 'quantity_ml' : 'amount_ml';

        $query = DB::table($this->table)->where('user_id', $userId);

        if ($fromDate) {
            $query->where('log_date', '>=', $fromDate);
        }

        return $query
            ->selectRaw("LOWER(REPLACE($typeColumn, ' ', '_')) as type_key")
            ->selectRaw("COALESCE(SUM($amountColumn), 0) as total_ml")
            ->groupByRaw("LOWER(REPLACE($typeColumn, ' ', '_'))")
            ->orderByRaw("LOWER(REPLACE($typeColumn, ' ', '_'))")
            ->get()
            ->map(fn ($row) => [
                'hydration_type' => $label = match ($row->type_key) {
                    'water' => 'Water',
                    'coffee' => 'Coffee',
                    'tea' => 'Tea',
                    'juice' => 'Juice',
                    'soft_drink' => 'Soft Drink',
                    'soup' => 'Soup',
                    default => 'Other',
                },
                'type' => $label,
                'total_ml' => (int) $row->total_ml,
            ])
            ->values()
            ->toArray();
    }


    private function normalizeIncomingPayload(Request $request): void
    {
        $rawType = $request->input('hydration_type', $request->input('drink_type', 'Water'));
        $type = $this->normalizeType((string) $rawType);

        $quantity = $request->input(
            'quantity_ml',
            $request->input('amount_ml', $request->input('water_ml', 250))
        );

        $request->merge([
            'hydration_type' => $type,
            'quantity_ml' => (int) $quantity,
            'log_date' => $request->input('log_date', now()->toDateString()),
            'log_time' => substr((string) $request->input('log_time', now()->format('H:i')), 0, 5),
        ]);
    }

    private function normalizeType(string $type): string
    {
        $key = strtolower(trim(str_replace(['-', '_'], ' ', $type)));

        return match ($key) {
            'water' => 'Water',
            'coffee' => 'Coffee',
            'tea' => 'Tea',
            'juice' => 'Juice',
            'soft drink', 'softdrink', 'soda' => 'Soft Drink',
            'soup' => 'Soup',
            default => 'Other',
        };
    }

    private function targetMl(string $userId): int
    {
        try {
            $target = DB::table('health_user_goals')
                ->where('user_id', $userId)
                ->value('daily_water_goal_ml');

            return (int) ($target ?: 2000);
        } catch (\Throwable $e) {
            return 2000;
        }
    }

    private function put(array &$payload, string $column, mixed $value): void
    {
        if (Schema::hasColumn($this->table, $column)) {
            $payload[$column] = $value;
        }
    }
}

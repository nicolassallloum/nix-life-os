<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
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

    private string $table = 'health_hydration_logs';

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
        $validated = $request->validate([
            'hydration_type' => ['required', 'string', Rule::in(self::TYPES)],
            'quantity_ml' => ['required', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $now = now();
        $date = Carbon::parse($validated['log_date'])->toDateString();
        $time = $validated['log_time'] ?? $now->format('H:i');
        $typeLabel = $validated['hydration_type'];
        $typeValue = self::TYPE_MAP[$typeLabel] ?? 'other';
        $quantity = (int) $validated['quantity_ml'];

        $payload = [];

        $this->putIfColumn($payload, 'id', (string) Str::uuid());
        $this->putIfColumn($payload, 'user_id', $request->user()->id);
        $this->putIfColumn($payload, 'log_date', $date);
        $this->putIfColumn($payload, 'log_time', $this->formatLogTime($date, $time));
        $this->putIfColumn($payload, 'hydration_type', $typeLabel);
        $this->putIfColumn($payload, 'drink_type', $typeValue);
        $this->putIfColumn($payload, 'quantity_ml', $quantity);
        $this->putIfColumn($payload, 'amount_ml', $quantity);

        if ($typeValue === 'water') {
            $this->putIfColumn($payload, 'water_ml', $quantity);
        } else {
            $this->putIfColumn($payload, 'water_ml', 0);
        }

        $this->putIfColumn($payload, 'is_ckd_safe', true);
        $this->putIfColumn($payload, 'source', 'manual');
        $this->putIfColumn($payload, 'notes', $validated['notes'] ?? null);
        $this->putIfColumn($payload, 'created_at', $now);
        $this->putIfColumn($payload, 'updated_at', $now);

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
        $validated = $request->validate([
            'hydration_type' => ['sometimes', 'required', 'string', Rule::in(self::TYPES)],
            'quantity_ml' => ['sometimes', 'required', 'integer', 'min:1', 'max:10000'],
            'log_date' => ['sometimes', 'required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $existing = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$existing) {
            return response()->json([
                'success' => false,
                'message' => 'Hydration log not found.',
            ], 404);
        }

        $payload = [];
        $date = $validated['log_date'] ?? ($existing->log_date ?? now()->toDateString());
        $time = $validated['log_time'] ?? now()->format('H:i');

        if (array_key_exists('log_date', $validated)) {
            $this->putIfColumn($payload, 'log_date', Carbon::parse($validated['log_date'])->toDateString());
        }

        if (array_key_exists('log_time', $validated)) {
            $this->putIfColumn($payload, 'log_time', $this->formatLogTime($date, $time));
        }

        if (array_key_exists('hydration_type', $validated)) {
            $typeLabel = $validated['hydration_type'];
            $typeValue = self::TYPE_MAP[$typeLabel] ?? 'other';
            $this->putIfColumn($payload, 'hydration_type', $typeLabel);
            $this->putIfColumn($payload, 'drink_type', $typeValue);
        }

        if (array_key_exists('quantity_ml', $validated)) {
            $quantity = (int) $validated['quantity_ml'];
            $this->putIfColumn($payload, 'quantity_ml', $quantity);
            $this->putIfColumn($payload, 'amount_ml', $quantity);
            $this->putIfColumn($payload, 'water_ml', $quantity);
        }

        if (array_key_exists('notes', $validated)) {
            $this->putIfColumn($payload, 'notes', $validated['notes']);
        }

        $this->putIfColumn($payload, 'updated_at', now());

        DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->update($payload);

        $row = DB::table($this->table)->where('id', $id)->first();

        return response()->json([
            'success' => true,
            'message' => 'Hydration log updated successfully.',
            'data' => $row,
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $deleted = DB::table($this->table)
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->delete();

        if (!$deleted) {
            return response()->json([
                'success' => false,
                'message' => 'Hydration log not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Hydration log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $today = now()->toDateString();
        $weekStart = now()->startOfWeek()->toDateString();
        $monthStart = now()->startOfMonth()->toDateString();

        return response()->json([
            'success' => true,
            'message' => 'Hydration summary retrieved successfully.',
            'data' => [
                'today_ml' => $this->sumFromDate($userId, $today),
                'week_ml' => $this->sumFromDate($userId, $weekStart),
                'month_ml' => $this->sumFromDate($userId, $monthStart),
                'all_time_ml' => $this->sumFromDate($userId, null),
                'target_ml' => 2000,
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
                'daily_by_type' => $this->groupByType($userId, now()->toDateString()),
                'weekly_by_type' => $this->groupByType($userId, now()->startOfWeek()->toDateString()),
                'monthly_by_type' => $this->groupByType($userId, now()->startOfMonth()->toDateString()),
                'all_time_by_type' => $this->groupByType($userId, null),
            ],
        ]);
    }

    private function sumFromDate(string $userId, ?string $fromDate): int
    {
        $query = DB::table($this->table)->where('user_id', $userId);

        if ($fromDate) {
            $query->where('log_date', '>=', $fromDate);
        }

        return (int) $query->selectRaw($this->amountExpression() . ' as total')->value('total');
    }

    private function groupByType(string $userId, ?string $fromDate): array
    {
        $query = DB::table($this->table)->where('user_id', $userId);

        if ($fromDate) {
            $query->where('log_date', '>=', $fromDate);
        }

        return $query
            ->selectRaw($this->typeExpression() . ' as type')
            ->selectRaw($this->amountExpression() . ' as total_ml')
            ->groupByRaw($this->typeExpression())
            ->orderByRaw($this->typeExpression())
            ->get()
            ->map(fn ($row) => [
                'type' => $this->displayType((string) $row->type),
                'total_ml' => (int) $row->total_ml,
            ])
            ->values()
            ->toArray();
    }

    private function amountExpression(): string
    {
        $parts = [];

        if ($this->hasColumn('quantity_ml')) {
            $parts[] = 'quantity_ml';
        }

        if ($this->hasColumn('amount_ml')) {
            $parts[] = 'amount_ml';
        }

        if ($this->hasColumn('water_ml')) {
            $parts[] = 'water_ml';
        }

        if (!$parts) {
            return '0';
        }

        return 'COALESCE(SUM(COALESCE(' . implode(', ', $parts) . ', 0)), 0)';
    }

    private function typeExpression(): string
    {
        $parts = [];

        if ($this->hasColumn('hydration_type')) {
            $parts[] = 'hydration_type';
        }

        if ($this->hasColumn('drink_type')) {
            $parts[] = 'drink_type';
        }

        if (!$parts) {
            return "'Other'";
        }

        return 'COALESCE(' . implode(', ', $parts) . ", 'Other')";
    }

    private function displayType(string $type): string
    {
        return match (strtolower($type)) {
            'water' => 'Water',
            'coffee' => 'Coffee',
            'tea' => 'Tea',
            'juice' => 'Juice',
            'soft_drink', 'soft drink', 'soda' => 'Soft Drink',
            'soup' => 'Soup',
            default => 'Other',
        };
    }

    private function formatLogTime(string $date, string $time): string
    {
        $type = $this->columnType('log_time');

        if (in_array($type, ['datetime', 'timestamp', 'timestamptz', 'datetimetz'], true)) {
            return Carbon::parse($date . ' ' . $time)->toDateTimeString();
        }

        return Carbon::parse($time)->format('H:i:s');
    }

    private function putIfColumn(array &$payload, string $column, mixed $value): void
    {
        if ($this->hasColumn($column)) {
            $payload[$column] = $value;
        }
    }

    private function hasColumn(string $column): bool
    {
        return Schema::hasColumn($this->table, $column);
    }

    private function columnType(string $column): string
    {
        try {
            return Schema::getColumnType($this->table, $column);
        } catch (\Throwable) {
            return '';
        }
    }
}

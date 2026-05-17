<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ProductivityHabit;
use App\Models\ProductivityHabitCheckIn;
use Carbon\CarbonPeriod;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ProductivityHabitController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = ProductivityHabit::query()
            ->where('user_id', $user->id)
            ->withCount([
                'checkIns as completed_check_ins_count' => fn ($query) => $query->where('status', 'completed'),
                'checkIns as missed_check_ins_count' => fn ($query) => $query->where('status', 'missed'),
            ])
            ->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('frequency')) {
            $query->where('frequency', $request->string('frequency'));
        }

        return response()->json([
            'success' => true,
            'message' => 'Habits loaded successfully.',
            'data' => $query->get(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $this->validateHabit($request);

        $habit = ProductivityHabit::query()->create([
            'user_id' => $request->user()->id,
            'name' => $validated['name'],
            'description' => $validated['description'] ?? null,
            'status' => $validated['status'] ?? 'active',
            'frequency' => $validated['frequency'] ?? 'daily',
            'target_count' => $validated['target_count'] ?? 1,
            'metadata' => $this->metadataFromRequest($validated),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Habit created successfully.',
            'data' => $habit->fresh(),
        ], 201);
    }

    public function show(Request $request, ProductivityHabit $habit)
    {
        $this->authorizeHabit($request, $habit);

        $habit->load(['checkIns' => fn ($query) => $query->orderByDesc('check_in_date')->limit(30)]);
        $habit->loadCount([
            'checkIns as completed_check_ins_count' => fn ($query) => $query->where('status', 'completed'),
            'checkIns as missed_check_ins_count' => fn ($query) => $query->where('status', 'missed'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Habit loaded successfully.',
            'data' => $habit,
        ]);
    }

    public function update(Request $request, ProductivityHabit $habit)
    {
        $this->authorizeHabit($request, $habit);

        $validated = $this->validateHabit($request, false);

        $habit->fill([
            'name' => $validated['name'] ?? $habit->name,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : $habit->description,
            'status' => $validated['status'] ?? $habit->status,
            'frequency' => $validated['frequency'] ?? $habit->frequency,
            'target_count' => $validated['target_count'] ?? $habit->target_count,
            'metadata' => array_merge($habit->metadata ?? [], $this->metadataFromRequest($validated)),
        ])->save();

        return response()->json([
            'success' => true,
            'message' => 'Habit updated successfully.',
            'data' => $habit->fresh(),
        ]);
    }

    public function destroy(Request $request, ProductivityHabit $habit)
    {
        $this->authorizeHabit($request, $habit);
        $habit->delete();

        return response()->json([
            'success' => true,
            'message' => 'Habit deleted successfully.',
        ]);
    }

    public function checkIn(Request $request, ProductivityHabit $habit)
    {
        $this->authorizeHabit($request, $habit);

        $validated = $request->validate([
            'check_in_date' => ['nullable', 'date'],
            'date' => ['nullable', 'date'],
            'status' => ['nullable', Rule::in(['completed', 'missed', 'skipped'])],
            'count' => ['nullable', 'integer', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'metadata' => ['nullable', 'array'],
        ]);

        $date = Carbon::parse($validated['check_in_date'] ?? $validated['date'] ?? now())->toDateString();
        $status = $validated['status'] ?? 'completed';
        $count = $validated['count'] ?? ($status === 'completed' ? 1 : 0);

        $checkIn = ProductivityHabitCheckIn::query()->updateOrCreate(
            [
                'habit_id' => $habit->id,
                'check_in_date' => $date,
            ],
            [
                'user_id' => $request->user()->id,
                'status' => $status,
                'count' => $count,
                'notes' => $validated['notes'] ?? null,
                'metadata' => $validated['metadata'] ?? null,
            ]
        );

        $this->recalculateHabitStats($habit);

        return response()->json([
            'success' => true,
            'message' => 'Habit check-in saved successfully.',
            'data' => $checkIn->fresh(),
        ]);
    }

    public function weeklySummary(Request $request)
    {
        $validated = $request->validate([
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
        ]);

        $end = Carbon::parse($validated['end_date'] ?? now())->endOfDay();
        $start = Carbon::parse($validated['start_date'] ?? $end->copy()->subDays(6))->startOfDay();
        $userId = $request->user()->id;

        $activeHabits = ProductivityHabit::query()
            ->where('user_id', $userId)
            ->where('status', 'active')
            ->count();

        $rows = ProductivityHabitCheckIn::query()
            ->select('check_in_date', 'status', DB::raw('COUNT(*) as total'))
            ->where('user_id', $userId)
            ->whereBetween('check_in_date', [$start->toDateString(), $end->toDateString()])
            ->groupBy('check_in_date', 'status')
            ->get();

        $byDate = [];
        foreach ($rows as $row) {
            $date = Carbon::parse($row->check_in_date)->toDateString();
            $byDate[$date][$row->status] = (int) $row->total;
        }

        $daily = collect(CarbonPeriod::create($start, $end))->map(function (Carbon $date) use ($byDate) {
            $key = $date->toDateString();
            $completed = $byDate[$key]['completed'] ?? 0;
            $missed = $byDate[$key]['missed'] ?? 0;
            $skipped = $byDate[$key]['skipped'] ?? 0;

            return [
                'date' => $key,
                'completed' => $completed,
                'missed' => $missed,
                'skipped' => $skipped,
                'total' => $completed + $missed + $skipped,
            ];
        })->values();

        $completed = $daily->sum('completed');
        $missed = $daily->sum('missed');
        $skipped = $daily->sum('skipped');
        $totalCheckIns = $completed + $missed + $skipped;

        return response()->json([
            'success' => true,
            'message' => 'Weekly habits summary loaded successfully.',
            'data' => [
                'period' => [
                    'start_date' => $start->toDateString(),
                    'end_date' => $end->toDateString(),
                ],
                'summary' => [
                    'total_habits' => ProductivityHabit::query()->where('user_id', $userId)->count(),
                    'active_habits' => $activeHabits,
                    'completed_check_ins' => $completed,
                    'missed_check_ins' => $missed,
                    'skipped_check_ins' => $skipped,
                    'total_check_ins' => $totalCheckIns,
                    'completion_rate' => $this->percentage($completed, max($totalCheckIns, 1)),
                ],
                'daily_progress' => $daily,
            ],
        ]);
    }

    private function validateHabit(Request $request, bool $creating = true): array
    {
        $required = $creating ? 'required' : 'sometimes';

        $validated = $request->validate([
            'name' => [$required, 'string', 'max:255'],
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'status' => ['nullable', Rule::in(['active', 'paused', 'archived'])],
            'frequency' => ['nullable', Rule::in(['daily', 'weekly', 'monthly'])],
            'target_count' => ['nullable', 'integer', 'min:1', 'max:100'],
            'category' => ['nullable', 'string', 'max:100'],
            'priority' => ['nullable', Rule::in(['low', 'medium', 'high', 'critical'])],
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'metadata' => ['nullable', 'array'],
        ]);

        if (!isset($validated['name']) && isset($validated['title'])) {
            $validated['name'] = $validated['title'];
        }

        return $validated;
    }

    private function metadataFromRequest(array $validated): array
    {
        $metadata = $validated['metadata'] ?? [];

        foreach (['category', 'priority', 'start_date', 'end_date'] as $key) {
            if (array_key_exists($key, $validated)) {
                $metadata[$key] = $validated[$key];
            }
        }

        return $metadata;
    }

    private function authorizeHabit(Request $request, ProductivityHabit $habit): void
    {
        abort_if($habit->user_id !== $request->user()->id, 404, 'Habit not found.');
    }

    private function recalculateHabitStats(ProductivityHabit $habit): void
    {
        $habit->refresh();

        $completedDates = $habit->checkIns()
            ->where('status', 'completed')
            ->orderBy('check_in_date')
            ->pluck('check_in_date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->unique()
            ->values();

        $missedDates = $habit->checkIns()
            ->where('status', 'missed')
            ->pluck('check_in_date')
            ->map(fn ($date) => Carbon::parse($date)->toDateString())
            ->unique()
            ->values();

        $bestStreak = 0;
        $running = 0;
        $previous = null;

        foreach ($completedDates as $dateString) {
            $date = Carbon::parse($dateString);
            if ($previous && $previous->copy()->addDay()->isSameDay($date)) {
                $running++;
            } else {
                $running = 1;
            }

            $bestStreak = max($bestStreak, $running);
            $previous = $date;
        }

        $today = Carbon::today();
        $cursor = $today->copy();
        $currentStreak = 0;
        $completedLookup = $completedDates->flip();
        $missedLookup = $missedDates->flip();

        if (!$completedLookup->has($cursor->toDateString())) {
            $cursor->subDay();
        }

        while ($completedLookup->has($cursor->toDateString())) {
            if ($missedLookup->has($cursor->toDateString())) {
                break;
            }

            $currentStreak++;
            $cursor->subDay();
        }

        $todayCompleted = $habit->checkIns()
            ->whereDate('check_in_date', $today)
            ->where('status', 'completed')
            ->sum('count');

        $lastCompletedAt = $completedDates->isNotEmpty()
            ? Carbon::parse($completedDates->last())->endOfDay()
            : null;

        $habit->forceFill([
            'completed_count_today' => (int) $todayCompleted,
            'current_streak' => $currentStreak,
            'best_streak' => $bestStreak,
            'last_completed_at' => $lastCompletedAt,
        ])->save();
    }

    private function percentage(int $value, int $total): int
    {
        if ($total <= 0) {
            return 0;
        }

        return (int) round(($value / $total) * 100);
    }
}

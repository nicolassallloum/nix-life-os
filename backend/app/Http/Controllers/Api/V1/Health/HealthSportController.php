<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthSport;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthSportController extends Controller
{
    private array $sportTypes = [
        'Walking',
        'Running',
        'Cycling',
        'Swimming',
        'Gym',
        'Football',
        'Basketball',
        'Yoga',
        'Other',
    ];

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthSport::query()
            ->where('user_id', $user->id)
            ->when($request->filled('from'), fn ($q) => $q->whereDate('activity_date', '>=', $request->from))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('activity_date', '<=', $request->to))
            ->when($request->filled('sport_type'), fn ($q) => $q->where('sport_type', $request->sport_type))
            ->orderByDesc('activity_date')
            ->orderByDesc('created_at');

        $records = $query->get()
            ->map(fn (HealthSport $sport) => $this->serializeSport($sport))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Sport activities retrieved successfully.',
            'data' => [
                'records' => $records,
                'summary' => $this->summaryData($user->id),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatedPayload($request);

        $sport = HealthSport::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sport activity saved successfully.',
            'data' => $this->serializeSport($sport->fresh()),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $sport = HealthSport::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $sport) {
            return response()->json([
                'success' => false,
                'message' => 'Sport activity not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Sport activity loaded successfully.',
            'data' => $this->serializeSport($sport),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $sport = HealthSport::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $sport) {
            return response()->json([
                'success' => false,
                'message' => 'Sport activity not found.',
            ], 404);
        }

        $validated = $this->validatedPayload($request, true);

        $sport->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Sport activity updated successfully.',
            'data' => $this->serializeSport($sport->fresh()),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $deleted = HealthSport::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->delete();

        return response()->json([
            'success' => (bool) $deleted,
            'message' => $deleted ? 'Sport activity deleted successfully.' : 'Sport activity not found.',
        ], $deleted ? 200 : 404);
    }

    private function validatedPayload(Request $request, bool $isUpdate = false): array
    {
        $required = $isUpdate ? 'sometimes' : 'required';

        return $request->validate([
            'sport_type' => [$required, 'string', 'max:100', Rule::in($this->sportTypes)],
            'calories_burned' => [$required, 'numeric', 'min:0', 'max:100000'],
            'duration_minutes' => [$required, 'integer', 'min:1', 'max:10080'],
            'activity_date' => [$required, 'date'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }

    private function summaryData(string $userId): array
    {
        $today = Carbon::today(config('app.timezone'));
        $weekStart = Carbon::now(config('app.timezone'))->startOfWeek();
        $weekEnd = Carbon::now(config('app.timezone'))->endOfWeek();

        $base = HealthSport::query()->where('user_id', $userId);

        $todayQuery = (clone $base)->whereDate('activity_date', $today->toDateString());
        $weekQuery = (clone $base)->whereBetween('activity_date', [
            $weekStart->toDateString(),
            $weekEnd->toDateString(),
        ]);

        return [
            'total_calories_today' => round((float) (clone $todayQuery)->sum('calories_burned'), 2),
            'total_calories_week' => round((float) (clone $weekQuery)->sum('calories_burned'), 2),
            'total_minutes_today' => (int) (clone $todayQuery)->sum('duration_minutes'),
            'total_minutes_week' => (int) (clone $weekQuery)->sum('duration_minutes'),
        ];
    }

    private function serializeSport(HealthSport $sport): array
    {
        return [
            'id' => $sport->id,
            'user_id' => $sport->user_id,
            'sport_type' => $sport->sport_type,
            'calories_burned' => (float) $sport->calories_burned,
            'duration_minutes' => (int) $sport->duration_minutes,
            'activity_date' => $sport->activity_date?->format('Y-m-d'),
            'notes' => $sport->notes,
            'created_at' => $sport->created_at?->toISOString(),
            'updated_at' => $sport->updated_at?->toISOString(),
        ];
    }
}

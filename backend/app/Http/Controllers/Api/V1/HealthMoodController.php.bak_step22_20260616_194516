<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthMoodLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class HealthMoodController extends Controller
{
    private array $legacyMoodMap = [
        'happy' => 'Happy',
        'normal' => 'Neutral',
        'stressed' => 'Stressed',
        'sad' => 'Sad',
        'angry' => 'Angry',
        'tired' => 'Tired',
        'very sad' => 'Very Sad',
        'very happy' => 'Very Happy',
        'good' => 'Good',
        'calm' => 'Calm',
        'anxious' => 'Anxious',
    ];

    public function index(Request $request): JsonResponse
    {
        $logs = HealthMoodLog::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('mood_date')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (HealthMoodLog $log) => $this->serializeLog($log))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Mood logs retrieved successfully.',
            'data' => $logs,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $payload = $this->normalizePayload($request);

        $validated = validator($payload, [
            'mood_date' => ['required', 'date'],
            'mood_label' => ['required', 'string', 'max:100'],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:80'],
        ])->validate();

        $log = HealthMoodLog::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'mood_date' => $validated['mood_date'],
            ],
            [
                'id' => Str::uuid()->toString(),
                'mood_label' => $validated['mood_label'],
                'mood_score' => $validated['mood_score'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'tags' => $validated['tags'] ?? [],
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Mood saved successfully.',
            'data' => $this->serializeLog($log->fresh()),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $log = HealthMoodLog::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $log) {
            return response()->json([
                'success' => false,
                'message' => 'Mood log not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Mood log retrieved successfully.',
            'data' => $this->serializeLog($log),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $log = HealthMoodLog::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (! $log) {
            return response()->json([
                'success' => false,
                'message' => 'Mood log not found.',
            ], 404);
        }

        $payload = $this->normalizePayload($request);

        $validated = validator($payload, [
            'mood_date' => ['sometimes', 'required', 'date'],
            'mood_label' => ['sometimes', 'required', 'string', 'max:100'],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:80'],
        ])->validate();

        $log->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Mood updated successfully.',
            'data' => $this->serializeLog($log->fresh()),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $deleted = HealthMoodLog::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->delete();

        return response()->json([
            'success' => (bool) $deleted,
            'message' => $deleted ? 'Mood deleted successfully.' : 'Mood log not found.',
        ], $deleted ? 200 : 404);
    }

    private function normalizePayload(Request $request): array
    {
        $rawMood = $request->input('mood_label', $request->input('mood', 'Neutral'));
        $key = strtolower(trim((string) $rawMood));

        $tags = $request->input('tags', []);

        if (is_string($tags)) {
            $tags = collect(explode(',', $tags))
                ->map(fn ($tag) => trim($tag))
                ->filter()
                ->values()
                ->all();
        }

        return [
            'mood_date' => $request->input('mood_date', $request->input('entry_date', now()->toDateString())),
            'mood_label' => $this->legacyMoodMap[$key] ?? (string) $rawMood,
            'mood_score' => $request->input('mood_score'),
            'notes' => $request->input('notes'),
            'tags' => is_array($tags) ? $tags : [],
        ];
    }

    private function serializeLog(HealthMoodLog $log): array
    {
        return [
            'id' => $log->id,
            'user_id' => $log->user_id,
            'mood_date' => optional($log->mood_date)->format('Y-m-d') ?: $log->mood_date,
            'entry_date' => optional($log->mood_date)->format('Y-m-d') ?: $log->mood_date,
            'mood_label' => $log->mood_label,
            'mood' => strtolower(str_replace(' ', '_', (string) $log->mood_label)),
            'mood_score' => $log->mood_score,
            'notes' => $log->notes,
            'tags' => $log->tags ?: [],
            'created_at' => $log->created_at,
            'updated_at' => $log->updated_at,
        ];
    }
}

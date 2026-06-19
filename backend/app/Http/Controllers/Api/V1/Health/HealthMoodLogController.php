<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMoodLog;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HealthMoodLogController extends Controller
{
    private function normalizeMoodPayload(Request $request): void
    {
        $rawMood = $request->input('mood_label', $request->input('mood', 'Neutral'));
        $key = strtolower(trim((string) $rawMood));

        $label = match ($key) {
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
            default => (string) $rawMood,
        };

        $tags = $request->input('tags', []);

        if (is_string($tags)) {
            $tags = collect(explode(',', $tags))
                ->map(fn ($tag) => trim($tag))
                ->filter()
                ->values()
                ->all();
        }

        $score = $request->input('mood_score', $request->input('score', $request->input('rating', null)));

        if ($score === null || $score === '') {
            $score = match (strtolower((string) $label)) {
                'very sad' => 1,
                'sad' => 3,
                'tired' => 4,
                'stressed', 'anxious', 'angry' => 4,
                'neutral', 'normal' => 5,
                'good', 'calm' => 7,
                'happy' => 8,
                'very happy' => 10,
                default => 5,
            };
        }

        $request->merge([
            'mood_date' => $request->input('mood_date', $request->input('entry_date', $request->input('date', now()->toDateString()))),
            'mood_label' => $label,
            'mood_score' => (int) $score,
            'tags' => is_array($tags) ? $tags : [],
        ]);
    }

    public function index()
    {
        $logs = HealthMoodLog::where('user_id', Auth::id())
            ->orderByDesc('mood_date')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Mood logs loaded successfully.',
            'data' => $logs,
        ]);
    }

    public function store(Request $request)
    {
        $this->normalizeMoodPayload($request);

        $validated = $request->validate([
            'mood_date' => ['required', 'date'],
            'mood_label' => ['required', 'string', 'max:50'],
            'mood_score' => ['required', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:50'],
        ]);

        $log = HealthMoodLog::query()
            ->where('user_id', Auth::id())
            ->whereDate('mood_date', $validated['mood_date'])
            ->first();

        if ($log) {
            $log->update([
                'mood_label' => $validated['mood_label'],
                'mood_score' => $validated['mood_score'],
                'notes' => $validated['notes'] ?? null,
                'tags' => $validated['tags'] ?? [],
            ]);

            $message = 'Mood log updated successfully.';
            $status = 200;
        } else {
            $log = HealthMoodLog::create([
                'user_id' => Auth::id(),
                'mood_date' => $validated['mood_date'],
                'mood_label' => $validated['mood_label'],
                'mood_score' => $validated['mood_score'],
                'notes' => $validated['notes'] ?? null,
                'tags' => $validated['tags'] ?? [],
            ]);

            $message = 'Mood log created successfully.';
            $status = 201;
        }

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $log->fresh(),
        ], $status);
    }


    private function moodDateString($value): ?string
    {
        if (! $value) {
            return null;
        }

        if ($value instanceof \DateTimeInterface) {
            return $value->format('Y-m-d');
        }

        try {
            return Carbon::parse($value)->format('Y-m-d');
        } catch (\Throwable $e) {
            return is_string($value) ? substr($value, 0, 10) : null;
        }
    }

    public function summary()
    {
        $userId = Auth::id();

        $logs = HealthMoodLog::where('user_id', $userId)
            ->orderByDesc('mood_date')
            ->orderByDesc('created_at')
            ->get();

        $today = now(config('app.timezone'))->toDateString();

        $todayMood = $logs
            ->first(fn ($log) => $this->moodDateString($log->mood_date) === $today);

        $averageScore = $logs->count() > 0
            ? round((float) $logs->avg('mood_score'), 2)
            : 0;

        $moodCounts = $logs
            ->groupBy('mood_label')
            ->map(fn ($items, $label) => [
                'mood_label' => $label,
                'count' => $items->count(),
            ])
            ->values();

        $chart = $logs
            ->sortBy('mood_date')
            ->values()
            ->map(fn ($log) => [
                'date' => $this->moodDateString($log->mood_date),
                'mood_label' => $log->mood_label,
                'mood_score' => $log->mood_score !== null ? (int) $log->mood_score : null,
            ])
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Mood summary retrieved successfully.',
            'data' => [
                'total_logs' => $logs->count(),
                'today_mood' => $todayMood?->mood_label,
                'today_mood_score' => $todayMood?->mood_score,
                'average_mood_score' => $averageScore,
                'latest_mood' => $logs->first()?->mood_label,
                'latest_mood_score' => $logs->first()?->mood_score,
                'mood_counts' => $moodCounts,
                'chart' => $chart,
            ],
        ]);
    }

    public function show(string $id)
    {
        if ($id === 'summary') {
            return $this->summary();
        }

        $log = HealthMoodLog::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Mood log loaded successfully.',
            'data' => $log,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $this->normalizeMoodPayload($request);

        $log = HealthMoodLog::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $validated = $request->validate([
            'mood_date' => ['required', 'date'],
            'mood_label' => ['required', 'string', 'max:50'],
            'mood_score' => ['required', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:50'],
        ]);

        $log->update([
            'mood_date' => $validated['mood_date'],
            'mood_label' => $validated['mood_label'],
            'mood_score' => $validated['mood_score'],
            'notes' => $validated['notes'] ?? null,
            'tags' => $validated['tags'] ?? [],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mood log updated successfully.',
            'data' => $log,
        ]);
    }

    public function destroy(string $id)
    {
        $log = HealthMoodLog::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mood log deleted successfully.',
        ]);
    }
}

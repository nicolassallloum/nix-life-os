<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMoodLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HealthMoodLogController extends Controller
{
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
        $validated = $request->validate([
            'mood_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'entry_date' => ['nullable', 'date'],
            'mood' => ['nullable', 'string', 'max:50'],
            'mood_label' => ['nullable', 'string', 'max:50'],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:50'],
        ]);

        $moodDate = $validated['mood_date']
            ?? $validated['log_date']
            ?? $validated['entry_date']
            ?? now()->toDateString();

        $moodLabel = $validated['mood_label']
            ?? $validated['mood']
            ?? 'normal';

        $log = HealthMoodLog::create([
            'user_id' => Auth::id(),
            'mood_date' => $moodDate,
            'mood_label' => $moodLabel,
            'mood_score' => $validated['mood_score'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'tags' => $validated['tags'] ?? [],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mood log created successfully.',
            'data' => $log,
        ], 201);
    }

    public function show(string $id)
    {
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
        $log = HealthMoodLog::where('user_id', Auth::id())
            ->where('id', $id)
            ->firstOrFail();

        $validated = $request->validate([
            'mood_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'entry_date' => ['nullable', 'date'],
            'mood' => ['nullable', 'string', 'max:50'],
            'mood_label' => ['nullable', 'string', 'max:50'],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string', 'max:2000'],
            'tags' => ['nullable', 'array'],
            'tags.*' => ['nullable', 'string', 'max:50'],
        ]);

        $moodDate = $validated['mood_date']
            ?? $validated['log_date']
            ?? $validated['entry_date']
            ?? $log->mood_date
            ?? now()->toDateString();

        $moodLabel = $validated['mood_label']
            ?? $validated['mood']
            ?? $log->mood_label
            ?? 'normal';

        $log->update([
            'mood_date' => $moodDate,
            'mood_label' => $moodLabel,
            'mood_score' => $validated['mood_score'] ?? $log->mood_score,
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

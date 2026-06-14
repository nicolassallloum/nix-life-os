<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthMoodLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class HealthMoodController extends Controller
{
    private function dateColumn(): string
    {
        if (Schema::hasColumn('health_mood_logs', 'entry_date')) {
            return 'entry_date';
        }

        if (Schema::hasColumn('health_mood_logs', 'log_date')) {
            return 'log_date';
        }

        return 'created_at';
    }

    private function normalizePayload(array $validated): array
    {
        $dateColumn = $this->dateColumn();

        if (isset($validated['log_date']) && ! isset($validated[$dateColumn])) {
            $validated[$dateColumn] = $validated['log_date'];
        }

        if (isset($validated['entry_date']) && ! isset($validated[$dateColumn])) {
            $validated[$dateColumn] = $validated['entry_date'];
        }

        unset($validated['log_date'], $validated['entry_date']);

        return $validated;
    }

    public function index(Request $request)
    {
        $dateColumn = $this->dateColumn();

        $data = HealthMoodLog::where('user_id', $request->user()->id)
            ->orderByDesc($dateColumn)
            ->paginate(30);

        return response()->json([
            'success' => true,
            'message' => 'Mood logs loaded successfully.',
            'data' => $data,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'mood' => ['required', Rule::in(['happy', 'normal', 'stressed', 'sad', 'angry', 'tired'])],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string'],
        ]);

        $payload = $this->normalizePayload($validated);

        if (! isset($payload[$this->dateColumn()])) {
            $payload[$this->dateColumn()] = now()->toDateString();
        }

        $record = HealthMoodLog::create([
            ...$payload,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mood saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthMoodLog $mood)
    {
        abort_if((string) $mood->user_id !== (string) $request->user()->id, 403);

        return response()->json([
            'success' => true,
            'message' => 'Mood log loaded successfully.',
            'data' => $mood,
        ]);
    }

    public function update(Request $request, HealthMoodLog $mood)
    {
        abort_if((string) $mood->user_id !== (string) $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'mood' => ['sometimes', 'required', Rule::in(['happy', 'normal', 'stressed', 'sad', 'angry', 'tired'])],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string'],
        ]);

        $mood->update($this->normalizePayload($validated));

        return response()->json([
            'success' => true,
            'message' => 'Mood updated successfully.',
            'data' => $mood->fresh(),
        ]);
    }

    public function destroy(Request $request, HealthMoodLog $mood)
    {
        abort_if((string) $mood->user_id !== (string) $request->user()->id, 403);

        $mood->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mood deleted successfully.',
        ]);
    }
}

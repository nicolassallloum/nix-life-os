<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthMoodLog;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthMoodController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthMoodLog::where('user_id', $request->user()->id)
            ->orderByDesc('entry_date')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['required', 'date'],
            'mood' => ['required', Rule::in(['happy', 'normal', 'stressed', 'sad', 'angry', 'tired'])],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthMoodLog::create([
            ...$validated,
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
        abort_if($mood->user_id !== $request->user()->id, 403);

        return response()->json(['success' => true, 'data' => $mood]);
    }

    public function update(Request $request, HealthMoodLog $mood)
    {
        abort_if($mood->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['sometimes', 'required', 'date'],
            'mood' => ['sometimes', 'required', Rule::in(['happy', 'normal', 'stressed', 'sad', 'angry', 'tired'])],
            'mood_score' => ['nullable', 'integer', 'min:1', 'max:10'],
            'notes' => ['nullable', 'string'],
        ]);

        $mood->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Mood updated successfully.',
            'data' => $mood,
        ]);
    }

    public function destroy(Request $request, HealthMoodLog $mood)
    {
        abort_if($mood->user_id !== $request->user()->id, 403);

        $mood->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mood deleted successfully.',
        ]);
    }
}
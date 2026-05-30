<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthSleepLog;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthSleepController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthSleepLog::where('user_id', $request->user()->id)
            ->orderByDesc('entry_date')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['required', 'date'],
            'sleep_start' => ['nullable', 'date_format:H:i'],
            'sleep_end' => ['nullable', 'date_format:H:i'],
            'duration_hours' => ['required', 'numeric', 'min:0', 'max:24'],
            'quality' => ['nullable', Rule::in(['poor', 'fair', 'good', 'excellent'])],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthSleepLog::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthSleepLog $sleep)
    {
        abort_if($sleep->user_id !== $request->user()->id, 403);

        return response()->json(['success' => true, 'data' => $sleep]);
    }

    public function update(Request $request, HealthSleepLog $sleep)
    {
        abort_if($sleep->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['sometimes', 'required', 'date'],
            'sleep_start' => ['nullable', 'date_format:H:i'],
            'sleep_end' => ['nullable', 'date_format:H:i'],
            'duration_hours' => ['sometimes', 'required', 'numeric', 'min:0', 'max:24'],
            'quality' => ['nullable', Rule::in(['poor', 'fair', 'good', 'excellent'])],
            'notes' => ['nullable', 'string'],
        ]);

        $sleep->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log updated successfully.',
            'data' => $sleep,
        ]);
    }

    public function destroy(Request $request, HealthSleepLog $sleep)
    {
        abort_if($sleep->user_id !== $request->user()->id, 403);

        $sleep->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sleep log deleted successfully.',
        ]);
    }
}
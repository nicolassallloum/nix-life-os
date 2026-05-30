<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthWaterLog;
use Illuminate\Http\Request;

class HealthWaterController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthWaterLog::where('user_id', $request->user()->id)
            ->orderByDesc('entry_date')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['required', 'date'],
            'amount_ml' => ['required', 'integer', 'min:1', 'max:10000'],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthWaterLog::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Water intake saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthWaterLog $water)
    {
        abort_if($water->user_id !== $request->user()->id, 403);

        return response()->json(['success' => true, 'data' => $water]);
    }

    public function update(Request $request, HealthWaterLog $water)
    {
        abort_if($water->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['sometimes', 'required', 'date'],
            'amount_ml' => ['sometimes', 'required', 'integer', 'min:1', 'max:10000'],
            'notes' => ['nullable', 'string'],
        ]);

        $water->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Water intake updated successfully.',
            'data' => $water,
        ]);
    }

    public function destroy(Request $request, HealthWaterLog $water)
    {
        abort_if($water->user_id !== $request->user()->id, 403);

        $water->delete();

        return response()->json([
            'success' => true,
            'message' => 'Water intake deleted successfully.',
        ]);
    }
}
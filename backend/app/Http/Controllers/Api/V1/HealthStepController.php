<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthStep;
use Illuminate\Http\Request;

class HealthStepController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthStep::where('user_id', $request->user()->id)
            ->orderByDesc('entry_date')
            ->paginate(30);

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['required', 'date'],
            'steps' => ['required', 'integer', 'min:0'],
            'distance_km' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthStep::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'entry_date' => $validated['entry_date'],
            ],
            [
                'steps' => $validated['steps'],
                'distance_km' => $validated['distance_km'] ?? 0,
                'notes' => $validated['notes'] ?? null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Steps saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthStep $step)
    {
        abort_if($step->user_id !== $request->user()->id, 403);

        return response()->json([
            'success' => true,
            'data' => $step,
        ]);
    }

    public function update(Request $request, HealthStep $step)
    {
        abort_if($step->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['sometimes', 'required', 'date'],
            'steps' => ['sometimes', 'required', 'integer', 'min:0'],
            'distance_km' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $step->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Steps updated successfully.',
            'data' => $step,
        ]);
    }

    public function destroy(Request $request, HealthStep $step)
    {
        abort_if($step->user_id !== $request->user()->id, 403);

        $step->delete();

        return response()->json([
            'success' => true,
            'message' => 'Steps deleted successfully.',
        ]);
    }
}
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthWeightLog;
use Illuminate\Http\Request;

class HealthWeightController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthWeightLog::where('user_id', $request->user()->id)
            ->orderByDesc('entry_date')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['required', 'date'],
            'weight_kg' => ['required', 'numeric', 'min:1', 'max:500'],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthWeightLog::create([
            ...$validated,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Weight saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthWeightLog $weight)
    {
        abort_if($weight->user_id !== $request->user()->id, 403);

        return response()->json(['success' => true, 'data' => $weight]);
    }

    public function update(Request $request, HealthWeightLog $weight)
    {
        abort_if($weight->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['sometimes', 'required', 'date'],
            'weight_kg' => ['sometimes', 'required', 'numeric', 'min:1', 'max:500'],
            'notes' => ['nullable', 'string'],
        ]);

        $weight->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Weight updated successfully.',
            'data' => $weight,
        ]);
    }

    public function destroy(Request $request, HealthWeightLog $weight)
    {
        abort_if($weight->user_id !== $request->user()->id, 403);

        $weight->delete();

        return response()->json([
            'success' => true,
            'message' => 'Weight deleted successfully.',
        ]);
    }
}
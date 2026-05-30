<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthMedication;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class HealthMedicationController extends Controller
{
    public function index(Request $request)
    {
        $data = HealthMedication::where('user_id', $request->user()->id)
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->orderByDesc('start_date')
            ->paginate(30);

        return response()->json(['success' => true, 'data' => $data]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'medication_name' => ['required', 'string', 'max:200'],
            'dosage' => ['required', 'string', 'max:100'],
            'medication_time' => ['required', 'date_format:H:i'],
            'frequency_type' => ['required', Rule::in(['daily', 'weekly'])],
            'quantity' => ['required', 'integer', 'min:1', 'max:1000'],
            'start_date' => ['required', 'date'],
            'stop_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'status' => ['nullable', Rule::in(['active', 'stopped', 'completed'])],
            'notes' => ['nullable', 'string'],
        ]);

        $record = HealthMedication::create([
            ...$validated,
            'user_id' => $request->user()->id,
            'status' => $validated['status'] ?? 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Medication saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthMedication $medication)
    {
        abort_if($medication->user_id !== $request->user()->id, 403);

        return response()->json(['success' => true, 'data' => $medication]);
    }

    public function update(Request $request, HealthMedication $medication)
    {
        abort_if($medication->user_id !== $request->user()->id, 403);

        $validated = $request->validate([
            'medication_name' => ['sometimes', 'required', 'string', 'max:200'],
            'dosage' => ['sometimes', 'required', 'string', 'max:100'],
            'medication_time' => ['sometimes', 'required', 'date_format:H:i'],
            'frequency_type' => ['sometimes', 'required', Rule::in(['daily', 'weekly'])],
            'quantity' => ['sometimes', 'required', 'integer', 'min:1', 'max:1000'],
            'start_date' => ['sometimes', 'required', 'date'],
            'stop_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'status' => ['nullable', Rule::in(['active', 'stopped', 'completed'])],
            'notes' => ['nullable', 'string'],
        ]);

        $medication->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Medication updated successfully.',
            'data' => $medication,
        ]);
    }

    public function destroy(Request $request, HealthMedication $medication)
    {
        abort_if($medication->user_id !== $request->user()->id, 403);

        $medication->delete();

        return response()->json([
            'success' => true,
            'message' => 'Medication deleted successfully.',
        ]);
    }
}
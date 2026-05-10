<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMedication;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MedicationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = HealthMedication::query()
            ->where('user_id', $request->user()->id);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = strtolower($request->search);

            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(medication_name) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(dosage) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(frequency) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(prescribed_by) LIKE ?', ["%{$search}%"]);
            });
        }

        $medications = $query
            ->orderByRaw("CASE WHEN status = 'active' THEN 1 ELSE 2 END")
            ->orderByDesc('start_date')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Medications retrieved successfully.',
            'data' => $medications,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'medication_name' => ['required', 'string', 'max:255'],
            'dosage' => ['required', 'string', 'max:100'],
            'daily_dose' => ['nullable', 'string', 'max:100'],
            'dose_times' => ['nullable', 'array'],
            'dose_times.*' => ['nullable', 'date_format:H:i'],
            'frequency' => ['required', 'string', 'max:100'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'status' => ['required', Rule::in(['active', 'paused', 'completed', 'inactive'])],
            'prescribed_by' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $validated['user_id'] = $request->user()->id;

        $medication = HealthMedication::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Medication created successfully.',
            'data' => $medication,
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $medication = HealthMedication::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Medication retrieved successfully.',
            'data' => $medication,
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $medication = HealthMedication::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $validated = $request->validate([
            'medication_name' => ['required', 'string', 'max:255'],
            'dosage' => ['required', 'string', 'max:100'],
            'daily_dose' => ['nullable', 'string', 'max:100'],
            'dose_times' => ['nullable', 'array'],
            'dose_times.*' => ['nullable', 'date_format:H:i'],
            'frequency' => ['required', 'string', 'max:100'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'status' => ['required', Rule::in(['active', 'paused', 'completed', 'inactive'])],
            'prescribed_by' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        $medication->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Medication updated successfully.',
            'data' => $medication->fresh(),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $medication = HealthMedication::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $medication->delete();

        return response()->json([
            'success' => true,
            'message' => 'Medication deleted successfully.',
        ]);
    }
}
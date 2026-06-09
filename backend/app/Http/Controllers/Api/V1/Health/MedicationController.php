<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMedication;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class MedicationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = HealthMedication::query()
            ->with('times')
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
                    ->orWhereRaw('LOWER(COALESCE(prescribed_by, doctor_name, \'\')) LIKE ?', ["%{$search}%"]);
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

    public function today(Request $request): JsonResponse
    {
        $today = now()->toDateString();

        $medications = HealthMedication::query()
            ->with('times')
            ->where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->whereDate('start_date', '<=', $today)
            ->where(function ($query) use ($today) {
                $query->whereNull('end_date')
                    ->orWhereDate('end_date', '>=', $today);
            })
            ->orderBy('medication_name')
            ->get();

        $schedule = $medications->flatMap(function (HealthMedication $medication) use ($today) {
            return $medication->times->map(function ($time) use ($medication, $today) {
                $dosageTime = substr((string) $time->dosage_time, 0, 5);

                return [
                    'medication_id' => $medication->id,
                    'medication_name' => $medication->medication_name,
                    'dosage' => $medication->dosage,
                    'frequency' => $medication->frequency,
                    'status' => $medication->status,
                    'dosage_time' => $dosageTime,
                    'dosage_note' => $time->dosage_note,
                    'scheduled_for' => $today . ' ' . $dosageTime,
                ];
            });
        })->values();

        return response()->json([
            'success' => true,
            'message' => 'Today medication schedule retrieved successfully.',
            'data' => [
                'date' => $today,
                'active_medications_count' => $medications->count(),
                'schedule_count' => $schedule->count(),
                'schedule' => $schedule,
                'medications' => $medications,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validateMedication($request);

        $medication = DB::transaction(function () use ($request, $validated) {
            $times = $validated['times'] ?? [];
            unset($validated['times']);

            $validated['user_id'] = $request->user()->id;
            $validated['daily_times'] = count($times);
            $validated['dose_times'] = collect($times)->pluck('dosage_time')->values()->all();
            $validated['prescribed_by'] = $validated['doctor_name'] ?? $validated['prescribed_by'] ?? null;

            $medication = HealthMedication::create($validated);

            foreach ($times as $time) {
                $medication->times()->create([
                    'dosage_time' => $time['dosage_time'],
                    'dosage_note' => $time['dosage_note'] ?? null,
                ]);
            }

            return $medication->fresh('times');
        });

        return response()->json([
            'success' => true,
            'message' => 'Medication created successfully.',
            'data' => $medication,
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $medication = HealthMedication::query()
            ->with('times')
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

        $validated = $this->validateMedication($request, true);

        $medication = DB::transaction(function () use ($medication, $validated) {
            $times = $validated['times'] ?? [];
            unset($validated['times']);

            $validated['daily_times'] = count($times);
            $validated['dose_times'] = collect($times)->pluck('dosage_time')->values()->all();
            $validated['prescribed_by'] = $validated['doctor_name'] ?? $validated['prescribed_by'] ?? null;

            $medication->update($validated);

            $medication->times()->delete();

            foreach ($times as $time) {
                $medication->times()->create([
                    'dosage_time' => $time['dosage_time'],
                    'dosage_note' => $time['dosage_note'] ?? null,
                ]);
            }

            return $medication->fresh('times');
        });

        return response()->json([
            'success' => true,
            'message' => 'Medication updated successfully.',
            'data' => $medication,
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $medication = HealthMedication::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        DB::transaction(function () use ($medication) {
            $medication->times()->delete();
            $medication->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Medication deleted successfully.',
        ]);
    }

    private function validateMedication(Request $request, bool $isUpdate = false): array
    {
        return $request->validate([
            'medication_name' => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:255'],
            'dosage' => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:100'],
            'daily_times' => [$isUpdate ? 'sometimes' : 'required', 'integer', 'min:1', 'max:3'],
            'times' => [$isUpdate ? 'sometimes' : 'required', 'array', 'min:1', 'max:3'],
            'times.*.dosage_time' => ['required_with:times', 'date_format:H:i'],
            'times.*.dosage_note' => ['nullable', 'string', 'max:500'],
            'frequency' => [$isUpdate ? 'sometimes' : 'required', 'string', 'max:100'],
            'start_date' => [$isUpdate ? 'sometimes' : 'required', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'status' => [$isUpdate ? 'sometimes' : 'required', Rule::in(['active', 'paused', 'completed', 'inactive'])],
            'doctor_name' => ['nullable', 'string', 'max:255'],
            'prescribed_by' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthLabTest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthLabTestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = HealthLabTest::query()
            ->where('user_id', $request->user()->id);

        if ($request->filled('from_date')) {
            $query->whereDate('test_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('test_date', '<=', $request->to_date);
        }

        if ($request->filled('search')) {
            $search = strtolower($request->search);

            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(test_name) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(lab_name) LIKE ?', ["%{$search}%"])
                    ->orWhereRaw('LOWER(notes) LIKE ?', ["%{$search}%"]);
            });
        }

        $labTests = $query
            ->orderByDesc('test_date')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Lab tests retrieved successfully.',
            'data' => $labTests,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validateLabTest($request);

        $validated['user_id'] = $request->user()->id;
        $validated['test_name'] = $validated['test_name'] ?? 'CKD Blood Test Panel';
        $validated['source_type'] = $validated['source_type'] ?? 'manual';

        $labTest = HealthLabTest::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Lab test created successfully.',
            'data' => $labTest,
            'warnings' => $this->buildKidneyWarnings($labTest),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $labTest = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Lab test retrieved successfully.',
            'data' => $labTest,
            'warnings' => $this->buildKidneyWarnings($labTest),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $labTest = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $validated = $this->validateLabTest($request, true);

        $validated['test_name'] = $validated['test_name'] ?? $labTest->test_name ?? 'CKD Blood Test Panel';
        $validated['source_type'] = $validated['source_type'] ?? $labTest->source_type ?? 'manual';

        $labTest->update($validated);

        $freshLabTest = $labTest->fresh();

        return response()->json([
            'success' => true,
            'message' => 'Lab test updated successfully.',
            'data' => $freshLabTest,
            'warnings' => $this->buildKidneyWarnings($freshLabTest),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $labTest = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $labTest->delete();

        return response()->json([
            'success' => true,
            'message' => 'Lab test deleted successfully.',
        ]);
    }

    public function trends(Request $request): JsonResponse
    {
        $days = (int) $request->get('days', 180);

        if ($days < 1) {
            $days = 180;
        }

        if ($days > 3650) {
            $days = 3650;
        }

        $fromDate = now()->subDays($days)->toDateString();

        $rows = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->whereNotNull('test_date')
            ->whereDate('test_date', '>=', $fromDate)
            ->orderBy('test_date')
            ->orderBy('id')
            ->get();

        $chart = $rows->map(function ($row) {
            return [
                'id' => $row->id,
                'date' => $this->formatDateValue($row->test_date),
                'creatinine' => $this->toFloatOrNull($row->creatinine),
                'urea' => $this->toFloatOrNull($row->urea),
                'egfr' => $this->toFloatOrNull($row->egfr),
                'hemoglobin' => $this->toFloatOrNull($row->hemoglobin),
                'sodium' => $this->toFloatOrNull($row->sodium),
                'potassium' => $this->toFloatOrNull($row->potassium),
                'phosphorus' => $this->toFloatOrNull($row->phosphorus),
            ];
        })->values();

        $latest = $rows->last();

        return response()->json([
            'success' => true,
            'message' => 'Lab test trends retrieved successfully.',
            'data' => [
                'days' => $days,
                'from_date' => $fromDate,
                'total_records' => $rows->count(),
                'latest' => $latest,
                'chart' => $chart,
                'warnings' => $latest ? $this->buildKidneyWarnings($latest) : [],
            ],
        ]);
    }

    private function validateLabTest(Request $request, bool $isUpdate = false): array
    {
        $required = $isUpdate ? 'sometimes' : 'required';

        return $request->validate([
            'test_date' => [$required, 'date'],
            'test_name' => ['nullable', 'string', 'max:255'],
            'result_value' => ['nullable', 'string', 'max:100'],
            'unit' => ['nullable', 'string', 'max:50'],
            'reference_range' => ['nullable', 'string', 'max:100'],
            'lab_name' => ['nullable', 'string', 'max:255'],

            'creatinine' => ['nullable', 'numeric', 'min:0', 'max:30'],
            'urea' => ['nullable', 'numeric', 'min:0', 'max:500'],
            'egfr' => ['nullable', 'numeric', 'min:0', 'max:200'],
            'hemoglobin' => ['nullable', 'numeric', 'min:0', 'max:30'],
            'sodium' => ['nullable', 'numeric', 'min:80', 'max:180'],
            'potassium' => ['nullable', 'numeric', 'min:1', 'max:10'],
            'phosphorus' => ['nullable', 'numeric', 'min:0', 'max:20'],

            'source_type' => ['nullable', 'string', 'max:50', 'in:manual,upload,import'],
            'attachment_path' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }

    private function buildKidneyWarnings(?HealthLabTest $labTest): array
    {
        if (! $labTest) {
            return [];
        }

        $warnings = [];

        if ($labTest->creatinine !== null && (float) $labTest->creatinine > 1.3) {
            $warnings[] = 'Creatinine is above the common adult reference range. Review with your nephrologist.';
        }

        if ($labTest->urea !== null && (float) $labTest->urea > 50) {
            $warnings[] = 'Urea is elevated. This may require kidney-health review.';
        }

        if ($labTest->egfr !== null && (float) $labTest->egfr < 30) {
            $warnings[] = 'eGFR is below 30. This is a serious CKD warning level.';
        } elseif ($labTest->egfr !== null && (float) $labTest->egfr < 60) {
            $warnings[] = 'eGFR is below 60. Kidney function should be monitored closely.';
        }

        if ($labTest->hemoglobin !== null && (float) $labTest->hemoglobin < 13) {
            $warnings[] = 'Hemoglobin is low for an adult male range. Anemia follow-up may be needed.';
        }

        if ($labTest->sodium !== null && (float) $labTest->sodium < 135) {
            $warnings[] = 'Sodium is below common reference range.';
        }

        if ($labTest->sodium !== null && (float) $labTest->sodium > 145) {
            $warnings[] = 'Sodium is above common reference range.';
        }

        if ($labTest->potassium !== null && (float) $labTest->potassium > 5.0) {
            $warnings[] = 'Potassium is high. This can be important for CKD patients.';
        }

        if ($labTest->phosphorus !== null && (float) $labTest->phosphorus > 4.5) {
            $warnings[] = 'Phosphorus is high. CKD diet and medication review may be needed.';
        }

        return $warnings;
    }

    private function toFloatOrNull($value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        return (float) $value;
    }

    private function formatDateValue($value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return date('Y-m-d', strtotime((string) $value));
    }
}
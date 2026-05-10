<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthLabTest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthLabTestController extends Controller
{
    public function categories(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab test categories retrieved successfully.',
            'data' => [
                [
                    'key' => 'kidney',
                    'name' => 'Kidney Function',
                    'tests' => [
                        'Creatinine',
                        'Urea',
                        'eGFR',
                    ],
                ],
                [
                    'key' => 'electrolytes',
                    'name' => 'Electrolytes',
                    'tests' => [
                        'Sodium',
                        'Potassium',
                        'Phosphorus',
                    ],
                ],
                [
                    'key' => 'blood',
                    'name' => 'Blood / Anemia',
                    'tests' => [
                        'Hemoglobin',
                    ],
                ],
                [
                    'key' => 'general',
                    'name' => 'General Lab Test',
                    'tests' => [
                        'Custom Test',
                    ],
                ],
            ],
        ]);
    }
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
        $validated['category'] = $validated['category'] ?? 'kidney';
        $validated['source_type'] = $validated['source_type'] ?? 'manual';

        $previous = $this->findPreviousResult($request, $validated);

        if ($previous) {
            $validated['previous_result_id'] = $previous->id;
            $validated['comparison_status'] = $this->buildComparisonStatus($validated, $previous);
        }

        $abnormal = $this->detectAbnormalResultFromArray($validated);
        $validated['is_abnormal'] = $abnormal['is_abnormal'];
        $validated['abnormal_reason'] = $abnormal['reason'];

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

        $previous = $this->findPreviousResult($request, $validated, $labTest->id);

        if ($previous) {
            $validated['previous_result_id'] = $previous->id;
            $validated['comparison_status'] = $this->buildComparisonStatus($validated, $previous);
        }

        $abnormal = $this->detectAbnormalResultFromArray($validated);
        $validated['is_abnormal'] = $abnormal['is_abnormal'];
        $validated['abnormal_reason'] = $abnormal['reason'];

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
            'category' => ['nullable', 'string', 'max:100', 'in:kidney,electrolytes,blood,general'],
            'doctor_notes' => ['nullable', 'string', 'max:3000'],
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
private function findPreviousResult(Request $request, array $validated, ?string $excludeId = null): ?HealthLabTest
{
    $query = HealthLabTest::query()
        ->where('user_id', $request->user()->id)
        ->whereDate('test_date', '<', $validated['test_date'] ?? now()->toDateString());

    if (! empty($validated['category'])) {
        $query->where('category', $validated['category']);
    }

    if ($excludeId) {
        $query->where('id', '!=', $excludeId);
    }

    return $query
        ->orderByDesc('test_date')
        ->orderByDesc('created_at')
        ->first();
}

private function buildComparisonStatus(array $current, HealthLabTest $previous): ?string
{
    $fields = [
        'creatinine' => 'lower_is_better',
        'urea' => 'lower_is_better',
        'egfr' => 'higher_is_better',
        'potassium' => 'stable_is_better',
        'phosphorus' => 'lower_is_better',
        'hemoglobin' => 'higher_is_better',
    ];

    $changes = [];

    foreach ($fields as $field => $direction) {
        if (! isset($current[$field]) || $current[$field] === null || $previous->{$field} === null) {
            continue;
        }

        $newValue = (float) $current[$field];
        $oldValue = (float) $previous->{$field};

        if ($newValue === $oldValue) {
            continue;
        }

        if ($direction === 'lower_is_better') {
            $changes[] = $newValue < $oldValue
                ? "{$field} improved"
                : "{$field} increased";
        }

        if ($direction === 'higher_is_better') {
            $changes[] = $newValue > $oldValue
                ? "{$field} improved"
                : "{$field} decreased";
        }

        if ($direction === 'stable_is_better') {
            $changes[] = abs($newValue - $oldValue) <= 0.2
                ? "{$field} stable"
                : "{$field} changed";
        }
    }

    return count($changes) ? implode(', ', $changes) : 'No major change';
}

    private function detectAbnormalResultFromArray(array $data): array
    {
        $reasons = [];

        if (isset($data['creatinine']) && $data['creatinine'] !== null && (float) $data['creatinine'] > 1.3) {
            $reasons[] = 'Creatinine above common adult reference range';
        }

        if (isset($data['urea']) && $data['urea'] !== null && (float) $data['urea'] > 50) {
            $reasons[] = 'Urea elevated';
        }

        if (isset($data['egfr']) && $data['egfr'] !== null && (float) $data['egfr'] < 60) {
            $reasons[] = 'eGFR below 60';
        }

        if (isset($data['hemoglobin']) && $data['hemoglobin'] !== null && (float) $data['hemoglobin'] < 13) {
            $reasons[] = 'Hemoglobin low';
        }

        if (isset($data['potassium']) && $data['potassium'] !== null && (float) $data['potassium'] > 5.0) {
            $reasons[] = 'Potassium high';
        }

        if (isset($data['phosphorus']) && $data['phosphorus'] !== null && (float) $data['phosphorus'] > 4.5) {
            $reasons[] = 'Phosphorus high';
        }

        return [
            'is_abnormal' => count($reasons) > 0,
            'reason' => count($reasons) ? implode('; ', $reasons) : null,
        ];
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
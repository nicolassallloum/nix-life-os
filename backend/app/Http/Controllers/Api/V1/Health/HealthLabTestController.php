<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthLabTest;
use App\Models\HealthLabTestResult;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

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

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => ['nullable'],
            'category' => ['nullable', 'string', 'max:255'],
            'test_name' => ['nullable', 'string', 'max:255'],
            'test_date' => ['nullable', 'date'],
            'lab_name' => ['nullable', 'string', 'max:255'],
            'doctor_name' => ['nullable', 'string', 'max:255'],
            'doctor_notes' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'result_value' => ['nullable', 'numeric'],
            'unit' => ['nullable', 'string', 'max:50'],
            'reference_range' => ['nullable', 'string', 'max:255'],
            'file' => ['nullable', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png,webp'],
        ]);

        $file = $request->file('file');
        $path = null;
        $mimeType = null;

        if ($file) {
            $path = $file->store('health/lab-tests', 'public');
            $mimeType = $file->getClientMimeType();
        }

        $testName = $validated['test_name']
            ?? ($file ? pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME) : null)
            ?? 'Uploaded Lab Test';

        $category = $validated['category'] ?? 'general';

        $payload = [
            'user_id' => $request->user()->id,
            'test_name' => $testName,
            'test_date' => $validated['test_date'] ?? now()->toDateString(),
            'result_value' => $validated['result_value'] ?? 0,
            'unit' => $validated['unit'] ?? '',
            'reference_range' => $validated['reference_range'] ?? null,
            'lab_name' => $validated['lab_name'] ?? null,
            'doctor_name' => $validated['doctor_name'] ?? null,
            'doctor_notes' => $validated['doctor_notes'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'category' => $category,
            'category_id' => is_numeric($validated['category_id'] ?? null) ? (int) $validated['category_id'] : null,
            'source_type' => $file ? 'upload' : 'manual',
            'attachment_path' => $path,
            'file_path' => $path,
            'file_type' => $mimeType,
            'status' => 'normal',
            'ai_status' => $file ? 'uploaded' : 'approved',
            'is_abnormal' => false,
            'extracted_payload' => [
                'source' => $file ? 'uploaded_file' : 'manual_entry',
                'message' => $file
                    ? 'File uploaded successfully. Please review values before approval.'
                    : 'Manual lab test saved.',
                'results' => [],
            ],
            'created_at' => now(),
            'updated_at' => now(),
        ];

        $columns = \Illuminate\Support\Facades\Schema::getColumnListing('health_lab_tests');
        $payload = collect($payload)
            ->filter(fn ($value, $column) => in_array($column, $columns, true))
            ->all();

        if (isset($payload['extracted_payload']) && is_array($payload['extracted_payload'])) {
            $payload['extracted_payload'] = json_encode($payload['extracted_payload']);
        }

        $id = DB::table('health_lab_tests')->insertGetId($payload);

        $labTest = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->with(['category', 'results'])
            ->find($id);

        return response()->json([
            'success' => true,
            'message' => $file
                ? 'Lab test uploaded successfully. Review is still required before saving final results.'
                : 'Lab test saved successfully.',
            'data' => $labTest,
        ], Response::HTTP_CREATED);
    }

    public function upload(Request $request)
    {
        return $this->store($request);
    }

    public function extract(Request $request, int $id)
    {
        $labTest = $this->findUserLabTest($request, $id);

        $draftResults = data_get($labTest->extracted_payload, 'results', []);

        if (empty($draftResults)) {
            $draftResults = [[
                'test_name' => $labTest->test_name ?: '',
                'result_value' => $labTest->result_value,
                'unit' => $labTest->unit ?: '',
                'reference_min' => null,
                'reference_max' => null,
                'reference_text' => $labTest->reference_range ?: '',
                'status' => 'pending_review',
                'result_date' => optional($labTest->test_date)->toDateString() ?? now()->toDateString(),
                'doctor_name' => $labTest->doctor_name,
                'ai_confidence' => 0,
            ]];
        }

        $labTest->update([
            'ai_status' => 'pending_review',
            'extracted_payload' => [
                'source' => 'manual_placeholder',
                'message' => 'OCR/AI extraction is not enabled yet. Please manually review/edit values before approval.',
                'results' => $draftResults,
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Extraction placeholder created. Please review and edit values before approval.',
            'data' => $labTest->fresh()->load(['category', 'results']),
        ]);
    }

    public function preview(Request $request, int $id)
    {
        $labTest = $this->findUserLabTest($request, $id);

        $path = $labTest->file_path ?: $labTest->attachment_path;

        if (!$path || !Storage::disk('public')->exists($path)) {
            return response()->json([
                'success' => false,
                'message' => 'File not found.',
            ], Response::HTTP_NOT_FOUND);
        }

        return response()->file(Storage::disk('public')->path($path), [
            'Content-Type' => $labTest->file_type ?: 'application/octet-stream',
            'Content-Disposition' => 'inline; filename="' . basename($path) . '"',
        ]);
    }

    public function approve(Request $request, int $id)
    {
        $labTest = $this->findUserLabTest($request, $id);

        $validated = $request->validate([
            'results' => ['required', 'array', 'min:1'],
            'results.*.test_name' => ['required', 'string', 'max:255'],
            'results.*.result_value' => ['nullable', 'numeric'],
            'results.*.unit' => ['nullable', 'string', 'max:50'],
            'results.*.reference_min' => ['nullable', 'numeric'],
            'results.*.reference_max' => ['nullable', 'numeric'],
            'results.*.reference_text' => ['nullable', 'string'],
            'results.*.status' => ['nullable', 'string', 'max:50'],
            'results.*.result_date' => ['nullable', 'date'],
            'results.*.doctor_name' => ['nullable', 'string', 'max:255'],
            'results.*.ai_confidence' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        DB::transaction(function () use ($labTest, $validated) {
            if (\Illuminate\Support\Facades\Schema::hasTable('health_lab_test_results')) {
                HealthLabTestResult::where('lab_test_id', $labTest->id)->delete();

                foreach ($validated['results'] as $row) {
                    HealthLabTestResult::create([
                        'lab_test_id' => $labTest->id,
                        'test_name' => $row['test_name'],
                        'result_value' => $row['result_value'] ?? null,
                        'unit' => $row['unit'] ?? null,
                        'reference_min' => $row['reference_min'] ?? null,
                        'reference_max' => $row['reference_max'] ?? null,
                        'reference_text' => $row['reference_text'] ?? null,
                        'status' => $row['status'] ?? 'approved',
                        'result_date' => $row['result_date'] ?? optional($labTest->test_date)->toDateString(),
                        'doctor_name' => $row['doctor_name'] ?? $labTest->doctor_name,
                        'ai_confidence' => $row['ai_confidence'] ?? 0,
                        'user_approved' => true,
                    ]);
                }
            }

            $first = $validated['results'][0];

            $labTest->update([
                'test_name' => $first['test_name'] ?? $labTest->test_name,
                'result_value' => $first['result_value'] ?? $labTest->result_value,
                'unit' => $first['unit'] ?? $labTest->unit,
                'reference_range' => $first['reference_text'] ?? $labTest->reference_range,
                'ai_status' => 'approved',
                'approved_at' => now(),
                'extracted_payload' => [
                    'source' => 'user_approved',
                    'results' => $validated['results'],
                ],
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Lab test results approved and saved.',
            'data' => $labTest->fresh()->load(['category', 'results']),
        ]);
    }

    private function findUserLabTest(Request $request, int $id): HealthLabTest
    {
        return HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->with(['category', 'results'])
            ->findOrFail($id);
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
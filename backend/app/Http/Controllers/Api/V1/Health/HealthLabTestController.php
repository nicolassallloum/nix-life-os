<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthLabTest;
use App\Models\HealthLabTestResult;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\Response;

class HealthLabTestController extends Controller
{
    private array $categories = [
        [
            'id' => 'kidney',
            'key' => 'kidney',
            'name' => 'Kidney Function',
            'tests' => ['Creatinine', 'Urea', 'eGFR'],
        ],
        [
            'id' => 'electrolytes',
            'key' => 'electrolytes',
            'name' => 'Electrolytes',
            'tests' => ['Sodium', 'Potassium', 'Phosphorus'],
        ],
        [
            'id' => 'blood',
            'key' => 'blood',
            'name' => 'Blood / Anemia',
            'tests' => ['Hemoglobin'],
        ],
        [
            'id' => 'general',
            'key' => 'general',
            'name' => 'General Lab Test',
            'tests' => ['Custom Test'],
        ],
    ];

    public function index(Request $request): JsonResponse
    {
        $query = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->with('results')
            ->orderByDesc('test_date')
            ->orderByDesc('id');

        if ($request->filled('category_id')) {
            $query->where(function ($q) use ($request) {
                $q->where('category_id', is_numeric($request->category_id) ? (int) $request->category_id : null)
                  ->orWhere('category', $request->category_id);
            });
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('ai_status')) {
            $query->where('ai_status', $request->ai_status);
        }

        $rows = $query->get()->map(fn (HealthLabTest $test) => $this->serializeLabTest($test))->values();

        return response()->json([
            'success' => true,
            'message' => 'Lab tests retrieved successfully.',
            'data' => $rows,
            'categories' => $this->categories,
        ]);
    }

    public function categories(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab test categories retrieved successfully.',
            'data' => $this->categories,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        return $this->upload($request);
    }

    public function upload(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'category_id' => ['nullable'],
                'category' => ['nullable', 'string', 'max:100'],
                'test_name' => ['nullable', 'string', 'max:255'],
                'test_date' => ['nullable', 'date'],
                'lab_name' => ['nullable', 'string', 'max:255'],
                'doctor_name' => ['nullable', 'string', 'max:255'],
                'notes' => ['nullable', 'string'],
                'file' => ['required', 'file', 'max:10240', 'mimes:pdf,jpg,jpeg,png,webp'],
            ]);

            Storage::disk('public')->makeDirectory('health/lab-tests');

            $file = $request->file('file');
            $path = $file->store('health/lab-tests', 'public');

            $payload = [
                'user_id' => $request->user()->id,
                'test_date' => $validated['test_date'] ?? now()->toDateString(),
                'test_name' => $validated['test_name'] ?? 'Uploaded Lab Test',
                'category' => $this->resolveCategoryName($validated['category'] ?? $validated['category_id'] ?? null),
                'category_id' => is_numeric($validated['category_id'] ?? null) ? (int) $validated['category_id'] : null,
                'lab_name' => $validated['lab_name'] ?? null,
                'doctor_name' => $validated['doctor_name'] ?? null,
                'file_path' => $path,
                'attachment_path' => $path,
                'file_type' => $file->getClientMimeType(),
                'source_type' => 'upload',
                'ai_status' => 'uploaded',
                'status' => 'uploaded',
                'notes' => $validated['notes'] ?? null,
                'extracted_payload' => null,
            ];

            $payload = $this->filterColumns('health_lab_tests', $payload);

            $labTest = HealthLabTest::create($payload);

            return response()->json([
                'success' => true,
                'message' => 'Lab test uploaded successfully.',
                'data' => $this->serializeLabTest($labTest->fresh('results')),
            ], Response::HTTP_CREATED);
        } catch (\Throwable $e) {
            Log::error('Lab test upload failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Lab test upload failed.',
                'debug' => [
                    'message' => $e->getMessage(),
                    'file' => basename($e->getFile()),
                    'line' => $e->getLine(),
                ],
            ], 500);
        }
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);

        return response()->json([
            'success' => true,
            'message' => 'Lab test retrieved successfully.',
            'data' => $this->serializeLabTest($labTest),
        ]);
    }

    public function extract(Request $request, string $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);

        $draftResults = data_get($labTest->extracted_payload, 'results', []);

        if (empty($draftResults)) {
            $draftResults = [[
                'test_name' => $labTest->test_name ?: '',
                'result_value' => null,
                'unit' => '',
                'reference_min' => null,
                'reference_max' => null,
                'reference_text' => '',
                'status' => 'pending_review',
                'result_date' => optional($labTest->test_date)->format('Y-m-d') ?: now()->toDateString(),
                'doctor_name' => $labTest->doctor_name,
                'ai_confidence' => 0,
            ]];
        }

        $labTest->update($this->filterColumns('health_lab_tests', [
            'ai_status' => 'pending_review',
            'status' => 'pending_review',
            'extracted_payload' => [
                'source' => 'manual_placeholder',
                'message' => 'OCR/AI extraction is not enabled yet. Please manually review/edit values before approval.',
                'results' => $draftResults,
            ],
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Extraction placeholder created. Please review and edit values before approval.',
            'data' => $this->serializeLabTest($labTest->fresh('results')),
        ]);
    }

    public function preview(Request $request, string $id)
    {
        $labTest = $this->findUserLabTest($request, $id);

        $filePath = $labTest->file_path ?: $labTest->attachment_path;

        if (! $filePath || ! Storage::disk('public')->exists($filePath)) {
            return response()->json([
                'success' => false,
                'message' => 'File not found.',
            ], Response::HTTP_NOT_FOUND);
        }

        return response()->file(Storage::disk('public')->path($filePath), [
            'Content-Type' => $labTest->file_type ?: 'application/octet-stream',
            'Content-Disposition' => 'inline; filename="' . basename($filePath) . '"',
        ]);
    }

    public function approve(Request $request, string $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);

        $validated = $request->validate([
            'results' => ['required', 'array', 'min:1'],
            'results.*.test_name' => ['required', 'string', 'max:255'],
            'results.*.result_value' => ['nullable'],
            'results.*.unit' => ['nullable', 'string', 'max:50'],
            'results.*.reference_min' => ['nullable'],
            'results.*.reference_max' => ['nullable'],
            'results.*.reference_text' => ['nullable', 'string'],
            'results.*.status' => ['nullable', 'string', 'max:50'],
            'results.*.result_date' => ['nullable', 'date'],
            'results.*.doctor_name' => ['nullable', 'string', 'max:255'],
            'results.*.ai_confidence' => ['nullable'],
        ]);

        DB::transaction(function () use ($labTest, $validated) {
            HealthLabTestResult::query()->where('lab_test_id', $labTest->id)->delete();

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
                    'result_date' => $row['result_date'] ?? optional($labTest->test_date)->format('Y-m-d'),
                    'doctor_name' => $row['doctor_name'] ?? $labTest->doctor_name,
                    'ai_confidence' => $row['ai_confidence'] ?? 0,
                    'user_approved' => true,
                ]);
            }

            $labTest->update($this->filterColumns('health_lab_tests', [
                'ai_status' => 'approved',
                'status' => 'approved',
                'approved_at' => now(),
                'extracted_payload' => [
                    'source' => 'user_approved',
                    'results' => $validated['results'],
                ],
            ]));
        });

        return response()->json([
            'success' => true,
            'message' => 'Lab test results approved and saved.',
            'data' => $this->serializeLabTest($labTest->fresh('results')),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);

        $validated = $request->validate([
            'test_date' => ['nullable', 'date'],
            'test_name' => ['nullable', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:100'],
            'lab_name' => ['nullable', 'string', 'max:255'],
            'doctor_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'ai_status' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', 'string', 'max:50'],
        ]);

        $labTest->update($this->filterColumns('health_lab_tests', $validated));

        return response()->json([
            'success' => true,
            'message' => 'Lab test updated successfully.',
            'data' => $this->serializeLabTest($labTest->fresh('results')),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);
        $filePath = $labTest->file_path ?: $labTest->attachment_path;

        DB::transaction(function () use ($labTest) {
            HealthLabTestResult::query()->where('lab_test_id', $labTest->id)->delete();
            $labTest->delete();
        });

        if ($filePath && Storage::disk('public')->exists($filePath)) {
            Storage::disk('public')->delete($filePath);
        }

        return response()->json([
            'success' => true,
            'message' => 'Lab test deleted successfully.',
        ]);
    }

    public function trends(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Lab test trends retrieved successfully.',
            'data' => [],
        ]);
    }

    private function findUserLabTest(Request $request, string $id): HealthLabTest
    {
        return HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->with('results')
            ->findOrFail($id);
    }

    private function serializeLabTest(HealthLabTest $test): array
    {
        $categoryKey = $test->category ?: $this->resolveCategoryName($test->category_id);

        return [
            'id' => $test->id,
            'user_id' => $test->user_id,
            'category_id' => $test->category_id,
            'category' => [
                'id' => $categoryKey,
                'key' => $categoryKey,
                'name' => $this->resolveCategoryName($categoryKey),
            ],
            'category_name' => $this->resolveCategoryName($categoryKey),
            'test_date' => optional($test->test_date)->format('Y-m-d') ?: $test->test_date,
            'test_name' => $test->test_name,
            'lab_name' => $test->lab_name,
            'doctor_name' => $test->doctor_name,
            'file_path' => $test->file_path ?: $test->attachment_path,
            'file_type' => $test->file_type,
            'ai_status' => $test->ai_status ?: $test->status ?: 'uploaded',
            'status' => $test->status ?: $test->ai_status ?: 'uploaded',
            'notes' => $test->notes,
            'extracted_payload' => $test->extracted_payload,
            'approved_at' => $test->approved_at,
            'results' => $test->results ?: [],
            'created_at' => $test->created_at,
            'updated_at' => $test->updated_at,
        ];
    }

    private function resolveCategoryName(mixed $value): string
    {
        $key = strtolower(trim((string) ($value ?: 'general')));

        return match ($key) {
            'kidney', 'kidney function', '1' => 'Kidney Function',
            'electrolytes', '2' => 'Electrolytes',
            'blood', 'blood / anemia', 'anemia', '3' => 'Blood / Anemia',
            'general', 'general lab test', '4', '' => 'General Lab Test',
            default => (string) $value,
        };
    }

    private function filterColumns(string $table, array $payload): array
    {
        return collect($payload)
            ->filter(fn ($value, $column) => Schema::hasColumn($table, $column))
            ->all();
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthLabTest;
use App\Models\HealthLabTestResult;
use App\Models\HealthTestCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\Response;

class HealthLabTestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = HealthLabTest::query()
            ->with(['category', 'results'])
            ->where('user_id', $request->user()->id)
            ->latest('test_date')
            ->latest('id');

        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }

        if ($request->filled('ai_status')) {
            $query->where('ai_status', $request->string('ai_status'));
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate($request->integer('per_page', 20)),
            'categories' => HealthTestCategory::query()
                ->where('is_active', true)
                ->orderBy('name')
                ->get(),
        ]);
    }

    public function upload(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_id' => ['nullable', 'integer', Rule::exists('health_test_categories', 'id')],
            'test_date' => ['nullable', 'date'],
            'lab_name' => ['nullable', 'string', 'max:255'],
            'doctor_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'file' => [
                'required',
                'file',
                'max:10240',
                'mimes:pdf,jpg,jpeg,png,webp',
            ],
        ]);

        $file = $request->file('file');
        $path = $file->store('health/lab-tests', 'public');

        $labTest = HealthLabTest::create([
            'user_id' => $request->user()->id,
            'category_id' => $validated['category_id'] ?? null,
            'test_date' => $validated['test_date'] ?? now()->toDateString(),
            'lab_name' => $validated['lab_name'] ?? null,
            'doctor_name' => $validated['doctor_name'] ?? null,
            'file_path' => $path,
            'file_type' => $file->getClientMimeType(),
            'ai_status' => 'uploaded',
            'notes' => $validated['notes'] ?? null,
            'extracted_payload' => null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lab test uploaded successfully. Review is still required before saving final results.',
            'data' => $labTest->load(['category', 'results']),
        ], Response::HTTP_CREATED);
    }

    public function extract(Request $request, int $id): JsonResponse
    {
        $labTest = $this->findUserLabTest($request, $id);

        /*
         * Safe placeholder workflow:
         * No OCR/AI values are trusted or saved as final results here.
         * We only prepare editable draft rows inside extracted_payload.
         * Final rows are inserted into health_lab_test_results only in approve().
         */
        $draftResults = $labTest->extracted_payload['results'] ?? [];

        if (empty($draftResults)) {
            $draftResults = [
                [
                    'test_name' => '',
                    'result_value' => null,
                    'unit' => '',
                    'reference_min' => null,
                    'reference_max' => null,
                    'reference_text' => '',
                    'status' => 'pending_review',
                    'result_date' => optional($labTest->test_date)->toDateString() ?? now()->toDateString(),
                    'doctor_name' => $labTest->doctor_name,
                    'ai_confidence' => 0,
                ],
            ];
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

        if (!$labTest->file_path || !Storage::disk('public')->exists($labTest->file_path)) {
            return response()->json([
                'success' => false,
                'message' => 'File not found.',
            ], Response::HTTP_NOT_FOUND);
        }

        $path = Storage::disk('public')->path($labTest->file_path);

        return response()->file($path, [
            'Content-Type' => $labTest->file_type ?: 'application/octet-stream',
            'Content-Disposition' => 'inline; filename="' . basename($labTest->file_path) . '"',
        ]);
    }

    public function approve(Request $request, int $id): JsonResponse
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

            $labTest->update([
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
}

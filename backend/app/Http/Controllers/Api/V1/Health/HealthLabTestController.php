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
        $categories = $this->categories;

        if (Schema::hasTable('health_test_categories')) {
            $dbCategories = DB::table('health_test_categories')
                ->where('is_active', true)
                ->orderBy('name')
                ->get()
                ->map(fn ($category) => [
                    'id' => (string) $category->id,
                    'key' => $category->slug ?? (string) $category->id,
                    'name' => $category->name,
                    'tests' => [],
                ])
                ->values()
                ->all();

            if (! empty($dbCategories)) {
                $categories = array_merge($dbCategories, $this->categories);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Lab test categories retrieved successfully.',
            'data' => $categories,
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

            $extractedRows = $this->extractLabResultRowsFromFile($labTest->fresh());
            $draftRows = ! empty($extractedRows)
                ? $extractedRows
                : $this->defaultDraftLabResultRows($labTest->fresh());

            $this->prepareDraftLabResultRows(
                $labTest,
                $draftRows,
                ! empty($extractedRows) ? 'pdf_text_extraction' : 'upload_draft_rows'
            );
            $this->syncDraftLabResultRows($labTest->fresh(), $draftRows);

            return response()->json([
                'success' => true,
                'message' => 'Lab test uploaded successfully.',
                'data' => $this->serializeLabTest($labTest->fresh('results')),
            ], Response::HTTP_CREATED);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            Log::error('Lab test upload failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Lab test upload failed. Please verify the file and try again.',
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

        $extractedRows = $this->extractLabResultRowsFromFile($labTest);
        $draftResults = ! empty($extractedRows)
            ? $extractedRows
            : data_get($labTest->extracted_payload, 'results', []);

        if (empty($draftResults)) {
            $draftResults = $this->defaultDraftLabResultRows($labTest);
        }

        $source = ! empty($extractedRows) ? 'pdf_text_extraction' : 'manual_placeholder';

        $this->prepareDraftLabResultRows($labTest, $draftResults, $source);
        $this->syncDraftLabResultRows($labTest->fresh(), $draftResults);

        return response()->json([
            'success' => true,
            'message' => ! empty($extractedRows)
                ? 'Lab test values extracted from the uploaded file. Please review before approval.'
                : 'Extraction placeholder created. Please manually review/edit values before approval.',
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
        $rows = HealthLabTest::query()
            ->where('user_id', $request->user()->id)
            ->orderBy('test_date')
            ->get()
            ->map(fn (HealthLabTest $test) => [
                'id' => $test->id,
                'test_date' => optional($test->test_date)->format('Y-m-d') ?: $test->test_date,
                'creatinine' => $test->creatinine,
                'urea' => $test->urea,
                'egfr' => $test->egfr,
                'hemoglobin' => $test->hemoglobin,
                'sodium' => $test->sodium,
                'potassium' => $test->potassium,
                'phosphorus' => $test->phosphorus,
            ])
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Lab test trends retrieved successfully.',
            'data' => [
                'chart' => $rows,
                'warnings' => [],
            ],
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



    private function extractLabResultRowsFromFile(HealthLabTest $labTest): array
    {
        $filePath = $labTest->file_path ?: $labTest->attachment_path;

        if (! $filePath || ! Storage::disk('public')->exists($filePath)) {
            return [];
        }

        $absolutePath = Storage::disk('public')->path($filePath);
        $text = $this->extractTextFromPdfOrImage($absolutePath, (string) $labTest->file_type);

        if (trim($text) === '') {
            return [];
        }

        return $this->parseLabResultText($text, $labTest);
    }

    private function extractTextFromPdfOrImage(string $absolutePath, string $fileType): string
    {
        if (! is_file($absolutePath)) {
            return '';
        }

        $text = '';

        if (str_contains(strtolower($fileType), 'pdf')) {
            $text = $this->runShellCommand(
                'pdftotext -layout ' . escapeshellarg($absolutePath) . ' - 2>/dev/null'
            );

            if ($this->looksLikeLabText($text)) {
                return $text;
            }

            $ocrText = $this->ocrPdf($absolutePath);

            return trim($ocrText) !== '' ? $ocrText : $text;
        }

        return $this->runShellCommand(
            'tesseract ' . escapeshellarg($absolutePath) . ' stdout --psm 6 2>/dev/null'
        );
    }

    private function ocrPdf(string $absolutePath): string
    {
        if (trim($this->runShellCommand('command -v pdftoppm 2>/dev/null')) === '') {
            return '';
        }

        if (trim($this->runShellCommand('command -v tesseract 2>/dev/null')) === '') {
            return '';
        }

        $prefix = storage_path('app/lab-ocr-' . uniqid('', true));
        $this->runShellCommand(
            'pdftoppm -r 220 -png -f 1 -l 3 ' . escapeshellarg($absolutePath) . ' ' . escapeshellarg($prefix) . ' 2>/dev/null'
        );

        $text = '';
        $images = glob($prefix . '-*.png') ?: [];

        foreach ($images as $image) {
            $text .= "\n" . $this->runShellCommand(
                'tesseract ' . escapeshellarg($image) . ' stdout --psm 6 2>/dev/null'
            );

            @unlink($image);
        }

        return $text;
    }

    private function looksLikeLabText(string $text): bool
    {
        $text = strtolower($text);

        $matches = 0;

        foreach (['creatinine', 'urea', 'sodium', 'potassium', 'chloride', 'calcium', 'phosphorus', 'parathormone', 'gfr'] as $term) {
            if (str_contains($text, $term)) {
                $matches++;
            }
        }

        return $matches >= 2;
    }

    private function parseLabResultText(string $text, HealthLabTest $labTest): array
    {
        $definitions = [
            ['name' => 'Creatinine', 'aliases' => ['Creatinine'], 'unit' => 'mg/dL'],
            ['name' => 'eGFR', 'aliases' => ['Estimated GFR', 'Est. GFR', 'eGFR', 'EGFR', 'GFR'], 'unit' => 'mL/min'],
            ['name' => 'Urea', 'aliases' => ['Urea'], 'unit' => 'mg/dL'],
            ['name' => 'Sodium', 'aliases' => ['Sodium', 'Na'], 'unit' => 'mEq/L'],
            ['name' => 'Potassium', 'aliases' => ['Potassium', 'K'], 'unit' => 'mEq/L'],
            ['name' => 'Chloride', 'aliases' => ['Chloride', 'Cl'], 'unit' => 'mEq/L'],
            ['name' => 'CO2', 'aliases' => ['CO2', 'CO₂', 'Carbon Dioxide', 'Bicarbonate'], 'unit' => 'mEq/L'],
            ['name' => 'Anion Gap', 'aliases' => ['Anion Gap'], 'unit' => 'mEq/L'],
            ['name' => 'Calcium', 'aliases' => ['Calcium', 'Ca'], 'unit' => 'mg/dL'],
            ['name' => 'Phosphorus', 'aliases' => ['Phosphorus', 'Phosphate'], 'unit' => 'mg/dL'],
            ['name' => 'Parathormone', 'aliases' => ['Parathormone', 'PTH', 'Parathyroid Hormone'], 'unit' => 'pg/mL'],
            ['name' => 'Hemoglobin', 'aliases' => ['Hemoglobin', 'Hb', 'Hgb'], 'unit' => 'g/dL'],
            ['name' => 'WBC', 'aliases' => ['WBC', 'White Blood Cells'], 'unit' => '10^3/uL'],
            ['name' => 'RBC', 'aliases' => ['RBC', 'Red Blood Cells'], 'unit' => '10^6/uL'],
            ['name' => 'Hematocrit', 'aliases' => ['Hematocrit', 'HCT'], 'unit' => '%'],
        ];

        $rows = [];
        $seen = [];

        foreach (preg_split('/\R/u', $text) as $line) {
            $line = $this->normalizeLabTextLine($line);

            if ($line === '') {
                continue;
            }

            foreach ($definitions as $definition) {
                $row = $this->parseKnownLabLine($line, $definition, $labTest);

                if (! $row) {
                    continue;
                }

                $key = strtolower($row['test_name']);

                if (! isset($seen[$key])) {
                    $rows[] = $row;
                    $seen[$key] = true;
                }

                break;
            }
        }

        return $rows;
    }

    private function normalizeLabTextLine(string $line): string
    {
        $line = str_replace(["\u{00A0}", '–', '—', '−'], [' ', '-', '-', '-'], $line);
        $line = preg_replace('/[|]+/', ' ', $line);
        $line = preg_replace('/\s+/', ' ', trim($line));

        return $line ?: '';
    }

    private function parseKnownLabLine(string $line, array $definition, HealthLabTest $labTest): ?array
    {
        foreach ($definition['aliases'] as $alias) {
            $pattern = '/^(?:.*?\s)?' . preg_quote($alias, '/') . '\s+(.+)$/iu';

            if (! preg_match($pattern, $line, $matches)) {
                continue;
            }

            $tail = trim($matches[1]);

            if (! preg_match('/-?\d+(?:[.,]\d+)?/', $tail, $valueMatch)) {
                continue;
            }

            $value = str_replace(',', '.', $valueMatch[0]);
            $unit = $this->extractUnitFromLabLine($tail, $definition['unit']);
            [$referenceText, $referenceMin, $referenceMax] = $this->extractReferenceRangeFromLabLine($tail);
            $status = $this->extractStatusFromLabLine($tail);

            return [
                'test_name' => $definition['name'],
                'result_value' => $value,
                'unit' => $unit,
                'reference_min' => $referenceMin,
                'reference_max' => $referenceMax,
                'reference_text' => $referenceText,
                'status' => $status,
                'result_date' => $this->labTestDateValue($labTest),
                'doctor_name' => $labTest->doctor_name,
                'ai_confidence' => 0.85,
                'user_approved' => false,
            ];
        }

        return null;
    }

    private function extractUnitFromLabLine(string $line, string $defaultUnit): string
    {
        $unitPatterns = [
            'mL/min/1.73m²',
            'mL/min/1.73m2',
            'mL/min/1.73',
            'ml/mn/1.73m^2',
            'ml/mn/1.73m²',
            'ml/mn/1.73m2',
            'ml/mn/1.73',
            'ml/mn',
            'mL/min',
            'mg/dL',
            'mg/dl',
            'mEq/L',
            'mEq/l',
            'mmol/L',
            'mmol/l',
            'pg/mL',
            'pg/ml',
            'g/dL',
            'g/dl',
            '10^3/uL',
            '10^6/uL',
            '%',
        ];

        foreach ($unitPatterns as $unit) {
            if (stripos($line, $unit) !== false) {
                return match (strtolower($unit)) {
                    'mg/dl' => 'mg/dL',
                    'meq/l' => 'mEq/L',
                    'mmol/l' => 'mmol/L',
                    'pg/ml' => 'pg/mL',
                    'g/dl' => 'g/dL',
                    'ml/min/1.73m2', 'ml/min/1.73', 'ml/mn/1.73m^2', 'ml/mn/1.73m²', 'ml/mn/1.73m2', 'ml/mn/1.73', 'ml/mn' => 'mL/min/1.73m²',
                    default => $unit,
                };
            }
        }

        return $defaultUnit;
    }

    private function extractReferenceRangeFromLabLine(string $line): array
    {
        if (preg_match('/(-?\d+(?:[.,]\d+)?)\s*-\s*(-?\d+(?:[.,]\d+)?)/', $line, $matches)) {
            $min = str_replace(',', '.', $matches[1]);
            $max = str_replace(',', '.', $matches[2]);

            return [$min . ' - ' . $max, $min, $max];
        }

        if (preg_match('/(>=|<=|>|<)\s*(-?\d+(?:[.,]\d+)?)/', $line, $matches)) {
            $value = str_replace(',', '.', $matches[2]);

            return [$matches[1] . ' ' . $value, null, null];
        }

        return ['', null, null];
    }

    private function extractStatusFromLabLine(string $line): string
    {
        // Match only explicit status flags separated by spaces.
        // This avoids false LOW matches from units such as mg/dL or mEq/L.
        if (preg_match('/(?:^|\s)(H|HIGH)(?=\s|$)/i', $line)) {
            return 'high';
        }

        if (preg_match('/(?:^|\s)(L|LOW)(?=\s|$)/i', $line)) {
            return 'low';
        }

        return 'normal';
    }

    private function runShellCommand(string $command): string
    {
        if (! function_exists('proc_open')) {
            return '';
        }

        $pipes = [];
        $process = @proc_open($command, [
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ], $pipes);

        if (! is_resource($process)) {
            return '';
        }

        $output = stream_get_contents($pipes[1]) ?: '';
        fclose($pipes[1]);

        $error = stream_get_contents($pipes[2]) ?: '';
        fclose($pipes[2]);

        proc_close($process);

        return trim($output) !== '' ? $output : $error;
    }


    private function defaultDraftLabResultRows(HealthLabTest $labTest): array
    {
        $categoryValue = $labTest->category_name
            ?? data_get($labTest, 'category.name')
            ?? $labTest->category
            ?? $labTest->category_id
            ?? 'general';

        if (is_array($categoryValue)) {
            $categoryValue = $categoryValue['name'] ?? $categoryValue['key'] ?? 'general';
        }

        if (is_object($categoryValue)) {
            $categoryValue = data_get($categoryValue, 'name') ?? data_get($categoryValue, 'key') ?? 'general';
        }

        $categoryName = strtolower(trim((string) $categoryValue));

        $tests = match (true) {
            str_contains($categoryName, 'kidney') => [
                ['Creatinine', 'mg/dL'],
                ['Urea', 'mg/dL'],
                ['eGFR', 'mL/min'],
            ],
            str_contains($categoryName, 'electrolyte') => [
                ['Sodium', 'mmol/L'],
                ['Potassium', 'mmol/L'],
                ['Phosphorus', 'mg/dL'],
            ],
            str_contains($categoryName, 'blood') || str_contains($categoryName, 'anemia') => [
                ['Hemoglobin', 'g/dL'],
            ],
            default => [
                [$labTest->test_name ?: 'Uploaded Lab Test', ''],
            ],
        };

        return array_map(function (array $test) use ($labTest) {
            return [
                'test_name' => $test[0],
                'result_value' => null,
                'unit' => $test[1],
                'reference_min' => null,
                'reference_max' => null,
                'reference_text' => '',
                'status' => 'pending_review',
                'result_date' => $this->labTestDateValue($labTest),
                'doctor_name' => $labTest->doctor_name,
                'ai_confidence' => 0,
                'user_approved' => false,
            ];
        }, $tests);
    }

    private function labTestDateValue(HealthLabTest $labTest): string
    {
        $date = $labTest->test_date;

        if ($date instanceof \Carbon\CarbonInterface) {
            return $date->toDateString();
        }

        return $date ? (string) $date : now()->toDateString();
    }

    private function prepareDraftLabResultRows(
        HealthLabTest $labTest,
        array $draftRows,
        string $source = 'upload_draft_rows'
    ): void {
        $message = $source === 'pdf_text_extraction'
            ? 'Lab values were extracted from the uploaded file. Review and edit values before final approval.'
            : 'Editable draft result rows were created after upload. Review and update values before final approval.';

        if ($source === 'manual_placeholder') {
            $message = 'Automatic extraction could not read enough values. Please manually review/edit values before approval.';
        }

        $labTest->forceFill($this->filterColumns('health_lab_tests', [
            'ai_status' => 'pending_review',
            'status' => 'pending_review',
            'extracted_payload' => [
                'source' => $source,
                'message' => $message,
                'results' => $draftRows,
            ],
        ]))->save();
    }

    private function syncDraftLabResultRows(HealthLabTest $labTest, array $draftRows): int
    {
        $table = 'health_lab_test_results';

        if (! Schema::hasTable($table)) {
            return 0;
        }

        DB::table($table)->where('lab_test_id', $labTest->id)->delete();

        $count = 0;
        $now = now();

        foreach ($draftRows as $row) {
            $testName = trim((string) ($row['test_name'] ?? ''));

            if ($testName === '') {
                $testName = 'Uploaded Lab Test';
            }

            $payload = [
                'lab_test_id' => $labTest->id,
                'user_id' => $labTest->user_id,
                'test_name' => $testName,
                'result_value' => $row['result_value'] ?? null,
                'unit' => $row['unit'] ?? '',
                'reference_min' => $row['reference_min'] ?? null,
                'reference_max' => $row['reference_max'] ?? null,
                'reference_text' => $row['reference_text'] ?? '',
                'status' => $row['status'] ?? 'pending_review',
                'result_date' => $row['result_date'] ?? $this->labTestDateValue($labTest),
                'doctor_name' => $row['doctor_name'] ?? $labTest->doctor_name,
                'ai_confidence' => $row['ai_confidence'] ?? 0,
                'user_approved' => false,
                'created_at' => $now,
                'updated_at' => $now,
            ];

            DB::table($table)->insert($this->filterColumns($table, $payload));
            $count++;
        }

        return $count;
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

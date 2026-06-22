<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthReportService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Throwable;

class HealthReportController extends Controller
{
    public function __construct(
        private readonly HealthReportService $healthReportService
    ) {
    }

    public function daily(Request $request)
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        $fromDate = $request->query('from_date', $request->query('start_date'));
        $toDate = $request->query('to_date', $request->query('end_date'));

        if ($fromDate || $toDate) {
            $data = $this->healthReportService->dateRangeReport(
                (string) $user->id,
                $fromDate ?: now()->startOfMonth()->toDateString(),
                $toDate ?: now()->toDateString()
            );

            return response()->json([
                'success' => true,
                'message' => 'Date range health report loaded successfully.',
                'data' => $data,
            ]);
        }

        $date = $request->query('date', now()->toDateString());

        $data = $this->healthReportService->dailyReport((string) $user->id, $date);

        return response()->json([
            'success' => true,
            'message' => 'Daily health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function weekly(Request $request)
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        $startDate = $request->query('start_date', now()->startOfWeek()->toDateString());
        $endDate = $request->query('end_date', now()->endOfWeek()->toDateString());

        $data = $this->healthReportService->weeklyReport((string) $user->id, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'message' => 'Weekly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function monthly(Request $request)
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        $month = $request->query('month', now()->format('Y-m'));

        $data = $this->healthReportService->monthlyReport((string) $user->id, $month);

        return response()->json([
            'success' => true,
            'message' => 'Monthly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function exportPreview(Request $request)
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        try {
            $period = $request->query('period', 'date_range');
            $date = $request->query('date', now()->toDateString());
            $month = $request->query('month', now()->format('Y-m'));
            $startDate = $request->query('from_date', $request->query('start_date'));
            $endDate = $request->query('to_date', $request->query('end_date'));

            $data = $this->healthReportService->exportPreview(
                (string) $user->id,
                $period,
                $date,
                $month,
                $startDate,
                $endDate
            );

            return response()->json([
                'success' => true,
                'message' => 'Export-ready health report preview loaded successfully.',
                'data' => $data,
            ]);
        } catch (Throwable $e) {
            Log::error('Health report export preview failed', [
                'user_id' => $user->id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to load health report export preview.',
            ], 500);
        }
    }

    public function pdf(Request $request)
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        try {
            $userId = (string) $user->id;

            $period = $request->query('period', 'date_range');
            $date = $request->query('date', now()->toDateString());
            $month = $request->query('month', now()->format('Y-m'));
            $startDate = $request->query('from_date', $request->query('start_date'));
            $endDate = $request->query('to_date', $request->query('end_date'));

            $preview = $this->healthReportService->exportPreview(
                $userId,
                $period,
                $date,
                $month,
                $startDate,
                $endDate
            );

            $report = $preview['report'];

            $pdfData = [
                'title' => 'Nix Life OS Health Report',
                'generated_at' => now()->format('Y-m-d H:i:s'),
                'export_date' => now()->toFormattedDateString(),
                'user' => [
                    'name' => $user->name ?? 'Nix Life OS User',
                    'email' => $user->email ?? null,
                    'id' => $userId,
                ],
                'goals' => $this->healthGoals($userId),
                'medications' => $this->medications($userId),
                'lab_tests' => $this->recentLabTests($userId),
                'report' => $report,
                'period_label' => $this->periodLabel($report['period'] ?? []),
            ];

            $pdf = Pdf::loadView('pdf.health-report', $pdfData)
                ->setPaper('a4', 'portrait');

            $filename = 'nix-life-os-health-report-' . now()->format('Ymd-His') . '.pdf';
            $output = $pdf->output();

            return response($output, 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="' . $filename . '"',
                'Cache-Control' => 'private, max-age=0, must-revalidate',
                'Pragma' => 'public',
            ]);
        } catch (Throwable $e) {
            Log::error('Health report PDF export failed', [
                'user_id' => $user->id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to export health report PDF.',
            ], 500);
        }
    }

    private function healthGoals(string $userId): ?object
    {
        if (! Schema::hasTable('health_user_goals')) {
            return null;
        }

        return DB::table('health_user_goals')
            ->where('user_id', $userId)
            ->orderByDesc(Schema::hasColumn('health_user_goals', 'updated_at') ? 'updated_at' : 'id')
            ->first();
    }

    private function medications(string $userId)
    {
        if (! Schema::hasTable('health_medications')) {
            return collect();
        }

        $query = DB::table('health_medications')
            ->where('user_id', $userId);

        if (Schema::hasColumn('health_medications', 'deleted_at')) {
            $query->whereNull('deleted_at');
        }

        $orderColumn = Schema::hasColumn('health_medications', 'medication_name')
            ? 'medication_name'
            : (Schema::hasColumn('health_medications', 'name') ? 'name' : 'id');

        return $query
            ->orderBy($orderColumn)
            ->limit(50)
            ->get($this->selectAliases('health_medications', [
                'medication_name' => ['medication_name', 'name'],
                'dosage' => ['dosage'],
                'daily_dose' => ['daily_dose', 'dosage'],
                'frequency' => ['frequency'],
                'start_date' => ['start_date'],
                'end_date' => ['end_date'],
                'status' => ['status'],
                'doctor_name' => ['doctor_name', 'prescribed_by'],
                'prescribed_by' => ['prescribed_by', 'doctor_name'],
                'notes' => ['notes'],
            ]))
            ->unique(function ($medication) {
                return strtolower(trim(
                    ($medication->medication_name ?? '') . '|' .
                    ($medication->dosage ?? $medication->daily_dose ?? '') . '|' .
                    ($medication->frequency ?? '')
                ));
            })
            ->values()
            ->take(20);
    }

    private function recentLabTests(string $userId)
    {
        if (! Schema::hasTable('health_lab_tests')) {
            return collect();
        }

        $query = DB::table('health_lab_tests')
            ->where('user_id', $userId);

        if (Schema::hasColumn('health_lab_tests', 'test_date')) {
            $query->orderByDesc('test_date');
        } elseif (Schema::hasColumn('health_lab_tests', 'created_at')) {
            $query->orderByDesc('created_at');
        } else {
            $query->orderByDesc('id');
        }

        return $query
            ->limit(20)
            ->get($this->selectAliases('health_lab_tests', [
                'test_date' => ['test_date', 'created_at'],
                'test_name' => ['test_name', 'name', 'category'],
                'result_value' => ['result_value', 'value'],
                'unit' => ['unit'],
                'reference_range' => ['reference_range', 'reference_text'],
                'lab_name' => ['lab_name'],
                'doctor_name' => ['doctor_name'],
                'status' => ['status', 'ai_status'],
                'is_abnormal' => ['is_abnormal'],
                'abnormal_reason' => ['abnormal_reason'],
                'creatinine' => ['creatinine'],
                'urea' => ['urea'],
                'egfr' => ['egfr'],
                'hemoglobin' => ['hemoglobin'],
                'sodium' => ['sodium'],
                'potassium' => ['potassium'],
                'phosphorus' => ['phosphorus'],
            ]));
    }

    private function selectAliases(string $table, array $aliases): array
    {
        $select = [];

        foreach ($aliases as $alias => $candidates) {
            foreach ($candidates as $column) {
                if (Schema::hasColumn($table, $column)) {
                    $select[] = $column . ' as ' . $alias;
                    continue 2;
                }
            }

            $select[] = DB::raw('NULL as ' . $alias);
        }

        return $select;
    }

    private function periodLabel(array $period): string
    {
        $type = $period['type'] ?? 'monthly';

        if ($type === 'daily') {
            return 'Daily Report - ' . ($period['date'] ?? now()->toDateString());
        }

        if ($type === 'weekly') {
            return 'Weekly Report - ' . ($period['start_date'] ?? '') . ' to ' . ($period['end_date'] ?? '');
        }

        if (in_array($type, ['date_range', 'range', 'custom'], true)) {
            return 'Date Range Report - ' . ($period['from_date'] ?? $period['start_date'] ?? '') . ' to ' . ($period['to_date'] ?? $period['end_date'] ?? '');
        }

        return 'Monthly Report - ' . ($period['month'] ?? now()->format('Y-m'));
    }
}

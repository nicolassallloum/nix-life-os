<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;

class HealthReportController extends Controller
{
    public function __construct(
        private readonly HealthReportService $healthReportService
    ) {
    }

    public function daily(Request $request)
    {
        $userId = Auth::id();

        $date = $request->query('date', now()->toDateString());

        $data = $this->healthReportService->dailyReport($userId, $date);

        return response()->json([
            'success' => true,
            'message' => 'Daily health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function weekly(Request $request)
    {
        $userId = Auth::id();

        $startDate = $request->query('start_date', now()->startOfWeek()->toDateString());
        $endDate = $request->query('end_date', now()->endOfWeek()->toDateString());

        $data = $this->healthReportService->weeklyReport($userId, $startDate, $endDate);

        return response()->json([
            'success' => true,
            'message' => 'Weekly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function monthly(Request $request)
    {
        $userId = Auth::id();

        $month = $request->query('month', now()->format('Y-m'));

        $data = $this->healthReportService->monthlyReport($userId, $month);

        return response()->json([
            'success' => true,
            'message' => 'Monthly health report loaded successfully.',
            'data' => $data,
        ]);
    }

    public function pdf(Request $request)
    {
        $user = $request->user();

        if (!$user) {
            abort(401, 'Unauthenticated.');
        }

        $userId = (string) $user->id;

        $period = $request->query('period', 'monthly');
        $date = $request->query('date', now()->toDateString());
        $month = $request->query('month', now()->format('Y-m'));

        $preview = $this->healthReportService->exportPreview($userId, $period, $date, $month);
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
    }

    private function healthGoals(string $userId): ?object
    {
        if (!Schema::hasTable('health_user_goals')) {
            return null;
        }

        return DB::table('health_user_goals')
            ->where('user_id', $userId)
            ->orderByDesc('updated_at')
            ->first();
    }

    private function medications(string $userId)
    {
        if (!Schema::hasTable('health_medications')) {
            return collect();
        }

        return DB::table('health_medications')
            ->where('user_id', $userId)
            ->whereNull('deleted_at')
            ->orderBy('medication_name')
            ->limit(20)
            ->get([
                'medication_name',
                'dosage',
                'daily_dose',
                'frequency',
                'start_date',
                'end_date',
                'status',
                'doctor_name',
                'prescribed_by',
                'notes',
            ]);
    }

    private function recentLabTests(string $userId)
    {
        if (!Schema::hasTable('health_lab_tests')) {
            return collect();
        }

        return DB::table('health_lab_tests')
            ->where('user_id', $userId)
            ->orderByDesc('test_date')
            ->limit(20)
            ->get([
                'test_date',
                'test_name',
                'result_value',
                'unit',
                'reference_range',
                'lab_name',
                'doctor_name',
                'status',
                'is_abnormal',
                'abnormal_reason',
                'creatinine',
                'urea',
                'egfr',
                'hemoglobin',
                'sodium',
                'potassium',
                'phosphorus',
            ]);
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

        return 'Monthly Report - ' . ($period['month'] ?? now()->format('Y-m'));
    }

    public function exportPreview(Request $request)
    {
        $userId = Auth::id();

        $period = $request->query('period', 'monthly');
        $date = $request->query('date', now()->toDateString());
        $month = $request->query('month', now()->format('Y-m'));

        $data = $this->healthReportService->exportPreview($userId, $period, $date, $month);

        return response()->json([
            'success' => true,
            'message' => 'Export-ready health report preview loaded successfully.',
            'data' => $data,
        ]);
    }
}
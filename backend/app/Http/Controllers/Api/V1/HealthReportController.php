<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

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
<?php

namespace App\Http\Controllers\Api\V1\Dashboard;

use App\Http\Controllers\Controller;
use App\Services\Dashboard\UnifiedDashboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UnifiedDashboardController extends Controller
{
    public function __construct(
        protected UnifiedDashboardService $dashboardService
    ) {}

    public function overview(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Unified dashboard overview loaded successfully.',
            'data' => $this->dashboardService->getOverview($userId),
        ]);
    }

    public function finance(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Finance dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getFinanceKpis($userId),
        ]);
    }

    public function health(Request $request): JsonResponse
    {
        $userId = $request->user()->id;
        $date = $request->query('date', now()->toDateString());

        return response()->json([
            'success' => true,
            'message' => 'Health dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getHealthKpis($userId, $date),
        ]);
    }

    public function projects(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Project dashboard KPIs loaded successfully.',
            'data' => $this->dashboardService->getProjectKpis($userId),
        ]);
    }

    public function trends(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        return response()->json([
            'success' => true,
            'message' => 'Unified dashboard trends loaded successfully.',
            'data' => [
                'finance' => $this->dashboardService->getFinanceTrend($userId),
                'health' => $this->dashboardService->getHealthTrend($userId),
                'projects' => $this->dashboardService->getProjectProgressTrend($userId),
            ],
        ]);
    }
}

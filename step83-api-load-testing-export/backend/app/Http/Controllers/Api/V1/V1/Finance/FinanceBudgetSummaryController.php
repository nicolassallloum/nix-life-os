<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FinanceBudgetSummaryController extends Controller
{
    public function show(string $budget): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Budget summary retrieved successfully',
            'data' => [
                'budget_id' => $budget,
                'summary' => [],
            ],
        ]);
    }

    public function monthlySummary(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Monthly budget summary retrieved successfully',
            'data' => [
                'month' => $request->query('month'),
                'summary' => [],
            ],
        ]);
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FinanceForecastController extends Controller
{
    public function summary(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Forecast summary retrieved successfully',
            'data' => [
                'month' => $request->query('month'),
                'forecast' => [],
            ],
        ]);
    }

    public function storeSnapshot(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Forecast snapshot stored successfully',
            'data' => $request->all(),
        ], 201);
    }
}

<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FinanceAnomalyController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Anomaly results retrieved successfully',
            'data' => [],
        ]);
    }

    public function show(string $anomalyLog): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Anomaly retrieved successfully',
            'data' => [
                'anomaly_log_id' => $anomalyLog,
            ],
        ]);
    }

    public function runForTransaction(string $transactionId): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Anomaly detection executed successfully',
            'data' => [
                'transaction_id' => $transactionId,
                'results' => [],
            ],
        ]);
    }
}

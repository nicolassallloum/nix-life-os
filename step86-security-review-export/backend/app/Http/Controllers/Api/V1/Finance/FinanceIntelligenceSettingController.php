<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class FinanceIntelligenceSettingController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Finance intelligence settings retrieved successfully',
            'data' => [],
        ]);
    }

    public function upsert(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Finance intelligence settings updated successfully',
            'data' => $request->all(),
        ]);
    }
}

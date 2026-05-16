<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\ProductivityAIInsightService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class ProductivityAIInsightController extends Controller
{
    public function __construct(
        private readonly ProductivityAIInsightService $insightService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        try {
            $data = $this->insightService->generateForUser((string) $request->user()->id);

            return response()->json([
                'success' => true,
                'message' => $data['has_data']
                    ? 'Productivity AI insights generated successfully.'
                    : 'No productivity data available yet.',
                'data' => $data,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Unable to generate productivity AI insights.',
                'error' => config('app.debug') ? $exception->getMessage() : 'Server error',
            ], 500);
        }
    }
}

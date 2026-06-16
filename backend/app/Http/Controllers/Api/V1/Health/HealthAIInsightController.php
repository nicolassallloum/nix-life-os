<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthAIInsightService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Throwable;

class HealthAIInsightController extends Controller
{
    public function __construct(
        private readonly HealthAIInsightService $healthAIInsightService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        try {
            $payload = $this->healthAIInsightService->generateForUser((string) $request->user()->id);

            return response()->json([
                'success' => true,
                'message' => $payload['summary']['has_health_data']
                    ? 'Health AI insights generated successfully.'
                    : 'No health data available yet.',
                'data' => $payload,
            ]);
        } catch (Throwable $exception) {
            report($exception);

            return response()->json([
                'success' => false,
                'message' => 'Unable to generate Health AI insights.',
                'error' => config('app.debug') ? $exception->getMessage() : 'Internal server error.',
            ], 500);
        }
    }

    public function summary(Request $request): JsonResponse
    {
        return $this->index($request);
    }

    public function generate(Request $request): JsonResponse
    {
        return $this->index($request);
    }

}

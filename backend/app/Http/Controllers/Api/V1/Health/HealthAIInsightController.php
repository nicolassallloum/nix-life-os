<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Services\Health\HealthAIInsightService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class HealthAIInsightController extends Controller
{
    public function __construct(
        private readonly HealthAIInsightService $healthAIInsightService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        abort_if(! $user, 401, 'Unauthenticated.');

        try {
            $payload = $this->healthAIInsightService->generateForUser((string) $user->id);

            return response()->json([
                'success' => true,
                'message' => ($payload['summary']['has_health_data'] ?? false)
                    ? 'Health AI insights generated successfully.'
                    : 'No health data available yet.',
                'data' => $payload,
            ]);
        } catch (Throwable $exception) {
            Log::error('Health AI insights generation failed', [
                'user_id' => $user->id,
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Unable to generate Health AI insights.',
                'error' => config('app.debug') ? $exception->getMessage() : null,
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

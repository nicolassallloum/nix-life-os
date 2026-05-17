<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Services\FinanceAIInsightService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class FinanceAIInsightController extends Controller
{
    public function __construct(
        private readonly FinanceAIInsightService $financeAIInsightService
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['nullable', 'string', 'in:all,expenses,savings,budgets,income,anomalies,recommendations'],
        ]);

        try {
            $data = $this->financeAIInsightService->generate(
                userId: $request->user()->id,
                type: $validated['type'] ?? null
            );

            $hasData = empty($data['empty_state']);

            return response()->json([
                'success' => true,
                'message' => $hasData
                    ? 'Finance AI insights generated successfully.'
                    : 'No finance data available yet.',
                'data' => $data,
            ]);
        } catch (\Throwable $e) {
            Log::error('Finance AI insights generation failed', [
                'user_id' => $request->user()?->id,
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to generate Finance AI insights.',
                'error' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }
}

<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HealthHydrationLogController extends Controller
{
    private function phase6(): HealthHydrationController
    {
        return app(HealthHydrationController::class);
    }

    public function index(Request $request): JsonResponse
    {
        return $this->phase6()->index($request);
    }

    public function store(Request $request): JsonResponse
    {
        return $this->phase6()->store($request);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        if ($id === 'summary') {
            return $this->phase6()->summary($request);
        }

        if ($id === 'charts') {
            return $this->phase6()->charts($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'Hydration log detail endpoint is handled by Phase 6 routes.',
        ], 404);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        return $this->phase6()->update($request, $id);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        return $this->phase6()->destroy($request, $id);
    }

    public function quickAdd(Request $request): JsonResponse
    {
        $amount = (int) ($request->input('quantity_ml') ?? $request->input('amount_ml') ?? $request->input('water_ml') ?? 250);

        $request->merge([
            'hydration_type' => 'Water',
            'quantity_ml' => $amount,
            'log_date' => $request->input('log_date', now()->toDateString()),
            'log_time' => $request->input('log_time', now()->format('H:i')),
            'notes' => $request->input('notes', 'Quick add ' . $amount . ' ml'),
        ]);

        return $this->phase6()->store($request);
    }

    public function dailySummary(Request $request): JsonResponse
    {
        return $this->phase6()->summary($request);
    }

    public function weeklySummary(Request $request): JsonResponse
    {
        return $this->phase6()->summary($request);
    }
}

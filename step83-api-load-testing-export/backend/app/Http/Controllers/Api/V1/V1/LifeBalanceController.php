<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\LifeBalance\LifeBalanceService;
use Illuminate\Http\Request;

class LifeBalanceController extends Controller
{
    public function today(Request $request, LifeBalanceService $service)
    {
        $score = $service->calculate(
            userId: $request->user()->id,
            date: now()->toDateString()
        );

        return response()->json([
            'success' => true,
            'data' => $score,
        ]);
    }

    public function calculate(Request $request, LifeBalanceService $service)
    {
        $validated = $request->validate([
            'target_date' => ['nullable', 'date'],
        ]);

        $score = $service->calculate(
            userId: $request->user()->id,
            date: $validated['target_date'] ?? now()->toDateString()
        );

        return response()->json([
            'success' => true,
            'data' => $score,
        ]);
    }

    public function history(Request $request)
    {
        $days = (int) $request->query('days', 30);

        $scores = $request->user()
            ->lifeBalanceScores()
            ->orderByDesc('target_date')
            ->limit($days)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $scores,
        ]);
    }
}
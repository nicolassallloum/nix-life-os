<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\LifeBalanceAiRecommendationService;
use Illuminate\Http\Request;

class LifeBalanceAiRecommendationController extends Controller
{
    public function index(Request $request, LifeBalanceAiRecommendationService $service)
    {
        $payload = $service->generate((string) $request->user()->id);

        return response()->json([
            'success' => true,
            'message' => 'Life Balance AI recommendations generated successfully.',
            'data' => $payload,
        ]);
    }
}

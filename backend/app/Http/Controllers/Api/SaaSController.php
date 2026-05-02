<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Plan;
use App\Models\SubscriptionUsage;
use App\Services\SaaS\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SaaSController extends Controller
{
    public function plans(): JsonResponse
    {
        return response()->json([
            'data' => Plan::where('is_active', true)
                ->orderBy('monthly_price')
                ->get(),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        $subscription = app(SubscriptionService::class)
            ->getActiveSubscription($user);

        $usage = null;

        if ($subscription) {
            $usage = SubscriptionUsage::where('user_id', $user->id)
                ->where('subscription_id', $subscription->id)
                ->latest()
                ->first();
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
            ],
            'subscription' => $subscription,
            'plan' => $subscription?->plan,
            'usage' => $usage,
        ]);
    }
}

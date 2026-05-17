<?php

namespace App\Services\SaaS;

use App\Models\Plan;
use App\Models\Subscription;
use App\Models\SubscriptionUsage;
use App\Models\User;
use Carbon\Carbon;

class SubscriptionService
{
    public function createDefaultFreeSubscription(User $user): Subscription
    {
        $plan = Plan::where('code', 'free')->firstOrFail();

        $existingSubscription = Subscription::where('user_id', $user->id)
            ->where('status', 'active')
            ->first();

        if ($existingSubscription) {
            return $existingSubscription;
        }

        $subscription = Subscription::create([
            'user_id' => $user->id,
            'plan_id' => $plan->id,
            'status' => 'active',
            'billing_cycle' => 'monthly',
            'started_at' => now(),
            'trial_ends_at' => null,
            'current_period_starts_at' => now()->startOfMonth(),
            'current_period_ends_at' => now()->endOfMonth(),
            'metadata' => [
                'source' => 'manual_or_default_registration',
            ],
        ]);

        SubscriptionUsage::create([
            'user_id' => $user->id,
            'subscription_id' => $subscription->id,
            'finance_accounts_count' => 0,
            'projects_count' => 0,
            'ai_insights_used' => 0,
            'notifications_sent' => 0,
            'period_start' => Carbon::now()->startOfMonth()->toDateString(),
            'period_end' => Carbon::now()->endOfMonth()->toDateString(),
        ]);

        return $subscription;
    }

    public function getActiveSubscription(User $user): ?Subscription
    {
        return Subscription::with('plan')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->first();
    }

    public function userHasFeature(User $user, string $feature): bool
    {
        $subscription = $this->getActiveSubscription($user);

        if (!$subscription || !$subscription->plan) {
            return false;
        }

        return match ($feature) {
            'finance' => $subscription->plan->finance_module_enabled,
            'health' => $subscription->plan->health_module_enabled,
            'projects' => $subscription->plan->projects_module_enabled,
            'ai' => $subscription->plan->ai_module_enabled,
            'automation' => $subscription->plan->automation_module_enabled,
            'monitoring' => $subscription->plan->monitoring_module_enabled,
            default => false,
        };
    }
}

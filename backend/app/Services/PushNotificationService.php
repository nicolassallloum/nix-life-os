<?php

namespace App\Services;

use App\Models\PushSubscription;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;

class PushNotificationService
{
    public function sendToUser(string $userId, array $payload): void
    {
        $subscriptions = PushSubscription::query()
            ->where('user_id', $userId)
            ->get();

        if ($subscriptions->isEmpty()) {
            return;
        }

        $webPush = new WebPush([
            'VAPID' => [
                'subject' => config('services.push.subject'),
                'publicKey' => config('services.push.public_key'),
                'privateKey' => config('services.push.private_key'),
            ],
        ]);

        foreach ($subscriptions as $subscription) {
            $webPush->queueNotification(
                Subscription::create([
                    'endpoint' => $subscription->endpoint,
                    'publicKey' => $subscription->public_key,
                    'authToken' => $subscription->auth_token,
                    'contentEncoding' => $subscription->content_encoding,
                ]),
                json_encode($payload)
            );
        }

        foreach ($webPush->flush() as $report) {
            if (! $report->isSuccess()) {
                logger()->warning('Push notification failed', [
                    'reason' => $report->getReason(),
                ]);
            }
        }
    }
}

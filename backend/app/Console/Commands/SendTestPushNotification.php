<?php

namespace App\Console\Commands;

use App\Services\PushNotificationService;
use Illuminate\Console\Command;

class SendTestPushNotification extends Command
{
    protected $signature = 'push:test {user_id}';

    protected $description = 'Send a test push notification to a user.';

    public function handle(PushNotificationService $pushNotificationService): int
    {
        $userId = $this->argument('user_id');

        $pushNotificationService->sendToUser($userId, [
            'title' => 'Nix Life OS',
            'body' => 'Your PWA push notifications are working.',
            'url' => '/dashboard',
            'icon' => '/pwa/icons/icon-192x192.png',
        ]);

        $this->info('Push notification sent.');

        return self::SUCCESS;
    }
}
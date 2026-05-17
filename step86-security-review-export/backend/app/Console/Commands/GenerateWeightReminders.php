<?php

namespace App\Console\Commands;

use App\Models\NotificationPreference;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateWeightReminders extends Command
{
    protected $signature = 'notifications:weight-reminders';

    protected $description = 'Generate weight tracking reminder notifications';

    public function handle(NotificationService $notificationService): int
    {
        $now = Carbon::now()->format('H:i');

        $preferences = NotificationPreference::where('weight_reminders_enabled', true)
            ->where('weight_reminder_time', $now)
            ->get();

        foreach ($preferences as $pref) {
            $notificationService->createNotification(
                $pref->user_id,
                'weight_reminder',
                'Weight Check Reminder',
                'Do not forget to record your weight today.',
                'info',
                'health'
            );
        }

        $this->info('Weight reminders generated successfully.');

        return self::SUCCESS;
    }
}
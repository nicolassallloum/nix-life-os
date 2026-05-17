<?php

namespace App\Console\Commands;

use App\Models\NotificationPreference;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateMealReminders extends Command
{
    protected $signature = 'notifications:meal-reminders';

    protected $description = 'Generate meal reminder notifications';

    public function handle(NotificationService $notificationService): int
    {
        $now = Carbon::now()->format('H:i');

        $preferences = NotificationPreference::where('meal_reminders_enabled', true)->get();

        foreach ($preferences as $pref) {
            if ($pref->breakfast_time === $now) {
                $notificationService->createNotification(
                    $pref->user_id,
                    'meal_reminder',
                    'Breakfast Reminder',
                    'Time to log your breakfast meal.',
                    'info',
                    'health',
                    ['meal_type' => 'breakfast']
                );
            }

            if ($pref->lunch_time === $now) {
                $notificationService->createNotification(
                    $pref->user_id,
                    'meal_reminder',
                    'Lunch Reminder',
                    'Time to log your lunch meal.',
                    'info',
                    'health',
                    ['meal_type' => 'lunch']
                );
            }

            if ($pref->dinner_time === $now) {
                $notificationService->createNotification(
                    $pref->user_id,
                    'meal_reminder',
                    'Dinner Reminder',
                    'Time to log your dinner meal.',
                    'info',
                    'health',
                    ['meal_type' => 'dinner']
                );
            }
        }

        $this->info('Meal reminders generated successfully.');

        return self::SUCCESS;
    }
}
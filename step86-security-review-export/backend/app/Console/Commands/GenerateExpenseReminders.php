<?php

namespace App\Console\Commands;

use App\Models\NotificationPreference;
use App\Services\NotificationService;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateExpenseReminders extends Command
{
    protected $signature = 'notifications:expense-reminders';

    protected $description = 'Generate daily expense reminder notifications';

    public function handle(NotificationService $notificationService): int
    {
        $now = Carbon::now()->format('H:i');

        $preferences = NotificationPreference::where('expense_reminders_enabled', true)
            ->where('expense_reminder_time', $now)
            ->get();

        foreach ($preferences as $pref) {
            $notificationService->createNotification(
                $pref->user_id,
                'expense_reminder',
                'Expense Reminder',
                'Remember to log today’s expenses before the end of the day.',
                'info',
                'finance'
            );
        }

        $this->info('Expense reminders generated successfully.');

        return self::SUCCESS;
    }
}
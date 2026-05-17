<?php

namespace App\Services;

use App\Models\LifeNotification;
use App\Models\NotificationPreference;
use Carbon\Carbon;

class NotificationService
{
    public function createNotification(
        string $userId,
        string $type,
        string $title,
        string $message,
        string $severity = 'info',
        ?string $sourceModule = null,
        ?array $metadata = null,
        ?Carbon $scheduledFor = null
    ): LifeNotification {
        return LifeNotification::create([
            'user_id' => $userId,
            'notification_type' => $type,
            'title' => $title,
            'message' => $message,
            'severity' => $severity,
            'source_module' => $sourceModule,
            'metadata' => $metadata,
            'scheduled_for' => $scheduledFor,
            'triggered_at' => now(),
        ]);
    }

    public function getOrCreatePreferences(string $userId): NotificationPreference
    {
        return NotificationPreference::firstOrCreate(
            ['user_id' => $userId],
            [
                'meal_reminders_enabled' => true,
                'breakfast_time' => '08:00',
                'lunch_time' => '13:00',
                'dinner_time' => '19:00',

                'weight_reminders_enabled' => true,
                'weight_reminder_time' => '08:30',

                'expense_reminders_enabled' => true,
                'expense_reminder_time' => '21:00',

                'finance_alerts_enabled' => true,
                'health_alerts_enabled' => true,
                'life_balance_alerts_enabled' => true,

                'daily_expense_warning_limit' => 50,
                'life_balance_warning_score' => 60,
            ]
        );
    }

    public function markAsRead(string $notificationId, string $userId): ?LifeNotification
    {
        $notification = LifeNotification::where('id', $notificationId)
            ->where('user_id', $userId)
            ->first();

        if (!$notification) {
            return null;
        }

        $notification->update([
            'is_read' => true,
            'read_at' => now(),
        ]);

        return $notification;
    }

    public function markAllAsRead(string $userId): int
    {
        return LifeNotification::where('user_id', $userId)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }

    public function unreadCount(string $userId): int
    {
        return LifeNotification::where('user_id', $userId)
            ->where('is_read', false)
            ->count();
    }
}

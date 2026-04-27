<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NotificationPreference extends Model
{
    use HasUuids;

    protected $table = 'notification_preferences';

    protected $fillable = [
        'user_id',

        'meal_reminders_enabled',
        'breakfast_time',
        'lunch_time',
        'dinner_time',

        'weight_reminders_enabled',
        'weight_reminder_time',

        'expense_reminders_enabled',
        'expense_reminder_time',

        'finance_alerts_enabled',
        'health_alerts_enabled',
        'life_balance_alerts_enabled',

        'daily_expense_warning_limit',
        'life_balance_warning_score',

        'metadata',
    ];

    protected $casts = [
        'meal_reminders_enabled' => 'boolean',
        'weight_reminders_enabled' => 'boolean',
        'expense_reminders_enabled' => 'boolean',
        'finance_alerts_enabled' => 'boolean',
        'health_alerts_enabled' => 'boolean',
        'life_balance_alerts_enabled' => 'boolean',
        'metadata' => 'array',
    ];
}
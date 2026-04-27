<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationPreferenceController extends Controller
{
    public function show(Request $request, NotificationService $service)
    {
        $preferences = $service->getOrCreatePreferences($request->user()->id);

        return response()->json([
            'success' => true,
            'data' => $preferences,
        ]);
    }

    public function update(Request $request, NotificationService $service)
    {
        $preferences = $service->getOrCreatePreferences($request->user()->id);

        $validated = $request->validate([
            'meal_reminders_enabled' => ['nullable', 'boolean'],
            'breakfast_time' => ['nullable', 'date_format:H:i'],
            'lunch_time' => ['nullable', 'date_format:H:i'],
            'dinner_time' => ['nullable', 'date_format:H:i'],

            'weight_reminders_enabled' => ['nullable', 'boolean'],
            'weight_reminder_time' => ['nullable', 'date_format:H:i'],

            'expense_reminders_enabled' => ['nullable', 'boolean'],
            'expense_reminder_time' => ['nullable', 'date_format:H:i'],

            'finance_alerts_enabled' => ['nullable', 'boolean'],
            'health_alerts_enabled' => ['nullable', 'boolean'],
            'life_balance_alerts_enabled' => ['nullable', 'boolean'],

            'daily_expense_warning_limit' => ['nullable', 'integer', 'min:1'],
            'life_balance_warning_score' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        $preferences->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Notification preferences updated.',
            'data' => $preferences,
        ]);
    }
}
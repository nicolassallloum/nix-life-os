<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class NotificationPreferenceController extends Controller
{
    public function show(Request $request)
    {
        $userId = $request->user()->id;

        $preferences = DB::table('notification_preferences')
            ->where('user_id', $userId)
            ->first();

        if (! $preferences) {
            $preferences = $this->createDefaultPreferences($userId);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notification preferences loaded successfully.',
            'data' => $preferences,
        ]);
    }

    public function storeOrUpdate(Request $request)
    {
        $userId = $request->user()->id;

        $data = $request->validate([
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

            'daily_expense_warning_limit' => ['nullable', 'numeric', 'min:0'],
            'life_balance_warning_score' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        $defaults = [
            'meal_reminders_enabled' => true,
            'breakfast_time' => null,
            'lunch_time' => null,
            'dinner_time' => null,

            'weight_reminders_enabled' => true,
            'weight_reminder_time' => null,

            'expense_reminders_enabled' => true,
            'expense_reminder_time' => null,

            'finance_alerts_enabled' => true,
            'health_alerts_enabled' => true,
            'life_balance_alerts_enabled' => true,

            'daily_expense_warning_limit' => null,
            'life_balance_warning_score' => 60,
        ];

        $payload = array_merge($defaults, $data);

        $existing = DB::table('notification_preferences')
            ->where('user_id', $userId)
            ->first();

        if ($existing) {
            DB::table('notification_preferences')
                ->where('user_id', $userId)
                ->update(array_merge($payload, [
                    'updated_at' => now(),
                ]));
        } else {
            DB::table('notification_preferences')->insert(array_merge($payload, [
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }

        $preferences = DB::table('notification_preferences')
            ->where('user_id', $userId)
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Notification preferences saved successfully.',
            'data' => $preferences,
        ]);
    }

    private function createDefaultPreferences(string $userId)
    {
        DB::table('notification_preferences')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $userId,

            'meal_reminders_enabled' => true,
            'breakfast_time' => null,
            'lunch_time' => null,
            'dinner_time' => null,

            'weight_reminders_enabled' => true,
            'weight_reminder_time' => null,

            'expense_reminders_enabled' => true,
            'expense_reminder_time' => null,

            'finance_alerts_enabled' => true,
            'health_alerts_enabled' => true,
            'life_balance_alerts_enabled' => true,

            'daily_expense_warning_limit' => null,
            'life_balance_warning_score' => 60,

            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return DB::table('notification_preferences')
            ->where('user_id', $userId)
            ->first();
    }
}
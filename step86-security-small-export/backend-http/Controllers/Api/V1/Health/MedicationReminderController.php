<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMedication;
use App\Models\HealthMedicationDoseLog;
use App\Models\HealthMedicationReminder;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MedicationReminderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $reminders = HealthMedicationReminder::query()
            ->with('medication')
            ->where('user_id', $request->user()->id)
            ->orderBy('reminder_time')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Medication reminders retrieved successfully.',
            'data' => $reminders,
        ]);
    }

    public function today(Request $request): JsonResponse
    {
        $today = Carbon::today();

        $logs = HealthMedicationDoseLog::query()
            ->with('medication')
            ->where('user_id', $request->user()->id)
            ->whereDate('scheduled_for', $today)
            ->orderBy('scheduled_for')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Today medication schedule retrieved successfully.',
            'data' => $logs,
            'summary' => [
                'pending' => $logs->where('status', 'pending')->count(),
                'taken' => $logs->where('status', 'taken')->count(),
                'late' => $logs->where('status', 'late')->count(),
                'missed' => $logs->where('status', 'missed')->count(),
                'skipped' => $logs->where('status', 'skipped')->count(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'medication_id' => ['required', 'uuid'],
            'reminder_time' => ['required', 'date_format:H:i'],
            'frequency_type' => ['required', Rule::in(['daily', 'weekly', 'specific_days', 'every_x_hours'])],
            'days_of_week' => ['nullable', 'array'],
            'days_of_week.*' => ['integer', 'between:0,6'],
            'interval_hours' => ['nullable', 'integer', 'between:1,24'],
            'timezone' => ['nullable', 'string', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
            'notification_enabled' => ['nullable', 'boolean'],
        ]);

        $medication = HealthMedication::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $validated['medication_id'])
            ->firstOrFail();

        $validated['user_id'] = $request->user()->id;
        $validated['timezone'] = $validated['timezone'] ?? 'Asia/Beirut';
        $validated['is_active'] = $validated['is_active'] ?? true;
        $validated['notification_enabled'] = $validated['notification_enabled'] ?? true;

        $reminder = HealthMedicationReminder::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Medication reminder created successfully.',
            'data' => $reminder->load('medication'),
        ], 201);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $reminder = HealthMedicationReminder::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $validated = $request->validate([
            'reminder_time' => ['required', 'date_format:H:i'],
            'frequency_type' => ['required', Rule::in(['daily', 'weekly', 'specific_days', 'every_x_hours'])],
            'days_of_week' => ['nullable', 'array'],
            'days_of_week.*' => ['integer', 'between:0,6'],
            'interval_hours' => ['nullable', 'integer', 'between:1,24'],
            'timezone' => ['nullable', 'string', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
            'notification_enabled' => ['nullable', 'boolean'],
        ]);

        $reminder->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Medication reminder updated successfully.',
            'data' => $reminder->fresh()->load('medication'),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $reminder = HealthMedicationReminder::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $reminder->delete();

        return response()->json([
            'success' => true,
            'message' => 'Medication reminder deleted successfully.',
        ]);
    }
}
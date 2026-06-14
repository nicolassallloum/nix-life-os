<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthSleepLog;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class SleepLogController extends Controller
{
    public function index(Request $request)
    {
        $logs = HealthSleepLog::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('sleep_date')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Sleep logs retrieved successfully.',
            'data' => $logs,
            'summary' => $this->buildSummary($logs),
        ]);
    }

    public function store(Request $request)
    {
        $validator = $this->validateSleepLog($request);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $sleepDate = $request->sleep_date
            ?? $request->log_date
            ?? $request->entry_date
            ?? now()->toDateString();

        $bedTime = $request->bed_time ?? '22:00';
        $wakeTime = $request->wake_time ?? '06:00';

        $durationMinutes = $request->filled('duration_hours')
            ? (int) round(((float) $request->duration_hours) * 60)
            : $this->calculateDurationMinutes($bedTime, $wakeTime);

        $qualityScore = $request->quality_score;
        if ($qualityScore === null && $request->filled('quality')) {
            $qualityScore = match (strtolower((string) $request->quality)) {
                'excellent' => 90,
                'good' => 75,
                'fair' => 55,
                'poor' => 30,
                default => null,
            };
        }

        $log = HealthSleepLog::create([
            'user_id' => $request->user()->id,
            'sleep_date' => $sleepDate,
            'bed_time' => $bedTime,
            'wake_time' => $wakeTime,
            'duration_minutes' => $durationMinutes,
            'quality_score' => $qualityScore,
            'notes' => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log created successfully.',
            'data' => $log,
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $log = HealthSleepLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Sleep log retrieved successfully.',
            'data' => $log,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $log = HealthSleepLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $validator = $this->validateSleepLog($request);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'The given data was invalid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $sleepDate = $request->sleep_date
            ?? $request->log_date
            ?? $request->entry_date
            ?? $log->sleep_date
            ?? now()->toDateString();

        $bedTime = $request->bed_time ?? $log->bed_time ?? '22:00';
        $wakeTime = $request->wake_time ?? $log->wake_time ?? '06:00';

        $durationMinutes = $request->filled('duration_hours')
            ? (int) round(((float) $request->duration_hours) * 60)
            : $this->calculateDurationMinutes($bedTime, $wakeTime);

        $qualityScore = $request->quality_score ?? $log->quality_score;
        if ($request->filled('quality')) {
            $qualityScore = match (strtolower((string) $request->quality)) {
                'excellent' => 90,
                'good' => 75,
                'fair' => 55,
                'poor' => 30,
                default => $qualityScore,
            };
        }

        $log->update([
            'sleep_date' => $sleepDate,
            'bed_time' => $bedTime,
            'wake_time' => $wakeTime,
            'duration_minutes' => $durationMinutes,
            'quality_score' => $qualityScore,
            'notes' => $request->notes,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log updated successfully.',
            'data' => $log,
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $log = HealthSleepLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sleep log deleted successfully.',
        ]);
    }

    private function validateSleepLog(Request $request)
    {
        return Validator::make($request->all(), [
            'sleep_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'entry_date' => ['nullable', 'date'],
            'bed_time' => ['nullable', 'date_format:H:i'],
            'wake_time' => ['nullable', 'date_format:H:i'],
            'quality_score' => ['nullable', 'integer', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }

    private function calculateDurationMinutes(string $bedTime, string $wakeTime): int
    {
        $bed = Carbon::createFromFormat('H:i', substr($bedTime, 0, 5));
        $wake = Carbon::createFromFormat('H:i', substr($wakeTime, 0, 5));

        if ($wake->lessThanOrEqualTo($bed)) {
            $wake->addDay();
        }

        return $bed->diffInMinutes($wake);
    }

    private function buildSummary($logs): array
    {
        $totalLogs = $logs->count();

        if ($totalLogs === 0) {
            return [
                'total_logs' => 0,
                'average_duration_hours' => 0,
                'average_quality_score' => 0,
                'weekly_average_hours' => 0,
            ];
        }

        $weeklyLogs = $logs->filter(function ($log) {
            return Carbon::parse($log->sleep_date)->greaterThanOrEqualTo(
                now()->subDays(6)->startOfDay()
            );
        });

        return [
            'total_logs' => $totalLogs,
            'average_duration_hours' => round($logs->avg('duration_minutes') / 60, 2),
            'average_quality_score' => round($logs->avg('quality_score'), 2),
            'weekly_average_hours' => $weeklyLogs->count() > 0
                ? round($weeklyLogs->avg('duration_minutes') / 60, 2)
                : 0,
        ];
    }
}

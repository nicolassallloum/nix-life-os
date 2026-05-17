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

        $durationMinutes = $this->calculateDurationMinutes(
            $request->bed_time,
            $request->wake_time
        );

        $log = HealthSleepLog::create([
            'user_id' => $request->user()->id,
            'sleep_date' => $request->sleep_date,
            'bed_time' => $request->bed_time,
            'wake_time' => $request->wake_time,
            'duration_minutes' => $durationMinutes,
            'quality_score' => $request->quality_score,
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

        $durationMinutes = $this->calculateDurationMinutes(
            $request->bed_time,
            $request->wake_time
        );

        $log->update([
            'sleep_date' => $request->sleep_date,
            'bed_time' => $request->bed_time,
            'wake_time' => $request->wake_time,
            'duration_minutes' => $durationMinutes,
            'quality_score' => $request->quality_score,
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
            'sleep_date' => ['required', 'date'],
            'bed_time' => ['required', 'date'],
            'wake_time' => ['required', 'date', 'after:bed_time'],
            'quality_score' => ['nullable', 'integer', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);
    }

    private function calculateDurationMinutes(string $bedTime, string $wakeTime): int
    {
        $bed = Carbon::parse($bedTime);
        $wake = Carbon::parse($wakeTime);

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

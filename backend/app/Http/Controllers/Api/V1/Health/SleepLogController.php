<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthSleepLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class SleepLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $logs = HealthSleepLog::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('sleep_date')
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (HealthSleepLog $log) => $this->serializeLog($log))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Sleep logs loaded successfully.',
            'data' => $logs,
            'logs' => $logs,
            'sleep_logs' => $logs,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $payload = $this->normalizePayload($request);

        $log = HealthSleepLog::create([
            ...$payload,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log saved successfully.',
            'data' => $this->serializeLog($log),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $log = HealthSleepLog::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $this->serializeLog($log),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $log = HealthSleepLog::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $payload = $this->normalizePayload($request, true);

        $log->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log updated successfully.',
            'data' => $this->serializeLog($log->fresh()),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $log = HealthSleepLog::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sleep log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $userId = (string) $request->user()->id;
        $fromDate = now()->subDays(6)->toDateString();

        $logs = DB::table('health_sleep_logs')
            ->where('user_id', $userId)
            ->whereDate('sleep_date', '>=', $fromDate)
            ->orderByDesc('sleep_date')
            ->orderByDesc('created_at')
            ->get();

        $latest = $logs->first();
        $averageMinutes = $logs->count() > 0 ? round((float) $logs->avg('duration_minutes')) : 0;
        $averageQuality = $logs->count() > 0 ? round((float) $logs->avg('quality_score')) : 0;

        return response()->json([
            'success' => true,
            'message' => 'Sleep summary loaded successfully.',
            'data' => [
                'total_records' => $logs->count(),
                'last_sleep_minutes' => (int) ($latest->duration_minutes ?? 0),
                'last_sleep_hours' => round(((int) ($latest->duration_minutes ?? 0)) / 60, 2),
                'weekly_average_minutes' => (int) $averageMinutes,
                'weekly_average_hours' => round($averageMinutes / 60, 2),
                'average_quality_score' => (int) $averageQuality,
            ],
        ]);
    }

    public function today(Request $request): JsonResponse
    {
        $rows = DB::table('health_sleep_logs')
            ->where('user_id', (string) $request->user()->id)
            ->whereDate('sleep_date', now()->toDateString())
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($row) => $this->serializeRow($row))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Today sleep logs loaded successfully.',
            'data' => $rows,
            'logs' => $rows,
            'sleep_logs' => $rows,
        ]);
    }

    private function normalizePayload(Request $request, bool $isUpdate = false): array
    {
        $data = $request->all();

        if (isset($data['log_date']) && empty($data['sleep_date'])) {
            $data['sleep_date'] = $data['log_date'];
        }

        if (isset($data['entry_date']) && empty($data['sleep_date'])) {
            $data['sleep_date'] = $data['entry_date'];
        }

        if (empty($data['sleep_date'])) {
            $data['sleep_date'] = now()->toDateString();
        }

        if (isset($data['start_time']) && empty($data['bed_time'])) {
            $data['bed_time'] = $data['start_time'];
        }

        if (isset($data['sleep_start']) && empty($data['bed_time'])) {
            $data['bed_time'] = $data['sleep_start'];
        }

        if (isset($data['end_time']) && empty($data['wake_time'])) {
            $data['wake_time'] = $data['end_time'];
        }

        if (isset($data['sleep_end']) && empty($data['wake_time'])) {
            $data['wake_time'] = $data['sleep_end'];
        }

        if (isset($data['hours']) && empty($data['duration_hours'])) {
            $data['duration_hours'] = $data['hours'];
        }

        if (isset($data['quality']) && empty($data['sleep_quality'])) {
            $data['sleep_quality'] = $data['quality'];
        }

        $rules = [
            'sleep_date' => ['nullable', 'date'],
            'wake_date' => ['nullable', 'date'],
            'bed_time' => [$isUpdate ? 'sometimes' : 'required'],
            'wake_time' => [$isUpdate ? 'sometimes' : 'required'],
            'duration_minutes' => ['nullable', 'integer', 'min:0', 'max:1440'],
            'duration_hours' => ['nullable', 'numeric', 'min:0', 'max:24'],
            'sleep_quality' => ['nullable', 'string'],
            'quality' => ['nullable', Rule::in(['poor', 'fair', 'good', 'excellent', 'Poor', 'Fair', 'Good', 'Excellent'])],
            'quality_score' => ['nullable', 'integer', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string'],
        ];

        $validated = validator($data, $rules)->validate();

        $sleepDate = $validated['sleep_date'] ?? $data['sleep_date'] ?? now()->toDateString();

        $bedTime = $this->normalizeDateTime($validated['bed_time'] ?? $data['bed_time'] ?? null, $sleepDate);

        $wakeBaseDate = $validated['wake_date'] ?? $data['wake_date'] ?? $sleepDate;
        $wakeTime = $this->normalizeDateTime($validated['wake_time'] ?? $data['wake_time'] ?? null, $wakeBaseDate);

        if ($bedTime && $wakeTime && Carbon::parse($wakeTime)->lessThanOrEqualTo(Carbon::parse($bedTime))) {
            $wakeTime = Carbon::parse($wakeTime)->addDay()->format('Y-m-d H:i:s');
            $wakeBaseDate = Carbon::parse($wakeTime)->toDateString();
        }

        $durationMinutes = $validated['duration_minutes'] ?? null;

        if ($durationMinutes === null && isset($validated['duration_hours'])) {
            $durationMinutes = (int) round(((float) $validated['duration_hours']) * 60);
        }

        if ($durationMinutes === null && $bedTime && $wakeTime) {
            $durationMinutes = Carbon::parse($bedTime)->diffInMinutes(Carbon::parse($wakeTime));
        }

        $durationMinutes = max(0, min(1440, (int) ($durationMinutes ?? 0)));

        $qualityLabel = $validated['sleep_quality'] ?? $validated['quality'] ?? null;
        $qualityScore = $validated['quality_score'] ?? $this->qualityScoreFromLabel($qualityLabel);

        return [
            'sleep_date' => Carbon::parse($sleepDate)->toDateString(),
            'wake_date' => $wakeTime ? Carbon::parse($wakeTime)->toDateString() : ($wakeBaseDate ? Carbon::parse($wakeBaseDate)->toDateString() : null),
            'bed_time' => $bedTime,
            'wake_time' => $wakeTime,
            'duration_minutes' => $durationMinutes,
            'duration_hours' => round($durationMinutes / 60, 2),
            'quality_score' => $qualityScore,
            'quality' => $qualityLabel ? strtolower((string) $qualityLabel) : null,
            'notes' => $validated['notes'] ?? null,
        ];
    }

    private function normalizeDateTime(?string $value, string $fallbackDate): ?string
    {
        if ($value === null || trim($value) === '') {
            return null;
        }

        $value = trim($value);

        if (preg_match('/^\d{2}:\d{2}$/', $value)) {
            return Carbon::parse($fallbackDate . ' ' . $value . ':00')->format('Y-m-d H:i:s');
        }

        if (preg_match('/^\d{2}:\d{2}:\d{2}$/', $value)) {
            return Carbon::parse($fallbackDate . ' ' . $value)->format('Y-m-d H:i:s');
        }

        return Carbon::parse($value)->format('Y-m-d H:i:s');
    }

    private function qualityScoreFromLabel(?string $quality): ?int
    {
        if ($quality === null || $quality === '') {
            return null;
        }

        return match (strtolower(trim($quality))) {
            'poor' => 35,
            'fair' => 60,
            'good' => 85,
            'excellent' => 95,
            default => is_numeric($quality) ? (int) $quality : null,
        };
    }


    private function formatDateOnly(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse((string) $value)->toDateString();
    }

    private function formatDateTimeValue(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::parse((string) $value)->format('Y-m-d H:i:s');
    }

    private function serializeRow(object $row): array
    {
        $durationMinutes = (int) ($row->duration_minutes ?? 0);

        return [
            'id' => (string) ($row->id ?? ''),
            'user_id' => (string) ($row->user_id ?? ''),
            'sleep_date' => $this->formatDateOnly($row->sleep_date ?? null),
            'wake_date' => $this->formatDateOnly($row->wake_date ?? null),
            'bed_time' => $this->formatDateTimeValue($row->bed_time ?? null),
            'wake_time' => $this->formatDateTimeValue($row->wake_time ?? null),
            'duration_minutes' => $durationMinutes,
            'duration_hours' => round($durationMinutes / 60, 2),
            'hours' => round($durationMinutes / 60, 2),
            'sleep_hours' => round($durationMinutes / 60, 2),
            'quality_score' => $row->quality_score ?? null,
            'quality' => $row->quality ?? null,
            'notes' => $row->notes ?? null,
            'created_at' => isset($row->created_at) ? Carbon::parse((string) $row->created_at)->toISOString() : null,
            'updated_at' => isset($row->updated_at) ? Carbon::parse((string) $row->updated_at)->toISOString() : null,
        ];
    }

    private function serializeLog(HealthSleepLog $log): array
    {
        return [
            'id' => $log->id,
            'user_id' => $log->user_id,
            'sleep_date' => $this->formatDateOnly($log->sleep_date),
            'wake_date' => $this->formatDateOnly($log->wake_date),
            'bed_time' => $this->formatDateTimeValue($log->bed_time),
            'wake_time' => $this->formatDateTimeValue($log->wake_time),
            'duration_minutes' => (int) $log->duration_minutes,
            'duration_hours' => round(((int) $log->duration_minutes) / 60, 2),
            'hours' => round(((int) $log->duration_minutes) / 60, 2),
            'sleep_hours' => round(((int) $log->duration_minutes) / 60, 2),
            'quality_score' => $log->quality_score,
            'quality' => $log->quality,
            'notes' => $log->notes,
            'created_at' => optional($log->created_at)->toISOString(),
            'updated_at' => optional($log->updated_at)->toISOString(),
        ];
    }
}

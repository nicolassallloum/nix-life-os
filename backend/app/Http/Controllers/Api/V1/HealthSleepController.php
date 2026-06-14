<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\HealthSleepLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class HealthSleepController extends Controller
{
    private function dateColumn(): string
    {
        if (Schema::hasColumn('health_sleep_logs', 'entry_date')) {
            return 'entry_date';
        }

        if (Schema::hasColumn('health_sleep_logs', 'log_date')) {
            return 'log_date';
        }

        return 'created_at';
    }

    private function normalizePayload(array $validated): array
    {
        $dateColumn = $this->dateColumn();

        if (isset($validated['log_date']) && ! isset($validated[$dateColumn])) {
            $validated[$dateColumn] = $validated['log_date'];
        }

        if (isset($validated['entry_date']) && ! isset($validated[$dateColumn])) {
            $validated[$dateColumn] = $validated['entry_date'];
        }

        unset($validated['log_date'], $validated['entry_date']);

        return $validated;
    }

    public function index(Request $request)
    {
        $dateColumn = $this->dateColumn();

        $data = HealthSleepLog::where('user_id', $request->user()->id)
            ->orderByDesc($dateColumn)
            ->paginate(30);

        return response()->json([
            'success' => true,
            'message' => 'Sleep logs loaded successfully.',
            'data' => $data,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'entry_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'sleep_start' => ['nullable', 'date_format:H:i'],
            'sleep_end' => ['nullable', 'date_format:H:i'],
            'duration_hours' => ['required', 'numeric', 'min:0', 'max:24'],
            'quality' => ['nullable', Rule::in(['poor', 'fair', 'good', 'excellent'])],
            'notes' => ['nullable', 'string'],
        ]);

        $payload = $this->normalizePayload($validated);

        if (! isset($payload[$this->dateColumn()])) {
            $payload[$this->dateColumn()] = now()->toDateString();
        }

        $record = HealthSleepLog::create([
            ...$payload,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log saved successfully.',
            'data' => $record,
        ], 201);
    }

    public function show(Request $request, HealthSleepLog $sleep)
    {
        abort_if((string) $sleep->user_id !== (string) $request->user()->id, 403);

        return response()->json([
            'success' => true,
            'message' => 'Sleep log loaded successfully.',
            'data' => $sleep,
        ]);
    }

    public function update(Request $request, HealthSleepLog $sleep)
    {
        abort_if((string) $sleep->user_id !== (string) $request->user()->id, 403);

        $validated = $request->validate([
            'entry_date' => ['nullable', 'date'],
            'log_date' => ['nullable', 'date'],
            'sleep_start' => ['nullable', 'date_format:H:i'],
            'sleep_end' => ['nullable', 'date_format:H:i'],
            'duration_hours' => ['sometimes', 'required', 'numeric', 'min:0', 'max:24'],
            'quality' => ['nullable', Rule::in(['poor', 'fair', 'good', 'excellent'])],
            'notes' => ['nullable', 'string'],
        ]);

        $sleep->update($this->normalizePayload($validated));

        return response()->json([
            'success' => true,
            'message' => 'Sleep log updated successfully.',
            'data' => $sleep->fresh(),
        ]);
    }

    public function destroy(Request $request, HealthSleepLog $sleep)
    {
        abort_if((string) $sleep->user_id !== (string) $request->user()->id, 403);

        $sleep->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sleep log deleted successfully.',
        ]);
    }
}

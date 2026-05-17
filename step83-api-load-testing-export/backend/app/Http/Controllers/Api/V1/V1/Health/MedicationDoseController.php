<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Models\HealthMedicationDoseLog;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MedicationDoseController extends Controller
{
    public function markTaken(Request $request, string $id): JsonResponse
    {
        
        $dose = HealthMedicationDoseLog::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        if ($dose->status === 'skipped') {
            return response()->json([
                'success' => false,
                'message' => 'This dose was already skipped and cannot be marked as taken.',
            ], 422);
        }
        $now = Carbon::now();
        $status = $now->greaterThan($dose->scheduled_for) ? 'late' : 'taken';

        $dose->update([
            'status' => $status,
            'taken_at' => $now,
        ]);

        return response()->json([
            'success' => true,
            'message' => $status === 'late'
                ? 'Medication marked as taken late.'
                : 'Medication marked as taken.',
            'data' => $dose->fresh()->load('medication'),
        ]);
    }

    public function markSkipped(Request $request, string $id): JsonResponse
    {
        $validated = $request->validate([
            'skip_reason' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $dose = HealthMedicationDoseLog::query()
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $dose->update([
            'status' => 'skipped',
            'skip_reason' => $validated['skip_reason'] ?? null,
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Medication dose marked as skipped.',
            'data' => $dose->fresh()->load('medication'),
        ]);
    }

    public function history(Request $request): JsonResponse
    {
        $query = HealthMedicationDoseLog::query()
            ->with('medication')
            ->where('user_id', $request->user()->id);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('from')) {
            $query->whereDate('scheduled_for', '>=', $request->from);
        }

        if ($request->filled('to')) {
            $query->whereDate('scheduled_for', '<=', $request->to);
        }

        $logs = $query
            ->orderByDesc('scheduled_for')
            ->limit(100)
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Medication dose history retrieved successfully.',
            'data' => $logs,
        ]);
    }
}
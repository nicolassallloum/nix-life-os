<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthWeightLogResource;
use App\Models\HealthWeightLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HealthWeightLogController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthWeightLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('log_date');

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        $logs = $query->paginate($request->integer('per_page', 30));

        return response()->json([
            'success' => true,
            'message' => 'Weight logs retrieved successfully.',
            'data' => HealthWeightLogResource::collection($logs)->response()->getData(true),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'log_date' => ['required', 'date'],
            'weight_kg' => ['required', 'numeric', 'min:20', 'max:400'],
            'body_fat_percentage' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'body_fat_percent' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'muscle_mass_kg' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'bmi' => ['nullable', 'numeric', 'min:5', 'max:100'],
            'height_cm' => ['nullable', 'numeric', 'min:30', 'max:250'],
            'length_cm' => ['nullable', 'numeric', 'min:30', 'max:250'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        $heightCm = $request->height_cm ?? $request->length_cm;
        $bmi = $this->resolveBmi($request->weight_kg, $heightCm, $request->bmi);

        $log = HealthWeightLog::updateOrCreate(
            [
                'user_id' => $user->id,
                'log_date' => $request->log_date,
            ],
            [
                'weight_kg' => $request->weight_kg,
                'height_cm' => $heightCm,
                'length_cm' => $heightCm,
                'body_fat_percentage' => $request->body_fat_percentage ?? $request->body_fat_percent,
                'muscle_mass_kg' => $request->muscle_mass_kg,
                'bmi' => $bmi,
                'notes' => $request->notes,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Weight log saved successfully.',
            'data' => new HealthWeightLogResource($log),
        ], 201);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Weight log retrieved successfully.',
            'data' => new HealthWeightLogResource($log),
        ]);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        $validator = Validator::make($request->all(), [
            'log_date' => ['sometimes', 'date'],
            'weight_kg' => ['sometimes', 'numeric', 'min:20', 'max:400'],
            'body_fat_percentage' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'body_fat_percent' => ['nullable', 'numeric', 'min:1', 'max:80'],
            'muscle_mass_kg' => ['nullable', 'numeric', 'min:1', 'max:200'],
            'bmi' => ['nullable', 'numeric', 'min:5', 'max:100'],
            'height_cm' => ['nullable', 'numeric', 'min:30', 'max:250'],
            'length_cm' => ['nullable', 'numeric', 'min:30', 'max:250'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $payload = $validator->validated();

        if (array_key_exists('body_fat_percent', $payload) && !array_key_exists('body_fat_percentage', $payload)) {
            $payload['body_fat_percentage'] = $payload['body_fat_percent'];
        }

        unset($payload['body_fat_percent']);

        $hasHeightInput = array_key_exists('height_cm', $payload) || array_key_exists('length_cm', $payload);
        $heightCm = $payload['height_cm'] ?? $payload['length_cm'] ?? null;
        unset($payload['height_cm'], $payload['length_cm']);

        if ($hasHeightInput) {
            $payload['height_cm'] = $heightCm;
            $payload['length_cm'] = $heightCm;
        }

        if (array_key_exists('weight_kg', $payload) || $hasHeightInput || array_key_exists('bmi', $payload)) {
            $weightKg = $payload['weight_kg'] ?? $log->weight_kg;
            $heightForBmi = $hasHeightInput
                ? $heightCm
                : ($log->height_cm ?? $log->length_cm ?? null);

            $payload['bmi'] = $this->resolveBmi($weightKg, $heightForBmi, $payload['bmi'] ?? $log->bmi);
        }

        $log->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Weight log updated successfully.',
            'data' => new HealthWeightLogResource($log),
        ]);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $log = HealthWeightLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();

        if (!$log) {
            return response()->json([
                'success' => false,
                'message' => 'Weight log not found.',
            ], 404);
        }

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Weight log deleted successfully.',
        ]);
    }

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = HealthWeightLog::query()
            ->where('user_id', $user->id);

        if ($request->filled('from_date')) {
            $query->whereDate('log_date', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('log_date', '<=', $request->to_date);
        }

        $logs = $query->orderBy('log_date')->get();

        if ($logs->isEmpty()) {
            return response()->json([
                'success' => true,
                'message' => 'Weight summary retrieved successfully.',
                'data' => [
                    'total_logs' => 0,
                    'min_weight' => null,
                    'max_weight' => null,
                    'average_weight' => null,
                    'latest_weight' => null,
                    'first_weight' => null,
                    'weight_change' => null,
                    'trend_direction' => 'no_data',
                    'chart' => [],
                ],
            ]);
        }

        $first = $logs->first();
        $latest = $logs->last();

        $minWeight = $logs->min('weight_kg');
        $maxWeight = $logs->max('weight_kg');
        $avgWeight = round($logs->avg('weight_kg'), 2);

        $weightChange = round(((float) $latest->weight_kg) - ((float) $first->weight_kg), 2);

        $trendDirection = match (true) {
            $weightChange > 0 => 'increasing',
            $weightChange < 0 => 'decreasing',
            default => 'stable',
        };

        $chart = $logs->map(function ($log) {
            return [
                'date' => $log->log_date->format('Y-m-d'),
                'weight_kg' => (float) $log->weight_kg,
                'height_cm' => $log->height_cm !== null ? (float) $log->height_cm : null,
                'length_cm' => $log->length_cm !== null ? (float) $log->length_cm : null,
                'bmi' => $log->bmi !== null ? (float) $log->bmi : null,
                'body_fat_percentage' => $log->body_fat_percentage !== null ? (float) $log->body_fat_percentage : null,
                'body_fat_percent' => $log->body_fat_percentage !== null ? (float) $log->body_fat_percentage : null,
                'muscle_mass_kg' => $log->muscle_mass_kg !== null ? (float) $log->muscle_mass_kg : null,
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Weight summary retrieved successfully.',
            'data' => [
                'total_logs' => $logs->count(),
                'min_weight' => (float) $minWeight,
                'max_weight' => (float) $maxWeight,
                'average_weight' => $avgWeight,
                'latest_weight' => (float) $latest->weight_kg,
                'first_weight' => (float) $first->weight_kg,
                'weight_change' => $weightChange,
                'trend_direction' => $trendDirection,
                'latest_date' => $latest->log_date->format('Y-m-d'),
                'first_date' => $first->log_date->format('Y-m-d'),
                'chart' => $chart,
            ],
        ]);
    }

    private function resolveBmi($weightKg, $heightCm = null, $providedBmi = null): ?float
    {
        if ($heightCm !== null && (float) $heightCm > 0) {
            $heightMeters = ((float) $heightCm) / 100;

            if ($heightMeters > 0) {
                return round(((float) $weightKg) / ($heightMeters * $heightMeters), 2);
            }
        }

        return $providedBmi !== null && $providedBmi !== ''
            ? round((float) $providedBmi, 2)
            : null;
    }

}

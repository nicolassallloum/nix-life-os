<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HealthNutritionLog;
use Illuminate\Http\Request;

class HealthNutritionLogController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = HealthNutritionLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('meal_date')
            ->orderByDesc('created_at');

        $date = $request->query('date', $request->query('target_date'));

        if ($date) {
            $query->whereDate('meal_date', $date);
        }

        if ($request->filled('meal_type')) {
            $query->where('meal_type', $request->meal_type);
        }

        return response()->json([
            'success' => true,
            'message' => 'Nutrition logs loaded successfully.',
            'data' => $query->get(),
        ]);
    }

    public function store(Request $request)
    {
        $payload = $this->validateAndNormalize($request, true);

        $log = HealthNutritionLog::create([
            ...$payload,
            'user_id' => $request->user()->id,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition log created successfully.',
            'data' => $log->fresh(),
        ], 201);
    }

    public function show(Request $request, string $id)
    {
        $log = HealthNutritionLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'message' => 'Nutrition log loaded successfully.',
            'data' => $log,
        ]);
    }

    public function update(Request $request, string $id)
    {
        $log = HealthNutritionLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $payload = $this->validateAndNormalize($request, false);

        $log->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition log updated successfully.',
            'data' => $log->fresh(),
        ]);
    }

    public function destroy(Request $request, string $id)
    {
        $log = HealthNutritionLog::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();

        $log->delete();

        return response()->json([
            'success' => true,
            'message' => 'Nutrition log deleted successfully.',
        ]);
    }

    public function summary(Request $request)
    {
        $date = $request->query('date', $request->query('target_date', now()->toDateString()));

        $totals = HealthNutritionLog::query()
            ->where('user_id', $request->user()->id)
            ->whereDate('meal_date', $date)
            ->selectRaw('
                COALESCE(SUM(calories), 0) as total_calories,
                COALESCE(SUM(COALESCE(protein_g, protein, 0)), 0) as total_protein,
                COALESCE(SUM(carbs_g), 0) as total_carbs,
                COALESCE(SUM(fat_g), 0) as total_fat,
                COALESCE(SUM(COALESCE(sodium_mg, sodium, 0)), 0) as total_sodium,
                COALESCE(SUM(COALESCE(potassium_mg, potassium, 0)), 0) as total_potassium,
                COALESCE(SUM(COALESCE(phosphorus_mg, phosphorus, 0)), 0) as total_phosphorus
            ')
            ->first();

        $limits = [
            'calories' => 1800,
            'protein' => 45,
            'sodium' => 2000,
            'potassium' => 2000,
            'phosphorus' => 800,
        ];

        $data = [
            'date' => $date,
            'total_calories' => (float) $totals->total_calories,
            'total_protein' => (float) $totals->total_protein,
            'total_carbs' => (float) $totals->total_carbs,
            'total_fat' => (float) $totals->total_fat,
            'total_sodium' => (float) $totals->total_sodium,
            'total_potassium' => (float) $totals->total_potassium,
            'total_phosphorus' => (float) $totals->total_phosphorus,

            // Frontend-friendly aliases
            'calories' => (float) $totals->total_calories,
            'protein' => (float) $totals->total_protein,
            'carbs' => (float) $totals->total_carbs,
            'fat' => (float) $totals->total_fat,
            'sodium' => (float) $totals->total_sodium,
            'potassium' => (float) $totals->total_potassium,
            'phosphorus' => (float) $totals->total_phosphorus,

            'limits' => $limits,
        ];

        $data['status'] = [
            'calories' => $data['total_calories'] <= $limits['calories'] ? 'within_limit' : 'over_limit',
            'protein' => $data['total_protein'] <= $limits['protein'] ? 'within_limit' : 'over_limit',
            'sodium' => $data['total_sodium'] <= $limits['sodium'] ? 'within_limit' : 'over_limit',
            'potassium' => $data['total_potassium'] <= $limits['potassium'] ? 'within_limit' : 'over_limit',
            'phosphorus' => $data['total_phosphorus'] <= $limits['phosphorus'] ? 'within_limit' : 'over_limit',
        ];

        return response()->json([
            'success' => true,
            'message' => 'Nutrition summary loaded successfully.',
            'data' => $data,
        ]);
    }

    private function validateAndNormalize(Request $request, bool $creating): array
    {
        $rules = [
            'meal_date' => [$creating ? 'required_without:log_date' : 'sometimes', 'date'],
            'log_date' => ['sometimes', 'date'],
            'meal_type' => ['nullable', 'string', 'max:50'],
            'food_name' => [$creating ? 'required' : 'sometimes', 'string', 'max:255'],
            'quantity' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:50'],
            'quantity_unit' => ['nullable', 'string', 'max:50'],
            'calories' => ['nullable', 'numeric', 'min:0'],

            'protein' => ['nullable', 'numeric', 'min:0'],
            'sodium' => ['nullable', 'numeric', 'min:0'],
            'potassium' => ['nullable', 'numeric', 'min:0'],
            'phosphorus' => ['nullable', 'numeric', 'min:0'],

            'protein_g' => ['nullable', 'numeric', 'min:0'],
            'carbs_g' => ['nullable', 'numeric', 'min:0'],
            'fat_g' => ['nullable', 'numeric', 'min:0'],
            'sodium_mg' => ['nullable', 'numeric', 'min:0'],
            'potassium_mg' => ['nullable', 'numeric', 'min:0'],
            'phosphorus_mg' => ['nullable', 'numeric', 'min:0'],

            // Frontend short aliases
            'carbs' => ['nullable', 'numeric', 'min:0'],
            'fat' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ];

        $validated = $request->validate($rules);

        $mealDate = $validated['meal_date'] ?? $validated['log_date'] ?? null;

        $payload = [
            'meal_date' => $mealDate,
            'meal_type' => $validated['meal_type'] ?? null,
            'food_name' => $validated['food_name'] ?? null,
            'quantity' => $validated['quantity'] ?? 1,
            'unit' => $validated['unit'] ?? $validated['quantity_unit'] ?? 'g',
            'calories' => $validated['calories'] ?? 0,

            'protein_g' => $validated['protein_g'] ?? $validated['protein'] ?? 0,
            'carbs_g' => $validated['carbs_g'] ?? $validated['carbs'] ?? 0,
            'fat_g' => $validated['fat_g'] ?? $validated['fat'] ?? 0,
            'sodium_mg' => $validated['sodium_mg'] ?? $validated['sodium'] ?? 0,
            'potassium_mg' => $validated['potassium_mg'] ?? $validated['potassium'] ?? 0,
            'phosphorus_mg' => $validated['phosphorus_mg'] ?? $validated['phosphorus'] ?? 0,

            // Keep legacy columns synchronized
            'protein' => $validated['protein'] ?? $validated['protein_g'] ?? 0,
            'sodium' => $validated['sodium'] ?? $validated['sodium_mg'] ?? 0,
            'potassium' => $validated['potassium'] ?? $validated['potassium_mg'] ?? 0,
            'phosphorus' => $validated['phosphorus'] ?? $validated['phosphorus_mg'] ?? 0,

            'notes' => $validated['notes'] ?? null,
        ];

        if (!$creating) {
            return array_filter($payload, fn ($value) => $value !== null);
        }

        return $payload;
    }
}

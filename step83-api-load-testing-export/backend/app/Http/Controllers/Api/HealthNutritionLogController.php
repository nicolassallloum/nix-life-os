<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HealthNutritionLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HealthNutritionLogController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $query = HealthNutritionLog::query()
            ->where('user_id', $user->id)
            ->orderByDesc('meal_date')
            ->orderByDesc('created_at');

        if ($request->filled('date')) {
            $query->whereDate('meal_date', $request->date);
        }

        if ($request->filled('meal_type')) {
            $query->where('meal_type', $request->meal_type);
        }

        $logs = $query->get();

        return response()->json([
            'success' => true,
            'message' => 'Nutrition logs loaded successfully.',
            'data' => $logs,
        ]);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'meal_date' => ['required', 'date'],
            'meal_type' => ['nullable', 'string', 'max:50'],
            'food_name' => ['required', 'string', 'max:255'],
            'quantity' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:50'],
            'calories' => ['nullable', 'numeric', 'min:0'],
            'protein' => ['nullable', 'numeric', 'min:0'],
            'sodium' => ['nullable', 'numeric', 'min:0'],
            'potassium' => ['nullable', 'numeric', 'min:0'],
            'phosphorus' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $validated['user_id'] = $user->id;
        $validated['quantity'] = $validated['quantity'] ?? 1;
        $validated['calories'] = $validated['calories'] ?? 0;
        $validated['protein'] = $validated['protein'] ?? 0;
        $validated['sodium'] = $validated['sodium'] ?? 0;
        $validated['potassium'] = $validated['potassium'] ?? 0;
        $validated['phosphorus'] = $validated['phosphorus'] ?? 0;

        $log = HealthNutritionLog::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition log created successfully.',
            'data' => $log,
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

        $validated = $request->validate([
            'meal_date' => ['required', 'date'],
            'meal_type' => ['nullable', 'string', 'max:50'],
            'food_name' => ['required', 'string', 'max:255'],
            'quantity' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:50'],
            'calories' => ['nullable', 'numeric', 'min:0'],
            'protein' => ['nullable', 'numeric', 'min:0'],
            'sodium' => ['nullable', 'numeric', 'min:0'],
            'potassium' => ['nullable', 'numeric', 'min:0'],
            'phosphorus' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);

        $validated['quantity'] = $validated['quantity'] ?? 1;
        $validated['calories'] = $validated['calories'] ?? 0;
        $validated['protein'] = $validated['protein'] ?? 0;
        $validated['sodium'] = $validated['sodium'] ?? 0;
        $validated['potassium'] = $validated['potassium'] ?? 0;
        $validated['phosphorus'] = $validated['phosphorus'] ?? 0;

        $log->update($validated);

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
        $user = $request->user();
        $date = $request->query('date', now()->toDateString());

        $totals = HealthNutritionLog::query()
            ->where('user_id', $user->id)
            ->whereDate('meal_date', $date)
            ->selectRaw('
                COALESCE(SUM(calories), 0) as total_calories,
                COALESCE(SUM(protein), 0) as total_protein,
                COALESCE(SUM(sodium), 0) as total_sodium,
                COALESCE(SUM(potassium), 0) as total_potassium,
                COALESCE(SUM(phosphorus), 0) as total_phosphorus
            ')
            ->first();

        $limits = [
            'calories' => 1800,
            'protein' => 45,
            'sodium' => 2000,
            'potassium' => 2000,
            'phosphorus' => 800,
        ];

        return response()->json([
            'success' => true,
            'message' => 'Nutrition summary loaded successfully.',
            'data' => [
                'date' => $date,
                'total_calories' => (float) $totals->total_calories,
                'total_protein' => (float) $totals->total_protein,
                'total_sodium' => (float) $totals->total_sodium,
                'total_potassium' => (float) $totals->total_potassium,
                'total_phosphorus' => (float) $totals->total_phosphorus,
                'limits' => $limits,
                'status' => [
                    'calories' => ((float) $totals->total_calories <= $limits['calories']) ? 'within_limit' : 'over_limit',
                    'protein' => ((float) $totals->total_protein <= $limits['protein']) ? 'within_limit' : 'over_limit',
                    'sodium' => ((float) $totals->total_sodium <= $limits['sodium']) ? 'within_limit' : 'over_limit',
                    'potassium' => ((float) $totals->total_potassium <= $limits['potassium']) ? 'within_limit' : 'over_limit',
                    'phosphorus' => ((float) $totals->total_phosphorus <= $limits['phosphorus']) ? 'within_limit' : 'over_limit',
                ],
            ],
        ]);
    }
}

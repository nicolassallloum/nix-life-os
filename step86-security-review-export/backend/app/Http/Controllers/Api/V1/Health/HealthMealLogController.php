<?php

namespace App\Http\Controllers\Api\V1\Health;

use App\Http\Controllers\Controller;
use App\Http\Resources\HealthMealLogResource;
use App\Models\HealthFoodItem;
use App\Models\HealthMealLog;
use App\Models\HealthMealLogItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class HealthMealLogController extends Controller
{
    public function index(Request $request)
    {
        $date = $request->query('date', now()->toDateString());

        $meals = HealthMealLog::with(['items.food'])
            ->where('user_id', $request->user()->id)
            ->whereDate('meal_date', $date)
            ->orderBy('created_at')
            ->get();

        return HealthMealLogResource::collection($meals);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'meal_date' => ['required', 'date'],
            'meal_type' => ['required', Rule::in(['breakfast', 'lunch', 'dinner', 'snack'])],
            'meal_name' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.food_item_id' => ['required', 'uuid', 'exists:health_food_items,id'],
            'items.*.quantity_g' => ['required', 'numeric', 'min:1'],
        ]);

        $meal = DB::transaction(function () use ($request, $data) {
            $meal = HealthMealLog::create([
                'user_id' => $request->user()->id,
                'meal_date' => $data['meal_date'],
                'meal_type' => $data['meal_type'],
                'meal_name' => $data['meal_name'] ?? null,
                'notes' => $data['notes'] ?? null,
            ]);

            foreach ($data['items'] as $item) {
                $food = HealthFoodItem::where('id', $item['food_item_id'])
                    ->where(function ($q) use ($request) {
                        $q->whereNull('user_id')
                          ->orWhere('user_id', $request->user()->id);
                    })
                    ->firstOrFail();

                $calculated = $food->calculateForQuantity((float) $item['quantity_g']);

                HealthMealLogItem::create([
                    'meal_log_id' => $meal->id,
                    'food_item_id' => $food->id,
                    'quantity_g' => $item['quantity_g'],
                    ...$calculated,
                ]);
            }

            $meal->recalculateTotals();

            return $meal->fresh(['items.food']);
        });

        return response()->json([
            'success' => true,
            'message' => 'Meal logged successfully.',
            'data' => new HealthMealLogResource($meal),
        ], 201);
    }

    public function destroy(Request $request, HealthMealLog $healthMealLog)
    {
        abort_if($healthMealLog->user_id !== $request->user()->id, 403);

        $healthMealLog->delete();

        return response()->json([
            'success' => true,
            'message' => 'Meal deleted successfully.',
        ]);
    }
}
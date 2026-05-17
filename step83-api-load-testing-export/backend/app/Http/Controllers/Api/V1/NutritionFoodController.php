<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Nutrition\NutritionFoodService;
use Illuminate\Http\Request;

class NutritionFoodController extends Controller
{
    public function __construct(
        private readonly NutritionFoodService $nutritionFoodService
    ) {}

    public function categories()
    {
        return response()->json([
            'success' => true,
            'message' => 'Nutrition food categories loaded successfully.',
            'data' => $this->nutritionFoodService->categories(),
        ]);
    }

    public function index(Request $request)
    {
        $foods = $this->nutritionFoodService->search($request->only([
            'q',
            'category_id',
            'ckd_friendly',
            'warning_level',
            'per_page',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Nutrition foods loaded successfully.',
            'data' => $foods,
        ]);
    }

    public function search(Request $request)
    {
        $request->validate([
            'q' => ['nullable', 'string', 'max:255'],
            'category_id' => ['nullable', 'uuid'],
            'ckd_friendly' => ['nullable'],
            'warning_level' => ['nullable', 'in:low,medium,high,avoid'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $foods = $this->nutritionFoodService->search($request->only([
            'q',
            'category_id',
            'ckd_friendly',
            'warning_level',
            'per_page',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Food search completed successfully.',
            'data' => $foods,
        ]);
    }

    public function show(string $id)
    {
        $food = $this->nutritionFoodService->findFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Nutrition food loaded successfully.',
            'data' => $food,
        ]);
    }

    public function servings(string $id)
    {
        $food = $this->nutritionFoodService->findFood($id);

        return response()->json([
            'success' => true,
            'message' => 'Food servings loaded successfully.',
            'data' => $food->servings,
        ]);
    }

    public function autofill(Request $request)
    {
        $validated = $request->validate([
            'food_id' => ['required', 'uuid', 'exists:nutrition_foods,id'],
            'quantity_grams' => ['required', 'numeric', 'min:1', 'max:5000'],
        ]);

        $result = $this->nutritionFoodService->calculateAutofill(
            $validated['food_id'],
            (float) $validated['quantity_grams']
        );

        return response()->json([
            'success' => true,
            'message' => 'Nutrition autofill calculated successfully.',
            'data' => $result,
        ]);
    }
}
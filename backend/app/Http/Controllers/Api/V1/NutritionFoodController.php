<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\NutritionCustomFood;
use App\Services\Nutrition\NutritionFoodService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

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
        $request->merge([
            'q' => $request->input('q', $request->input('query', $request->input('search', ''))),
        ]);

        $validated = $request->validate([
            'q' => ['nullable', 'string', 'max:255'],
            'query' => ['nullable', 'string', 'max:255'],
            'search' => ['nullable', 'string', 'max:255'],
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

        $standardFoods = collect(data_get($foods, 'data', []))
            ->map(function ($food) {
                $food = is_array($food) ? $food : $food->toArray();

                return array_merge($food, [
                    'food_source' => $food['food_source'] ?? 'database',
                    'source_type' => $food['source_type'] ?? 'database',
                    'default_serving_label' => $food['default_serving_label'] ?? (($food['default_serving_grams'] ?? 100) . ' g'),
                ]);
            });

        $query = trim((string) ($validated['q'] ?? ''));
        $userId = Auth::id();
        $perPage = max(1, min((int) ($validated['per_page'] ?? 15), 50));

        $customFoodsQuery = NutritionCustomFood::query()
            ->where(function ($q) use ($userId) {
                $q->where('user_id', $userId)
                  ->orWhere('is_global', true);
            });

        if ($query !== '') {
            $lower = strtolower($query);

            $customFoodsQuery->where(function ($q) use ($lower) {
                $q->whereRaw('LOWER(name) LIKE ?', ["%{$lower}%"])
                  ->orWhereRaw("LOWER(COALESCE(brand, '')) LIKE ?", ["%{$lower}%"])
                  ->orWhereRaw("LOWER(COALESCE(category, '')) LIKE ?", ["%{$lower}%"]);
            });
        }

        $customFoods = $customFoodsQuery
            ->orderBy('name')
            ->limit($perPage)
            ->get()
            ->map(function (NutritionCustomFood $food) {
                return [
                    'id' => $food->id,
                    'name' => $food->name,
                    'brand_name' => $food->brand,
                    'brand' => $food->brand,
                    'category' => $food->category,
                    'default_serving_label' => trim(($food->serving_size ?? 100) . ' ' . ($food->serving_unit ?? 'g')),
                    'default_serving_grams' => (float) ($food->serving_size ?? 100),
                    'serving_size' => (float) ($food->serving_size ?? 100),
                    'serving_unit' => $food->serving_unit ?? 'g',
                    'calories' => (float) ($food->calories ?? 0),
                    'protein_g' => (float) ($food->protein_g ?? 0),
                    'carbs_g' => (float) ($food->carbs_g ?? 0),
                    'fat_g' => (float) ($food->fat_g ?? 0),
                    'sodium_mg' => (float) ($food->sodium_mg ?? 0),
                    'potassium_mg' => (float) ($food->potassium_mg ?? 0),
                    'phosphorus_mg' => (float) ($food->phosphorus_mg ?? 0),
                    'ckd_warning_level' => 'custom',
                    'ckd_notes' => 'Custom food saved by user.',
                    'food_source' => 'custom',
                    'source_type' => 'custom',
                    'custom_food_id' => $food->id,
                ];
            });

        $merged = $customFoods
            ->concat($standardFoods)
            ->unique(fn ($food) => ($food['source_type'] ?? 'database') . ':' . ($food['id'] ?? $food['name']))
            ->values()
            ->take($perPage)
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Food search completed successfully.',
            'data' => [
                'current_page' => 1,
                'data' => $merged,
                'from' => $merged->isNotEmpty() ? 1 : null,
                'to' => $merged->count() ?: null,
                'total' => $merged->count(),
                'per_page' => $perPage,
                'last_page' => 1,
            ],
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
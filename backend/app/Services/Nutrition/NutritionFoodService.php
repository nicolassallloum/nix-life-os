<?php

namespace App\Services\Nutrition;

use App\Models\NutritionFood;
use App\Models\NutritionFoodCategory;
use Illuminate\Support\Facades\DB;

class NutritionFoodService
{
    public function categories()
    {
        return NutritionFoodCategory::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();
    }

    public function search(array $filters)
    {
        $query = NutritionFood::query()
            ->with(['category', 'servings'])
            ->where('nutrition_foods.is_active', true);

        if (!empty($filters['q'])) {
            $search = trim($filters['q']);

            $query->where(function ($q) use ($search) {
                $q->where('nutrition_foods.name', 'ILIKE', "%{$search}%")
                    ->orWhere('nutrition_foods.brand_name', 'ILIKE', "%{$search}%")
                    ->orWhereExists(function ($sub) use ($search) {
                        $sub->select(DB::raw(1))
                            ->from('nutrition_food_aliases')
                            ->whereColumn('nutrition_food_aliases.food_id', 'nutrition_foods.id')
                            ->where('nutrition_food_aliases.alias_name', 'ILIKE', "%{$search}%");
                    });
            });
        }

        if (!empty($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }

        if (isset($filters['ckd_friendly'])) {
            $query->where('is_ckd_friendly', filter_var($filters['ckd_friendly'], FILTER_VALIDATE_BOOLEAN));
        }

        if (!empty($filters['warning_level'])) {
            $query->where('ckd_warning_level', $filters['warning_level']);
        }

        return $query
            ->orderBy('is_ckd_friendly', 'desc')
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 15);
    }

    public function findFood(string $id): NutritionFood
    {
        return NutritionFood::query()
            ->with(['category', 'servings', 'aliases'])
            ->where('is_active', true)
            ->findOrFail($id);
    }

    public function calculateAutofill(string $foodId, float $quantityGrams): array
    {
        $food = $this->findFood($foodId);

        $baseGrams = (float) $food->default_serving_grams;

        if ($baseGrams <= 0) {
            $baseGrams = 100;
        }

        $ratio = $quantityGrams / $baseGrams;

        return [
            'food_id' => $food->id,
            'food_name' => $food->name,
            'quantity_grams' => round($quantityGrams, 2),

            'calories' => round((float) $food->calories * $ratio, 2),
            'protein_g' => round((float) $food->protein_g * $ratio, 2),
            'carbs_g' => round((float) $food->carbs_g * $ratio, 2),
            'fat_g' => round((float) $food->fat_g * $ratio, 2),

            'sodium_mg' => round((float) $food->sodium_mg * $ratio, 2),
            'potassium_mg' => round((float) $food->potassium_mg * $ratio, 2),
            'phosphorus_mg' => round((float) $food->phosphorus_mg * $ratio, 2),

            'is_ckd_friendly' => $food->is_ckd_friendly,
            'ckd_warning_level' => $food->ckd_warning_level,
            'ckd_notes' => $food->ckd_notes,
        ];
    }
}

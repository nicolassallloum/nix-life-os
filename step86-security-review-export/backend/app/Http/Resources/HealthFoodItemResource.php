<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthFoodItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'food_name' => $this->food_name,
            'brand_name' => $this->brand_name,
            'category' => $this->category,
            'calories_per_100g' => (float) $this->calories_per_100g,
            'protein_per_100g' => (float) $this->protein_per_100g,
            'carbs_per_100g' => (float) $this->carbs_per_100g,
            'fat_per_100g' => (float) $this->fat_per_100g,
            'sodium_per_100g_mg' => (float) $this->sodium_per_100g_mg,
            'potassium_per_100g_mg' => (float) $this->potassium_per_100g_mg,
            'phosphorus_per_100g_mg' => (float) $this->phosphorus_per_100g_mg,
            'is_ckd_friendly' => (bool) $this->is_ckd_friendly,
            'is_custom' => (bool) $this->is_custom,
            'notes' => $this->notes,
        ];
    }
}
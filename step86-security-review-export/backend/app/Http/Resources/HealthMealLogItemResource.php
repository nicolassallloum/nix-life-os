<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthMealLogItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'food_item_id' => $this->food_item_id,
            'food' => new HealthFoodItemResource($this->whenLoaded('food')),
            'quantity_g' => (float) $this->quantity_g,
            'calories' => (float) $this->calories,
            'protein_g' => (float) $this->protein_g,
            'carbs_g' => (float) $this->carbs_g,
            'fat_g' => (float) $this->fat_g,
            'sodium_mg' => (float) $this->sodium_mg,
            'potassium_mg' => (float) $this->potassium_mg,
            'phosphorus_mg' => (float) $this->phosphorus_mg,
        ];
    }
}
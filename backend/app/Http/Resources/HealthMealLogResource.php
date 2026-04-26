<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthMealLogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'meal_date' => $this->meal_date,
            'meal_type' => $this->meal_type,
            'meal_name' => $this->meal_name,
            'notes' => $this->notes,

            'totals' => [
                'calories' => (float) $this->total_calories,
                'protein_g' => (float) $this->total_protein_g,
                'carbs_g' => (float) $this->total_carbs_g,
                'fat_g' => (float) $this->total_fat_g,
                'sodium_mg' => (float) $this->total_sodium_mg,
                'potassium_mg' => (float) $this->total_potassium_mg,
                'phosphorus_mg' => (float) $this->total_phosphorus_mg,
            ],

            'items' => HealthMealLogItemResource::collection($this->whenLoaded('items')),
        ];
    }
}
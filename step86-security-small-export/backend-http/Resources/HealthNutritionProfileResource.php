<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HealthNutritionProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'profile_name' => $this->profile_name,
            'daily_calories_min' => $this->daily_calories_min,
            'daily_calories_max' => $this->daily_calories_max,
            'daily_protein_max_g' => (float) $this->daily_protein_max_g,
            'daily_carbs_max_g' => (float) $this->daily_carbs_max_g,
            'daily_fat_max_g' => (float) $this->daily_fat_max_g,
            'daily_sodium_max_mg' => (float) $this->daily_sodium_max_mg,
            'daily_potassium_max_mg' => (float) $this->daily_potassium_max_mg,
            'daily_phosphorus_max_mg' => (float) $this->daily_phosphorus_max_mg,
            'is_ckd_safe_mode' => (bool) $this->is_ckd_safe_mode,
            'is_active' => (bool) $this->is_active,
            'notes' => $this->notes,
        ];
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthFoodItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'food_name',
        'brand_name',
        'category',
        'calories_per_100g',
        'protein_per_100g',
        'carbs_per_100g',
        'fat_per_100g',
        'sodium_per_100g_mg',
        'potassium_per_100g_mg',
        'phosphorus_per_100g_mg',
        'is_ckd_friendly',
        'is_custom',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'is_ckd_friendly' => 'boolean',
        'is_custom' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function calculateForQuantity(float $quantityG): array
    {
        $factor = $quantityG / 100;

        return [
            'calories' => round($this->calories_per_100g * $factor, 2),
            'protein_g' => round($this->protein_per_100g * $factor, 2),
            'carbs_g' => round($this->carbs_per_100g * $factor, 2),
            'fat_g' => round($this->fat_per_100g * $factor, 2),
            'sodium_mg' => round($this->sodium_per_100g_mg * $factor, 2),
            'potassium_mg' => round($this->potassium_per_100g_mg * $factor, 2),
            'phosphorus_mg' => round($this->phosphorus_per_100g_mg * $factor, 2),
        ];
    }
}
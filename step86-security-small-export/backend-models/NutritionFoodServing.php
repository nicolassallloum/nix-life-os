<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodServing extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_servings';

    protected $fillable = [
        'food_id',
        'serving_label',
        'serving_grams',

        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',

        'is_default',
        'display_order',
    ];

    protected $casts = [
        'serving_grams' => 'decimal:2',

        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',

        'is_default' => 'boolean',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
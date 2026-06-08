<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class HealthNutritionLog extends Model
{
    use HasUuids;

    protected $table = 'health_nutrition_logs';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'meal_date',
        'meal_type',
        'food_name',
        'quantity',
        'unit',
        'calories',

        // Legacy nutrition fields
        'protein',
        'sodium',
        'potassium',
        'phosphorus',

        // Phase 7 kidney-friendly fields
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',

        'custom_food_id',
        'food_source',
        'notes',
    ];

    protected $casts = [
        'meal_date' => 'date:Y-m-d',
        'quantity' => 'decimal:2',
        'calories' => 'decimal:2',

        'protein' => 'decimal:2',
        'sodium' => 'decimal:2',
        'potassium' => 'decimal:2',
        'phosphorus' => 'decimal:2',

        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',
    ];
}

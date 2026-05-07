<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

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
        'protein',
        'sodium',
        'potassium',
        'phosphorus',
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
    ];
}

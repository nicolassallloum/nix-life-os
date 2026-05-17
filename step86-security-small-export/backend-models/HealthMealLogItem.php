<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthMealLogItem extends Model
{
    use HasUuids;

    protected $fillable = [
        'meal_log_id',
        'food_item_id',
        'quantity_g',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
    ];

    public function food()
    {
        return $this->belongsTo(HealthFoodItem::class, 'food_item_id');
    }

    public function mealLog()
    {
        return $this->belongsTo(HealthMealLog::class, 'meal_log_id');
    }
}
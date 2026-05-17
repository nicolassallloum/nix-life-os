<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class NutritionCustomFood extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_custom_foods';

    protected $fillable = [
        'user_id',
        'name',
        'brand',
        'category',
        'serving_size',
        'serving_unit',
        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
        'is_personal',
        'is_global',
        'is_ai_recommended',
        'ai_metadata',
    ];

    protected $casts = [
        'serving_size' => 'decimal:2',
        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',
        'is_personal' => 'boolean',
        'is_global' => 'boolean',
        'is_ai_recommended' => 'boolean',
        'ai_metadata' => 'array',
    ];
}
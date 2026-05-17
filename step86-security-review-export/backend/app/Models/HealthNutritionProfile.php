<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthNutritionProfile extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'profile_name',
        'daily_calories_min',
        'daily_calories_max',
        'daily_protein_max_g',
        'daily_carbs_max_g',
        'daily_fat_max_g',
        'daily_sodium_max_mg',
        'daily_potassium_max_mg',
        'daily_phosphorus_max_mg',
        'is_ckd_safe_mode',
        'is_active',
        'notes',
    ];

    protected $casts = [
        'is_ckd_safe_mode' => 'boolean',
        'is_active' => 'boolean',
    ];
}
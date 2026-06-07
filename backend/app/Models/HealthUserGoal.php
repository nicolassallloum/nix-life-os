<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthUserGoal extends Model
{
    protected $table = 'health_user_goals';

    protected $fillable = [
        'user_id',
        'daily_steps_goal',
        'target_weight_kg',
        'daily_calories_goal',
        'daily_water_goal_ml',
        'protein_limit_g',
        'carbs_limit_g',
        'fat_limit_g',
        'sugar_limit_g',
        'sodium_limit_mg',
        'potassium_limit_mg',
        'phosphorus_limit_mg',
    ];

    protected $casts = [
        'daily_steps_goal' => 'integer',
        'target_weight_kg' => 'decimal:2',
        'daily_calories_goal' => 'integer',
        'daily_water_goal_ml' => 'integer',
        'protein_limit_g' => 'decimal:2',
        'carbs_limit_g' => 'decimal:2',
        'fat_limit_g' => 'decimal:2',
        'sugar_limit_g' => 'decimal:2',
        'sodium_limit_mg' => 'decimal:2',
        'potassium_limit_mg' => 'decimal:2',
        'phosphorus_limit_mg' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

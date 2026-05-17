<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFood extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_foods';

    protected $fillable = [
        'category_id',
        'food_code',
        'name',
        'brand_name',
        'description',
        'default_serving_label',
        'default_serving_grams',

        'calories',
        'protein_g',
        'carbs_g',
        'fat_g',
        'fiber_g',
        'sugar_g',

        'sodium_mg',
        'potassium_mg',
        'phosphorus_mg',
        'calcium_mg',
        'iron_mg',
        'cholesterol_mg',

        'is_ckd_friendly',
        'is_low_sodium',
        'is_low_potassium',
        'is_low_phosphorus',
        'is_low_protein',

        'ckd_warning_level',
        'ckd_notes',

        'source',
        'source_reference',
        'is_verified',
        'is_active',
    ];

    protected $casts = [
        'default_serving_grams' => 'decimal:2',

        'calories' => 'decimal:2',
        'protein_g' => 'decimal:2',
        'carbs_g' => 'decimal:2',
        'fat_g' => 'decimal:2',
        'fiber_g' => 'decimal:2',
        'sugar_g' => 'decimal:2',

        'sodium_mg' => 'decimal:2',
        'potassium_mg' => 'decimal:2',
        'phosphorus_mg' => 'decimal:2',
        'calcium_mg' => 'decimal:2',
        'iron_mg' => 'decimal:2',
        'cholesterol_mg' => 'decimal:2',

        'is_ckd_friendly' => 'boolean',
        'is_low_sodium' => 'boolean',
        'is_low_potassium' => 'boolean',
        'is_low_phosphorus' => 'boolean',
        'is_low_protein' => 'boolean',
        'is_verified' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function category()
    {
        return $this->belongsTo(NutritionFoodCategory::class, 'category_id');
    }

    public function servings()
    {
        return $this->hasMany(NutritionFoodServing::class, 'food_id');
    }

    public function aliases()
    {
        return $this->hasMany(NutritionFoodAlias::class, 'food_id');
    }

    public function sources()
    {
        return $this->hasMany(NutritionFoodSource::class, 'food_id');
    }
}
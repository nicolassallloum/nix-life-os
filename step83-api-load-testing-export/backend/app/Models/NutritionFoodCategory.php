<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodCategory extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'nutrition_food_categories';

    protected $fillable = [
        'name',
        'slug',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function foods()
    {
        return $this->hasMany(NutritionFood::class, 'category_id');
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodAlias extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_aliases';

    protected $fillable = [
        'food_id',
        'alias_name',
        'language_code',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
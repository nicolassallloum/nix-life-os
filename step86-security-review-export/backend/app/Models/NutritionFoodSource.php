<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class NutritionFoodSource extends Model
{
    use HasUuids;

    protected $table = 'nutrition_food_sources';

    protected $fillable = [
        'food_id',
        'source_name',
        'source_food_id',
        'source_url',
        'imported_at',
    ];

    protected $casts = [
        'imported_at' => 'datetime',
    ];

    public function food()
    {
        return $this->belongsTo(NutritionFood::class, 'food_id');
    }
}
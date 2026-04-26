<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthMealLog extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'meal_date',
        'meal_type',
        'meal_name',
        'notes',
        'total_calories',
        'total_protein_g',
        'total_carbs_g',
        'total_fat_g',
        'total_sodium_mg',
        'total_potassium_mg',
        'total_phosphorus_mg',
    ];

    public function items()
    {
        return $this->hasMany(HealthMealLogItem::class, 'meal_log_id');
    }

    public function recalculateTotals(): void
    {
        $totals = $this->items()
            ->selectRaw('
                COALESCE(SUM(calories), 0) as calories,
                COALESCE(SUM(protein_g), 0) as protein_g,
                COALESCE(SUM(carbs_g), 0) as carbs_g,
                COALESCE(SUM(fat_g), 0) as fat_g,
                COALESCE(SUM(sodium_mg), 0) as sodium_mg,
                COALESCE(SUM(potassium_mg), 0) as potassium_mg,
                COALESCE(SUM(phosphorus_mg), 0) as phosphorus_mg
            ')
            ->first();

        $this->update([
            'total_calories' => $totals->calories,
            'total_protein_g' => $totals->protein_g,
            'total_carbs_g' => $totals->carbs_g,
            'total_fat_g' => $totals->fat_g,
            'total_sodium_mg' => $totals->sodium_mg,
            'total_potassium_mg' => $totals->potassium_mg,
            'total_phosphorus_mg' => $totals->phosphorus_mg,
        ]);
    }
}
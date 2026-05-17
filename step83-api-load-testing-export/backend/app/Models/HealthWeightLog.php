<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthWeightLog extends Model
{
    use HasFactory;

    protected $table = 'health_weight_logs';

    protected $fillable = [
        'user_id',
        'log_date',
        'weight_kg',
        'body_fat_percentage',
        'muscle_mass_kg',
        'bmi',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'weight_kg' => 'decimal:2',
        'body_fat_percentage' => 'decimal:2',
        'muscle_mass_kg' => 'decimal:2',
        'bmi' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }
}
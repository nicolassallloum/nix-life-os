<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthWeightLog extends Model
{
    use HasFactory;

    protected $table = 'nix_life_os.health_weight_logs';

    protected $primaryKey = 'id';

    public $incrementing = true;

    protected $keyType = 'int';

    protected $fillable = [
        'user_id',
        'log_date',
        'weight_kg',
        'body_fat_percentage',
        'body_fat_percent',
        'muscle_mass_kg',
        'bmi',
        'notes',
    ];

    protected $casts = [
        'user_id' => 'string',
        'log_date' => 'date',
        'weight_kg' => 'decimal:2',
        'body_fat_percentage' => 'decimal:2',
        'body_fat_percent' => 'decimal:2',
        'muscle_mass_kg' => 'decimal:2',
        'bmi' => 'decimal:2',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthWeightLog extends Model
{
    use HasFactory;
    protected $table = 'nix_life_os.health_weight_logs';

    protected $fillable = [
        'user_id',
        'entry_date',
        'weight_kg',
        'notes',
    ];
    protected $casts = [
        'user_id' => 'string',
    ];
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthStep extends Model
{
    use HasFactory;
    protected $table = 'nix_life_os.health_steps';

    protected $fillable = [
        'user_id',
        'entry_date',
        'steps',
        'distance_km',
        'notes',
    ];
    protected $casts = [
        'user_id' => 'string',
    ];
}
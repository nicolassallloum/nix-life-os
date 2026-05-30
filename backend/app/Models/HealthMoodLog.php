<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthMoodLog extends Model
{
    use HasFactory;
    protected $table = 'nix_life_os.health_mood_logs';

    protected $fillable = [
        'user_id',
        'entry_date',
        'mood',
        'mood_score',
        'notes',
    ];

    protected $casts = [
        'user_id' => 'string',
    ];
}
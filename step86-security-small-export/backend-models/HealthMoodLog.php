<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class HealthMoodLog extends Model
{
    use HasUuids;

    protected $table = 'health_mood_logs';

    protected $fillable = [
        'user_id',
        'mood_date',
        'mood_label',
        'mood_score',
        'notes',
        'tags',
    ];

    protected $casts = [
        'mood_date' => 'date:Y-m-d',
        'mood_score' => 'integer',
        'tags' => 'array',
    ];
}

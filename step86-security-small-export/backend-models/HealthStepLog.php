<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class HealthStepLog extends Model
{
    use HasUuids;

    protected $table = 'health_step_log';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'log_date',
        'steps_count',
        'distance_km',
        'goal_steps',
        'goal_percentage',
        'goal_completed',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'steps_count' => 'integer',
        'distance_km' => 'decimal:3',
        'goal_steps' => 'integer',
        'goal_percentage' => 'decimal:2',
        'goal_completed' => 'boolean',
    ];
}

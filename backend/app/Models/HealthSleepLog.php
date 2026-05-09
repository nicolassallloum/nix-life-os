<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class HealthSleepLog extends Model
{
    use HasUuids;

    protected $table = 'health_sleep_logs';

    protected $fillable = [
        'user_id',
        'sleep_date',
        'bed_time',
        'wake_time',
        'duration_minutes',
        'quality_score',
        'notes',
    ];

    protected $casts = [
        'sleep_date' => 'date:Y-m-d',
        'bed_time' => 'datetime:Y-m-d H:i:s',
        'wake_time' => 'datetime:Y-m-d H:i:s',
        'duration_minutes' => 'integer',
        'quality_score' => 'integer',
    ];
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthSleepLog extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'health_sleep_logs';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'sleep_date',
        'wake_date',
        'bed_time',
        'wake_time',
        'duration_minutes',
        'duration_hours',
        'quality_score',
        'quality',
        'notes',
    ];

    protected $casts = [
        'id' => 'string',
        'user_id' => 'string',
        'sleep_date' => 'date:Y-m-d',
        'wake_date' => 'date:Y-m-d',
        'bed_time' => 'datetime:Y-m-d H:i:s',
        'wake_time' => 'datetime:Y-m-d H:i:s',
        'duration_minutes' => 'integer',
        'duration_hours' => 'decimal:2',
        'quality_score' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}

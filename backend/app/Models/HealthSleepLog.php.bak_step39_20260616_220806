<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthSleepLog extends Model
{
    use HasFactory;
    use HasUuids;

    protected $table = 'nix_life_os.health_sleep_logs';

    protected $primaryKey = 'id';

    public $incrementing = false;

    protected $keyType = 'string';

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
        'id' => 'string',
        'user_id' => 'string',
        'sleep_date' => 'date',
        'bed_time' => 'datetime',
        'wake_time' => 'datetime',
        'duration_minutes' => 'integer',
        'quality_score' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}

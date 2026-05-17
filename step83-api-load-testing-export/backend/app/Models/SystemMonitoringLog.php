<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class SystemMonitoringLog extends Model
{
    use HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'service_name',
        'status',
        'response_time_ms',
        'metrics',
        'message',
        'checked_at',
    ];

    protected $casts = [
        'metrics' => 'array',
        'checked_at' => 'datetime',
    ];
}
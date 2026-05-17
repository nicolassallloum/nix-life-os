<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthAlert extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'alert_type',
        'category',
        'severity',
        'status',
        'title',
        'message',
        'alert_date',
        'source_table',
        'source_id',
        'metadata',
        'read_at',
        'resolved_at',
        'dismissed_at',
    ];

    protected $casts = [
        'alert_date' => 'date',
        'metadata' => 'array',
        'read_at' => 'datetime',
        'resolved_at' => 'datetime',
        'dismissed_at' => 'datetime',
    ];
}
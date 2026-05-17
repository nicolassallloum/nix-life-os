<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiAlert extends Model
{
    use HasUuids;

    protected $table = 'ai_alerts';

    protected $fillable = [
        'user_id',
        'alert_type',
        'module',
        'title',
        'message',
        'severity',
        'risk_score',
        'trigger_data',
        'alert_date',
        'is_resolved',
        'resolved_at',
    ];

    protected $casts = [
        'trigger_data' => 'array',
        'alert_date' => 'date',
        'resolved_at' => 'datetime',
        'is_resolved' => 'boolean',
        'risk_score' => 'decimal:2',
    ];
}
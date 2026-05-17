<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class LifeNotification extends Model
{
    use HasUuids;

    protected $table = 'life_notifications';

    protected $fillable = [
        'user_id',
        'notification_type',
        'title',
        'message',
        'severity',
        'source_module',
        'metadata',
        'is_read',
        'read_at',
        'scheduled_for',
        'triggered_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'is_read' => 'boolean',
        'read_at' => 'datetime',
        'scheduled_for' => 'datetime',
        'triggered_at' => 'datetime',
    ];
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class AiInsight extends Model
{
    use HasUuids;

    protected $table = 'ai_insights';

    protected $fillable = [
        'user_id',
        'insight_type',
        'category',
        'title',
        'message',
        'severity',
        'score',
        'metadata',
        'insight_date',
        'is_read',
        'is_archived',
    ];

    protected $casts = [
        'metadata' => 'array',
        'insight_date' => 'date',
        'is_read' => 'boolean',
        'is_archived' => 'boolean',
        'score' => 'decimal:2',
    ];
}
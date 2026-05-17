<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class LifeBalanceScore extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'target_date',
        'finance_score',
        'health_score',
        'productivity_score',
        'overall_score',
        'status',
        'finance_breakdown',
        'health_breakdown',
        'productivity_breakdown',
        'recommendations',
    ];

    protected $casts = [
        'target_date' => 'date',
        'finance_breakdown' => 'array',
        'health_breakdown' => 'array',
        'productivity_breakdown' => 'array',
        'recommendations' => 'array',
    ];
}
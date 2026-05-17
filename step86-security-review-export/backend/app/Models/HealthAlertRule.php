<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthAlertRule extends Model
{
    use HasUuids;

    protected $fillable = [
        'code',
        'name',
        'category',
        'severity',
        'warning_threshold',
        'critical_threshold',
        'operator',
        'unit',
        'is_active',
        'metadata',
    ];

    protected $casts = [
        'warning_threshold' => 'decimal:2',
        'critical_threshold' => 'decimal:2',
        'is_active' => 'boolean',
        'metadata' => 'array',
    ];
}
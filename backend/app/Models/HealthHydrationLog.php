<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class HealthHydrationLog extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'health_hydration_logs';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'hydration_type',
        'quantity_ml',
        'log_date',
        'log_time',
        'notes',
        'date',
        'drink_type',
        'water_ml',
        'amount_ml',
        'is_ckd_safe',
        'source',
    ];

    protected $casts = [
        'log_date' => 'date',
        'date' => 'date',
        'log_time' => 'datetime',
        'quantity_ml' => 'integer',
        'water_ml' => 'integer',
        'amount_ml' => 'integer',
        'is_ckd_safe' => 'boolean',
    ];

    public const TYPES = [
        'Water',
        'Coffee',
        'Tea',
        'Juice',
        'Soft Drink',
        'Soup',
        'Other',
    ];
}

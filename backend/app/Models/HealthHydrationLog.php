<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HealthHydrationLog extends Model
{
    use HasFactory;

    protected $table = 'health_hydration_logs';

    protected $fillable = [
        'user_id',
        'hydration_type',
        'quantity_ml',
        'log_date',
        'log_time',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'quantity_ml' => 'integer',
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

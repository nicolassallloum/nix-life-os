<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class HealthMedication extends Model
{
    use HasUuids, SoftDeletes;

    protected $table = 'health_medications';

    protected $fillable = [
        'user_id',
        'medication_name',
        'dosage',
        'daily_dose',
        'dose_times',
        'frequency',
        'start_date',
        'end_date',
        'status',
        'prescribed_by',
        'notes',
    ];

    protected $casts = [
        'start_date' => 'date:Y-m-d',
        'end_date' => 'date:Y-m-d',
        'dose_times' => 'array',
    ];
}
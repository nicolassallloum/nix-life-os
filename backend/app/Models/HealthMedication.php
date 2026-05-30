<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthMedication extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'medication_name',
        'dosage',
        'medication_time',
        'frequency_type',
        'quantity',
        'start_date',
        'stop_date',
        'status',
        'notes',
    ];
}
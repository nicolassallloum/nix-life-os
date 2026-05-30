<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthSleepLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'entry_date',
        'sleep_start',
        'sleep_end',
        'duration_hours',
        'quality',
        'notes',
    ];
}
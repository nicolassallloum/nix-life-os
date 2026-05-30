<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class HealthWaterLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'entry_date',
        'amount_ml',
        'notes',
    ];
}
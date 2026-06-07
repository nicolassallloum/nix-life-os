<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthStepLog extends Model
{
    protected $table = 'health_step_logs';

    protected $fillable = [
        'user_id',
        'log_date',
        'steps',
        'kilometers',
        'calories_burned',
        'source',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'steps' => 'integer',
        'kilometers' => 'decimal:3',
        'calories_burned' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

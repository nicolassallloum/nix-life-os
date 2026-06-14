<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthStepLog extends Model
{
    use HasFactory;

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
        'log_date' => 'date:Y-m-d',
        'steps' => 'integer',
        'kilometers' => 'decimal:2',
        'calories_burned' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

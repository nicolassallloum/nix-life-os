<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthHydrationLog extends Model
{
    use HasUuids;

    protected $table = 'health_hydration_logs';

    protected $fillable = [
        'user_id',
        'log_date',
        'log_time',
        'drink_type',
        'amount_ml',
        'is_ckd_safe',
        'source',
        'notes',
    ];

    protected $casts = [
        'log_date' => 'date',
        'amount_ml' => 'decimal:2',
        'is_ckd_safe' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

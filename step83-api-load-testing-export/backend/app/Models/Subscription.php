<?php

namespace App\Models;

use App\Models\Concerns\UsesUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Subscription extends Model
{
    use UsesUuid;

    protected $fillable = [
        'user_id',
        'plan_id',
        'status',
        'billing_cycle',
        'started_at',
        'trial_ends_at',
        'current_period_starts_at',
        'current_period_ends_at',
        'cancelled_at',
        'payment_provider',
        'payment_customer_id',
        'payment_subscription_id',
        'metadata',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'current_period_starts_at' => 'datetime',
        'current_period_ends_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function plan(): BelongsTo
    {
        return $this->belongsTo(Plan::class);
    }

    public function usage(): HasMany
    {
        return $this->hasMany(SubscriptionUsage::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProductivityGoal extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'status',
        'category',
        'priority',
        'progress_percentage',
        'target_date',
        'completed_at',
        'metadata',
    ];

    protected $casts = [
        'target_date' => 'date',
        'completed_at' => 'datetime',
        'progress_percentage' => 'decimal:2',
        'metadata' => 'array',
    ];

    protected $appends = [
        'is_overdue',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getIsOverdueAttribute(): bool
    {
        if (!$this->target_date) {
            return false;
        }

        if (in_array($this->status, ['completed', 'cancelled'], true)) {
            return false;
        }

        return $this->target_date->isPast() && !$this->target_date->isToday();
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProductivityTask extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'status',
        'priority',
        'progress_percentage',
        'start_date',
        'due_date',
        'completed_at',
        'metadata',
    ];

    protected $casts = [
        'start_date' => 'date',
        'due_date' => 'date',
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
        if (!$this->due_date) {
            return false;
        }

        if (in_array($this->status, ['completed', 'cancelled'], true)) {
            return false;
        }

        return $this->due_date->isPast() && !$this->due_date->isToday();
    }
}

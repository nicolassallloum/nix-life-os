<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProjectTask extends Model
{
    use HasUuids;

    protected $fillable = [
        'project_id',
        'user_id',
        'task_title',
        'task_description',
        'status',
        'priority',
        'task_order',
        'start_date',
        'due_date',
        'completed_date',
        'progress_percentage',
        'metadata',
    ];

    protected $casts = [
        'start_date' => 'date',
        'due_date' => 'date',
        'completed_date' => 'date',
        'progress_percentage' => 'decimal:2',
        'metadata' => 'array',
    ];

    protected $appends = [
        'is_overdue',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

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

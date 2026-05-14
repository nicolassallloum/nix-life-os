<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;

class ProductivityHabit extends Model
{
    use HasUuids;

    protected $fillable = [
        'user_id',
        'name',
        'description',
        'status',
        'frequency',
        'target_count',
        'completed_count_today',
        'current_streak',
        'best_streak',
        'last_completed_at',
        'metadata',
    ];

    protected $casts = [
        'target_count' => 'integer',
        'completed_count_today' => 'integer',
        'current_streak' => 'integer',
        'best_streak' => 'integer',
        'last_completed_at' => 'datetime',
        'metadata' => 'array',
    ];

    protected $appends = [
        'is_completed_today',
        'title',
        'best_streak_count',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function checkIns()
    {
        return $this->hasMany(ProductivityHabitCheckIn::class, 'habit_id');
    }

    public function getIsCompletedTodayAttribute(): bool
    {
        if ($this->completed_count_today >= $this->target_count) {
            return true;
        }

        return $this->last_completed_at?->isToday() ?? false;
    }

    public function getTitleAttribute(): string
    {
        return (string) $this->name;
    }

    public function getBestStreakCountAttribute(): int
    {
        return (int) $this->best_streak;
    }
}

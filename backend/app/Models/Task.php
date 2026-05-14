<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Casts\Attribute;

class Task extends Model
{
    use HasFactory;
    use SoftDeletes;

    protected $fillable = [
        'user_id',
        'title',
        'description',
        'status',
        'priority',
        'due_date',
        'completed_at',
    ];

    protected $casts = [
        'due_date' => 'date:Y-m-d',
        'completed_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $appends = [
        'is_overdue',
    ];

    protected function isOverdue(): Attribute
    {
        return Attribute::make(
            get: function () {
                if (!$this->due_date) {
                    return false;
                }

                return $this->due_date->isPast()
                    && !$this->due_date->isToday()
                    && $this->status !== 'completed';
            }
        );
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

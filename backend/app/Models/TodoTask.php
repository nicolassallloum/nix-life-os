<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TodoTask extends Model
{
    use HasFactory;

    public const TYPE_GENERAL = 'general';
    public const TYPE_MONTHLY = 'monthly';
    public const TYPE_WEEKLY = 'weekly';
    public const TYPE_DAILY = 'daily';

    public const TYPES = [
        self::TYPE_GENERAL,
        self::TYPE_MONTHLY,
        self::TYPE_WEEKLY,
        self::TYPE_DAILY,
    ];

    public const STATUS_PENDING = 'pending';
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_FINISHED = 'finished';

    public const STATUSES = [
        self::STATUS_PENDING,
        self::STATUS_IN_PROGRESS,
        self::STATUS_FINISHED,
    ];

    public const PRIORITY_LOW = 'low';
    public const PRIORITY_MEDIUM = 'medium';
    public const PRIORITY_HIGH = 'high';

    public const PRIORITIES = [
        self::PRIORITY_LOW,
        self::PRIORITY_MEDIUM,
        self::PRIORITY_HIGH,
    ];

    protected $fillable = [
        'user_id',
        'project_id',
        'title',
        'description',
        'task_type',
        'status',
        'priority',
        'points',
        'due_date',
        'completed_at',
        'sort_order',
        'notes',
    ];

    protected $casts = [
        'points' => 'integer',
        'sort_order' => 'integer',
        'due_date' => 'date',
        'completed_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function project(): BelongsTo
    {
        return $this->belongsTo(TodoProject::class, 'project_id');
    }
}
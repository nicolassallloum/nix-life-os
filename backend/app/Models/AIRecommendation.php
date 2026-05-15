<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AIRecommendation extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'ai_recommendations';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'rule_id',
        'module',
        'recommendation_type',
        'title',
        'message',
        'action_text',
        'severity',
        'priority',
        'confidence_score',
        'impact_score',
        'status',
        'period_key',
        'duplicate_key',
        'source_data',
        'score_breakdown',
        'metadata',
        'generated_at',
        'viewed_at',
        'accepted_at',
        'dismissed_at',
        'completed_at',
        'expired_at',
        'expires_at',
    ];

    protected $casts = [
        'source_data' => 'array',
        'score_breakdown' => 'array',
        'metadata' => 'array',
        'priority' => 'integer',
        'confidence_score' => 'decimal:2',
        'impact_score' => 'decimal:2',
        'generated_at' => 'datetime',
        'viewed_at' => 'datetime',
        'accepted_at' => 'datetime',
        'dismissed_at' => 'datetime',
        'completed_at' => 'datetime',
        'expired_at' => 'datetime',
        'expires_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public const STATUS_PENDING = 'pending';
    public const STATUS_VIEWED = 'viewed';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_DISMISSED = 'dismissed';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_EXPIRED = 'expired';

    public const SEVERITY_CRITICAL = 'critical';
    public const SEVERITY_HIGH = 'high';
    public const SEVERITY_MEDIUM = 'medium';
    public const SEVERITY_LOW = 'low';
    public const SEVERITY_POSITIVE = 'positive';
    public const SEVERITY_INFO = 'info';

    public const MODULE_FINANCE = 'finance';
    public const MODULE_HEALTH = 'health';
    public const MODULE_PRODUCTIVITY = 'productivity';
    public const MODULE_LIFE_BALANCE = 'life_balance';
    public const MODULE_GOALS = 'goals';
    public const MODULE_HABITS = 'habits';
    public const MODULE_SYSTEM = 'system';

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function rule(): BelongsTo
    {
        return $this->belongsTo(AIRecommendationRule::class, 'rule_id');
    }

    public function feedback(): HasMany
    {
        return $this->hasMany(AIRecommendationFeedback::class, 'recommendation_id');
    }

    public function scopeForUser(Builder $query, string $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForModule(Builder $query, string $module): Builder
    {
        return $query->where('module', $module);
    }

    public function scopeForType(Builder $query, string $type): Builder
    {
        return $query->where('recommendation_type', $type);
    }

    public function scopeByStatus(Builder $query, string $status): Builder
    {
        return $query->where('status', $status);
    }

    public function scopeBySeverity(Builder $query, string $severity): Builder
    {
        return $query->where('severity', $severity);
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    public function scopeViewed(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_VIEWED);
    }

    public function scopeAccepted(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_ACCEPTED);
    }

    public function scopeDismissed(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_DISMISSED);
    }

    public function scopeCompleted(Builder $query): Builder
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->whereIn('status', [
            self::STATUS_PENDING,
            self::STATUS_VIEWED,
            self::STATUS_ACCEPTED,
        ]);
    }

    public function scopeCritical(Builder $query): Builder
    {
        return $query->where('severity', self::SEVERITY_CRITICAL);
    }

    public function scopeHighPriority(Builder $query): Builder
    {
        return $query->whereIn('priority', [1, 2]);
    }

    public function scopeExpired(Builder $query): Builder
    {
        return $query
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now());
    }

    public function scopeNotExpired(Builder $query): Builder
    {
        return $query->where(function (Builder $q) {
            $q->whereNull('expires_at')
                ->orWhere('expires_at', '>=', now());
        });
    }

    public function scopeLatestGenerated(Builder $query): Builder
    {
        return $query->orderByDesc('generated_at');
    }

    public function markViewed(): bool
    {
        if ($this->viewed_at === null) {
            $this->viewed_at = now();
        }

        if ($this->status === self::STATUS_PENDING) {
            $this->status = self::STATUS_VIEWED;
        }

        return $this->save();
    }

    public function accept(): bool
    {
        $this->status = self::STATUS_ACCEPTED;
        $this->accepted_at = now();

        return $this->save();
    }

    public function dismiss(): bool
    {
        $this->status = self::STATUS_DISMISSED;
        $this->dismissed_at = now();

        return $this->save();
    }

    public function complete(): bool
    {
        $this->status = self::STATUS_COMPLETED;
        $this->completed_at = now();

        return $this->save();
    }

    public function expire(): bool
    {
        $this->status = self::STATUS_EXPIRED;
        $this->expired_at = now();

        return $this->save();
    }

    public function isPending(): bool
    {
        return $this->status === self::STATUS_PENDING;
    }

    public function isViewed(): bool
    {
        return $this->status === self::STATUS_VIEWED;
    }

    public function isAccepted(): bool
    {
        return $this->status === self::STATUS_ACCEPTED;
    }

    public function isDismissed(): bool
    {
        return $this->status === self::STATUS_DISMISSED;
    }

    public function isCompleted(): bool
    {
        return $this->status === self::STATUS_COMPLETED;
    }

    public function isExpiredStatus(): bool
    {
        return $this->status === self::STATUS_EXPIRED;
    }

    public function isExpiredByDate(): bool
    {
        return $this->expires_at !== null && $this->expires_at->lessThan(now());
    }

    public function isActive(): bool
    {
        return in_array($this->status, [
            self::STATUS_PENDING,
            self::STATUS_VIEWED,
            self::STATUS_ACCEPTED,
        ], true);
    }

    public function isCritical(): bool
    {
        return $this->severity === self::SEVERITY_CRITICAL;
    }

    public function isHighSeverity(): bool
    {
        return in_array($this->severity, [
            self::SEVERITY_CRITICAL,
            self::SEVERITY_HIGH,
        ], true);
    }

    public function isHighPriority(): bool
    {
        return in_array((int) $this->priority, [1, 2], true);
    }

    public function confidenceLevel(): string
    {
        $score = (float) $this->confidence_score;

        return match (true) {
            $score >= 85 => 'very_high',
            $score >= 70 => 'high',
            $score >= 50 => 'medium',
            $score >= 30 => 'low',
            default => 'very_low',
        };
    }

    public function impactLevel(): string
    {
        $score = (float) $this->impact_score;

        return match (true) {
            $score >= 85 => 'very_high',
            $score >= 70 => 'high',
            $score >= 50 => 'medium',
            $score >= 30 => 'low',
            default => 'very_low',
        };
    }

    public function severityLabel(): string
    {
        return match ($this->severity) {
            self::SEVERITY_CRITICAL => 'Critical',
            self::SEVERITY_HIGH => 'High',
            self::SEVERITY_MEDIUM => 'Medium',
            self::SEVERITY_LOW => 'Low',
            self::SEVERITY_POSITIVE => 'Positive',
            self::SEVERITY_INFO => 'Info',
            default => 'Unknown',
        };
    }

    public function statusLabel(): string
    {
        return match ($this->status) {
            self::STATUS_PENDING => 'Pending',
            self::STATUS_VIEWED => 'Viewed',
            self::STATUS_ACCEPTED => 'Accepted',
            self::STATUS_DISMISSED => 'Dismissed',
            self::STATUS_COMPLETED => 'Completed',
            self::STATUS_EXPIRED => 'Expired',
            default => 'Unknown',
        };
    }

    public function moduleLabel(): string
    {
        return match ($this->module) {
            self::MODULE_FINANCE => 'Finance',
            self::MODULE_HEALTH => 'Health',
            self::MODULE_PRODUCTIVITY => 'Productivity',
            self::MODULE_LIFE_BALANCE => 'Life Balance',
            self::MODULE_GOALS => 'Goals',
            self::MODULE_HABITS => 'Habits',
            self::MODULE_SYSTEM => 'System',
            default => 'Unknown',
        };
    }
}
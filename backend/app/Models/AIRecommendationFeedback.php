<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class AIRecommendationFeedback extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'ai_recommendation_feedback';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'recommendation_id',
        'user_id',
        'feedback_type',
        'feedback_value',
        'feedback_comment',
        'metadata',
    ];

    protected $casts = [
        'feedback_value' => 'integer',
        'metadata' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public const TYPE_USEFUL = 'useful';
    public const TYPE_NOT_USEFUL = 'not_useful';
    public const TYPE_TOO_LATE = 'too_late';
    public const TYPE_NOT_RELEVANT = 'not_relevant';
    public const TYPE_ACCEPTED = 'accepted';
    public const TYPE_DISMISSED = 'dismissed';
    public const TYPE_COMPLETED = 'completed';
    public const TYPE_RATING = 'rating';

    public function recommendation(): BelongsTo
    {
        return $this->belongsTo(AIRecommendation::class, 'recommendation_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeForUser(Builder $query, string $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForRecommendation(Builder $query, string $recommendationId): Builder
    {
        return $query->where('recommendation_id', $recommendationId);
    }

    public function scopeByType(Builder $query, string $type): Builder
    {
        return $query->where('feedback_type', $type);
    }

    public function scopePositive(Builder $query): Builder
    {
        return $query->whereIn('feedback_type', [
            self::TYPE_USEFUL,
            self::TYPE_ACCEPTED,
            self::TYPE_COMPLETED,
        ]);
    }

    public function scopeNegative(Builder $query): Builder
    {
        return $query->whereIn('feedback_type', [
            self::TYPE_NOT_USEFUL,
            self::TYPE_TOO_LATE,
            self::TYPE_NOT_RELEVANT,
            self::TYPE_DISMISSED,
        ]);
    }

    public function scopeRating(Builder $query): Builder
    {
        return $query->where('feedback_type', self::TYPE_RATING);
    }

    public function isPositive(): bool
    {
        return in_array($this->feedback_type, [
            self::TYPE_USEFUL,
            self::TYPE_ACCEPTED,
            self::TYPE_COMPLETED,
        ], true);
    }

    public function isNegative(): bool
    {
        return in_array($this->feedback_type, [
            self::TYPE_NOT_USEFUL,
            self::TYPE_TOO_LATE,
            self::TYPE_NOT_RELEVANT,
            self::TYPE_DISMISSED,
        ], true);
    }

    public function isRating(): bool
    {
        return $this->feedback_type === self::TYPE_RATING;
    }

    public function feedbackLabel(): string
    {
        return match ($this->feedback_type) {
            self::TYPE_USEFUL => 'Useful',
            self::TYPE_NOT_USEFUL => 'Not Useful',
            self::TYPE_TOO_LATE => 'Too Late',
            self::TYPE_NOT_RELEVANT => 'Not Relevant',
            self::TYPE_ACCEPTED => 'Accepted',
            self::TYPE_DISMISSED => 'Dismissed',
            self::TYPE_COMPLETED => 'Completed',
            self::TYPE_RATING => 'Rating',
            default => 'Unknown',
        };
    }
}
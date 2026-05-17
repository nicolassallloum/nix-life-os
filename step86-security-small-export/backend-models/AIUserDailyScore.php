<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class AIUserDailyScore extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'ai_user_daily_scores';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'user_id',
        'score_date',
        'finance_score',
        'health_score',
        'productivity_score',
        'goals_score',
        'habits_score',
        'life_balance_score',
        'classification',
        'score_breakdown',
        'source_summary',
        'metadata',
    ];

    protected $casts = [
        'score_date' => 'date',
        'finance_score' => 'decimal:2',
        'health_score' => 'decimal:2',
        'productivity_score' => 'decimal:2',
        'goals_score' => 'decimal:2',
        'habits_score' => 'decimal:2',
        'life_balance_score' => 'decimal:2',
        'score_breakdown' => 'array',
        'source_summary' => 'array',
        'metadata' => 'array',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public const CLASSIFICATION_EXCELLENT = 'excellent';
    public const CLASSIFICATION_GOOD = 'good';
    public const CLASSIFICATION_NEEDS_ATTENTION = 'needs_attention';
    public const CLASSIFICATION_RISK = 'risk';
    public const CLASSIFICATION_CRITICAL = 'critical';

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeForUser(Builder $query, string $userId): Builder
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForDate(Builder $query, string $date): Builder
    {
        return $query->whereDate('score_date', $date);
    }

    public function scopeBetweenDates(Builder $query, string $startDate, string $endDate): Builder
    {
        return $query->whereBetween('score_date', [$startDate, $endDate]);
    }

    public function scopeLatestScore(Builder $query): Builder
    {
        return $query->orderByDesc('score_date');
    }

    public function scopeByClassification(Builder $query, string $classification): Builder
    {
        return $query->where('classification', $classification);
    }

    public function scopeCritical(Builder $query): Builder
    {
        return $query->where('classification', self::CLASSIFICATION_CRITICAL);
    }

    public function scopeRisk(Builder $query): Builder
    {
        return $query->whereIn('classification', [
            self::CLASSIFICATION_RISK,
            self::CLASSIFICATION_CRITICAL,
        ]);
    }

    public function isExcellent(): bool
    {
        return $this->classification === self::CLASSIFICATION_EXCELLENT;
    }

    public function isGood(): bool
    {
        return $this->classification === self::CLASSIFICATION_GOOD;
    }

    public function needsAttention(): bool
    {
        return $this->classification === self::CLASSIFICATION_NEEDS_ATTENTION;
    }

    public function isRisk(): bool
    {
        return $this->classification === self::CLASSIFICATION_RISK;
    }

    public function isCritical(): bool
    {
        return $this->classification === self::CLASSIFICATION_CRITICAL;
    }

    public function isHealthyBalance(): bool
    {
        return (float) $this->life_balance_score >= 70;
    }

    public function weakestArea(): string
    {
        $scores = [
            'finance' => (float) $this->finance_score,
            'health' => (float) $this->health_score,
            'productivity' => (float) $this->productivity_score,
            'goals' => (float) $this->goals_score,
            'habits' => (float) $this->habits_score,
        ];

        asort($scores);

        return array_key_first($scores);
    }

    public function strongestArea(): string
    {
        $scores = [
            'finance' => (float) $this->finance_score,
            'health' => (float) $this->health_score,
            'productivity' => (float) $this->productivity_score,
            'goals' => (float) $this->goals_score,
            'habits' => (float) $this->habits_score,
        ];

        arsort($scores);

        return array_key_first($scores);
    }

    public function classificationLabel(): string
    {
        return match ($this->classification) {
            self::CLASSIFICATION_EXCELLENT => 'Excellent',
            self::CLASSIFICATION_GOOD => 'Good',
            self::CLASSIFICATION_NEEDS_ATTENTION => 'Needs Attention',
            self::CLASSIFICATION_RISK => 'Risk',
            self::CLASSIFICATION_CRITICAL => 'Critical',
            default => 'Unknown',
        };
    }

    public static function classifyScore(float $score): string
    {
        return match (true) {
            $score >= 85 => self::CLASSIFICATION_EXCELLENT,
            $score >= 70 => self::CLASSIFICATION_GOOD,
            $score >= 50 => self::CLASSIFICATION_NEEDS_ATTENTION,
            $score >= 30 => self::CLASSIFICATION_RISK,
            default => self::CLASSIFICATION_CRITICAL,
        };
    }
}
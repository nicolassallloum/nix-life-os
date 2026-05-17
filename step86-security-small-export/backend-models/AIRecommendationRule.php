<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class AIRecommendationRule extends Model
{
    use HasUuids;
    use SoftDeletes;

    protected $table = 'ai_recommendation_rules';

    protected $keyType = 'string';

    public $incrementing = false;

    protected $fillable = [
        'rule_code',
        'rule_name',
        'module',
        'recommendation_type',
        'condition_key',
        'operator',
        'threshold_value',
        'condition_payload',
        'severity',
        'priority',
        'title_template',
        'message_template',
        'action_template',
        'base_confidence_score',
        'base_impact_score',
        'is_active',
        'valid_from',
        'valid_to',
        'metadata',
    ];

    protected $casts = [
        'condition_payload' => 'array',
        'metadata' => 'array',
        'threshold_value' => 'decimal:4',
        'base_confidence_score' => 'decimal:2',
        'base_impact_score' => 'decimal:2',
        'priority' => 'integer',
        'is_active' => 'boolean',
        'valid_from' => 'datetime',
        'valid_to' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public const MODULE_FINANCE = 'finance';
    public const MODULE_HEALTH = 'health';
    public const MODULE_PRODUCTIVITY = 'productivity';
    public const MODULE_LIFE_BALANCE = 'life_balance';
    public const MODULE_GOALS = 'goals';
    public const MODULE_HABITS = 'habits';
    public const MODULE_SYSTEM = 'system';

    public const SEVERITY_CRITICAL = 'critical';
    public const SEVERITY_HIGH = 'high';
    public const SEVERITY_MEDIUM = 'medium';
    public const SEVERITY_LOW = 'low';
    public const SEVERITY_POSITIVE = 'positive';
    public const SEVERITY_INFO = 'info';

    public function recommendations(): HasMany
    {
        return $this->hasMany(AIRecommendation::class, 'rule_id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true);
    }

    public function scopeInactive(Builder $query): Builder
    {
        return $query->where('is_active', false);
    }

    public function scopeForModule(Builder $query, string $module): Builder
    {
        return $query->where('module', $module);
    }

    public function scopeForType(Builder $query, string $type): Builder
    {
        return $query->where('recommendation_type', $type);
    }

    public function scopeBySeverity(Builder $query, string $severity): Builder
    {
        return $query->where('severity', $severity);
    }

    public function scopeCritical(Builder $query): Builder
    {
        return $query->where('severity', self::SEVERITY_CRITICAL);
    }

    public function scopeHighPriority(Builder $query): Builder
    {
        return $query->whereIn('priority', [1, 2]);
    }

    public function scopeCurrentlyValid(Builder $query): Builder
    {
        return $query
            ->where(function (Builder $q) {
                $q->whereNull('valid_from')
                    ->orWhere('valid_from', '<=', now());
            })
            ->where(function (Builder $q) {
                $q->whereNull('valid_to')
                    ->orWhere('valid_to', '>=', now());
            });
    }

    public function isActive(): bool
    {
        return (bool) $this->is_active;
    }

    public function isCurrentlyValid(): bool
    {
        $now = now();

        if ($this->valid_from && $this->valid_from->greaterThan($now)) {
            return false;
        }

        if ($this->valid_to && $this->valid_to->lessThan($now)) {
            return false;
        }

        return true;
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
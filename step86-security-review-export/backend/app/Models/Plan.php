<?php

namespace App\Models;

use App\Models\Concerns\UsesUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model
{
    use UsesUuid;

    protected $fillable = [
        'code',
        'name',
        'monthly_price',
        'yearly_price',
        'max_finance_accounts',
        'max_projects',
        'max_ai_insights_per_month',
        'max_notifications_per_month',
        'finance_module_enabled',
        'health_module_enabled',
        'projects_module_enabled',
        'ai_module_enabled',
        'automation_module_enabled',
        'monitoring_module_enabled',
        'features',
        'is_active',
    ];

    protected $casts = [
        'monthly_price' => 'decimal:2',
        'yearly_price' => 'decimal:2',
        'features' => 'array',
        'is_active' => 'boolean',
        'finance_module_enabled' => 'boolean',
        'health_module_enabled' => 'boolean',
        'projects_module_enabled' => 'boolean',
        'ai_module_enabled' => 'boolean',
        'automation_module_enabled' => 'boolean',
        'monitoring_module_enabled' => 'boolean',
    ];

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }
}
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceIntelligenceSetting extends Model
{
    use HasUuids;

    protected $table = 'finance_intelligence_setting';
    protected $primaryKey = 'finance_intelligence_setting_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'auto_save_enabled',
        'auto_save_percentage',
        'default_savings_account_id',
        'budget_warning_default_pct',
        'large_expense_multiplier',
        'category_spike_multiplier',
        'abnormal_daily_multiplier',
        'anomaly_minimum_amount',
        'metadata_json',
    ];

    protected $casts = [
        'auto_save_enabled' => 'boolean',
        'auto_save_percentage' => 'decimal:2',
        'budget_warning_default_pct' => 'decimal:2',
        'large_expense_multiplier' => 'decimal:2',
        'category_spike_multiplier' => 'decimal:2',
        'abnormal_daily_multiplier' => 'decimal:2',
        'anomaly_minimum_amount' => 'decimal:2',
        'metadata_json' => 'array',
    ];
}
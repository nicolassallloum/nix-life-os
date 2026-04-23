<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class FinanceForecastSnapshot extends Model
{
    use HasUuids;

    protected $table = 'finance_forecast_snapshot';
    protected $primaryKey = 'forecast_snapshot_id';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'user_id',
        'forecast_month',
        'current_total_balance',
        'projected_income_total',
        'projected_expense_total',
        'projected_net_cash_flow',
        'projected_savings_transfer',
        'projected_month_end_balance',
        'forecast_data_json',
    ];

    protected $casts = [
        'forecast_month' => 'date',
        'current_total_balance' => 'decimal:2',
        'projected_income_total' => 'decimal:2',
        'projected_expense_total' => 'decimal:2',
        'projected_net_cash_flow' => 'decimal:2',
        'projected_savings_transfer' => 'decimal:2',
        'projected_month_end_balance' => 'decimal:2',
        'forecast_data_json' => 'array',
    ];
}
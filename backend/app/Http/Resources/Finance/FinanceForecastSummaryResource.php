<?php

namespace App\Http\Resources\Finance;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceForecastSummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'forecast_month' => $this['forecast_month'],
            'current_total_balance' => $this['current_total_balance'],
            'mtd_income' => $this['mtd_income'],
            'mtd_expense' => $this['mtd_expense'],
            'avg_daily_income' => $this['avg_daily_income'],
            'avg_daily_expense' => $this['avg_daily_expense'],
            'projected_income_total' => $this['projected_income_total'],
            'projected_expense_total' => $this['projected_expense_total'],
            'projected_net_cash_flow' => $this['projected_net_cash_flow'],
            'projected_savings_transfer' => $this['projected_savings_transfer'],
            'projected_month_end_balance' => $this['projected_month_end_balance'],
            'forecast_end_of_month_savings' => $this['forecast_end_of_month_savings'],
            'formula_notes' => $this['formula_notes'] ?? [],
        ];
    }
}
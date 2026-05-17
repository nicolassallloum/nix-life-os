<?php

namespace App\Http\Requests\Finance;

use Illuminate\Foundation\Http\FormRequest;

class UpdateFinanceIntelligenceSettingRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'auto_save_enabled' => ['required', 'boolean'],
            'auto_save_percentage' => ['required', 'numeric', 'min:0', 'max:100'],
            'default_savings_account_id' => ['nullable', 'uuid'],
            'budget_warning_default_pct' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'large_expense_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'category_spike_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'abnormal_daily_multiplier' => ['nullable', 'numeric', 'gt:0'],
            'anomaly_minimum_amount' => ['nullable', 'numeric', 'min:0'],
        ];
    }
}
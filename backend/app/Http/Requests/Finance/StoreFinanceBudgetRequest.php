<?php

namespace App\Http\Requests\Finance;

use Illuminate\Foundation\Http\FormRequest;

class StoreFinanceBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'budget_name' => ['required', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],
            'budget_amount' => ['nullable', 'numeric', 'min:0'],
            'budget_month' => ['required', 'string', 'max:20'],
            'currency_code' => ['required', 'string', 'max:10'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
            'metadata_json' => ['nullable', 'array'],

            'lines' => ['required', 'array', 'min:1'],
            'lines.*.account_id' => ['nullable', 'uuid', 'exists:finance_accounts,id'],
            'lines.*.category_id' => ['nullable', 'uuid'],
            'lines.*.category' => ['nullable', 'string', 'max:255'],
            'lines.*.planned_amount' => ['required', 'numeric', 'min:0'],
            'lines.*.actual_amount' => ['nullable', 'numeric', 'min:0'],
            'lines.*.spent_amount' => ['nullable', 'numeric', 'min:0'],
            'lines.*.warning_percentage' => ['nullable', 'numeric', 'min:0'],
            'lines.*.exceeded_percentage' => ['nullable', 'numeric', 'min:0'],
            'lines.*.line_notes' => ['nullable', 'string'],
            'lines.*.notes' => ['nullable', 'string'],
            'lines.*.metadata_json' => ['nullable', 'array'],
        ];
    }
}

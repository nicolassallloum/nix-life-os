<?php

namespace App\Http\Requests\Finance;
use Illuminate\Validation\Rule;
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
            'budget_name' => ['required', 'string', 'max:150'],
            'budget_month' => ['required', 'date_format:Y-m-d'],
            'currency_code' => ['required', 'string', 'max:10'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string'],
            'metadata_json' => ['nullable', 'array'],

            'lines' => ['required', 'array', 'min:1'],
            'lines.*.category_id' => ['nullable', 'uuid'],
            'lines.*.account_id' => ['nullable', 'uuid'],
            'lines.*.planned_amount' => ['required', 'numeric', 'min:0'],
            'lines.*.warning_percentage' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'lines.*.exceeded_percentage' => ['nullable', 'numeric', 'min:0'],
            'lines.*.line_notes' => ['nullable', 'string'],
            'lines.*.metadata_json' => ['nullable', 'array'],
            'lines.*.category_id' => ['nullable', 'uuid', 'exists:finance_category,category_id'],
            'lines.*.account_id' => ['nullable', 'uuid', 'exists:finance_account,account_id'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            foreach ($this->input('lines', []) as $index => $line) {
                if (empty($line['category_id']) && empty($line['account_id'])) {
                    $validator->errors()->add("lines.$index", 'Either category_id or account_id is required.');
                }
            }
        });
    }
}
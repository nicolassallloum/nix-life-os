<?php

namespace App\Http\Requests\Finance;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFinanceBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->user()?->id;

        return [
            /*
            |--------------------------------------------------------------------------
            | Budget Header
            |--------------------------------------------------------------------------
            */
            'budget_name' => [
                'required',
                'string',
                'max:150',
            ],

            'budget_month' => [
                'required',
                'date_format:Y-m-d',
            ],

            'currency_code' => [
                'required',
                'string',
                'max:10',
            ],

            'is_active' => [
                'nullable',
                'boolean',
            ],

            'notes' => [
                'nullable',
                'string',
            ],

            'metadata_json' => [
                'nullable',
                'array',
            ],

            /*
            |--------------------------------------------------------------------------
            | Budget Lines
            |--------------------------------------------------------------------------
            */
            'lines' => [
                'required',
                'array',
                'min:1',
            ],

            'lines.*.category_id' => [
                'nullable',
                'uuid',
            ],

            'lines.*.account_id' => [
                'nullable',
                'uuid',
                Rule::exists('finance_accounts', 'id')->where(function ($query) use ($userId) {
                    if ($userId) {
                        $query->where('user_id', $userId);
                    }
                }),
            ],

            'lines.*.planned_amount' => [
                'required',
                'numeric',
                'min:0',
            ],

            'lines.*.warning_percentage' => [
                'nullable',
                'numeric',
                'min:0',
                'max:100',
            ],

            'lines.*.exceeded_percentage' => [
                'nullable',
                'numeric',
                'min:0',
            ],

            'lines.*.line_notes' => [
                'nullable',
                'string',
            ],

            'lines.*.metadata_json' => [
                'nullable',
                'array',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'budget_name.required' => 'The budget name field is required.',
            'budget_month.required' => 'The budget month field is required.',
            'budget_month.date_format' => 'The budget month field must match the format Y-m-d.',
            'currency_code.required' => 'The currency code field is required.',

            'lines.required' => 'At least one budget line is required.',
            'lines.array' => 'Budget lines must be provided as an array.',
            'lines.min' => 'At least one budget line is required.',

            'lines.*.account_id.exists' => 'The selected account does not exist for the authenticated user.',
            'lines.*.planned_amount.required' => 'The planned amount field is required.',
            'lines.*.planned_amount.numeric' => 'The planned amount must be numeric.',
            'lines.*.planned_amount.min' => 'The planned amount must be at least 0.',
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            foreach ($this->input('lines', []) as $index => $line) {
                $hasCategory = ! empty($line['category_id']);
                $hasAccount = ! empty($line['account_id']);

                if (! $hasCategory && ! $hasAccount) {
                    $validator->errors()->add(
                        "lines.$index",
                        'Either category_id or account_id is required.'
                    );
                }
            }
        });
    }
}
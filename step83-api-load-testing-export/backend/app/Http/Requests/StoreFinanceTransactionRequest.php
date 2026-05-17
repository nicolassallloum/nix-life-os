<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreFinanceTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'transaction_type' => ['required', Rule::in(['income', 'expense', 'transfer'])],
            'account_id' => ['required', 'uuid'],
            'transfer_account_id' => ['nullable', 'uuid'],
            'category_id' => ['nullable', 'uuid'],
            'amount' => ['required', 'numeric', 'gt:0'],
            'transaction_date' => ['required', 'date'],
            'description' => ['nullable', 'string'],
            'reference_no' => ['nullable', 'string', 'max:100'],
            'metadata_json' => ['nullable', 'array'],
        ];
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            $type = $this->input('transaction_type');

            if (in_array($type, ['income', 'expense'], true) && $this->filled('transfer_account_id')) {
                $validator->errors()->add('transfer_account_id', 'transfer_account_id must be null for income or expense.');
            }

            if ($type === 'transfer' && !$this->filled('transfer_account_id')) {
                $validator->errors()->add('transfer_account_id', 'transfer_account_id is required for transfer.');
            }

            if ($type === 'transfer' && $this->input('transfer_account_id') === $this->input('account_id')) {
                $validator->errors()->add('transfer_account_id', 'Transfer account must be different from account_id.');
            }
        });
    }
}

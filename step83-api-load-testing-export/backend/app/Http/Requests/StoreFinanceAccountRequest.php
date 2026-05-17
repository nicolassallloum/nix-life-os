<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Enum;
use App\Enums\AccountType;

class StoreFinanceAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_name' => ['required', 'string', 'max:100'],
            'account_type' => ['required', new Enum(AccountType::class)],
            'currency_code' => ['nullable', 'string', 'size:3'],
            'opening_balance' => ['nullable', 'numeric'],
            'description' => ['nullable', 'string'],
            'is_active' => ['nullable', 'boolean'],
        ];
    }
}
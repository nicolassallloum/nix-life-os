<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateHealthHydrationLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'log_date' => ['sometimes', 'date'],
            'log_time' => ['nullable', 'date_format:H:i'],
            'drink_type' => ['sometimes', 'string', 'max:50', 'in:water,tea,coffee,juice,soup,milk,other'],
            'amount_ml' => ['sometimes', 'numeric', 'min:1', 'max:5000'],
            'is_ckd_safe' => ['nullable', 'boolean'],
            'source' => ['nullable', 'string', 'max:50', 'in:manual,quick_add,import,wearable'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
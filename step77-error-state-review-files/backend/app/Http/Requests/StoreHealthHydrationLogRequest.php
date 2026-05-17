<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreHealthHydrationLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $drinkType = $this->input('drink_type', 'water');

        $this->merge([
            'log_date' => $this->input('log_date', $this->input('date')),
            'amount_ml' => $this->input('amount_ml', $this->input('water_ml')),
            'drink_type' => strtolower($drinkType),
            'is_ckd_safe' => $this->input('is_ckd_safe', true),
            'source' => $this->input('source', 'manual'),
        ]);
    }

    public function rules(): array
    {
        return [
            'log_date' => ['required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i:s'],
            'drink_type' => [
                'required',
                'string',
                Rule::in([
                    'water',
                    'coffee',
                    'tea',
                    'juice',
                    'milk',
                    'soup',
                    'other',
                ]),
            ],
            'amount_ml' => ['required', 'numeric', 'min:1', 'max:10000'],
            'is_ckd_safe' => ['required', 'boolean'],
            'source' => ['required', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
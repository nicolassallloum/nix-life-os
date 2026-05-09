<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateHealthHydrationLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('drink_type')) {
            $this->merge([
                'drink_type' => strtolower($this->input('drink_type')),
            ]);
        }

        $this->merge([
            'log_date' => $this->input('log_date', $this->input('date')),
            'amount_ml' => $this->input('amount_ml', $this->input('water_ml')),
            'is_ckd_safe' => $this->input('is_ckd_safe', true),
            'source' => $this->input('source', 'manual'),
        ]);
    }

    public function rules(): array
    {
        return [
            'log_date' => ['sometimes', 'required', 'date'],
            'log_time' => ['nullable', 'date_format:H:i:s'],
            'drink_type' => [
                'sometimes',
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
            'amount_ml' => ['sometimes', 'required', 'numeric', 'min:1', 'max:10000'],
            'is_ckd_safe' => ['sometimes', 'required', 'boolean'],
            'source' => ['sometimes', 'required', 'string', 'max:50'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'account_id' => $this->account_id,
            'account_name' => $this->account_name,
            'account_type' => ucfirst($this->account_type->value ?? $this->account_type),
            'currency_code' => $this->currency_code,
            'opening_balance' => number_format((float) $this->opening_balance, 2, '.', ''),
            'current_balance' => number_format((float) $this->current_balance, 2, '.', ''),
            'description' => $this->description,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
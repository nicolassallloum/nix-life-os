<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $id = $this->id ?? $this->account_id ?? null;

        return [
            'id' => $id,
            'account_id' => $id,

            'user_id' => $this->user_id,

            'account_name' => $this->account_name ?? $this->name ?? 'Account',
            'name' => $this->account_name ?? $this->name ?? 'Account',

            'account_type' => ucfirst((string) ($this->account_type->value ?? $this->account_type ?? $this->type ?? 'account')),
            'type' => $this->account_type->value ?? $this->account_type ?? $this->type ?? 'account',

            'currency_code' => $this->currency_code ?? $this->currency ?? 'USD',
            'currency' => $this->currency_code ?? $this->currency ?? 'USD',

            'opening_balance' => number_format((float) ($this->opening_balance ?? 0), 2, '.', ''),
            'current_balance' => number_format((float) ($this->current_balance ?? $this->balance ?? 0), 2, '.', ''),
            'balance' => number_format((float) ($this->current_balance ?? $this->balance ?? 0), 2, '.', ''),

            'description' => $this->description ?? $this->notes ?? null,
            'notes' => $this->notes ?? $this->description ?? null,

            'is_active' => (bool) ($this->is_active ?? true),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}

<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'transaction_id' => $this->transaction_id,
            'transaction_type' => ucfirst($this->transaction_type->value ?? $this->transaction_type),
            'account' => $this->account?->account_name,
            'transfer_account' => $this->transferAccount?->account_name,
            'category' => $this->category?->category_name,
            'amount' => number_format((float) $this->amount, 2, '.', ''),
            'transaction_date' => $this->transaction_date?->format('Y-m-d'),
            'description' => $this->description,
            'reference_no' => $this->reference_no,
        ];
    }
}
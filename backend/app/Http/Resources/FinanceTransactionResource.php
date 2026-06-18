<?php

namespace App\Http\Resources;

use Carbon\CarbonInterface;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FinanceTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $id = $this->id ?? $this->transaction_id ?? null;

        $accountName =
            $this->account_name
            ?? $this->account?->account_name
            ?? $this->account?->name
            ?? null;

        $transferAccountName =
            $this->transfer_account_name
            ?? $this->transferAccount?->account_name
            ?? $this->transferAccount?->name
            ?? null;

        $categoryName = is_string($this->category ?? null)
            ? $this->category
            : (
                $this->category_name
                ?? data_get($this->resource, 'category.name')
                ?? data_get($this->resource, 'category.category_name')
                ?? 'Uncategorized'
            );

        $type = $this->transaction_type->value ?? $this->transaction_type ?? $this->type ?? null;

        $transactionDate = $this->transaction_date ?? $this->date ?? null;
        $formattedTransactionDate = $transactionDate instanceof CarbonInterface
            ? $transactionDate->format('Y-m-d')
            : ($transactionDate ? (string) $transactionDate : null);

        return [
            'id' => $id,
            'transaction_id' => $id,

            'user_id' => $this->user_id,
            'account_id' => $this->account_id,
            'transfer_account_id' => $this->transfer_account_id,
            'category_id' => $this->category_id,

            'transaction_type' => $type,
            'type' => $type,

            'account' => $accountName,
            'account_name' => $accountName,
            'transfer_account' => $transferAccountName,
            'transfer_account_name' => $transferAccountName,

            'category' => $categoryName,
            'category_name' => $categoryName,

            'amount' => number_format((float) ($this->amount ?? 0), 2, '.', ''),
            'currency_code' => $this->currency_code ?? $this->currency ?? 'USD',
            'currency' => $this->currency_code ?? $this->currency ?? 'USD',

            'transaction_date' => $formattedTransactionDate,
            'date' => $formattedTransactionDate,

            'description' => $this->description ?? $this->notes ?? null,
            'notes' => $this->notes ?? $this->description ?? null,
            'reference_no' => $this->reference_no,

            'status' => $this->status ?? 'completed',

            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}

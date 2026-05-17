<?php

namespace App\Services;

use App\Enums\TransactionType;
use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use Illuminate\Support\Facades\DB;

class FinanceBalanceService
{
    public function rebuildAccountBalance(string $accountId): void
    {
        $account = FinanceAccount::query()->findOrFail($accountId);

        $balance = (float) $account->opening_balance;

        $transactions = FinanceTransaction::query()
            ->where('user_id', $account->user_id)
            ->where(function ($query) use ($accountId) {
                $query->where('account_id', $accountId)
                      ->orWhere('transfer_account_id', $accountId);
            })
            ->get();

        foreach ($transactions as $tx) {
            if ($tx->transaction_type === TransactionType::INCOME && $tx->account_id === $accountId) {
                $balance += (float) $tx->amount;
            }

            if ($tx->transaction_type === TransactionType::EXPENSE && $tx->account_id === $accountId) {
                $balance -= (float) $tx->amount;
            }

            if ($tx->transaction_type === TransactionType::TRANSFER) {
                if ($tx->account_id === $accountId) {
                    $balance -= (float) $tx->amount;
                }

                if ($tx->transfer_account_id === $accountId) {
                    $balance += (float) $tx->amount;
                }
            }
        }

        $account->update([
            'current_balance' => $balance,
        ]);
    }

    public function rebuildMany(array $accountIds): void
    {
        $uniqueIds = array_values(array_unique(array_filter($accountIds)));

        foreach ($uniqueIds as $accountId) {
            $this->rebuildAccountBalance($accountId);
        }
    }
}
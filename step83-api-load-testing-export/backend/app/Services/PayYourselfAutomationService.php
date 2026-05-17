public function handleIncomeTransaction(FinanceTransaction $transaction): ?FinanceTransaction
    {
        if ($transaction->transaction_type !== 'income') {
            return null;
        }

        $payYourselfAmount = round($transaction->amount * 0.10, 2);

        $payYourselfTransaction = FinanceTransaction::create([
            'user_id' => $transaction->user_id,
            'transaction_type' => 'expense',
            'account_id' => $transaction->account_id,
            'category_id' => null,
            'amount' => $payYourselfAmount,
            'transaction_date' => now()->toDateString(),
            'description' => 'Pay Yourself - 10% of Income',
            'reference_no' => null,
            'metadata_json' => [
                'source_transaction_id' => $transaction->transaction_id,
                'automation_triggered_by' => 'PayYourselfAutomationService',
            ],
        ]);

        return $payYourselfTransaction;
    }
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceTransactionRequest;
use App\Http\Requests\UpdateFinanceTransactionRequest;
use App\Models\FinanceAccount;
use App\Models\FinanceCategory;
use App\Models\FinanceTransaction;
use App\Services\FinanceBalanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceTransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $transactions = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $request->user()->user_id)
            ->when($request->filled('transaction_type'), fn ($q) => $q->where('transaction_type', $request->transaction_type))
            ->when($request->filled('account_id'), fn ($q) => $q->where('account_id', $request->account_id))
            ->when($request->filled('date_from'), fn ($q) => $q->whereDate('transaction_date', '>=', $request->date_from))
            ->when($request->filled('date_to'), fn ($q) => $q->whereDate('transaction_date', '<=', $request->date_to))
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json($transactions);
    }

    public function store(
        StoreFinanceTransactionRequest $request,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->user_id;
        $data = $request->validated();

        $account = FinanceAccount::query()
            ->where('user_id', $userId)
            ->findOrFail($data['account_id']);

        if (!empty($data['transfer_account_id'])) {
            FinanceAccount::query()
                ->where('user_id', $userId)
                ->findOrFail($data['transfer_account_id']);
        }

        if (!empty($data['category_id'])) {
            FinanceCategory::query()
                ->where('user_id', $userId)
                ->findOrFail($data['category_id']);
        }

        $transaction = DB::transaction(function () use ($data, $userId) {
            return FinanceTransaction::query()->create([
                'user_id' => $userId,
                'transaction_type' => $data['transaction_type'],
                'account_id' => $data['account_id'],
                'transfer_account_id' => $data['transfer_account_id'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'amount' => $data['amount'],
                'transaction_date' => $data['transaction_date'],
                'description' => $data['description'] ?? null,
                'reference_no' => $data['reference_no'] ?? null,
                'metadata_json' => $data['metadata_json'] ?? [],
            ]);
        });

        $balanceService->rebuildMany([
            $transaction->account_id,
            $transaction->transfer_account_id,
        ]);

        return response()->json($transaction->load(['account', 'transferAccount', 'category']), 201);
    }

    public function show(Request $request, string $transactionId): JsonResponse
    {
        $transaction = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($transactionId);

        return response()->json($transaction);
    }

    public function update(
        UpdateFinanceTransactionRequest $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->user_id;

        $transaction = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->findOrFail($transactionId);

        $oldAccountId = $transaction->account_id;
        $oldTransferAccountId = $transaction->transfer_account_id;

        $data = $request->validated();

        FinanceAccount::query()
            ->where('user_id', $userId)
            ->findOrFail($data['account_id']);

        if (!empty($data['transfer_account_id'])) {
            FinanceAccount::query()
                ->where('user_id', $userId)
                ->findOrFail($data['transfer_account_id']);
        }

        if (!empty($data['category_id'])) {
            FinanceCategory::query()
                ->where('user_id', $userId)
                ->findOrFail($data['category_id']);
        }

        DB::transaction(function () use ($transaction, $data) {
            $transaction->update([
                'transaction_type' => $data['transaction_type'],
                'account_id' => $data['account_id'],
                'transfer_account_id' => $data['transfer_account_id'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'amount' => $data['amount'],
                'transaction_date' => $data['transaction_date'],
                'description' => $data['description'] ?? null,
                'reference_no' => $data['reference_no'] ?? null,
                'metadata_json' => $data['metadata_json'] ?? [],
            ]);
        });

        $balanceService->rebuildMany([
            $oldAccountId,
            $oldTransferAccountId,
            $transaction->account_id,
            $transaction->transfer_account_id,
        ]);

        return response()->json($transaction->fresh()->load(['account', 'transferAccount', 'category']));
    }

    public function destroy(
        Request $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $transaction = FinanceTransaction::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($transactionId);

        $accountIds = [
            $transaction->account_id,
            $transaction->transfer_account_id,
        ];

        DB::transaction(function () use ($transaction) {
            $transaction->delete();
        });

        $balanceService->rebuildMany($accountIds);

        return response()->json(['message' => 'Transaction deleted successfully.']);
    }
}
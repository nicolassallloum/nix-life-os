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
use Illuminate\Support\Str;

class FinanceTransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $transactions = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $userId)
            ->when($request->filled('transaction_type'), function ($query) use ($request) {
                $query->where('transaction_type', $request->transaction_type);
            })
            ->when($request->filled('account_id'), function ($query) use ($request) {
                $query->where('account_id', $request->account_id);
            })
            ->when($request->filled('date_from'), function ($query) use ($request) {
                $query->whereDate('transaction_date', '>=', $request->date_from);
            })
            ->when($request->filled('date_to'), function ($query) use ($request) {
                $query->whereDate('transaction_date', '<=', $request->date_to);
            })
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'message' => 'Finance transactions loaded successfully.',
            'data' => $transactions,
        ]);
    }

    public function store(
        StoreFinanceTransactionRequest $request,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->id;
        $data = $request->validated();

        $account = FinanceAccount::query()
            ->where('id', $data['account_id'])
            ->where('user_id', $userId)
            ->first();

        if (! $account) {
            return response()->json([
                'success' => false,
                'message' => 'Selected account was not found for the authenticated user.',
                'errors' => [
                    'account_id' => ['Selected account was not found for the authenticated user.'],
                ],
            ], 422);
        }

        if (! empty($data['transfer_account_id'])) {
            $transferAccount = FinanceAccount::query()
                ->where('id', $data['transfer_account_id'])
                ->where('user_id', $userId)
                ->first();

            if (! $transferAccount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected transfer account was not found for the authenticated user.',
                    'errors' => [
                        'transfer_account_id' => ['Selected transfer account was not found for the authenticated user.'],
                    ],
                ], 422);
            }
        }

        if (! empty($data['category_id'])) {
            $category = FinanceCategory::query()
                ->where('id', $data['category_id'])
                ->where('user_id', $userId)
                ->first();

            if (! $category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected category was not found for the authenticated user.',
                    'errors' => [
                        'category_id' => ['Selected category was not found for the authenticated user.'],
                    ],
                ], 422);
            }
        }

        $transaction = DB::transaction(function () use ($data, $userId) {
            return FinanceTransaction::query()->create([
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'transaction_type' => $data['transaction_type'],
                'account_id' => $data['account_id'],
                'transfer_account_id' => $data['transfer_account_id'] ?? null,
                'category_id' => $data['category_id'] ?? null,
                'category' => $data['category'] ?? null,
                'amount' => $data['amount'],
                'currency_code' => $data['currency_code'] ?? 'USD',
                'transaction_date' => $data['transaction_date'],
                'description' => $data['description'] ?? null,
                'reference_no' => $data['reference_no'] ?? null,
                'notes' => $data['notes'] ?? null,
                'metadata_json' => $data['metadata_json'] ?? [],
            ]);
        });

        try {
            $balanceService->rebuildMany([
                $transaction->account_id,
                $transaction->transfer_account_id,
            ]);
        } catch (\Throwable $e) {
            // Do not fail transaction creation if balance rebuild has an issue.
        }

        return response()->json([
            'success' => true,
            'message' => 'Transaction created successfully.',
            'data' => $transaction->fresh()->load(['account', 'transferAccount', 'category']),
        ], 201);
    }

    public function show(Request $request, string $transactionId): JsonResponse
    {
        $userId = $request->user()->id;

        $transaction = FinanceTransaction::query()
            ->with(['account', 'transferAccount', 'category'])
            ->where('user_id', $userId)
            ->where('id', $transactionId)
            ->first();

        if (! $transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Transaction loaded successfully.',
            'data' => $transaction,
        ]);
    }

    public function update(
        UpdateFinanceTransactionRequest $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->id;

        $transaction = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->where('id', $transactionId)
            ->first();

        if (! $transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found.',
            ], 404);
        }

        $oldAccountId = $transaction->account_id;
        $oldTransferAccountId = $transaction->transfer_account_id;

        $data = $request->validated();

        if (! empty($data['account_id'])) {
            $account = FinanceAccount::query()
                ->where('id', $data['account_id'])
                ->where('user_id', $userId)
                ->first();

            if (! $account) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected account was not found for the authenticated user.',
                    'errors' => [
                        'account_id' => ['Selected account was not found for the authenticated user.'],
                    ],
                ], 422);
            }
        }

        if (! empty($data['transfer_account_id'])) {
            $transferAccount = FinanceAccount::query()
                ->where('id', $data['transfer_account_id'])
                ->where('user_id', $userId)
                ->first();

            if (! $transferAccount) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected transfer account was not found for the authenticated user.',
                    'errors' => [
                        'transfer_account_id' => ['Selected transfer account was not found for the authenticated user.'],
                    ],
                ], 422);
            }
        }

        if (! empty($data['category_id'])) {
            $category = FinanceCategory::query()
                ->where('id', $data['category_id'])
                ->where('user_id', $userId)
                ->first();

            if (! $category) {
                return response()->json([
                    'success' => false,
                    'message' => 'Selected category was not found for the authenticated user.',
                    'errors' => [
                        'category_id' => ['Selected category was not found for the authenticated user.'],
                    ],
                ], 422);
            }
        }

        DB::transaction(function () use ($transaction, $data) {
            $transaction->update([
                'transaction_type' => $data['transaction_type'] ?? $transaction->transaction_type,
                'account_id' => $data['account_id'] ?? $transaction->account_id,
                'transfer_account_id' => $data['transfer_account_id'] ?? $transaction->transfer_account_id,
                'category_id' => $data['category_id'] ?? $transaction->category_id,
                'category' => $data['category'] ?? $transaction->category,
                'amount' => $data['amount'] ?? $transaction->amount,
                'currency_code' => $data['currency_code'] ?? $transaction->currency_code,
                'transaction_date' => $data['transaction_date'] ?? $transaction->transaction_date,
                'description' => $data['description'] ?? $transaction->description,
                'reference_no' => $data['reference_no'] ?? $transaction->reference_no,
                'notes' => $data['notes'] ?? $transaction->notes,
                'metadata_json' => $data['metadata_json'] ?? $transaction->metadata_json ?? [],
            ]);
        });

        try {
            $balanceService->rebuildMany([
                $oldAccountId,
                $oldTransferAccountId,
                $transaction->account_id,
                $transaction->transfer_account_id,
            ]);
        } catch (\Throwable $e) {
            // Do not fail transaction update if balance rebuild has an issue.
        }

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully.',
            'data' => $transaction->fresh()->load(['account', 'transferAccount', 'category']),
        ]);
    }

    public function destroy(
        Request $request,
        string $transactionId,
        FinanceBalanceService $balanceService
    ): JsonResponse {
        $userId = $request->user()->id;

        $transaction = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->where('id', $transactionId)
            ->first();

        if (! $transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found.',
            ], 404);
        }

        $accountIds = [
            $transaction->account_id,
            $transaction->transfer_account_id,
        ];

        DB::transaction(function () use ($transaction) {
            $transaction->delete();
        });

        try {
            $balanceService->rebuildMany($accountIds);
        } catch (\Throwable $e) {
            // Do not fail delete response if balance rebuild has an issue.
        }

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully.',
        ]);
    }
}
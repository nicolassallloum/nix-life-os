<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;


use Illuminate\Support\Str;

class FinanceTransactionController extends Controller
{
    public function index(Request $request)
    {
        try {
            $query = FinanceTransaction::query()
                ->with('account')
                ->where('user_id', $request->user()->id);

            if ($request->filled('transaction_type')) {
                $query->where('transaction_type', $request->transaction_type);
            }

            if ($request->filled('account_id')) {
                $query->where('account_id', $request->account_id);
            }

            if ($request->filled('category')) {
                $query->where('category', 'ILIKE', '%' . $request->category . '%');
            }

            $transactions = $query
                ->orderByDesc('transaction_date')
                ->orderByDesc('created_at')
                ->paginate($request->get('per_page', 20));

            return response()->json([
                'success' => true,
                'message' => 'Finance transactions loaded successfully.',
                'data' => $transactions,
            ]);
        } catch (\Throwable $e) {
            Log::error('Finance transactions index failed', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to load finance transactions.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

FinanceDashboardView

    public function show(Request $request, string $id)
    {
        try {
            $transaction = FinanceTransaction::with('account')
                ->where('user_id', $request->user()->id)
                ->where('id', $id)
                ->firstOrFail();

            return response()->json([
                'success' => true,
                'message' => 'Transaction loaded successfully.',
                'data' => $transaction,
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found.',
            ], 404);
        }
    }

    public function update(Request $request, string $id)
    {
        $data = $request->validate([
            'transaction_type' => ['sometimes', 'required', 'string', 'in:income,expense'],
            'account_id' => ['sometimes', 'required', 'uuid', 'exists:finance_accounts,id'],
            'category' => ['nullable', 'string', 'max:255'],
            'amount' => ['sometimes', 'required', 'numeric', 'min:0.01'],
            'currency_code' => ['nullable', 'string', 'max:10'],
            'transaction_date' => ['sometimes', 'required', 'date'],
            'description' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
        ]);

        try {
            $transaction = FinanceTransaction::where('user_id', $request->user()->id)
                ->where('id', $id)
                ->firstOrFail();

            $transaction->update($data);

            return response()->json([
                'success' => true,
                'message' => 'Transaction updated successfully.',
                'data' => $transaction->fresh('account'),
            ]);
        } catch (\Throwable $e) {
            Log::error('Finance transaction update failed', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'transaction_id' => $id,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to update transaction.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(Request $request, string $id)
    {
        try {
            $transaction = FinanceTransaction::where('user_id', $request->user()->id)
                ->where('id', $id)
                ->firstOrFail();

            $transaction->delete();

            return response()->json([
                'success' => true,
                'message' => 'Transaction deleted successfully.',
            ]);
        } catch (\Throwable $e) {
            Log::error('Finance transaction delete failed', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'transaction_id' => $id,
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete transaction.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
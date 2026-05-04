<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceAccountRequest;
use App\Http\Requests\UpdateFinanceAccountRequest;
use App\Models\FinanceAccount;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class FinanceAccountController extends Controller
{
    public function index(Request $request)
    {
        $accounts = FinanceAccount::where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Finance accounts loaded successfully.',
            'data' => $accounts->map(function ($account) {
                return $this->formatAccount($account);
            }),
        ]);
    }

    public function store(StoreFinanceAccountRequest $request)
    {
        $data = $request->validated();

        $account = FinanceAccount::create([
            'id' => (string) Str::uuid(),
            'user_id' => $request->user()->id,
            'account_name' => $data['account_name'],
            'account_type' => $data['account_type'],
            'currency_code' => $data['currency_code'] ?? 'USD',
            'opening_balance' => $data['opening_balance'] ?? 0,
            'current_balance' => $data['current_balance'] ?? ($data['opening_balance'] ?? 0),
            'description' => $data['description'] ?? null,
            'notes' => $data['notes'] ?? null,
            'is_active' => $data['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Account created successfully.',
            'data' => $this->formatAccount($account),
        ], 201);
    }

    public function show(Request $request, FinanceAccount $account)
    {
        if ($account->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Account loaded successfully.',
            'data' => $this->formatAccount($account),
        ]);
    }

    public function update(UpdateFinanceAccountRequest $request, FinanceAccount $account)
    {
        if ($account->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        $data = $request->validated();

        $account->update([
            'account_name' => $data['account_name'] ?? $account->account_name,
            'account_type' => $data['account_type'] ?? $account->account_type?->value ?? $account->account_type,
            'currency_code' => $data['currency_code'] ?? $account->currency_code,
            'opening_balance' => $data['opening_balance'] ?? $account->opening_balance,
            'current_balance' => $data['current_balance'] ?? $account->current_balance,
            'description' => $data['description'] ?? $account->description,
            'notes' => $data['notes'] ?? $account->notes,
            'is_active' => $data['is_active'] ?? $account->is_active,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Account updated successfully.',
            'data' => $this->formatAccount($account->fresh()),
        ]);
    }

    public function destroy(Request $request, FinanceAccount $account)
    {
        if ($account->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Account not found.',
            ], 404);
        }

        $account->delete();

        return response()->json([
            'success' => true,
            'message' => 'Account deleted successfully.',
        ]);
    }

    private function formatAccount(FinanceAccount $account): array
    {
        return [
            'id' => $account->id,
            'account_id' => $account->id,
            'user_id' => $account->user_id,
            'account_name' => $account->account_name,
            'account_type' => $account->account_type?->value ?? $account->account_type,
            'currency_code' => $account->currency_code,
            'opening_balance' => $account->opening_balance,
            'current_balance' => $account->current_balance,
            'description' => $account->description,
            'notes' => $account->notes,
            'is_active' => $account->is_active,
            'created_at' => $account->created_at,
            'updated_at' => $account->updated_at,
        ];
    }
}
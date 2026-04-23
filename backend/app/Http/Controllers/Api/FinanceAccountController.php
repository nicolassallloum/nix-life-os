<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceAccountRequest;
use App\Http\Requests\UpdateFinanceAccountRequest;
use App\Http\Resources\FinanceAccountResource;
use App\Models\FinanceAccount;
use App\Services\FinanceBalanceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinanceAccountController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $accounts = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->orderBy('account_name')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Accounts fetched successfully.',
            'data' => FinanceAccountResource::collection($accounts),
        ]);
    }

    public function store(StoreFinanceAccountRequest $request): JsonResponse
    {
        $account = FinanceAccount::query()->create([
            'user_id' => $request->user()->user_id,
            'account_name' => $request->account_name,
            'account_type' => $request->account_type,
            'currency_code' => strtoupper($request->input('currency_code', 'USD')),
            'opening_balance' => $request->input('opening_balance', 0),
            'current_balance' => $request->input('opening_balance', 0),
            'description' => $request->description,
            'is_active' => $request->input('is_active', true),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Account created successfully.',
            'data' => new FinanceAccountResource($account),
        ], 201);
    }

    public function show(Request $request, string $accountId): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        return response()->json([
            'success' => true,
            'message' => 'Account fetched successfully.',
            'data' => new FinanceAccountResource($account),
        ]);
    }

    public function update(UpdateFinanceAccountRequest $request, string $accountId, FinanceBalanceService $balanceService): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        $account->update([
            'account_name' => $request->input('account_name', $account->account_name),
            'account_type' => $request->input('account_type', $account->account_type?->value ?? $account->account_type),
            'currency_code' => strtoupper($request->input('currency_code', $account->currency_code)),
            'opening_balance' => $request->input('opening_balance', $account->opening_balance),
            'description' => $request->input('description', $account->description),
            'is_active' => $request->input('is_active', $account->is_active),
        ]);

        $balanceService->rebuildAccountBalance($account->account_id);

        return response()->json([
            'success' => true,
            'message' => 'Account updated successfully.',
            'data' => new FinanceAccountResource($account->fresh()),
        ]);
    }

    public function destroy(Request $request, string $accountId): JsonResponse
    {
        $account = FinanceAccount::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($accountId);

        $account->delete();

        return response()->json([
            'success' => true,
            'message' => 'Account deleted successfully.',
        ]);
    }
}
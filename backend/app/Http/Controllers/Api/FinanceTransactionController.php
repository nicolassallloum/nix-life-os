<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class FinanceTransactionController extends Controller
{
    private array $types = ['income', 'expense', 'transfer'];


    public function summary(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $base = DB::table('finance_transactions')
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $userId));

        $income = (clone $base)
            ->where('transaction_type', 'income')
            ->sum('amount');

        $expenses = (clone $base)
            ->where('transaction_type', 'expense')
            ->sum('amount');

        $transfers = (clone $base)
            ->where('transaction_type', 'transfer')
            ->sum('amount');

        $transactionCount = (clone $base)->count();

        $accountBalance = DB::table('finance_accounts')
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $userId))
            ->sum('current_balance');

        $savingRate = (float) $income > 0
            ? round((((float) $income - (float) $expenses) / (float) $income) * 100, 2)
            : 0;

        return response()->json([
            'success' => true,
            'message' => 'Finance summary loaded successfully.',
            'data' => [
                'total_income' => number_format((float) $income, 2, '.', ''),
                'total_expenses' => number_format((float) $expenses, 2, '.', ''),
                'total_expense' => number_format((float) $expenses, 2, '.', ''),
                'total_transfers' => number_format((float) $transfers, 2, '.', ''),
                'net_balance' => number_format((float) $income - (float) $expenses, 2, '.', ''),
                'account_balance' => number_format((float) $accountBalance, 2, '.', ''),
                'saving_rate' => $savingRate,
                'transaction_count' => $transactionCount,
            ],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $query = DB::table('finance_transactions')
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at');

        if (! $this->isAdmin($request)) {
            $query->where('user_id', $request->user()->id);
        }

        if ($request->filled('type')) {
            $query->where('transaction_type', strtolower((string) $request->query('type')));
        }

        $limit = (int) ($request->input('limit') ?: $request->input('per_page') ?: 250);
        $limit = max(1, min($limit, 1000));

        $transactions = $query
            ->limit($limit)
            ->get()
            ->map(fn ($transaction) => $this->serializeTransaction($transaction))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Finance transactions loaded successfully.',
            'data' => $transactions,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules())->validate();

        $account = $this->findUserAccount($request, $validated['account_id'] ?? null);

        if (! $account) {
            return $this->validationError('account_id', 'The selected account id is invalid.');
        }

        $type = $validated['transaction_type'];
        $transferAccount = null;

        if ($type === 'transfer') {
            if (empty($validated['transfer_account_id'])) {
                return $this->validationError('transfer_account_id', 'Destination account is required for transfer transactions.');
            }

            if ($validated['transfer_account_id'] === $account->id) {
                return $this->validationError('transfer_account_id', 'Destination account must be different from source account.');
            }

            $transferAccount = $this->findUserAccount($request, $validated['transfer_account_id']);

            if (! $transferAccount) {
                return $this->validationError('transfer_account_id', 'The selected destination account id is invalid.');
            }
        } else {
            $validated['transfer_account_id'] = null;
        }

        if (! empty($validated['category_id']) && empty($validated['category'])) {
            $categoryName = DB::table('finance_categories')
                ->where('id', $validated['category_id'])
                ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
                ->value('name');

            if ($categoryName) {
                $validated['category'] = $categoryName;
            }
        }

        $id = (string) Str::uuid();
        $now = now();

        DB::transaction(function () use ($request, $validated, $account, $id, $now, $type) {
            $payload = $this->filterExistingColumns('finance_transactions', [
                'id' => $id,
                'user_id' => $request->user()->id,
                'account_id' => $account->id,
                'transaction_type' => $type,
                'type' => $type,
                'category' => $validated['category'] ?? null,
                'amount' => $validated['amount'],
                'currency_code' => strtoupper($validated['currency_code'] ?? $account->currency_code ?? 'USD'),
                'currency' => strtoupper($validated['currency_code'] ?? $account->currency_code ?? 'USD'),
                'transaction_date' => $validated['transaction_date'] ?? now()->toDateString(),
                'description' => $validated['description'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? null,
                'transfer_account_id' => $validated['transfer_account_id'] ?? null,
                'category_id' => (! empty($validated['category_id']) && Str::isUuid((string) $validated['category_id']))
                    ? $validated['category_id']
                    : null,
                'reference_no' => $validated['reference_no'] ?? null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('finance_transactions')->insert($payload);

            $this->applyBalanceDelta(
                $account->id,
                $validated['transfer_account_id'] ?? null,
                $type,
                (float) $validated['amount']
            );
        });

        $transaction = $this->findUserTransaction($request, $id);

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction created successfully.',
            'data' => $this->serializeTransaction($transaction),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        if (! $this->isValidRouteUuid($id)) {
            return $this->notFound('Invalid finance transaction id.');
        }

        $transaction = $this->findUserTransaction($request, $id);

        if (! $transaction) {
            return $this->notFound();
        }

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction loaded successfully.',
            'data' => $this->serializeTransaction($transaction),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        if (! $this->isValidRouteUuid($id)) {
            return $this->notFound('Invalid finance transaction id.');
        }

        $transaction = $this->findUserTransaction($request, $id);

        if (! $transaction) {
            return $this->notFound();
        }

        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules(true))->validate();

        if (! empty($validated['category_id']) && empty($validated['category'])) {
            $categoryName = DB::table('finance_categories')
                ->where('id', $validated['category_id'])
                ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
                ->value('name');

            if ($categoryName) {
                $validated['category'] = $categoryName;
            }
        }

        $account = ! empty($validated['account_id'])
            ? $this->findUserAccount($request, $validated['account_id'])
            : $this->findUserAccount($request, $transaction->account_id);

        if (! $account) {
            return $this->validationError('account_id', 'The selected account id is invalid.');
        }

        $newType = $validated['transaction_type'] ?? ($transaction->transaction_type ?? $transaction->type ?? 'expense');
        $newTransferAccountId = $validated['transfer_account_id'] ?? ($transaction->transfer_account_id ?? null);

        if ($newType === 'transfer') {
            if (empty($newTransferAccountId)) {
                return $this->validationError('transfer_account_id', 'Destination account is required for transfer transactions.');
            }

            if ($newTransferAccountId === $account->id) {
                return $this->validationError('transfer_account_id', 'Destination account must be different from source account.');
            }

            if (! $this->findUserAccount($request, $newTransferAccountId)) {
                return $this->validationError('transfer_account_id', 'The selected destination account id is invalid.');
            }
        } else {
            $newTransferAccountId = null;
        }

        DB::transaction(function () use ($request, $transaction, $validated, $account, $id, $newType, $newTransferAccountId) {
            $oldType = $transaction->transaction_type ?? $transaction->type ?? 'expense';
            $oldAmount = (float) $transaction->amount;
            $oldTransferAccountId = $transaction->transfer_account_id ?? null;

            $this->reverseBalanceDelta($transaction->account_id, $oldTransferAccountId, $oldType, $oldAmount);

            $newAmount = $validated['amount'] ?? $transaction->amount;

            $payload = $this->filterExistingColumns('finance_transactions', [
                'account_id' => $account->id,
                'transaction_type' => $newType,
                'type' => $newType,
                'category' => $validated['category'] ?? ($transaction->category ?? null),
                'amount' => $newAmount,
                'currency_code' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : ($transaction->currency_code ?? null),
                'currency' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : ($transaction->currency ?? null),
                'transaction_date' => $validated['transaction_date'] ?? ($transaction->transaction_date ?? null),
                'description' => array_key_exists('description', $validated) ? $validated['description'] : ($transaction->description ?? null),
                'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : ($transaction->notes ?? null),
                'metadata_json' => $validated['metadata_json'] ?? ($transaction->metadata_json ?? null),
                'transfer_account_id' => $newTransferAccountId,
                'category_id' => (! empty($validated['category_id']) && Str::isUuid((string) $validated['category_id']))
                    ? $validated['category_id']
                    : ($transaction->category_id ?? null),
                'reference_no' => $validated['reference_no'] ?? ($transaction->reference_no ?? null),
                'updated_at' => now(),
            ]);

            DB::table('finance_transactions')
                ->where('id', $id)
                ->when(! $this->isAdmin($request), fn ($q) => $q->where('user_id', $request->user()->id))
                ->update($payload);

            $this->applyBalanceDelta($account->id, $newTransferAccountId, $newType, (float) $newAmount);
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction updated successfully.',
            'data' => $this->serializeTransaction($this->findUserTransaction($request, $id)),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        if (! $this->isValidRouteUuid($id)) {
            return $this->notFound('Invalid finance transaction id.');
        }

        $transaction = $this->findUserTransaction($request, $id);

        if (! $transaction) {
            return $this->notFound();
        }

        DB::transaction(function () use ($request, $transaction, $id) {
            $type = $transaction->transaction_type ?? $transaction->type ?? 'expense';

            $this->reverseBalanceDelta(
                $transaction->account_id,
                $transaction->transfer_account_id ?? null,
                $type,
                (float) $transaction->amount
            );

            DB::table('finance_transactions')
                ->where('id', $id)
                ->when(! $this->isAdmin($request), fn ($q) => $q->where('user_id', $request->user()->id))
                ->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction deleted successfully.',
        ]);
    }

    private function isValidRouteUuid(?string $id): bool
    {
        return filled($id) && $id !== 'null' && Str::isUuid($id);
    }

    private function normalizePayload(Request $request): array
    {
        $data = $request->all();
        $rawJson = json_decode($request->getContent() ?: '{}', true);

        if (is_array($rawJson)) {
            $data = array_merge($rawJson, $data);
        }

        $transactionType = $data['transaction_type'] ?? $data['type'] ?? $request->input('transaction_type') ?? $request->input('type') ?? 'expense';
        $currencyCode = $data['currency_code'] ?? $data['currency'] ?? $request->input('currency_code') ?? $request->input('currency') ?? 'USD';

        $data['transaction_type'] = strtolower((string) $transactionType);
        $data['currency_code'] = strtoupper((string) $currencyCode);

        unset($data['type'], $data['currency']);

        return $data;
    }

    private function rules(bool $update = false): array
    {
        return [
            'account_id' => [$update ? 'sometimes' : 'required', 'uuid'],
            'transaction_type' => [$update ? 'sometimes' : 'required', 'string', Rule::in($this->types)],
            'amount' => [$update ? 'sometimes' : 'required', 'numeric', 'min:0.01'],
            'currency_code' => ['sometimes', 'string', 'min:3', 'max:10'],
            'transaction_date' => ['sometimes', 'date'],
            'category' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:1000'],
            'notes' => ['nullable', 'string'],
            'metadata_json' => ['nullable', 'array'],
            'transfer_account_id' => ['nullable', 'uuid'],
            'category_id' => ['nullable'],
            'reference_no' => ['nullable', 'string', 'max:255'],
        ];
    }

    private function findUserAccount(Request $request, ?string $id): ?object
    {
        if (! $id || ! Str::isUuid($id)) {
            return null;
        }

        return DB::table('finance_accounts')
            ->where('id', $id)
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->first();
    }

    private function findUserTransaction(Request $request, ?string $id): ?object
    {
        if (! $id || ! Str::isUuid($id)) {
            return null;
        }

        return DB::table('finance_transactions')
            ->where('id', $id)
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->first();
    }

    private function applyBalanceDelta(string $accountId, ?string $transferAccountId, string $type, float $amount): void
    {
        if ($type === 'income') {
            $this->incrementAccountBalance($accountId, $amount);
            return;
        }

        if ($type === 'expense') {
            $this->incrementAccountBalance($accountId, -$amount);
            return;
        }

        if ($type === 'transfer') {
            $this->incrementAccountBalance($accountId, -$amount);

            if ($transferAccountId && Str::isUuid($transferAccountId)) {
                $this->incrementAccountBalance($transferAccountId, $amount);
            }
        }
    }

    private function reverseBalanceDelta(?string $accountId, ?string $transferAccountId, string $type, float $amount): void
    {
        if (! $accountId || ! Str::isUuid($accountId)) {
            return;
        }

        if ($type === 'income') {
            $this->incrementAccountBalance($accountId, -$amount);
            return;
        }

        if ($type === 'expense') {
            $this->incrementAccountBalance($accountId, $amount);
            return;
        }

        if ($type === 'transfer') {
            $this->incrementAccountBalance($accountId, $amount);

            if ($transferAccountId && Str::isUuid($transferAccountId)) {
                $this->incrementAccountBalance($transferAccountId, -$amount);
            }
        }
    }

    private function incrementAccountBalance(string $accountId, float $delta): void
    {
        DB::table('finance_accounts')
            ->where('id', $accountId)
            ->increment('current_balance', $delta, ['updated_at' => now()]);
    }

    private function serializeTransaction(?object $transaction): array
    {
        if (! $transaction) {
            return [];
        }

        $type = $transaction->transaction_type ?? $transaction->type ?? null;
        $currency = $transaction->currency_code ?? $transaction->currency ?? null;

        return [
            'id' => $transaction->id,
            'transaction_id' => $transaction->id,
            'user_id' => $transaction->user_id,
            'account_id' => $transaction->account_id,
            'transfer_account_id' => $transaction->transfer_account_id ?? null,
            'type' => $type,
            'transaction_type' => $type,
            'category' => $transaction->category ?? null,
            'category_id' => $transaction->category_id ?? null,
            'amount' => $transaction->amount,
            'currency' => $currency,
            'currency_code' => $currency,
            'transaction_date' => $transaction->transaction_date ?? null,
            'description' => $transaction->description ?? null,
            'notes' => $transaction->notes ?? null,
            'reference_no' => $transaction->reference_no ?? null,
            'created_at' => $transaction->created_at ?? null,
            'updated_at' => $transaction->updated_at ?? null,
        ];
    }

    private function filterExistingColumns(string $table, array $payload): array
    {
        return collect($payload)
            ->filter(fn ($value, $column) => Schema::hasColumn($table, $column))
            ->all();
    }

    private function isAdmin(Request $request): bool
    {
        return strtolower((string) optional($request->user())->email) === 'admin@nixlifeos.com';
    }

    private function validationError(string $field, string $message): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'status' => 422,
            ],
            'errors' => [$field => [$message]],
        ], 422);
    }

    private function notFound(string $message = 'The requested resource was not found.'): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'error' => [
                'code' => 'NOT_FOUND',
                'status' => 404,
            ],
        ], 404);
    }
}

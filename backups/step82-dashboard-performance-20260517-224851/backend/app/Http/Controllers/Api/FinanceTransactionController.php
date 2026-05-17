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

    public function index(Request $request): JsonResponse
    {
        $transactions = DB::table('finance_transactions')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at')
            ->limit((int) $request->input('limit', 100))
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

        $id = (string) Str::uuid();
        $now = now();
        $type = $validated['transaction_type'];

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
                'category_id' => $validated['category_id'] ?? null,
                'reference_no' => $validated['reference_no'] ?? null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            DB::table('finance_transactions')->insert($payload);
            $this->applyBalanceDelta($account->id, $type, (float) $validated['amount']);
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
        $transaction = $this->findUserTransaction($request, $id);

        if (! $transaction) {
            return $this->notFound();
        }

        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules(true))->validate();

        $account = ! empty($validated['account_id'])
            ? $this->findUserAccount($request, $validated['account_id'])
            : $this->findUserAccount($request, $transaction->account_id);

        if (! $account) {
            return $this->validationError('account_id', 'The selected account id is invalid.');
        }

        DB::transaction(function () use ($request, $transaction, $validated, $account, $id) {
            $oldType = $transaction->transaction_type ?? $transaction->type ?? 'expense';
            $oldAmount = (float) $transaction->amount;
            $this->reverseBalanceDelta($transaction->account_id, $oldType, $oldAmount);

            $newType = $validated['transaction_type'] ?? $oldType;
            $newAmount = $validated['amount'] ?? $transaction->amount;

            $payload = $this->filterExistingColumns('finance_transactions', [
                'account_id' => $account->id,
                'transaction_type' => $newType,
                'type' => $newType,
                'category' => $validated['category'] ?? null,
                'amount' => $newAmount,
                'currency_code' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : ($transaction->currency_code ?? null),
                'currency' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : ($transaction->currency ?? null),
                'transaction_date' => $validated['transaction_date'] ?? ($transaction->transaction_date ?? null),
                'description' => array_key_exists('description', $validated) ? $validated['description'] : ($transaction->description ?? null),
                'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : ($transaction->notes ?? null),
                'metadata_json' => $validated['metadata_json'] ?? ($transaction->metadata_json ?? null),
                'transfer_account_id' => $validated['transfer_account_id'] ?? ($transaction->transfer_account_id ?? null),
                'category_id' => $validated['category_id'] ?? ($transaction->category_id ?? null),
                'reference_no' => $validated['reference_no'] ?? ($transaction->reference_no ?? null),
                'updated_at' => now(),
            ]);

            DB::table('finance_transactions')
                ->where('user_id', $request->user()->id)
                ->where('id', $id)
                ->update($payload);

            $this->applyBalanceDelta($account->id, $newType, (float) $newAmount);
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction updated successfully.',
            'data' => $this->serializeTransaction($this->findUserTransaction($request, $id)),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $transaction = $this->findUserTransaction($request, $id);

        if (! $transaction) {
            return $this->notFound();
        }

        DB::transaction(function () use ($request, $transaction, $id) {
            $type = $transaction->transaction_type ?? $transaction->type ?? 'expense';
            $this->reverseBalanceDelta($transaction->account_id, $type, (float) $transaction->amount);

            DB::table('finance_transactions')
                ->where('user_id', $request->user()->id)
                ->where('id', $id)
                ->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction deleted successfully.',
        ]);
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
            'category_id' => ['nullable', 'uuid'],
            'reference_no' => ['nullable', 'string', 'max:255'],
        ];
    }

    private function findUserAccount(Request $request, ?string $id): ?object
    {
        if (! $id || ! Str::isUuid($id)) {
            return null;
        }

        return DB::table('finance_accounts')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();
    }

    private function findUserTransaction(Request $request, ?string $id): ?object
    {
        if (! $id || ! Str::isUuid($id)) {
            return null;
        }

        return DB::table('finance_transactions')
            ->where('user_id', $request->user()->id)
            ->where('id', $id)
            ->first();
    }

    private function applyBalanceDelta(string $accountId, string $type, float $amount): void
    {
        $delta = $type === 'income' ? $amount : -$amount;

        DB::table('finance_accounts')
            ->where('id', $accountId)
            ->increment('current_balance', $delta, ['updated_at' => now()]);
    }

    private function reverseBalanceDelta(?string $accountId, string $type, float $amount): void
    {
        if (! $accountId || ! Str::isUuid($accountId)) {
            return;
        }

        $delta = $type === 'income' ? -$amount : $amount;

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
            'type' => $type,
            'transaction_type' => $type,
            'category' => $transaction->category ?? null,
            'amount' => $transaction->amount,
            'currency' => $currency,
            'currency_code' => $currency,
            'transaction_date' => $transaction->transaction_date ?? null,
            'description' => $transaction->description ?? null,
            'notes' => $transaction->notes ?? null,
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

    private function notFound(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'The requested resource was not found.',
            'error' => [
                'code' => 'NOT_FOUND',
                'status' => 404,
            ],
        ], 404);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class FinanceTransactionController extends Controller
{
    private array $types = ['income', 'expense', 'transfer'];

    public function index(Request $request): JsonResponse
    {
        $transactions = FinanceTransaction::query()
            ->where('user_id', $request->user()->id)
            ->with('account')
            ->orderByDesc('transaction_date')
            ->orderByDesc('created_at')
            ->limit((int) $request->input('limit', 100))
            ->get()
            ->map(fn (FinanceTransaction $transaction) => $this->serializeTransaction($transaction));

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
        if (!$account) {
            return $this->validationError('account_id', 'The selected account id is invalid.');
        }

        $transaction = DB::transaction(function () use ($request, $validated, $account) {
            $transaction = FinanceTransaction::create([
                'user_id' => $request->user()->id,
                'account_id' => $account->id,
                'transaction_type' => $validated['transaction_type'],
                'category' => $validated['category'] ?? null,
                'amount' => $validated['amount'],
                'currency_code' => strtoupper($validated['currency_code'] ?? $account->currency_code ?? 'USD'),
                'transaction_date' => $validated['transaction_date'] ?? now()->toDateString(),
                'description' => $validated['description'] ?? null,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? null,
                'transfer_account_id' => $validated['transfer_account_id'] ?? null,
                'category_id' => $validated['category_id'] ?? null,
                'reference_no' => $validated['reference_no'] ?? null,
            ]);

            $this->applyBalanceDelta($account, $validated['transaction_type'], (float) $validated['amount']);

            return $transaction;
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction created successfully.',
            'data' => $this->serializeTransaction($transaction->fresh('account')),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $transaction = $this->findUserTransaction($request, $id);

        if (!$transaction) {
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

        if (!$transaction) {
            return $this->notFound();
        }

        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules(true))->validate();

        $newAccount = $transaction->account;
        if (!empty($validated['account_id'])) {
            $newAccount = $this->findUserAccount($request, $validated['account_id']);
            if (!$newAccount) {
                return $this->validationError('account_id', 'The selected account id is invalid.');
            }
        }

        DB::transaction(function () use ($transaction, $validated, $newAccount) {
            $oldAccount = $transaction->account;
            if ($oldAccount) {
                $this->reverseBalanceDelta($oldAccount, $transaction->transaction_type, (float) $transaction->amount);
            }

            $transaction->update(array_filter([
                'account_id' => $newAccount?->id,
                'transaction_type' => $validated['transaction_type'] ?? $transaction->transaction_type,
                'category' => $validated['category'] ?? null,
                'amount' => $validated['amount'] ?? $transaction->amount,
                'currency_code' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : null,
                'transaction_date' => $validated['transaction_date'] ?? null,
                'description' => array_key_exists('description', $validated) ? $validated['description'] : null,
                'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : null,
                'metadata_json' => $validated['metadata_json'] ?? null,
                'transfer_account_id' => $validated['transfer_account_id'] ?? null,
                'category_id' => $validated['category_id'] ?? null,
                'reference_no' => $validated['reference_no'] ?? null,
            ], fn ($value) => $value !== null));

            if ($newAccount) {
                $this->applyBalanceDelta($newAccount, $transaction->fresh()->transaction_type, (float) $transaction->fresh()->amount);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction updated successfully.',
            'data' => $this->serializeTransaction($transaction->fresh('account')),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $transaction = $this->findUserTransaction($request, $id);

        if (!$transaction) {
            return $this->notFound();
        }

        DB::transaction(function () use ($transaction) {
            if ($transaction->account) {
                $this->reverseBalanceDelta($transaction->account, $transaction->transaction_type, (float) $transaction->amount);
            }

            $transaction->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Finance transaction deleted successfully.',
        ]);
    }

    private function normalizePayload(Request $request): array
    {
        $data = $request->all();
        $data['transaction_type'] = strtolower($data['transaction_type'] ?? $data['type'] ?? 'expense');
        $data['currency_code'] = strtoupper($data['currency_code'] ?? $data['currency'] ?? 'USD');
        return $data;
    }

    private function rules(bool $update = false): array
    {
        return [
            'account_id' => [$update ? 'sometimes' : 'required', 'uuid'],
            'transaction_type' => [$update ? 'sometimes' : 'required', 'string', Rule::in($this->types)],
            'amount' => [$update ? 'sometimes' : 'required', 'numeric', 'min:0.01'],
            'currency_code' => ['sometimes', 'string', 'size:3'],
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

    private function findUserAccount(Request $request, ?string $id): ?FinanceAccount
    {
        if (!$id || !Str::isUuid($id)) {
            return null;
        }

        return FinanceAccount::where('user_id', $request->user()->id)->where('id', $id)->first();
    }

    private function findUserTransaction(Request $request, string $id): ?FinanceTransaction
    {
        if (!Str::isUuid($id)) {
            return null;
        }

        return FinanceTransaction::where('user_id', $request->user()->id)
            ->where('id', $id)
            ->with('account')
            ->first();
    }

    private function applyBalanceDelta(FinanceAccount $account, string $type, float $amount): void
    {
        $delta = $type === 'income' ? $amount : -$amount;
        if ($type === 'transfer') {
            $delta = -$amount;
        }

        $account->increment('current_balance', $delta);
    }

    private function reverseBalanceDelta(FinanceAccount $account, string $type, float $amount): void
    {
        $delta = $type === 'income' ? -$amount : $amount;
        if ($type === 'transfer') {
            $delta = $amount;
        }

        $account->increment('current_balance', $delta);
    }

    private function serializeTransaction(FinanceTransaction $transaction): array
    {
        return [
            'id' => $transaction->id,
            'transaction_id' => $transaction->id,
            'user_id' => $transaction->user_id,
            'account_id' => $transaction->account_id,
            'type' => $transaction->transaction_type,
            'transaction_type' => $transaction->transaction_type,
            'category' => $transaction->category,
            'amount' => $transaction->amount,
            'currency' => $transaction->currency_code,
            'currency_code' => $transaction->currency_code,
            'transaction_date' => optional($transaction->transaction_date)->format('Y-m-d') ?? $transaction->transaction_date,
            'description' => $transaction->description,
            'notes' => $transaction->notes,
            'account' => $transaction->relationLoaded('account') && $transaction->account ? [
                'id' => $transaction->account->id,
                'name' => $transaction->account->account_name,
                'account_name' => $transaction->account->account_name,
                'type' => is_object($transaction->account->account_type) ? $transaction->account->account_type->value : $transaction->account->account_type,
                'currency' => $transaction->account->currency_code,
            ] : null,
            'created_at' => optional($transaction->created_at)->toISOString(),
            'updated_at' => optional($transaction->updated_at)->toISOString(),
        ];
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

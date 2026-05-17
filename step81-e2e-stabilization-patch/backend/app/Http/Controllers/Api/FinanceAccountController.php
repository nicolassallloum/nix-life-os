<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FinanceAccount;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class FinanceAccountController extends Controller
{
    private array $types = ['cash', 'bank', 'credit_card', 'debit_card', 'wallet', 'savings', 'investment', 'loan', 'other'];

    public function index(Request $request): JsonResponse
    {
        $accounts = FinanceAccount::query()
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn (FinanceAccount $account) => $this->serializeAccount($account));

        return response()->json([
            'success' => true,
            'message' => 'Finance accounts loaded successfully.',
            'data' => $accounts,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules())->validate();

        $account = FinanceAccount::create([
            'user_id' => $request->user()->id,
            'account_name' => $validated['account_name'],
            'account_type' => $validated['account_type'],
            'currency_code' => strtoupper($validated['currency_code'] ?? 'USD'),
            'opening_balance' => $validated['opening_balance'] ?? 0,
            'current_balance' => $validated['current_balance'] ?? ($validated['opening_balance'] ?? 0),
            'description' => $validated['description'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Finance account created successfully.',
            'data' => $this->serializeAccount($account->fresh()),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        if (! Str::isUuid($id)) {
            return $this->notFound();
        }

        $account = FinanceAccount::where('user_id', $request->user()->id)->where('id', $id)->first();

        if (!$account) {
            return $this->notFound();
        }

        return response()->json([
            'success' => true,
            'message' => 'Finance account loaded successfully.',
            'data' => $this->serializeAccount($account),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        if (! Str::isUuid($id)) {
            return $this->notFound();
        }

        $account = FinanceAccount::where('user_id', $request->user()->id)->where('id', $id)->first();

        if (!$account) {
            return $this->notFound();
        }

        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules(true))->validate();

        $account->update(array_filter([
            'account_name' => $validated['account_name'] ?? null,
            'account_type' => $validated['account_type'] ?? null,
            'currency_code' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : null,
            'opening_balance' => $validated['opening_balance'] ?? null,
            'current_balance' => $validated['current_balance'] ?? null,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : null,
            'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : null,
            'is_active' => array_key_exists('is_active', $validated) ? $validated['is_active'] : null,
        ], fn ($value) => $value !== null));

        return response()->json([
            'success' => true,
            'message' => 'Finance account updated successfully.',
            'data' => $this->serializeAccount($account->fresh()),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        if (! Str::isUuid($id)) {
            return $this->notFound();
        }

        $account = FinanceAccount::where('user_id', $request->user()->id)->where('id', $id)->first();

        if (!$account) {
            return $this->notFound();
        }

        $account->delete();

        return response()->json([
            'success' => true,
            'message' => 'Finance account deleted successfully.',
        ]);
    }

    private function normalizePayload(Request $request): array
    {
        $data = $request->all();

        $data['account_name'] = $data['account_name'] ?? $data['name'] ?? null;
        $data['account_type'] = strtolower($data['account_type'] ?? $data['type'] ?? 'cash');
        $data['currency_code'] = strtoupper($data['currency_code'] ?? $data['currency'] ?? 'USD');

        return $data;
    }

    private function rules(bool $update = false): array
    {
        $required = $update ? 'sometimes' : 'required';

        return [
            'account_name' => [$required, 'string', 'max:255'],
            'account_type' => [$update ? 'sometimes' : 'required', 'string', Rule::in($this->types)],
            'currency_code' => ['sometimes', 'string', 'size:3'],
            'opening_balance' => ['sometimes', 'numeric'],
            'current_balance' => ['sometimes', 'numeric'],
            'description' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    private function serializeAccount(FinanceAccount $account): array
    {
        return [
            'id' => $account->id,
            'account_id' => $account->id,
            'user_id' => $account->user_id,
            'name' => $account->account_name,
            'account_name' => $account->account_name,
            'type' => is_object($account->account_type) ? $account->account_type->value : $account->account_type,
            'account_type' => is_object($account->account_type) ? $account->account_type->value : $account->account_type,
            'currency' => $account->currency_code,
            'currency_code' => $account->currency_code,
            'opening_balance' => $account->opening_balance,
            'current_balance' => $account->current_balance,
            'description' => $account->description ?? null,
            'notes' => $account->notes,
            'is_active' => (bool) $account->is_active,
            'created_at' => optional($account->created_at)->toISOString(),
            'updated_at' => optional($account->updated_at)->toISOString(),
        ];
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

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class FinanceAccountController extends Controller
{
    private array $types = ['cash', 'bank', 'credit_card', 'debit_card', 'wallet', 'savings', 'investment', 'loan', 'other', 'main'];

    public function index(Request $request): JsonResponse
    {
        $accounts = DB::table('finance_accounts')
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($account) => $this->serializeAccount($account))
            ->values();

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

        $now = now();
        $id = (string) Str::uuid();

        $payload = $this->filterExistingColumns('finance_accounts', [
            'id' => $id,
            'user_id' => $request->user()->id,
            'account_name' => $validated['account_name'],
            'account_type' => $validated['account_type'],
            'currency_code' => strtoupper($validated['currency_code'] ?? 'USD'),
            'opening_balance' => $validated['opening_balance'] ?? 0,
            'current_balance' => $validated['current_balance'] ?? ($validated['opening_balance'] ?? 0),
            'description' => $validated['description'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        DB::table('finance_accounts')->insert($payload);

        $account = $this->findAccountRow($request, $id);

        return response()->json([
            'success' => true,
            'message' => 'Finance account created successfully.',
            'data' => $this->serializeAccount($account),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $account = $this->findAccountRow($request, $id);

        if (! $account) {
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
        $account = $this->findAccountRow($request, $id);

        if (! $account) {
            return $this->notFound();
        }

        $data = $this->normalizePayload($request);
        $validated = validator($data, $this->rules(true))->validate();

        $payload = $this->filterExistingColumns('finance_accounts', [
            'account_name' => $validated['account_name'] ?? null,
            'account_type' => $validated['account_type'] ?? null,
            'currency_code' => isset($validated['currency_code']) ? strtoupper($validated['currency_code']) : null,
            'opening_balance' => $validated['opening_balance'] ?? null,
            'current_balance' => $validated['current_balance'] ?? null,
            'description' => array_key_exists('description', $validated) ? $validated['description'] : null,
            'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : null,
            'is_active' => array_key_exists('is_active', $validated) ? $validated['is_active'] : null,
            'updated_at' => now(),
        ]);

        $payload = array_filter($payload, fn ($value) => $value !== null);

        DB::table('finance_accounts')
            ->where('id', $id)
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Finance account updated successfully.',
            'data' => $this->serializeAccount($this->findAccountRow($request, $id)),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $account = $this->findAccountRow($request, $id);

        if (! $account) {
            return $this->notFound();
        }

        DB::table('finance_accounts')
            ->where('id', $id)
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Finance account deleted successfully.',
        ]);
    }

    private function normalizePayload(Request $request): array
    {
        $data = $request->all();
        $rawJson = json_decode($request->getContent() ?: '{}', true);

        if (is_array($rawJson)) {
            $data = array_merge($rawJson, $data);
        }

        $accountName = $data['account_name'] ?? $data['name'] ?? $request->input('account_name') ?? $request->input('name');
        $accountType = $data['account_type'] ?? $data['type'] ?? $request->input('account_type') ?? $request->input('type') ?? 'cash';
        $currencyCode = $data['currency_code'] ?? $data['currency'] ?? $request->input('currency_code') ?? $request->input('currency') ?? 'USD';

        $data['account_name'] = $accountName;
        $data['account_type'] = strtolower((string) $accountType);
        $data['currency_code'] = strtoupper((string) $currencyCode);

        unset($data['name'], $data['type'], $data['currency']);

        return $data;
    }

    private function rules(bool $update = false): array
    {
        return [
            'account_name' => [$update ? 'sometimes' : 'required', 'string', 'max:255'],
            'account_type' => [$update ? 'sometimes' : 'required', 'string', Rule::in($this->types)],
            'currency_code' => ['sometimes', 'string', 'min:3', 'max:10'],
            'opening_balance' => ['sometimes', 'numeric'],
            'current_balance' => ['sometimes', 'numeric'],
            'description' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['sometimes', 'boolean'],
        ];
    }

    private function findAccountRow(Request $request, ?string $id): ?object
    {
        if (! $id || ! Str::isUuid($id)) {
            return null;
        }

        return DB::table('finance_accounts')
            ->where('id', $id)
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->first();
    }

    private function serializeAccount(?object $account): array
    {
        if (! $account) {
            return [];
        }

        return [
            'id' => $account->id,
            'account_id' => $account->id,
            'user_id' => $account->user_id,
            'name' => $account->account_name ?? null,
            'account_name' => $account->account_name ?? null,
            'type' => $account->account_type ?? null,
            'account_type' => $account->account_type ?? null,
            'currency' => $account->currency_code ?? null,
            'currency_code' => $account->currency_code ?? null,
            'opening_balance' => $account->opening_balance ?? 0,
            'current_balance' => $account->current_balance ?? 0,
            'balance' => $account->current_balance ?? 0,
            'description' => $account->description ?? null,
            'notes' => $account->notes ?? null,
            'is_active' => (bool) ($account->is_active ?? true),
            'created_at' => $account->created_at ?? null,
            'updated_at' => $account->updated_at ?? null,
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

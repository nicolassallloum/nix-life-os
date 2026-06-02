<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class FinanceCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $table = $this->tableName();

        if (! $table) {
            return response()->json([
                'success' => true,
                'message' => 'Finance categories table is not available yet.',
                'data' => [],
            ]);
        }

        $query = DB::table($table)
            ->when(! $this->isAdmin($request), function ($query) use ($request) {
                if (Schema::hasColumn($this->tableName(), 'user_id')) {
                    $query->where(function ($q) use ($request) {
                        $q->whereNull('user_id')->orWhere('user_id', $request->user()->id);
                    });
                }
            });

        if ($request->filled('type') && Schema::hasColumn($table, 'type')) {
            $query->where('type', strtolower((string) $request->query('type')));
        }

        $categories = $query
            ->orderBy(Schema::hasColumn($table, 'name') ? 'name' : 'id')
            ->get()
            ->map(fn ($category) => $this->serializeCategory($category))
            ->values();

        return response()->json([
            'success' => true,
            'message' => 'Finance categories loaded successfully.',
            'data' => $categories,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $table = $this->tableName();

        if (! $table) {
            return response()->json([
                'success' => false,
                'message' => 'Finance categories table is not available yet.',
            ], 500);
        }

        $validated = validator($request->all(), [
            'name' => ['required', 'string', 'max:255'],
            'type' => ['required', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['active', 'inactive', 'ACTIVE', 'INACTIVE'])],
        ])->validate();

        $payload = $this->filterExistingColumns($table, [
            'user_id' => $request->user()->id,
            'name' => $validated['name'],
            'type' => strtolower($validated['type']),
            'icon' => $validated['icon'] ?? null,
            'color' => $validated['color'] ?? null,
            'status' => strtolower($validated['status'] ?? 'active'),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $id = DB::table($table)->insertGetId($payload);

        $category = DB::table($table)->where('id', $id)->first();

        return response()->json([
            'success' => true,
            'message' => 'Finance category created successfully.',
            'data' => $this->serializeCategory($category),
        ], 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $category = $this->findCategory($request, $id);

        if (! $category) {
            return $this->notFound();
        }

        return response()->json([
            'success' => true,
            'message' => 'Finance category loaded successfully.',
            'data' => $this->serializeCategory($category),
        ]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $table = $this->tableName();
        $category = $this->findCategory($request, $id);

        if (! $table || ! $category) {
            return $this->notFound();
        }

        $validated = validator($request->all(), [
            'name' => ['sometimes', 'string', 'max:255'],
            'type' => ['sometimes', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['active', 'inactive', 'ACTIVE', 'INACTIVE'])],
        ])->validate();

        $payload = $this->filterExistingColumns($table, [
            'name' => $validated['name'] ?? null,
            'type' => isset($validated['type']) ? strtolower($validated['type']) : null,
            'icon' => array_key_exists('icon', $validated) ? $validated['icon'] : null,
            'color' => array_key_exists('color', $validated) ? $validated['color'] : null,
            'status' => isset($validated['status']) ? strtolower($validated['status']) : null,
            'updated_at' => now(),
        ]);

        $payload = array_filter($payload, fn ($value) => $value !== null);

        DB::table($table)->where('id', $id)->update($payload);

        return response()->json([
            'success' => true,
            'message' => 'Finance category updated successfully.',
            'data' => $this->serializeCategory($this->findCategory($request, $id)),
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $table = $this->tableName();
        $category = $this->findCategory($request, $id);

        if (! $table || ! $category) {
            return $this->notFound();
        }

        DB::table($table)->where('id', $id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Finance category deleted successfully.',
        ]);
    }

    private function findCategory(Request $request, string $id): ?object
    {
        $table = $this->tableName();

        if (! $table) {
            return null;
        }

        return DB::table($table)
            ->where('id', $id)
            ->when(! $this->isAdmin($request) && Schema::hasColumn($table, 'user_id'), function ($query) use ($request) {
                $query->where(function ($q) use ($request) {
                    $q->whereNull('user_id')->orWhere('user_id', $request->user()->id);
                });
            })
            ->first();
    }

    private function serializeCategory(?object $category): array
    {
        if (! $category) {
            return [];
        }

        return [
            'id' => $category->id ?? null,
            'category_id' => $category->id ?? null,
            'user_id' => $category->user_id ?? null,
            'name' => $category->name ?? null,
            'type' => $category->type ?? null,
            'icon' => $category->icon ?? null,
            'color' => $category->color ?? null,
            'status' => $category->status ?? 'active',
            'created_at' => $category->created_at ?? null,
            'updated_at' => $category->updated_at ?? null,
        ];
    }

    private function tableName(): ?string
    {
        if (Schema::hasTable('finance_categories')) {
            return 'finance_categories';
        }

        if (Schema::hasTable('finance_category')) {
            return 'finance_category';
        }

        if (Schema::hasTable('nix_life_os.finance_category')) {
            return 'nix_life_os.finance_category';
        }

        return null;
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
            'message' => 'Finance category not found.',
        ], 404);
    }
}

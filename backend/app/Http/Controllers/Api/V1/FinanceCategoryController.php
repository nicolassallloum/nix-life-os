<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class FinanceCategoryController extends Controller
{
    private string $schema = 'nix_life_os';
    private string $table = 'finance_category';

    private function tableName(): string
    {
        return $this->schema . '.' . $this->table;
    }

    private function columns(): array
    {
        return DB::table('information_schema.columns')
            ->where('table_schema', $this->schema)
            ->where('table_name', $this->table)
            ->pluck('column_name')
            ->toArray();
    }

    private function firstExistingColumn(array $columns, array $candidates): ?string
    {
        foreach ($candidates as $candidate) {
            if (in_array($candidate, $columns, true)) {
                return $candidate;
            }
        }

        return null;
    }

    public function index(Request $request)
    {
        try {
            $columns = $this->columns();

            $nameColumn = $this->firstExistingColumn($columns, [
                'name',
                'category_name',
                'category',
                'label',
                'title',
            ]);

            $typeColumn = $this->firstExistingColumn($columns, [
                'type',
                'category_type',
                'transaction_type',
            ]);

            $statusColumn = $this->firstExistingColumn($columns, [
                'status',
                'is_active',
            ]);

            $query = DB::table($this->tableName());

            if ($typeColumn && $request->filled('type')) {
                $query->where($typeColumn, $request->type);
            }

            if ($statusColumn && $request->filled('status')) {
                $query->where($statusColumn, $request->status);
            }

            if ($nameColumn) {
                $query->orderBy($nameColumn);
            } else {
                $query->orderBy('id');
            }

            $categories = $query->get();

            return response()->json([
                'success' => true,
                'data' => $categories,
                // 'meta' => [
                //     'real_table' => $this->tableName(),
                //     'name_column_used' => $nameColumn,
                //     'type_column_used' => $typeColumn,
                //     'status_column_used' => $statusColumn,
                // ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Finance categories index failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Finance categories failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function store(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => ['required', 'string', 'max:150'],
                'type' => ['required', Rule::in(['income', 'expense'])],
                'icon' => ['nullable', 'string', 'max:100'],
                'color' => ['nullable', 'string', 'max:20'],
                'status' => ['nullable', Rule::in(['active', 'inactive'])],
            ]);

            $columns = $this->columns();

            $nameColumn = $this->firstExistingColumn($columns, [
                'name',
                'category_name',
                'category',
                'label',
                'title',
            ]);

            $typeColumn = $this->firstExistingColumn($columns, [
                'type',
                'category_type',
                'transaction_type',
            ]);

            $insert = [];

            if (in_array('user_id', $columns, true)) {
                $insert['user_id'] = 1;
            }

            if ($nameColumn) {
                $insert[$nameColumn] = $validated['name'];
            }

            if ($typeColumn) {
                $insert[$typeColumn] = $validated['type'];
            }

            if (in_array('icon', $columns, true)) {
                $insert['icon'] = $validated['icon'] ?? null;
            }

            if (in_array('color', $columns, true)) {
                $insert['color'] = $validated['color'] ?? null;
            }

            if (in_array('status', $columns, true)) {
                $insert['status'] = $validated['status'] ?? 'active';
            }

            if (in_array('created_at', $columns, true)) {
                $insert['created_at'] = now();
            }

            if (in_array('updated_at', $columns, true)) {
                $insert['updated_at'] = now();
            }

            if (!$nameColumn) {
                return response()->json([
                    'success' => false,
                    'message' => 'No category name column found in finance_category table.',
                    'available_columns' => $columns,
                ], 422);
            }

            $id = DB::table($this->tableName())->insertGetId($insert);

            $category = DB::table($this->tableName())->where('id', $id)->first();

            return response()->json([
                'success' => true,
                'message' => 'Finance category created successfully.',
                'data' => $category,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Finance categories store failed', [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Finance category creation failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function show($category)
    {
        $row = DB::table($this->tableName())->where('id', $category)->first();

        abort_if(!$row, 404);

        return response()->json([
            'success' => true,
            'data' => $row,
        ]);
    }

    public function update(Request $request, $category)
    {
        try {
            $columns = $this->columns();

            $nameColumn = $this->firstExistingColumn($columns, [
                'name',
                'category_name',
                'category',
                'label',
                'title',
            ]);

            $typeColumn = $this->firstExistingColumn($columns, [
                'type',
                'category_type',
                'transaction_type',
            ]);

            $update = [];

            if ($nameColumn && $request->filled('name')) {
                $update[$nameColumn] = $request->name;
            }

            if ($typeColumn && $request->filled('type')) {
                $update[$typeColumn] = $request->type;
            }

            if (in_array('icon', $columns, true) && $request->has('icon')) {
                $update['icon'] = $request->icon;
            }

            if (in_array('color', $columns, true) && $request->has('color')) {
                $update['color'] = $request->color;
            }

            if (in_array('status', $columns, true) && $request->has('status')) {
                $update['status'] = $request->status;
            }

            if (in_array('updated_at', $columns, true)) {
                $update['updated_at'] = now();
            }

            DB::table($this->tableName())->where('id', $category)->update($update);

            return response()->json([
                'success' => true,
                'message' => 'Finance category updated successfully.',
                'data' => DB::table($this->tableName())->where('id', $category)->first(),
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Finance category update failed.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy($category)
    {
        DB::table($this->tableName())->where('id', $category)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Finance category deleted successfully.',
        ]);
    }
}
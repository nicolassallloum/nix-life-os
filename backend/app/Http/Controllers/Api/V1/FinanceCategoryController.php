<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\FinanceCategory;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FinanceCategoryController extends Controller
{
    public function index(Request $request)
    {
        $categories = FinanceCategory::where('user_id', $request->user()->id)
            ->when($request->type, fn ($q) => $q->where('type', $request->type))
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->orderBy('name')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $categories,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'type' => ['required', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color' => ['nullable', 'string', 'max:30'],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
        ]);

        $category = FinanceCategory::create([
            ...$validated,
            'user_id' => $request->user()->id,
            'status' => $validated['status'] ?? 'active',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Finance category created successfully.',
            'data' => $category,
        ], 201);
    }

    public function show(Request $request, FinanceCategory $category)
    {
        $this->authorizeUserRecord($request, $category);

        return response()->json([
            'success' => true,
            'data' => $category,
        ]);
    }

    public function update(Request $request, FinanceCategory $category)
    {
        $this->authorizeUserRecord($request, $category);

        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'type' => ['sometimes', 'required', Rule::in(['income', 'expense'])],
            'icon' => ['nullable', 'string', 'max:100'],
            'color' => ['nullable', 'string', 'max:30'],
            'status' => ['nullable', Rule::in(['active', 'inactive'])],
        ]);

        $category->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Finance category updated successfully.',
            'data' => $category,
        ]);
    }

    public function destroy(Request $request, FinanceCategory $category)
    {
        $this->authorizeUserRecord($request, $category);

        $category->delete();

        return response()->json([
            'success' => true,
            'message' => 'Finance category deleted successfully.',
        ]);
    }

    private function authorizeUserRecord(Request $request, FinanceCategory $category): void
    {
        abort_if($category->user_id !== $request->user()->id, 403, 'Unauthorized record.');
    }
}
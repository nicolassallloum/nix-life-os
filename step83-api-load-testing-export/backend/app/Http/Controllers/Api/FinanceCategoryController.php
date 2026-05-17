<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFinanceCategoryRequest;
use App\Http\Requests\UpdateFinanceCategoryRequest;
use App\Models\FinanceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FinanceCategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $categories = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->orderBy('category_type')
            ->orderBy('category_name')
            ->get();

        return response()->json($categories);
    }

    public function store(StoreFinanceCategoryRequest $request): JsonResponse
    {
        $category = FinanceCategory::query()->create([
            'user_id' => $request->user()->user_id,
            'category_name' => $request->category_name,
            'category_type' => $request->category_type,
            'icon' => $request->icon,
            'color_code' => $request->color_code,
            'notes' => $request->notes,
            'is_active' => $request->input('is_active', true),
            'is_system' => false,
        ]);

        return response()->json($category, 201);
    }

    public function show(Request $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        return response()->json($category);
    }

    public function update(UpdateFinanceCategoryRequest $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        $category->update($request->validated());

        return response()->json($category->fresh());
    }

    public function destroy(Request $request, string $categoryId): JsonResponse
    {
        $category = FinanceCategory::query()
            ->where('user_id', $request->user()->user_id)
            ->findOrFail($categoryId);

        $category->delete();

        return response()->json(['message' => 'Category deleted successfully.']);
    }
}
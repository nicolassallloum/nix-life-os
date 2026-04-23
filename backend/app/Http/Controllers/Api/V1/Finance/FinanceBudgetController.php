<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Http\Requests\Finance\StoreFinanceBudgetRequest;
use App\Models\FinanceBudget;
use App\Models\FinanceBudgetLine;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class FinanceBudgetController extends Controller
{
    public function index(): JsonResponse
    {
        $budgets = FinanceBudget::query()
            ->where('user_id', Auth::id())
            ->with('lines')
            ->orderByDesc('budget_month')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Budgets retrieved successfully',
            'data' => $budgets,
        ]);
    }

    public function store(StoreFinanceBudgetRequest $request): JsonResponse
    {
        $userId = Auth::id();
        $validated = $request->validated();

        $budget = DB::transaction(function () use ($validated, $userId) {
            $budget = FinanceBudget::create([
                'user_id' => $userId,
                'budget_name' => $validated['budget_name'],
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            foreach ($validated['lines'] as $line) {
                FinanceBudgetLine::create([
                    'budget_id' => $budget->budget_id,
                    'user_id' => $userId,
                    'category_id' => $line['category_id'] ?? null,
                    'account_id' => $line['account_id'] ?? null,
                    'planned_amount' => $line['planned_amount'],
                    'warning_percentage' => $line['warning_percentage'] ?? 80,
                    'exceeded_percentage' => $line['exceeded_percentage'] ?? 100,
                    'line_notes' => $line['line_notes'] ?? null,
                    'metadata_json' => $line['metadata_json'] ?? [],
                ]);
            }

            return $budget->load('lines');
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget created successfully',
            'data' => $budget,
        ], 201);
    }

    public function show(string $budget): JsonResponse
    {
        $budgetModel = FinanceBudget::query()
            ->where('user_id', Auth::id())
            ->with('lines')
            ->findOrFail($budget);

        return response()->json([
            'success' => true,
            'message' => 'Budget retrieved successfully',
            'data' => $budgetModel,
        ]);
    }

    public function update(StoreFinanceBudgetRequest $request, string $budget): JsonResponse
    {
        $userId = Auth::id();
        $validated = $request->validated();

        $budgetModel = DB::transaction(function () use ($budget, $userId, $validated) {
            $budgetModel = FinanceBudget::query()
                ->where('user_id', $userId)
                ->findOrFail($budget);

            $budgetModel->update([
                'budget_name' => $validated['budget_name'],
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            FinanceBudgetLine::query()
                ->where('budget_id', $budgetModel->budget_id)
                ->delete();

            foreach ($validated['lines'] as $line) {
                FinanceBudgetLine::create([
                    'budget_id' => $budgetModel->budget_id,
                    'user_id' => $userId,
                    'category_id' => $line['category_id'] ?? null,
                    'account_id' => $line['account_id'] ?? null,
                    'planned_amount' => $line['planned_amount'],
                    'warning_percentage' => $line['warning_percentage'] ?? 80,
                    'exceeded_percentage' => $line['exceeded_percentage'] ?? 100,
                    'line_notes' => $line['line_notes'] ?? null,
                    'metadata_json' => $line['metadata_json'] ?? [],
                ]);
            }

            return $budgetModel->load('lines');
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget updated successfully',
            'data' => $budgetModel,
        ]);
    }

    public function destroy(string $budget): JsonResponse
    {
        $budgetModel = FinanceBudget::query()
            ->where('user_id', Auth::id())
            ->findOrFail($budget);

        $budgetModel->delete();

        return response()->json([
            'success' => true,
            'message' => 'Budget deleted successfully',
            'data' => [
                'budget_id' => $budget,
            ],
        ]);
    }
}
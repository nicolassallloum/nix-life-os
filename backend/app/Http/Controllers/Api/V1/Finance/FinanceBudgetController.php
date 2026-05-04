<?php

namespace App\Http\Controllers\Api\V1\Finance;

use App\Http\Controllers\Controller;
use App\Http\Requests\Finance\StoreFinanceBudgetRequest;
use App\Models\FinanceBudget;
use App\Models\FinanceBudgetLine;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FinanceBudgetController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $budgets = FinanceBudget::query()
            ->where('user_id', $userId)
            ->with('lines')
            ->orderByDesc('budget_month')
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Budgets retrieved successfully.',
            'data' => $budgets,
        ]);
    }

    public function store(StoreFinanceBudgetRequest $request): JsonResponse
    {
        $userId = $request->user()->id;
        $validated = $request->validated();

        $budget = DB::transaction(function () use ($validated, $userId) {
            $budget = FinanceBudget::query()->create([
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'budget_name' => $validated['budget_name'],
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            foreach ($validated['lines'] as $line) {
                FinanceBudgetLine::query()->create([
                    'id' => (string) Str::uuid(),
                    'budget_id' => $budget->id,
                    'user_id' => $userId,
                    'category_id' => $line['category_id'] ?? null,
                    'account_id' => $line['account_id'] ?? null,
                    'planned_amount' => $line['planned_amount'],
                    'actual_amount' => $line['actual_amount'] ?? 0,
                    'spent_amount' => $line['spent_amount'] ?? 0,
                    'warning_percentage' => $line['warning_percentage'] ?? 80,
                    'exceeded_percentage' => $line['exceeded_percentage'] ?? 100,
                    'line_notes' => $line['line_notes'] ?? null,
                    'notes' => $line['notes'] ?? null,
                    'metadata_json' => $line['metadata_json'] ?? [],
                ]);
            }

            return $budget->fresh()->load('lines');
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget created successfully.',
            'data' => $budget,
        ], 201);
    }

    public function show(Request $request, string $budget): JsonResponse
    {
        $userId = $request->user()->id;

        $budgetModel = FinanceBudget::query()
            ->where('user_id', $userId)
            ->with('lines')
            ->where('id', $budget)
            ->first();

        if (! $budgetModel) {
            return response()->json([
                'success' => false,
                'message' => 'Budget not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Budget retrieved successfully.',
            'data' => $budgetModel,
        ]);
    }

    public function update(StoreFinanceBudgetRequest $request, string $budget): JsonResponse
    {
        $userId = $request->user()->id;
        $validated = $request->validated();

        $budgetModel = DB::transaction(function () use ($budget, $userId, $validated) {
            $budgetModel = FinanceBudget::query()
                ->where('user_id', $userId)
                ->where('id', $budget)
                ->first();

            if (! $budgetModel) {
                abort(404, 'Budget not found.');
            }

            $budgetModel->update([
                'budget_name' => $validated['budget_name'],
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            FinanceBudgetLine::query()
                ->where('budget_id', $budgetModel->id)
                ->delete();

            foreach ($validated['lines'] as $line) {
                FinanceBudgetLine::query()->create([
                    'id' => (string) Str::uuid(),
                    'budget_id' => $budgetModel->id,
                    'user_id' => $userId,
                    'category_id' => $line['category_id'] ?? null,
                    'account_id' => $line['account_id'] ?? null,
                    'planned_amount' => $line['planned_amount'],
                    'actual_amount' => $line['actual_amount'] ?? 0,
                    'spent_amount' => $line['spent_amount'] ?? 0,
                    'warning_percentage' => $line['warning_percentage'] ?? 80,
                    'exceeded_percentage' => $line['exceeded_percentage'] ?? 100,
                    'line_notes' => $line['line_notes'] ?? null,
                    'notes' => $line['notes'] ?? null,
                    'metadata_json' => $line['metadata_json'] ?? [],
                ]);
            }

            return $budgetModel->fresh()->load('lines');
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget updated successfully.',
            'data' => $budgetModel,
        ]);
    }

    public function destroy(Request $request, string $budget): JsonResponse
    {
        $userId = $request->user()->id;

        $budgetModel = FinanceBudget::query()
            ->where('user_id', $userId)
            ->where('id', $budget)
            ->first();

        if (! $budgetModel) {
            return response()->json([
                'success' => false,
                'message' => 'Budget not found.',
            ], 404);
        }

        DB::transaction(function () use ($budgetModel) {
            FinanceBudgetLine::query()
                ->where('budget_id', $budgetModel->id)
                ->delete();

            $budgetModel->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget deleted successfully.',
            'data' => [
                'id' => $budget,
                'budget_id' => $budget,
            ],
        ]);
    }
}
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
        $month = $request->query('month');

        $query = FinanceBudget::query()
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $userId))
            ->with('lines')
            ->orderByDesc('budget_month')
            ->orderByDesc('created_at');

        if (! empty($month)) {
            $query->where(function ($q) use ($month) {
                $q->where('budget_month', $month)
                  ->orWhere('budget_month', $month . '-01')
                  ->orWhere('budget_month', 'like', $month . '%');
            });
        }

        $budgets = $query->get()->map(function ($budget) {
            $planned = (float) $budget->budget_amount;
            $spent = (float) $budget->spent_amount;

            if ($budget->lines && $budget->lines->count() > 0) {
                $planned = (float) $budget->lines->sum('planned_amount');
                $spent = (float) $budget->lines->sum('spent_amount');
            }

            $remaining = $planned - $spent;

            $budget->budget_amount = number_format($planned, 2, '.', '');
            $budget->spent_amount = number_format($spent, 2, '.', '');
            $budget->remaining_amount = number_format($remaining, 2, '.', '');
            $budget->usage_percentage = $planned > 0 ? round(($spent / $planned) * 100, 2) : 0;
            $budget->is_over_budget = $spent > $planned;

            return $budget;
        });

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
            $lines = $validated['lines'];

            $budgetAmount = collect($lines)->sum(fn ($line) => (float) ($line['planned_amount'] ?? 0));
            $spentAmount = collect($lines)->sum(fn ($line) => (float) ($line['spent_amount'] ?? 0));
            $mainCategory = $validated['category'] ?? ($lines[0]['category'] ?? 'General');

            $budget = FinanceBudget::query()->create([
                'id' => (string) Str::uuid(),
                'user_id' => $userId,
                'budget_name' => $validated['budget_name'],
                'category' => $mainCategory,
                'budget_amount' => $budgetAmount,
                'spent_amount' => $spentAmount,
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            foreach ($lines as $line) {
                FinanceBudgetLine::query()->create([
                    'id' => (string) Str::uuid(),
                    'budget_id' => $budget->id,
                    'user_id' => $userId,
                    'account_id' => $line['account_id'] ?? null,
                    'category_id' => $line['category_id'] ?? null,
                    'category' => $line['category'] ?? $mainCategory,
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

    public function show(Request $request, string $id): JsonResponse
    {
        $budget = FinanceBudget::query()
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->where('id', $id)
            ->with('lines')
            ->first();

        if (! $budget) {
            return response()->json([
                'success' => false,
                'message' => 'Budget not found.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Budget retrieved successfully.',
            'data' => $budget,
        ]);
    }

    public function update(StoreFinanceBudgetRequest $request, string $id): JsonResponse
    {
        $userId = $request->user()->id;
        $validated = $request->validated();

        $budget = DB::transaction(function () use ($id, $userId, $validated) {
            $budget = FinanceBudget::query()
                ->when(! $this->isAdmin(request()), fn ($query) => $query->where('user_id', $userId))
                ->where('id', $id)
                ->first();

            if (! $budget) {
                abort(404, 'Budget not found.');
            }

            $lines = $validated['lines'];

            $budgetAmount = collect($lines)->sum(fn ($line) => (float) ($line['planned_amount'] ?? 0));
            $spentAmount = collect($lines)->sum(fn ($line) => (float) ($line['spent_amount'] ?? 0));
            $mainCategory = $validated['category'] ?? ($lines[0]['category'] ?? $budget->category ?? 'General');

            $budget->update([
                'budget_name' => $validated['budget_name'],
                'category' => $mainCategory,
                'budget_amount' => $budgetAmount,
                'spent_amount' => $spentAmount,
                'budget_month' => $validated['budget_month'],
                'currency_code' => $validated['currency_code'],
                'is_active' => $validated['is_active'] ?? true,
                'notes' => $validated['notes'] ?? null,
                'metadata_json' => $validated['metadata_json'] ?? [],
            ]);

            FinanceBudgetLine::query()
                ->where('budget_id', $budget->id)
                ->delete();

            foreach ($lines as $line) {
                FinanceBudgetLine::query()->create([
                    'id' => (string) Str::uuid(),
                    'budget_id' => $budget->id,
                    'user_id' => $userId,
                    'account_id' => $line['account_id'] ?? null,
                    'category_id' => $line['category_id'] ?? null,
                    'category' => $line['category'] ?? $mainCategory,
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
            'message' => 'Budget updated successfully.',
            'data' => $budget,
        ]);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $budget = FinanceBudget::query()
            ->when(! $this->isAdmin($request), fn ($query) => $query->where('user_id', $request->user()->id))
            ->where('id', $id)
            ->first();

        if (! $budget) {
            return response()->json([
                'success' => false,
                'message' => 'Budget not found.',
            ], 404);
        }

        DB::transaction(function () use ($budget) {
            FinanceBudgetLine::query()
                ->where('budget_id', $budget->id)
                ->delete();

            $budget->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Budget deleted successfully.',
            'data' => [
                'id' => $id,
                'budget_id' => $id,
            ],
        ]);
    }

    private function isAdmin(Request $request): bool
    {
        return strtolower((string) optional($request->user())->email) === 'admin@nixlifeos.com';
    }
}

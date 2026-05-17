<?php

namespace App\Services\Finance;

use App\Models\FinanceBudget;
use App\Models\FinanceTransaction;
use Carbon\Carbon;

class BudgetCalculationService
{
    public function getBudgetSummary(FinanceBudget $budget): array
    {
        $monthStart = Carbon::parse($budget->budget_month)->startOfMonth();
        $monthEnd   = Carbon::parse($budget->budget_month)->endOfMonth();

        $lines = $budget->lines()->get()->map(function ($line) use ($monthStart, $monthEnd) {
            $query = FinanceTransaction::query()
                ->where('user_id', $line->user_id)
                ->whereBetween('transaction_date', [$monthStart, $monthEnd])
                ->where('transaction_type', 'expense');

            if ($line->category_id) {
                $query->where('category_id', $line->category_id);
            }

            if ($line->account_id) {
                $query->where('account_id', $line->account_id);
            }

            $actualSpent = (float) $query->sum('amount');
            $planned = (float) $line->planned_amount;
            $remaining = $planned - $actualSpent;
            $usagePct = $planned > 0 ? round(($actualSpent / $planned) * 100, 2) : 0;

            $status = 'safe';
            if ($usagePct >= (float) $line->exceeded_percentage) {
                $status = 'exceeded';
            } elseif ($usagePct >= (float) $line->warning_percentage) {
                $status = 'warning';
            }

            return [
                'budget_line_id' => $line->budget_line_id,
                'category_id' => $line->category_id,
                'account_id' => $line->account_id,
                'planned_amount' => $planned,
                'actual_spent' => round($actualSpent, 2),
                'remaining_budget' => round($remaining, 2),
                'budget_usage_percentage' => $usagePct,
                'status' => $status,
            ];
        });

        return [
            'budget_id' => $budget->budget_id,
            'budget_name' => $budget->budget_name,
            'budget_month' => $budget->budget_month->format('Y-m-d'),
            'totals' => [
                'planned_amount' => round($lines->sum('planned_amount'), 2),
                'actual_spent' => round($lines->sum('actual_spent'), 2),
                'remaining_budget' => round($lines->sum('remaining_budget'), 2),
            ],
            'lines' => $lines->values(),
        ];
    }
}
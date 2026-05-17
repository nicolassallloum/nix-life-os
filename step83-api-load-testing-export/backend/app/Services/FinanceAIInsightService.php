<?php

namespace App\Services;

use App\Models\FinanceBudget;
use App\Models\FinanceBudgetLine;
use App\Models\FinanceTransaction;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class FinanceAIInsightService
{
    public function generate(string $userId, ?string $type = null): array
    {
        $now = Carbon::now();
        $currentMonthStart = $now->copy()->startOfMonth();
        $currentMonthEnd = $now->copy()->endOfMonth();

        $previousMonthStart = $now->copy()->subMonth()->startOfMonth();
        $previousMonthEnd = $now->copy()->subMonth()->endOfMonth();

        $currentMonthTransactions = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->whereBetween('transaction_date', [$currentMonthStart, $currentMonthEnd])
            ->get();

        $previousMonthTransactions = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->whereBetween('transaction_date', [$previousMonthStart, $previousMonthEnd])
            ->get();

        $allTransactions = FinanceTransaction::query()
            ->where('user_id', $userId)
            ->orderByDesc('transaction_date')
            ->get();

        $budgets = FinanceBudget::query()
            ->where('user_id', $userId)
            ->where('is_active', true)
            ->with('lines')
            ->orderByDesc('budget_month')
            ->get();

        $hasFinanceData = $allTransactions->count() > 0 || $budgets->count() > 0;

        $summary = $this->buildSummary($currentMonthTransactions, $budgets);

        $data = [
            'summary' => $summary,
            'expense_insights' => $this->expenseInsights($currentMonthTransactions),
            'savings_insights' => $this->savingsInsights($summary),
            'budget_warnings' => $this->budgetWarnings($budgets),
            'income_trends' => $this->incomeTrends($currentMonthTransactions, $previousMonthTransactions),
            'spending_anomalies' => $this->spendingAnomalies($allTransactions),
            'recommendations' => [],
            'empty_state' => null,
            'meta' => [
                'generated_at' => now()->toISOString(),
                'period' => 'current_month',
                'filters' => [
                    'type' => $type,
                ],
            ],
        ];

        $data['recommendations'] = $this->recommendations($data);

        if (! $hasFinanceData) {
            $data['empty_state'] = [
                'title' => 'No finance data yet',
                'message' => 'Add accounts, transactions, and budgets to receive AI-powered finance insights.',
            ];
        }

        return $this->filterByType($data, $type);
    }

    private function buildSummary(Collection $transactions, Collection $budgets): array
    {
        $totalIncome = (float) $transactions
            ->where('transaction_type', 'income')
            ->sum('amount');

        $totalExpenses = (float) $transactions
            ->where('transaction_type', 'expense')
            ->sum('amount');

        $netSavings = $totalIncome - $totalExpenses;

        $savingsRate = $totalIncome > 0
            ? round(($netSavings / $totalIncome) * 100, 2)
            : 0;

        $totalBudget = 0;
        $totalSpent = 0;

        foreach ($budgets as $budget) {
            if ($budget->lines && $budget->lines->count() > 0) {
                $totalBudget += (float) $budget->lines->sum('planned_amount');
                $totalSpent += (float) $budget->lines->sum('spent_amount');
            } else {
                $totalBudget += (float) $budget->budget_amount;
                $totalSpent += (float) $budget->spent_amount;
            }
        }

        $budgetUsagePercentage = $totalBudget > 0
            ? round(($totalSpent / $totalBudget) * 100, 2)
            : 0;

        return [
            'total_income' => round($totalIncome, 2),
            'total_expenses' => round($totalExpenses, 2),
            'net_savings' => round($netSavings, 2),
            'savings_rate' => $savingsRate,
            'total_budget' => round($totalBudget, 2),
            'total_budget_spent' => round($totalSpent, 2),
            'budget_usage_percentage' => $budgetUsagePercentage,
        ];
    }

    private function expenseInsights(Collection $transactions): array
    {
        $expenses = $transactions->where('transaction_type', 'expense');

        if ($expenses->isEmpty()) {
            return [];
        }

        $totalExpenses = (float) $expenses->sum('amount');

        if ($totalExpenses <= 0) {
            return [];
        }

        return $expenses
            ->groupBy(fn ($transaction) => $transaction->category ?: 'Uncategorized')
            ->map(function ($items, $category) use ($totalExpenses) {
                $amount = (float) $items->sum('amount');
                $percentage = round(($amount / $totalExpenses) * 100, 2);

                if ($percentage < 40) {
                    return null;
                }

                return [
                    'type' => 'high_spending_category',
                    'severity' => $percentage >= 60 ? 'high' : 'medium',
                    'title' => 'High spending detected',
                    'description' => "Your spending in {$category} represents {$percentage}% of your monthly expenses.",
                    'category' => $category,
                    'amount' => round($amount, 2),
                    'percentage' => $percentage,
                ];
            })
            ->filter()
            ->values()
            ->all();
    }

    private function savingsInsights(array $summary): array
    {
        $insights = [];

        if ($summary['total_income'] <= 0 && $summary['total_expenses'] > 0) {
            $insights[] = [
                'type' => 'no_income_detected',
                'severity' => 'warning',
                'title' => 'No income detected this month',
                'description' => 'You have expenses recorded but no income for the current month.',
            ];

            return $insights;
        }

        if ($summary['total_income'] <= 0) {
            return [];
        }

        if ($summary['savings_rate'] < 0) {
            $insights[] = [
                'type' => 'negative_savings',
                'severity' => 'danger',
                'title' => 'Negative monthly savings',
                'description' => 'Your expenses are higher than your income this month.',
            ];
        } elseif ($summary['savings_rate'] < 20) {
            $insights[] = [
                'type' => 'low_savings_rate',
                'severity' => 'warning',
                'title' => 'Low savings rate',
                'description' => 'Your savings rate is below 20%. Review flexible expenses to improve savings.',
            ];
        } else {
            $insights[] = [
                'type' => 'healthy_savings_rate',
                'severity' => 'success',
                'title' => 'Healthy savings rate',
                'description' => 'Your savings rate is currently in a healthy range.',
            ];
        }

        return $insights;
    }

    private function budgetWarnings(Collection $budgets): array
    {
        $warnings = [];

        foreach ($budgets as $budget) {
            if ($budget->lines && $budget->lines->count() > 0) {
                foreach ($budget->lines as $line) {
                    $planned = (float) $line->planned_amount;
                    $spent = (float) $line->spent_amount;

                    if ($planned <= 0) {
                        continue;
                    }

                    $usage = round(($spent / $planned) * 100, 2);

                    if ($usage >= (float) $line->exceeded_percentage) {
                        $warnings[] = [
                            'type' => 'budget_exceeded',
                            'severity' => 'danger',
                            'title' => 'Budget exceeded',
                            'description' => "The {$line->category} budget line exceeded its planned amount.",
                            'budget_name' => $budget->budget_name,
                            'category' => $line->category,
                            'planned_amount' => round($planned, 2),
                            'spent_amount' => round($spent, 2),
                            'usage_percentage' => $usage,
                        ];
                    } elseif ($usage >= (float) $line->warning_percentage) {
                        $warnings[] = [
                            'type' => 'budget_near_limit',
                            'severity' => 'warning',
                            'title' => 'Budget near limit',
                            'description' => "The {$line->category} budget line has reached {$usage}% usage.",
                            'budget_name' => $budget->budget_name,
                            'category' => $line->category,
                            'planned_amount' => round($planned, 2),
                            'spent_amount' => round($spent, 2),
                            'usage_percentage' => $usage,
                        ];
                    }
                }

                continue;
            }

            $planned = (float) $budget->budget_amount;
            $spent = (float) $budget->spent_amount;

            if ($planned <= 0) {
                continue;
            }

            $usage = round(($spent / $planned) * 100, 2);

            if ($usage >= 100) {
                $warnings[] = [
                    'type' => 'budget_exceeded',
                    'severity' => 'danger',
                    'title' => 'Budget exceeded',
                    'description' => "The {$budget->budget_name} budget exceeded its planned amount.",
                    'budget_name' => $budget->budget_name,
                    'category' => $budget->category,
                    'planned_amount' => round($planned, 2),
                    'spent_amount' => round($spent, 2),
                    'usage_percentage' => $usage,
                ];
            } elseif ($usage >= 80) {
                $warnings[] = [
                    'type' => 'budget_near_limit',
                    'severity' => 'warning',
                    'title' => 'Budget near limit',
                    'description' => "The {$budget->budget_name} budget has reached {$usage}% usage.",
                    'budget_name' => $budget->budget_name,
                    'category' => $budget->category,
                    'planned_amount' => round($planned, 2),
                    'spent_amount' => round($spent, 2),
                    'usage_percentage' => $usage,
                ];
            }
        }

        return $warnings;
    }

    private function incomeTrends(Collection $currentMonthTransactions, Collection $previousMonthTransactions): array
    {
        $currentIncome = (float) $currentMonthTransactions
            ->where('transaction_type', 'income')
            ->sum('amount');

        $previousIncome = (float) $previousMonthTransactions
            ->where('transaction_type', 'income')
            ->sum('amount');

        if ($currentIncome <= 0 && $previousIncome <= 0) {
            return [];
        }

        if ($previousIncome <= 0 && $currentIncome > 0) {
            return [
                [
                    'type' => 'income_started',
                    'severity' => 'success',
                    'title' => 'Income detected this month',
                    'description' => 'Income was recorded this month while no income was found last month.',
                    'current_income' => round($currentIncome, 2),
                    'previous_income' => round($previousIncome, 2),
                    'change_percentage' => 100,
                ],
            ];
        }

        $change = $previousIncome > 0
            ? round((($currentIncome - $previousIncome) / $previousIncome) * 100, 2)
            : 0;

        if ($change > 10) {
            $type = 'income_increasing';
            $severity = 'success';
            $title = 'Income is increasing';
            $description = "Your income increased by {$change}% compared to last month.";
        } elseif ($change < -10) {
            $type = 'income_decreasing';
            $severity = 'warning';
            $title = 'Income is decreasing';
            $description = 'Your income decreased compared to last month.';
        } else {
            $type = 'income_stable';
            $severity = 'success';
            $title = 'Stable income trend';
            $description = 'Your income appears stable compared to last month.';
        }

        return [
            [
                'type' => $type,
                'severity' => $severity,
                'title' => $title,
                'description' => $description,
                'current_income' => round($currentIncome, 2),
                'previous_income' => round($previousIncome, 2),
                'change_percentage' => $change,
            ],
        ];
    }

    private function spendingAnomalies(Collection $transactions): array
    {
        $expenses = $transactions->where('transaction_type', 'expense');

        if ($expenses->count() < 3) {
            return [];
        }

        $averageExpense = (float) $expenses->avg('amount');

        if ($averageExpense <= 0) {
            return [];
        }

        return $expenses
            ->filter(fn ($transaction) => (float) $transaction->amount > ($averageExpense * 2))
            ->take(5)
            ->map(function ($transaction) use ($averageExpense) {
                return [
                    'type' => 'unusual_transaction',
                    'severity' => 'high',
                    'title' => 'Unusual spending detected',
                    'description' => 'This transaction is significantly higher than your normal spending pattern.',
                    'transaction_id' => $transaction->id,
                    'category' => $transaction->category ?: 'Uncategorized',
                    'amount' => round((float) $transaction->amount, 2),
                    'average_expense' => round($averageExpense, 2),
                    'transaction_date' => optional($transaction->transaction_date)->format('Y-m-d'),
                ];
            })
            ->values()
            ->all();
    }

    private function recommendations(array $data): array
    {
        $recommendations = [];

        if (($data['summary']['savings_rate'] ?? 0) < 20 && ($data['summary']['total_income'] ?? 0) > 0) {
            $recommendations[] = [
                'type' => 'improve_savings_rate',
                'priority' => 'high',
                'title' => 'Improve your savings rate',
                'description' => 'Try reducing non-essential spending until your savings rate reaches at least 20%.',
            ];
        }

        if (! empty($data['budget_warnings'])) {
            $recommendations[] = [
                'type' => 'review_budgets',
                'priority' => 'high',
                'title' => 'Review budget limits',
                'description' => 'Some budgets are near or above their limits. Review the affected categories.',
            ];
        }

        if (! empty($data['spending_anomalies'])) {
            $recommendations[] = [
                'type' => 'review_anomalies',
                'priority' => 'medium',
                'title' => 'Review unusual transactions',
                'description' => 'Check unusual expenses to confirm they are valid and expected.',
            ];
        }

        if (! empty($data['expense_insights'])) {
            $recommendations[] = [
                'type' => 'reduce_high_category_spending',
                'priority' => 'medium',
                'title' => 'Reduce high category spending',
                'description' => 'One or more categories represent a large share of your monthly spending.',
            ];
        }

        if (empty($recommendations) && ($data['summary']['total_income'] ?? 0) > 0) {
            $recommendations[] = [
                'type' => 'maintain_financial_habits',
                'priority' => 'low',
                'title' => 'Maintain your current financial habits',
                'description' => 'Your current financial indicators look stable. Continue tracking your income, expenses, and budgets.',
            ];
        }

        return $recommendations;
    }

    private function filterByType(array $data, ?string $type): array
    {
        if (! $type || $type === 'all') {
            return $data;
        }

        $map = [
            'expenses' => 'expense_insights',
            'savings' => 'savings_insights',
            'budgets' => 'budget_warnings',
            'income' => 'income_trends',
            'anomalies' => 'spending_anomalies',
            'recommendations' => 'recommendations',
        ];

        if (! isset($map[$type])) {
            return $data;
        }

        $selectedKey = $map[$type];

        foreach ([
            'expense_insights',
            'savings_insights',
            'budget_warnings',
            'income_trends',
            'spending_anomalies',
            'recommendations',
        ] as $key) {
            if ($key !== $selectedKey) {
                $data[$key] = [];
            }
        }

        return $data;
    }
}

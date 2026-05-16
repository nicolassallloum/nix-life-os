<script setup>
import FinanceDashboardCards from "@/components/finance/FinanceDashboardCards.vue";
import FinanceIncomeExpenseChart from "@/components/finance/FinanceIncomeExpenseChart.vue";
import FinanceTransactionsTable from "@/components/finance/FinanceTransactionsTable.vue";
import FinanceBudgetProgress from "@/components/finance/FinanceBudgetProgress.vue";
import FinanceAddTransactionForm from "@/components/finance/FinanceAddTransactionForm.vue";
import FinanceAIInsightsWidget from "@/components/finance/FinanceAIInsightsWidget.vue";

const handleTransactionSaved = async () => {
  if (typeof loadFinanceSummary === "function") {
    await loadFinanceSummary();
  }

  if (typeof loadTransactions === "function") {
    await loadTransactions();
  }

  if (typeof loadAccounts === "function") {
    await loadAccounts();
  }
};
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance Dashboard
        </h1>
        <p class="text-slate-500 mt-1">
          Track income, expenses, budgets, savings, and financial intelligence.
        </p>
      </div>

      <RouterLink
        to="/finance/ai-insights"
        class="inline-flex items-center justify-center rounded-xl bg-slate-900 px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-slate-800"
      >
        View AI Insights
      </RouterLink>
    </div>

    <FinanceDashboardCards />

    <div class="mt-6">
      <FinanceAIInsightsWidget />
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
      <div class="xl:col-span-2">
        <FinanceIncomeExpenseChart />
      </div>

      <div>
        <FinanceBudgetProgress />
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mt-6">
      <div class="xl:col-span-2">
        <FinanceTransactionsTable />
      </div>

      <div>
        <FinanceAddTransactionForm @saved="handleTransactionSaved" />
      </div>
    </div>
  </div>
</template>
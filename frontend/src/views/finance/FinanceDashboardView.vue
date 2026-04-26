<script setup>
import FinanceDashboardCards from "@/components/finance/FinanceDashboardCards.vue";
import FinanceIncomeExpenseChart from "@/components/finance/FinanceIncomeExpenseChart.vue";
import FinanceTransactionsTable from "@/components/finance/FinanceTransactionsTable.vue";
import FinanceBudgetProgress from "@/components/finance/FinanceBudgetProgress.vue";
import FinanceAddTransactionForm from "@/components/finance/FinanceAddTransactionForm.vue";
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-slate-900">
        Finance Dashboard
      </h1>
      <p class="text-slate-500 mt-1">
        Track income, expenses, budgets, savings, and financial intelligence.
      </p>
    </div>

    <FinanceDashboardCards />

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
        <FinanceAddTransactionForm />
      </div>
    </div>
  </div>
</template>
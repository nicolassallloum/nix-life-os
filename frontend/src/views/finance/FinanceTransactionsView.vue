<script setup>
import FinanceTransactionsTable from "@/components/finance/FinanceTransactionsTable.vue";
import FinanceAddTransactionForm from "@/components/finance/FinanceAddTransactionForm.vue";
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance Transactions
        </h1>
        <p class="text-slate-500 mt-1">
          Search, manage, and create income, expense, and transfer transactions.
        </p>
      </div>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Search
          </label>
          <input
            type="text"
            placeholder="Search transactions..."
            class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Type
          </label>
          <select class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500">
            <option value="">All Types</option>
            <option value="income">Income</option>
            <option value="expense">Expense</option>
            <option value="transfer">Transfer</option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            From Date
          </label>
          <input
            type="date"
            class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            To Date
          </label>
          <input
            type="date"
            class="w-full rounded-xl border-slate-300 focus:border-indigo-500 focus:ring-indigo-500"
          />
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <div class="xl:col-span-2">
        <FinanceTransactionsTable />
      </div>

      <div>
        <FinanceAddTransactionForm />
      </div>
    </div>
  </div>
</template>
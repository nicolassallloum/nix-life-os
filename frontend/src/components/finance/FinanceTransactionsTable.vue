<script setup>
const transactions = [
  {
    id: 1,
    date: "2026-04-20",
    category: "Salary",
    account: "Main Account",
    type: "Income",
    amount: 2800,
    status: "Completed",
  },
  {
    id: 2,
    date: "2026-04-21",
    category: "Groceries",
    account: "Main Account",
    type: "Expense",
    amount: 85,
    status: "Completed",
  },
  {
    id: 3,
    date: "2026-04-22",
    category: "Savings Transfer",
    account: "Savings Account",
    type: "Transfer",
    amount: 1400,
    status: "Completed",
  },
];

const formatCurrency = (amount) => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          Recent Transactions
        </h2>
        <p class="text-sm text-slate-500 mt-1">
          Latest income, expenses, and transfers.
        </p>
      </div>

      <button class="text-sm font-semibold text-indigo-600 hover:text-indigo-800">
        View All
      </button>
    </div>

    <div class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-200 text-left text-slate-500">
            <th class="py-3 pr-4">Date</th>
            <th class="py-3 pr-4">Category</th>
            <th class="py-3 pr-4">Account</th>
            <th class="py-3 pr-4">Type</th>
            <th class="py-3 pr-4 text-right">Amount</th>
            <th class="py-3 pr-4">Status</th>
          </tr>
        </thead>

        <tbody>
          <tr
            v-for="transaction in transactions"
            :key="transaction.id"
            class="border-b border-slate-100 hover:bg-slate-50"
          >
            <td class="py-4 pr-4 text-slate-700">
              {{ transaction.date }}
            </td>

            <td class="py-4 pr-4 font-medium text-slate-900">
              {{ transaction.category }}
            </td>

            <td class="py-4 pr-4 text-slate-600">
              {{ transaction.account }}
            </td>

            <td class="py-4 pr-4">
              <span
                class="px-2 py-1 rounded-full text-xs font-semibold"
                :class="{
                  'bg-emerald-50 text-emerald-700': transaction.type === 'Income',
                  'bg-red-50 text-red-700': transaction.type === 'Expense',
                  'bg-blue-50 text-blue-700': transaction.type === 'Transfer'
                }"
              >
                {{ transaction.type }}
              </span>
            </td>

            <td class="py-4 pr-4 text-right font-semibold">
              {{ formatCurrency(transaction.amount) }}
            </td>

            <td class="py-4 pr-4">
              <span class="bg-slate-100 text-slate-700 px-2 py-1 rounded-full text-xs font-medium">
                {{ transaction.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
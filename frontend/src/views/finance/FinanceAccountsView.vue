<script setup>
const accounts = [
  {
    id: 1,
    name: "Main Account",
    type: "Checking",
    currency: "USD",
    balance: 4250,
    is_default: true,
    is_savings: false,
  },
  {
    id: 2,
    name: "Savings Account",
    type: "Savings",
    currency: "USD",
    balance: 1400,
    is_default: false,
    is_savings: true,
  },
    {
    id: 3,
    name: "NIX MARKET Account",
    type: "FREELANCE",
    currency: "USD",
    balance: 0,
    is_default: false,
    is_savings: true,
  },
];

const formatCurrency = (amount, currency = "USD") => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency,
  }).format(amount);
};
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance Accounts
        </h1>
        <p class="text-slate-500 mt-1">
          Manage your cash, bank, wallet, and savings accounts.
        </p>
      </div>

      <button class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-5 py-3 rounded-xl">
        Add Account
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      <div
        v-for="account in accounts"
        :key="account.id"
        class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6"
      >
        <div class="flex items-start justify-between gap-4">
          <div>
            <h2 class="text-xl font-bold text-slate-900">
              {{ account.name }}
            </h2>
            <p class="text-sm text-slate-500 mt-1">
              {{ account.type }} Account
            </p>
          </div>

          <span
            v-if="account.is_default"
            class="text-xs font-semibold bg-indigo-50 text-indigo-700 px-3 py-1 rounded-full"
          >
            Default
          </span>

          <span
            v-else-if="account.is_savings"
            class="text-xs font-semibold bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full"
          >
            Savings
          </span>
        </div>

        <div class="mt-6">
          <p class="text-sm text-slate-500">
            Current Balance
          </p>
          <p class="text-3xl font-bold text-slate-900 mt-1">
            {{ formatCurrency(account.balance, account.currency) }}
          </p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 border border-slate-300 text-slate-700 font-semibold py-2 rounded-xl hover:bg-slate-50">
            Edit
          </button>

          <button class="flex-1 bg-slate-900 text-white font-semibold py-2 rounded-xl hover:bg-slate-800">
            View
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
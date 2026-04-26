<script setup>
const cards = [
  {
    title: "Total Balance",
    value: "$4,250.00",
    change: "+8.2%",
    description: "Across all accounts",
  },
  {
    title: "Monthly Income",
    value: "$2,800.00",
    change: "+12.4%",
    description: "Current month income",
  },
  {
    title: "Monthly Expenses",
    value: "$1,650.00",
    change: "-4.1%",
    description: "Current month spending",
  },
  {
    title: "Savings Rate",
    value: "41%",
    change: "+6.5%",
    description: "Pay Yourself System",
  },
];
</script>

<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
    <div
      v-for="card in cards"
      :key="card.title"
      class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5"
    >
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-slate-500">
          {{ card.title }}
        </h3>

        <span class="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-1 rounded-full">
          {{ card.change }}
        </span>
      </div>

      <p class="text-3xl font-bold text-slate-900 mt-4">
        {{ card.value }}
      </p>

      <p class="text-sm text-slate-500 mt-2">
        {{ card.description }}
      </p>
    </div>
  </div>
</template>
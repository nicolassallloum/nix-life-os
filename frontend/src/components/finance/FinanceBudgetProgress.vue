<script setup>
const budgets = [
  {
    name: "Groceries",
    planned: 300,
    actual: 210,
    status: "safe",
  },
  {
    name: "Transport",
    planned: 150,
    actual: 130,
    status: "warning",
  },
  {
    name: "Restaurants",
    planned: 100,
    actual: 125,
    status: "exceeded",
  },
];

const getPercentage = (actual, planned) => {
  if (!planned) return 0;
  return Math.round((actual / planned) * 100);
};
</script>

<template>
  <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
    <div class="mb-6">
      <h2 class="text-xl font-bold text-slate-900">
        Budget Progress
      </h2>
      <p class="text-sm text-slate-500 mt-1">
        Planned vs actual spending.
      </p>
    </div>

    <div class="space-y-5">
      <div
        v-for="budget in budgets"
        :key="budget.name"
      >
        <div class="flex items-center justify-between mb-2">
          <span class="text-sm font-medium text-slate-700">
            {{ budget.name }}
          </span>

          <span class="text-sm font-semibold text-slate-900">
            {{ getPercentage(budget.actual, budget.planned) }}%
          </span>
        </div>

        <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
          <div
            class="h-3 rounded-full"
            :class="{
              'bg-emerald-500': budget.status === 'safe',
              'bg-amber-500': budget.status === 'warning',
              'bg-red-500': budget.status === 'exceeded'
            }"
            :style="{ width: Math.min(getPercentage(budget.actual, budget.planned), 100) + '%' }"
          ></div>
        </div>

        <div class="flex justify-between mt-1 text-xs text-slate-500">
          <span>Actual: ${{ budget.actual }}</span>
          <span>Planned: ${{ budget.planned }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
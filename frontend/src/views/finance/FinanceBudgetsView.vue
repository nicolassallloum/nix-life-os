<script setup>
const budgets = [
  {
    id: 1,
    name: "Groceries",
    month: "April 2026",
    planned: 300,
    actual: 210,
    status: "safe",
  },
  {
    id: 2,
    name: "Transport",
    month: "April 2026",
    planned: 150,
    actual: 130,
    status: "warning",
  },
  {
    id: 3,
    name: "Restaurants",
    month: "April 2026",
    planned: 100,
    actual: 125,
    status: "exceeded",
  },
];

const formatCurrency = (amount) => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
  }).format(amount);
};

const getUsagePercentage = (actual, planned) => {
  if (!planned) return 0;
  return Math.round((actual / planned) * 100);
};

const getStatusLabel = (status) => {
  if (status === "safe") return "Safe";
  if (status === "warning") return "Warning";
  if (status === "exceeded") return "Exceeded";
  return "Unknown";
};
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance Budgets
        </h1>
        <p class="text-slate-500 mt-1">
          Track monthly budget planning, actual expenses, and spending status.
        </p>
      </div>

      <button class="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-5 py-3 rounded-xl">
        Add Budget
      </button>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="border-b border-slate-200 text-left text-slate-500">
              <th class="py-3 pr-4">Budget Name</th>
              <th class="py-3 pr-4">Month</th>
              <th class="py-3 pr-4 text-right">Planned</th>
              <th class="py-3 pr-4 text-right">Actual</th>
              <th class="py-3 pr-4">Usage</th>
              <th class="py-3 pr-4">Status</th>
              <th class="py-3 pr-4 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr
              v-for="budget in budgets"
              :key="budget.id"
              class="border-b border-slate-100 hover:bg-slate-50"
            >
              <td class="py-4 pr-4 font-semibold text-slate-900">
                {{ budget.name }}
              </td>

              <td class="py-4 pr-4 text-slate-600">
                {{ budget.month }}
              </td>

              <td class="py-4 pr-4 text-right text-slate-700">
                {{ formatCurrency(budget.planned) }}
              </td>

              <td class="py-4 pr-4 text-right font-semibold text-slate-900">
                {{ formatCurrency(budget.actual) }}
              </td>

              <td class="py-4 pr-4 min-w-[180px]">
                <div class="flex items-center gap-3">
                  <div class="w-full bg-slate-100 rounded-full h-3 overflow-hidden">
                    <div
                      class="h-3 rounded-full"
                      :class="{
                        'bg-emerald-500': budget.status === 'safe',
                        'bg-amber-500': budget.status === 'warning',
                        'bg-red-500': budget.status === 'exceeded'
                      }"
                      :style="{ width: Math.min(getUsagePercentage(budget.actual, budget.planned), 100) + '%' }"
                    ></div>
                  </div>

                  <span class="text-xs font-semibold text-slate-600">
                    {{ getUsagePercentage(budget.actual, budget.planned) }}%
                  </span>
                </div>
              </td>

              <td class="py-4 pr-4">
                <span
                  class="px-3 py-1 rounded-full text-xs font-semibold"
                  :class="{
                    'bg-emerald-50 text-emerald-700': budget.status === 'safe',
                    'bg-amber-50 text-amber-700': budget.status === 'warning',
                    'bg-red-50 text-red-700': budget.status === 'exceeded'
                  }"
                >
                  {{ getStatusLabel(budget.status) }}
                </span>
              </td>

              <td class="py-4 pr-4 text-right">
                <button class="text-indigo-600 hover:text-indigo-800 font-semibold">
                  Edit
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
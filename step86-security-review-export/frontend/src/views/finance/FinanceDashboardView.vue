<script setup>
import { defineAsyncComponent } from 'vue'

const FinanceDashboardCards = defineAsyncComponent(() => import('@/components/finance/FinanceDashboardCards.vue'))
const FinanceAIInsightsWidget = defineAsyncComponent(() => import('@/components/finance/FinanceAIInsightsWidget.vue'))

const loadingPanelClass = 'rounded-2xl border border-slate-200 bg-white p-6 text-sm text-slate-500 shadow-sm'
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance Dashboard
        </h1>
        <p class="mt-1 text-slate-500">
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

    <Suspense>
      <FinanceDashboardCards />
      <template #fallback>
        <div :class="loadingPanelClass">Loading finance dashboard...</div>
      </template>
    </Suspense>

    <div class="mt-6">
      <Suspense>
        <FinanceAIInsightsWidget />
        <template #fallback>
          <div :class="loadingPanelClass">Loading AI insights...</div>
        </template>
      </Suspense>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import financeService from '@/services/financeService'

const loading = ref(false)
const errorMessage = ref('')
const recommendations = ref<any[]>([])
const budgetWarnings = ref<any[]>([])
const spendingAnomalies = ref<any[]>([])
const savingsInsights = ref<any[]>([])

const totalAlerts = computed(() => {
  return budgetWarnings.value.length + spendingAnomalies.value.length
})

const topRecommendation = computed(() => {
  return recommendations.value[0] || null
})

const loadWidget = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await financeService.getAIInsights()
    const data = response.data || {}

    recommendations.value = data.recommendations || []
    budgetWarnings.value = data.budget_warnings || []
    spendingAnomalies.value = data.spending_anomalies || []
    savingsInsights.value = data.savings_insights || []
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message || 'Failed to load Finance AI widget.'
  } finally {
    loading.value = false
  }
}

onMounted(loadWidget)
</script>

<template>
  <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
    <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          AI Finance Insights
        </h2>
        <p class="mt-1 text-sm text-slate-500">
          Smart warnings and recommendations based on your finance activity.
        </p>
      </div>

      <RouterLink
        to="/finance/ai-insights"
        class="inline-flex items-center justify-center rounded-xl bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
      >
        Open Full Insights
      </RouterLink>
    </div>

    <div
      v-if="loading"
      class="mt-5 rounded-xl bg-slate-50 p-4 text-sm text-slate-500"
    >
      Loading AI insights...
    </div>

    <div
      v-else-if="errorMessage"
      class="mt-5 rounded-xl bg-red-50 p-4 text-sm text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div v-else class="mt-5 grid grid-cols-1 gap-4 md:grid-cols-3">
      <div class="rounded-xl bg-amber-50 p-4">
        <p class="text-sm font-medium text-amber-700">
          Active Alerts
        </p>
        <h3 class="mt-2 text-2xl font-bold text-amber-900">
          {{ totalAlerts }}
        </h3>
      </div>

      <div class="rounded-xl bg-blue-50 p-4">
        <p class="text-sm font-medium text-blue-700">
          Recommendations
        </p>
        <h3 class="mt-2 text-2xl font-bold text-blue-900">
          {{ recommendations.length }}
        </h3>
      </div>

      <div class="rounded-xl bg-emerald-50 p-4">
        <p class="text-sm font-medium text-emerald-700">
          Savings Insights
        </p>
        <h3 class="mt-2 text-2xl font-bold text-emerald-900">
          {{ savingsInsights.length }}
        </h3>
      </div>
    </div>

    <div
      v-if="!loading && !errorMessage && topRecommendation"
      class="mt-5 rounded-xl border border-slate-100 bg-slate-50 p-4"
    >
      <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">
        Top Recommendation
      </p>
      <h3 class="mt-2 font-semibold text-slate-900">
        {{ topRecommendation.title }}
      </h3>
      <p class="mt-1 text-sm text-slate-600">
        {{ topRecommendation.description }}
      </p>
    </div>

    <div
      v-if="!loading && !errorMessage && !topRecommendation"
      class="mt-5 rounded-xl border border-slate-100 bg-slate-50 p-4 text-sm text-slate-500"
    >
      No Finance AI recommendations yet. Add more transactions and budgets to improve insights.
    </div>
  </section>
</template>

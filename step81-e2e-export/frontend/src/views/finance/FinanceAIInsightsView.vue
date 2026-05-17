<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import financeService from '@/services/financeService'

type Insight = {
  type: string
  severity?: string
  priority?: string
  title: string
  description: string
  category?: string
  amount?: number
  percentage?: number
  budget_name?: string
  planned_amount?: number
  spent_amount?: number
  usage_percentage?: number
  transaction_date?: string
}

const loading = ref(false)
const errorMessage = ref('')
const selectedType = ref('all')

const summary = ref({
  total_income: 0,
  total_expenses: 0,
  net_savings: 0,
  savings_rate: 0,
  total_budget: 0,
  total_budget_spent: 0,
  budget_usage_percentage: 0,
})

const expenseInsights = ref<Insight[]>([])
const savingsInsights = ref<Insight[]>([])
const budgetWarnings = ref<Insight[]>([])
const incomeTrends = ref<Insight[]>([])
const spendingAnomalies = ref<Insight[]>([])
const recommendations = ref<Insight[]>([])
const emptyState = ref<{ title: string; message: string } | null>(null)

const insightTypes = [
  { value: 'all', label: 'All Insights' },
  { value: 'expenses', label: 'Expenses' },
  { value: 'savings', label: 'Savings' },
  { value: 'budgets', label: 'Budgets' },
  { value: 'income', label: 'Income' },
  { value: 'anomalies', label: 'Anomalies' },
  { value: 'recommendations', label: 'Recommendations' },
]

const hasInsights = computed(() => {
  return (
    expenseInsights.value.length > 0 ||
    savingsInsights.value.length > 0 ||
    budgetWarnings.value.length > 0 ||
    incomeTrends.value.length > 0 ||
    spendingAnomalies.value.length > 0 ||
    recommendations.value.length > 0
  )
})

const formatMoney = (value: number | string | null | undefined) => {
  const amount = Number(value || 0)

  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(amount)
}

const severityClass = (severity?: string) => {
  switch (severity) {
    case 'danger':
    case 'high':
      return 'border-red-200 bg-red-50 text-red-800'
    case 'warning':
    case 'medium':
      return 'border-amber-200 bg-amber-50 text-amber-800'
    case 'success':
      return 'border-emerald-200 bg-emerald-50 text-emerald-800'
    default:
      return 'border-blue-200 bg-blue-50 text-blue-800'
  }
}

const badgeClass = (severity?: string) => {
  switch (severity) {
    case 'danger':
    case 'high':
      return 'bg-red-100 text-red-700'
    case 'warning':
    case 'medium':
      return 'bg-amber-100 text-amber-700'
    case 'success':
      return 'bg-emerald-100 text-emerald-700'
    default:
      return 'bg-blue-100 text-blue-700'
  }
}

const loadInsights = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await financeService.getAIInsights({
      type: selectedType.value,
    })

    const data = response.data || {}

    summary.value = {
      total_income: Number(data.summary?.total_income || 0),
      total_expenses: Number(data.summary?.total_expenses || 0),
      net_savings: Number(data.summary?.net_savings || 0),
      savings_rate: Number(data.summary?.savings_rate || 0),
      total_budget: Number(data.summary?.total_budget || 0),
      total_budget_spent: Number(data.summary?.total_budget_spent || 0),
      budget_usage_percentage: Number(data.summary?.budget_usage_percentage || 0),
    }

    expenseInsights.value = data.expense_insights || []
    savingsInsights.value = data.savings_insights || []
    budgetWarnings.value = data.budget_warnings || []
    incomeTrends.value = data.income_trends || []
    spendingAnomalies.value = data.spending_anomalies || []
    recommendations.value = data.recommendations || []
    emptyState.value = data.empty_state || null
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message || 'Failed to load Finance AI Insights.'
  } finally {
    loading.value = false
  }
}

onMounted(loadInsights)
</script>

<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">
          Finance AI Insights
        </h1>
        <p class="mt-1 text-slate-500">
          AI-powered analysis for expenses, savings, budgets, income trends, anomalies, and recommendations.
        </p>
      </div>

      <div class="flex flex-col gap-3 sm:flex-row">
        <select
          v-model="selectedType"
          class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm shadow-sm outline-none focus:border-blue-500"
          @change="loadInsights"
        >
          <option
            v-for="type in insightTypes"
            :key="type.value"
            :value="type.value"
          >
            {{ type.label }}
          </option>
        </select>

        <button
          type="button"
          class="rounded-xl bg-slate-900 px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-slate-800 disabled:opacity-60"
          :disabled="loading"
          @click="loadInsights"
        >
          {{ loading ? 'Refreshing...' : 'Refresh Insights' }}
        </button>
      </div>
    </div>

    <div
      v-if="errorMessage"
      class="mb-6 rounded-2xl border border-red-200 bg-red-50 p-4 text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Monthly Income</p>
        <h2 class="mt-2 text-2xl font-bold text-emerald-600">
          {{ formatMoney(summary.total_income) }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Monthly Expenses</p>
        <h2 class="mt-2 text-2xl font-bold text-red-600">
          {{ formatMoney(summary.total_expenses) }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Net Savings</p>
        <h2 class="mt-2 text-2xl font-bold text-blue-600">
          {{ formatMoney(summary.net_savings) }}
        </h2>
      </div>

      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-slate-500">Savings Rate</p>
        <h2 class="mt-2 text-2xl font-bold text-purple-600">
          {{ summary.savings_rate }}%
        </h2>
      </div>
    </div>

    <div
      v-if="loading"
      class="mt-6 rounded-2xl border border-slate-100 bg-white p-8 text-center text-slate-500 shadow-sm"
    >
      Loading Finance AI Insights...
    </div>

    <div
      v-else-if="emptyState"
      class="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-8 text-center"
    >
      <h2 class="text-xl font-bold text-blue-900">
        {{ emptyState.title }}
      </h2>
      <p class="mt-2 text-blue-700">
        {{ emptyState.message }}
      </p>
    </div>

    <div
      v-else-if="!hasInsights"
      class="mt-6 rounded-2xl border border-slate-100 bg-white p-8 text-center text-slate-500 shadow-sm"
    >
      No insights found for the selected filter.
    </div>

    <div v-else class="mt-6 grid grid-cols-1 gap-6 xl:grid-cols-2">
      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Expense Insights</h2>

        <div v-if="expenseInsights.length === 0" class="text-sm text-slate-400">
          No expense insights found.
        </div>

        <div
          v-for="item in expenseInsights"
          :key="`${item.type}-${item.category}`"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.severity)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.severity)">
              {{ item.severity || 'info' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
          <p v-if="item.amount" class="mt-2 text-sm font-semibold">
            Amount: {{ formatMoney(item.amount) }}
          </p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Savings Insights</h2>

        <div v-if="savingsInsights.length === 0" class="text-sm text-slate-400">
          No savings insights found.
        </div>

        <div
          v-for="item in savingsInsights"
          :key="item.type"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.severity)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.severity)">
              {{ item.severity || 'info' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Budget Warnings</h2>

        <div v-if="budgetWarnings.length === 0" class="text-sm text-slate-400">
          No budget warnings found.
        </div>

        <div
          v-for="item in budgetWarnings"
          :key="`${item.type}-${item.budget_name}-${item.category}`"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.severity)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.severity)">
              {{ item.severity || 'info' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
          <p class="mt-2 text-sm">
            Usage: <strong>{{ item.usage_percentage }}%</strong>
          </p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Income Trends</h2>

        <div v-if="incomeTrends.length === 0" class="text-sm text-slate-400">
          No income trends found.
        </div>

        <div
          v-for="item in incomeTrends"
          :key="item.type"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.severity)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.severity)">
              {{ item.severity || 'info' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Spending Anomalies</h2>

        <div v-if="spendingAnomalies.length === 0" class="text-sm text-slate-400">
          No spending anomalies found.
        </div>

        <div
          v-for="item in spendingAnomalies"
          :key="`${item.type}-${item.amount}-${item.transaction_date}`"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.severity)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.severity)">
              {{ item.severity || 'info' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
          <p class="mt-2 text-sm font-semibold">
            {{ item.category }} — {{ formatMoney(item.amount) }}
          </p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm">
        <h2 class="mb-4 text-xl font-bold text-slate-900">Recommendations</h2>

        <div v-if="recommendations.length === 0" class="text-sm text-slate-400">
          No recommendations found.
        </div>

        <div
          v-for="item in recommendations"
          :key="item.type"
          class="mb-3 rounded-xl border p-4"
          :class="severityClass(item.priority)"
        >
          <div class="flex items-start justify-between gap-3">
            <h3 class="font-semibold">{{ item.title }}</h3>
            <span class="rounded-full px-3 py-1 text-xs font-semibold" :class="badgeClass(item.priority)">
              {{ item.priority || 'low' }}
            </span>
          </div>
          <p class="mt-2 text-sm">{{ item.description }}</p>
        </div>
      </section>
    </div>
  </div>
</template>

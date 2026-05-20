<script setup>
import { computed, onMounted, ref } from 'vue'
import { financeService } from '@/services/financeService'
import EmptyState from '@/components/common/EmptyState.vue'

const loading = ref(false)
const error = ref('')
const budgets = ref([])

function normalizeList(payload) {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.data)) return payload.data
  if (Array.isArray(payload?.data?.data)) return payload.data.data
  if (Array.isArray(payload?.data?.budgets)) return payload.data.budgets
  if (Array.isArray(payload?.budgets)) return payload.budgets
  return []
}

const normalizedBudgets = computed(() => budgets.value.map((budget) => {
  const planned = Number(budget.budget_amount ?? budget.planned_amount ?? budget.amount ?? 0)
  const actual = Number(budget.spent_amount ?? budget.actual_amount ?? budget.used_amount ?? 0)
  const rawPercentage = planned > 0 ? Math.round((actual / planned) * 100) : 0
  const percentage = Number.isFinite(rawPercentage) ? rawPercentage : 0

  return {
    id: budget.id ?? budget.budget_name ?? budget.category ?? budget.name,
    name: budget.budget_name ?? budget.category ?? budget.name ?? 'Budget',
    planned,
    actual,
    percentage,
    status: percentage >= 100 ? 'exceeded' : percentage >= 80 ? 'warning' : 'safe',
  }
}))

async function loadBudgets() {
  loading.value = true
  error.value = ''

  try {
    const response = await financeService.getBudgets()
    budgets.value = normalizeList(response)
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Unable to load budget progress.'
    budgets.value = []
  } finally {
    loading.value = false
  }
}

function formatCurrency(amount) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(Number(amount || 0))
}

onMounted(loadBudgets)
</script>

<template>
  <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="mb-6 flex items-start justify-between gap-4">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          Budget Progress
        </h2>
        <p class="mt-1 text-sm text-slate-500">
          Planned vs actual spending.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-50"
        :disabled="loading"
        @click="loadBudgets"
      >
        Refresh
      </button>
    </div>

    <div v-if="loading" class="rounded-xl bg-slate-50 p-6 text-center text-sm text-slate-500">
      Loading budgets...
    </div>

    <div v-else-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
      {{ error }}
    </div>

    <EmptyState
      v-else-if="normalizedBudgets.length === 0"
      title="No budget data available yet"
      message="Create a budget to see planned vs actual spending progress."
      action-label="Create Budget"
      action-to="/finance/budgets"
    />

    <div v-else class="space-y-5">
      <div v-for="budget in normalizedBudgets" :key="budget.id || budget.name">
        <div class="mb-2 flex items-center justify-between">
          <span class="text-sm font-medium text-slate-700">
            {{ budget.name }}
          </span>

          <span class="text-sm font-semibold text-slate-900">
            {{ budget.percentage }}%
          </span>
        </div>

        <div class="h-3 w-full overflow-hidden rounded-full bg-slate-100">
          <div
            class="h-3 rounded-full"
            :class="{
              'bg-emerald-500': budget.status === 'safe',
              'bg-amber-500': budget.status === 'warning',
              'bg-red-500': budget.status === 'exceeded',
            }"
            :style="{ width: Math.min(Math.max(budget.percentage, 0), 100) + '%' }"
          ></div>
        </div>

        <div class="mt-1 flex justify-between text-xs text-slate-500">
          <span>Actual: {{ formatCurrency(budget.actual) }}</span>
          <span>Planned: {{ formatCurrency(budget.planned) }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

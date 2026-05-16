<script setup>
import { computed, onMounted, ref } from 'vue'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale,
} from 'chart.js'
import { Bar } from 'vue-chartjs'
import { financeService } from '@/services/financeService'
import EmptyState from '@/components/common/EmptyState.vue'

ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)

const loading = ref(false)
const error = ref('')
const transactions = ref([])

function normalizeList(payload) {
  if (Array.isArray(payload)) return payload
  if (Array.isArray(payload?.data)) return payload.data
  if (Array.isArray(payload?.data?.data)) return payload.data.data
  if (Array.isArray(payload?.data?.transactions)) return payload.data.transactions
  if (Array.isArray(payload?.transactions)) return payload.transactions
  return []
}

const monthlyRows = computed(() => {
  const grouped = new Map()

  transactions.value.forEach((transaction) => {
    const rawDate = transaction.transaction_date ?? transaction.date ?? transaction.created_at
    if (!rawDate) return

    const date = new Date(rawDate)
    if (Number.isNaN(date.getTime())) return

    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
    const label = date.toLocaleString('en-US', { month: 'short', year: 'numeric' })

    if (!grouped.has(key)) {
      grouped.set(key, { key, label, income: 0, expense: 0 })
    }

    const row = grouped.get(key)
    const amount = Number(transaction.amount || 0)
    const type = String(transaction.transaction_type ?? transaction.type ?? '').toLowerCase()

    if (type === 'income') row.income += amount
    if (type === 'expense') row.expense += amount
  })

  return [...grouped.values()].sort((a, b) => a.key.localeCompare(b.key)).slice(-6)
})

const hasChartData = computed(() => monthlyRows.value.some((row) => row.income > 0 || row.expense > 0))

const chartData = computed(() => ({
  labels: monthlyRows.value.map((row) => row.label),
  datasets: [
    {
      label: 'Income',
      data: monthlyRows.value.map((row) => row.income),
      borderRadius: 8,
    },
    {
      label: 'Expenses',
      data: monthlyRows.value.map((row) => row.expense),
      borderRadius: 8,
    },
  ],
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'bottom',
    },
  },
  scales: {
    y: {
      beginAtZero: true,
    },
  },
}

async function loadTransactions() {
  loading.value = true
  error.value = ''

  try {
    const response = await financeService.getTransactions({ per_page: 500 })
    transactions.value = normalizeList(response)
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Unable to load chart data.'
    transactions.value = []
  } finally {
    loading.value = false
  }
}

onMounted(loadTransactions)
</script>

<template>
  <div class="h-[420px] rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="mb-6 flex items-start justify-between gap-4">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          Income vs Expenses
        </h2>
        <p class="mt-1 text-sm text-slate-500">
          Monthly comparison between money earned and money spent.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-50"
        :disabled="loading"
        @click="loadTransactions"
      >
        Refresh
      </button>
    </div>

    <div v-if="loading" class="flex h-[300px] items-center justify-center rounded-xl bg-slate-50 text-sm text-slate-500">
      Loading chart...
    </div>

    <div v-else-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
      {{ error }}
    </div>

    <EmptyState
      v-else-if="!hasChartData"
      title="No chart data available yet"
      message="Add income or expense transactions to generate the monthly finance chart."
      action-label="Add Transaction"
      action-to="/finance/transactions"
    />

    <div v-else class="h-[300px]">
      <Bar :data="chartData" :options="chartOptions" />
    </div>
  </div>
</template>

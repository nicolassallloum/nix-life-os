<script setup>
import { computed, onMounted, ref } from 'vue'
import { financeService } from '@/services/financeService'
import EmptyState from '@/components/common/EmptyState.vue'

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

const recentTransactions = computed(() => transactions.value.slice(0, 8).map((transaction) => ({
  id: transaction.id,
  date: transaction.transaction_date ?? transaction.date ?? transaction.created_at ?? '-',
  category: transaction.category?.name ?? transaction.category_name ?? transaction.category ?? 'Uncategorized',
  account:
    transaction.account_name ??
    transaction.account?.account_name ??
    transaction.account?.name ??
    transaction.finance_account?.account_name ??
    transaction.finance_account?.name ??
    '-',
  description: transaction.description ?? transaction.notes ?? '',
  type: transaction.transaction_type ?? transaction.type ?? '-',
  amount: Number(transaction.amount ?? 0),
  status: transaction.status ?? 'completed',
})))

async function loadTransactions() {
  loading.value = true
  error.value = ''

  try {
    const response = await financeService.getTransactions({ per_page: 8 })
    transactions.value = normalizeList(response)
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Unable to load transactions.'
    transactions.value = []
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

function formatDate(value) {
  if (!value || value === '-') return '-'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? '-' : date.toISOString().slice(0, 10)
}

function typeClass(type) {
  const normalized = String(type || '').toLowerCase()
  if (normalized === 'income') return 'bg-emerald-50 text-emerald-700'
  if (normalized === 'expense') return 'bg-red-50 text-red-700'
  if (normalized === 'transfer') return 'bg-blue-50 text-blue-700'
  return 'bg-slate-100 text-slate-700'
}

onMounted(loadTransactions)
</script>

<template>
  <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-slate-900">
          Recent Transactions
        </h2>
        <p class="mt-1 text-sm text-slate-500">
          Latest income, expenses, and transfers.
        </p>
      </div>

      <RouterLink class="text-sm font-semibold text-indigo-600 hover:text-indigo-800" to="/finance/transactions">
        View All
      </RouterLink>
    </div>

    <div v-if="loading" class="rounded-xl bg-slate-50 p-6 text-center text-sm text-slate-500">
      Loading transactions...
    </div>

    <div v-else-if="error" class="rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
      {{ error }}
    </div>

    <EmptyState
      v-else-if="recentTransactions.length === 0"
      title="No transactions found"
      message="Add income, expense, or transfer records to populate this table."
      action-label="Add Transaction"
      action-to="/finance/transactions"
    />

    <div v-else class="overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-slate-200 text-left text-slate-500">
            <th class="py-3 pr-4">Date</th>
            <th class="py-3 pr-4">Category</th>
            <th class="py-3 pr-4">Account</th>
            <th class="py-3 pr-4">Description</th>
            <th class="py-3 pr-4">Type</th>
            <th class="py-3 pr-4 text-right">Amount</th>
            <th class="py-3 pr-4">Status</th>
          </tr>
        </thead>

        <tbody>
          <tr
            v-for="transaction in recentTransactions"
            :key="transaction.id"
            class="border-b border-slate-100 hover:bg-slate-50"
          >
            <td class="py-4 pr-4 text-slate-700">
              {{ formatDate(transaction.date) }}
            </td>

            <td class="py-4 pr-4 font-medium text-slate-900">
              {{ transaction.category }}
            </td>

            <td class="py-4 pr-4 text-slate-600">
              {{ transaction.account }}
            </td>

            <td class="py-4 pr-4 text-slate-600">
              {{ transaction.description || '-' }}
            </td>

            <td class="py-4 pr-4">
              <span class="rounded-full px-2 py-1 text-xs font-semibold" :class="typeClass(transaction.type)">
                {{ transaction.type }}
              </span>
            </td>

            <td class="py-4 pr-4 text-right font-semibold">
              {{ formatCurrency(transaction.amount) }}
            </td>

            <td class="py-4 pr-4">
              <span class="rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700">
                {{ transaction.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

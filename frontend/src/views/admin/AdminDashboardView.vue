<template>
  <div class="min-h-screen bg-slate-50 p-6">
    <div class="mb-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h1 class="text-3xl font-bold text-slate-900">Admin Dashboard</h1>
        <p class="mt-1 text-sm text-slate-500">
          Platform usage, online users, finance totals, and user activity.
        </p>
      </div>

      <button
        type="button"
        class="rounded-xl bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-60"
        :disabled="loading"
        @click="loadDashboard"
      >
        {{ loading ? 'Refreshing...' : 'Refresh' }}
      </button>
    </div>

    <div
      v-if="errorMessage"
      class="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
    >
      {{ errorMessage }}
    </div>

    <div v-if="loading && !summary" class="rounded-2xl bg-white p-6 text-center text-sm text-slate-500">
      Loading admin dashboard...
    </div>

    <template v-else>
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div
          v-for="card in cards"
          :key="card.title"
          class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
        >
          <p class="text-sm font-medium text-slate-500">{{ card.title }}</p>
          <h2 class="mt-2 text-2xl font-bold text-slate-900">{{ card.value }}</h2>
          <p class="mt-1 text-xs text-slate-500">{{ card.note }}</p>
        </div>
      </div>

      <div class="mt-6 grid grid-cols-1 gap-6 xl:grid-cols-2">
        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold text-slate-900">Most Used Pages</h2>
          <p class="mb-4 text-sm text-slate-500">Tracked from application visits.</p>

          <div v-if="mostUsedPages.length === 0" class="text-sm text-slate-500">
            No page visit data yet.
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="page in mostUsedPages"
              :key="page.page_url"
              class="flex items-center justify-between rounded-xl bg-slate-50 px-4 py-3 text-sm"
            >
              <span class="truncate pr-4 text-slate-700">{{ page.page_url }}</span>
              <span class="font-bold text-slate-900">{{ page.visits }}</span>
            </div>
          </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 class="text-lg font-semibold text-slate-900">Recent Users</h2>
          <p class="mb-4 text-sm text-slate-500">Latest registered or active users.</p>

          <div v-if="recentUsers.length === 0" class="text-sm text-slate-500">
            No user data found.
          </div>

          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-sm">
              <thead>
                <tr class="border-b border-slate-200 text-slate-500">
                  <th class="py-3 pr-4 font-medium">Name</th>
                  <th class="py-3 pr-4 font-medium">Email</th>
                  <th class="py-3 pr-4 font-medium">Last Login</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="user in recentUsers" :key="user.id || user.email" class="border-b border-slate-100">
                  <td class="py-3 pr-4 text-slate-800">{{ user.name || '-' }}</td>
                  <td class="py-3 pr-4 text-slate-600">{{ user.email || '-' }}</td>
                  <td class="py-3 pr-4 text-slate-600">{{ user.last_login_at || '-' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import api from '@/services/api'

const loading = ref(false)
const errorMessage = ref('')
const summary = ref(null)

const users = computed(() => summary.value?.users || {})
const app = computed(() => summary.value?.application || {})
const finance = computed(() => summary.value?.finance || {})
const recentUsers = computed(() => summary.value?.recent_users || [])
const mostUsedPages = computed(() => app.value?.most_used_pages || [])

const cards = computed(() => [
  { title: 'Total Users', value: users.value.total_users || 0, note: 'Registered users' },
  { title: 'Online Users', value: users.value.online_users || 0, note: 'Seen in last 5 minutes' },
  { title: 'Application Visits', value: app.value.total_visits || 0, note: `${app.value.today_visits || 0} today` },
  { title: 'Total Logins', value: users.value.total_logins || 0, note: `${users.value.today_logins || 0} today` },
  { title: 'Finance Transactions', value: finance.value.total_transactions || 0, note: 'All users' },
  { title: 'Total Income', value: formatMoney(finance.value.total_income), note: 'All users' },
  { title: 'Total Expenses', value: formatMoney(finance.value.total_expenses), note: 'All users' },
  { title: 'Accounts / Budgets', value: `${finance.value.total_accounts || 0} / ${finance.value.total_budgets || 0}`, note: 'Finance setup' },
])

function formatMoney(value) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(Number(value || 0))
}

async function loadDashboard() {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/admin/dashboard/summary')
    summary.value = response.data?.data || null
  } catch (error) {
    errorMessage.value = error?.message || 'Failed to load admin dashboard.'
  } finally {
    loading.value = false
  }
}

onMounted(loadDashboard)
</script>

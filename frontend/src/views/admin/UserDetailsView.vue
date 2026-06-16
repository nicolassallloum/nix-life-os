<template>
  <main class="min-h-screen bg-slate-950 px-6 py-8 text-white">
    <section class="mx-auto max-w-4xl">
      <div class="mb-8">
        <RouterLink to="/admin/users-management" class="text-sm font-semibold text-indigo-300 hover:text-indigo-200">
          ← Back to User Management
        </RouterLink>
        <h1 class="mt-4 text-3xl font-bold">User Details</h1>
        <p class="mt-2 text-slate-400">View and update user role, status, and profile data.</p>
      </div>

      <div v-if="loading" class="rounded-2xl border border-slate-800 bg-slate-900/80 p-8 text-center text-slate-400">
        Loading user...
      </div>

      <form
        v-else-if="user"
        class="rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl"
        @submit.prevent="submitForm"
      >
        <div v-if="errorMessage" class="mb-5 rounded-xl border border-red-900 bg-red-950/40 p-4 text-red-300">
          {{ errorMessage }}
        </div>

        <div v-if="successMessage" class="mb-5 rounded-xl border border-green-900 bg-green-950/40 p-4 text-green-300">
          {{ successMessage }}
        </div>

        <div class="mb-6 rounded-xl bg-slate-950 p-4 text-sm text-slate-400">
          <p><strong class="text-slate-200">ID:</strong> {{ user.id }}</p>
          <p><strong class="text-slate-200">Created:</strong> {{ user.created_at || '-' }}</p>
          <p><strong class="text-slate-200">Last login:</strong> {{ user.last_login_at || 'Never' }}</p>
        </div>

        <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
          <div>
            <label class="mb-2 block text-sm text-slate-400">Name</label>
            <input v-model="form.name" required type="text" class="field" />
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Email</label>
            <input v-model="form.email" required type="email" class="field" />
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Role</label>
            <select v-model="form.role" required class="field">
              <option value="admin">admin</option>
              <option value="user">user</option>
              <option value="demo">demo</option>
              <option value="qa">qa</option>
            </select>
          </div>

          <div>
            <label class="mb-2 block text-sm text-slate-400">Status</label>
            <select v-model="form.status" required class="field">
              <option value="active">active</option>
              <option value="hold">hold</option>
              <option value="inactive">inactive</option>
            </select>
          </div>

          <div class="md:col-span-2">
            <label class="mb-2 block text-sm text-slate-400">New Password</label>
            <input v-model="form.password" type="password" minlength="8" placeholder="Leave empty to keep current password" class="field" />
          </div>
        </div>

        <div class="mt-8 flex flex-col justify-end gap-3 sm:flex-row">
          <button
            type="button"
            class="rounded-xl border border-amber-800 px-5 py-3 font-semibold text-amber-300 hover:bg-amber-950/50"
            @click="holdUser"
          >
            Hold
          </button>

          <button
            type="button"
            class="rounded-xl border border-green-800 px-5 py-3 font-semibold text-green-300 hover:bg-green-950/50"
            @click="activateUser"
          >
            Activate
          </button>

          <button
            type="submit"
            class="rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white hover:bg-indigo-500 disabled:opacity-60"
            :disabled="saving"
          >
            {{ saving ? 'Saving...' : 'Save Changes' }}
          </button>
        </div>
      </form>

      <section
        v-if="userDashboard"
        class="mt-6 rounded-2xl border border-slate-800 bg-slate-900/80 p-6 shadow-xl"
      >
        <div class="mb-5">
          <h2 class="text-2xl font-bold">User Finance & Health Dashboard</h2>
          <p class="mt-1 text-sm text-slate-400">
            A complete admin snapshot for this user's Finance and Health modules.
          </p>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div class="dashboard-card">
            <p>Finance Balance</p>
            <strong>${{ money(userDashboard.finance?.summary?.total_balance) }}</strong>
          </div>
          <div class="dashboard-card">
            <p>Transactions</p>
            <strong>{{ userDashboard.finance?.summary?.transactions_count || 0 }}</strong>
          </div>
          <div class="dashboard-card">
            <p>Today Steps</p>
            <strong>{{ userDashboard.health?.summary?.today_steps || 0 }}</strong>
          </div>
          <div class="dashboard-card">
            <p>Today Calories</p>
            <strong>{{ userDashboard.health?.summary?.today_calories || 0 }}</strong>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-1 gap-5 xl:grid-cols-2">
          <div class="dashboard-panel">
            <h3>Finance Summary</h3>
            <div class="mini-grid">
              <span>Accounts</span><strong>{{ userDashboard.finance?.summary?.accounts_count || 0 }}</strong>
              <span>Total Income</span><strong>${{ money(userDashboard.finance?.summary?.total_income) }}</strong>
              <span>Total Expenses</span><strong>${{ money(userDashboard.finance?.summary?.total_expenses) }}</strong>
              <span>Net Total</span><strong>${{ money(userDashboard.finance?.summary?.net_total) }}</strong>
            </div>
          </div>

          <div class="dashboard-panel">
            <h3>Health Summary</h3>
            <div class="mini-grid">
              <span>Water</span><strong>{{ userDashboard.health?.summary?.today_water_ml || 0 }} ml</strong>
              <span>Weight</span><strong>{{ userDashboard.health?.summary?.current_weight_kg || '—' }} kg</strong>
              <span>BMI</span><strong>{{ userDashboard.health?.summary?.current_bmi || '—' }}</strong>
              <span>Sleep</span><strong>{{ userDashboard.health?.summary?.last_sleep_hours || '—' }} h</strong>
              <span>Mood</span><strong>{{ userDashboard.health?.summary?.today_mood || '—' }}</strong>
              <span>Medications</span><strong>{{ userDashboard.health?.summary?.active_medications || 0 }}</strong>
              <span>Lab Tests</span><strong>{{ userDashboard.health?.summary?.lab_tests_count || 0 }}</strong>
              <span>Active Alerts</span><strong>{{ userDashboard.health?.summary?.active_alerts_count || 0 }}</strong>
            </div>
          </div>
        </div>

        <div class="mt-6 grid grid-cols-1 gap-5 xl:grid-cols-2">
          <div class="dashboard-panel">
            <h3>Recent Transactions</h3>
            <div v-if="recentFinanceTransactions.length === 0" class="empty-mini">No finance transactions.</div>
            <div v-for="transaction in recentFinanceTransactions" :key="transaction.id" class="recent-row">
              <span>{{ transaction.transaction_date || transaction.created_at }}</span>
              <strong>{{ transaction.transaction_type }} · ${{ money(transaction.amount) }}</strong>
            </div>
          </div>

          <div class="dashboard-panel">
            <h3>Recent Health Activity</h3>
            <div class="mini-grid">
              <span>Step Logs</span><strong>{{ userDashboard.health?.counts?.step_logs || 0 }}</strong>
              <span>Nutrition Logs</span><strong>{{ userDashboard.health?.counts?.nutrition_logs || 0 }}</strong>
              <span>Hydration Logs</span><strong>{{ userDashboard.health?.counts?.hydration_logs || 0 }}</strong>
              <span>Sleep Logs</span><strong>{{ userDashboard.health?.counts?.sleep_logs || 0 }}</strong>
              <span>Mood Logs</span><strong>{{ userDashboard.health?.counts?.mood_logs || 0 }}</strong>
            </div>
          </div>
        </div>
      </section>

      <div v-else class="rounded-2xl border border-red-900 bg-red-950/40 p-6 text-red-300">
        User not found.
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import api, { getApiErrorMessage } from '@/services/api'

const route = useRoute()
const userId = String(route.params.id)

const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const user = ref<any>(null)
const userDashboard = ref<any>(null)

const recentFinanceTransactions = computed(() => {
  return Array.isArray(userDashboard.value?.finance?.recent_transactions)
    ? userDashboard.value.finance.recent_transactions
    : []
})

function money(value: any) {
  const number = Number(value || 0)
  return Number.isFinite(number) ? number.toFixed(2) : '0.00'
}

const form = reactive({
  name: '',
  email: '',
  password: '',
  role: 'user',
  status: 'active',
})

function fillForm(data: any) {
  user.value = data
  form.name = data?.name || ''
  form.email = data?.email || ''
  form.role = data?.role || 'user'
  form.status = data?.status || 'active'
  form.password = ''
}

async function loadUser() {
  loading.value = true
  errorMessage.value = ''

  try {
    const [userResponse, dashboardResponse] = await Promise.all([
      api.get(`/admin/users/${userId}`),
      api.get(`/admin/users/${userId}/dashboard`),
    ])

    fillForm(userResponse.data?.data?.user)
    userDashboard.value = dashboardResponse.data?.data || null
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to load user.')
  } finally {
    loading.value = false
  }
}

async function submitForm() {
  saving.value = true
  errorMessage.value = ''
  successMessage.value = ''

  const payload: Record<string, string> = {
    name: form.name,
    email: form.email,
    role: form.role,
    status: form.status,
  }

  if (form.password) {
    payload.password = form.password
  }

  try {
    const response = await api.put(`/admin/users/${userId}`, payload)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User updated successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to update user.')
  } finally {
    saving.value = false
  }
}

async function holdUser() {
  if (!confirm(`Place ${form.email} on hold?`)) return

  try {
    const response = await api.put(`/admin/users/${userId}/hold`)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User placed on hold successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to place user on hold.')
  }
}

async function activateUser() {
  try {
    const response = await api.put(`/admin/users/${userId}/activate`)
    fillForm(response.data?.data?.user)
    successMessage.value = 'User activated successfully.'
  } catch (error) {
    errorMessage.value = getApiErrorMessage(error, 'Failed to activate user.')
  }
}

onMounted(loadUser)
</script>

<style scoped>
.field {
  width: 100%;
  border-radius: 0.75rem;
  border: 1px solid rgb(51 65 85);
  background: rgb(2 6 23);
  padding: 0.75rem 1rem;
  color: white;
  outline: none;
}
.field:focus {
  border-color: rgb(99 102 241);
}

.dashboard-card {
  border: 1px solid rgb(51 65 85);
  border-radius: 1rem;
  background: rgb(15 23 42);
  padding: 1rem;
}
.dashboard-card p {
  color: rgb(148 163 184);
  font-size: 0.875rem;
}
.dashboard-card strong {
  display: block;
  margin-top: 0.5rem;
  color: white;
  font-size: 1.5rem;
}
.dashboard-panel {
  border: 1px solid rgb(51 65 85);
  border-radius: 1rem;
  background: rgb(2 6 23);
  padding: 1rem;
}
.dashboard-panel h3 {
  margin-bottom: 1rem;
  font-weight: 700;
  color: white;
}
.mini-grid {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 0.75rem;
  color: rgb(203 213 225);
}
.mini-grid span {
  color: rgb(148 163 184);
}
.recent-row {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  border-top: 1px solid rgb(30 41 59);
  padding: 0.75rem 0;
  color: rgb(203 213 225);
}
.empty-mini {
  color: rgb(148 163 184);
  font-size: 0.875rem;
}

</style>

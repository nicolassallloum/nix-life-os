<template>
  <main class="hydration-page">
    <section class="page-header">
      <div>
        <p class="eyebrow">Health Module</p>
        <h1>Hydration Tracker</h1>
        <p class="subtitle">Track water, coffee, tea, juice, soft drinks, soup, and other hydration sources.</p>
      </div>
      <button class="refresh-btn" type="button" @click="loadAll" :disabled="loading">
        {{ loading ? 'Loading...' : 'Refresh' }}
      </button>
    </section>

    <section class="summary-grid">
      <article class="summary-card">
        <span>Today</span>
        <strong>{{ summary.daily_total_ml }} ml</strong>
        <small>{{ summary.daily_total_liters }} L</small>
      </article>
      <article class="summary-card">
        <span>This Week</span>
        <strong>{{ summary.weekly_total_ml }} ml</strong>
        <small>{{ summary.weekly_total_liters }} L</small>
      </article>
      <article class="summary-card">
        <span>This Month</span>
        <strong>{{ summary.monthly_total_ml }} ml</strong>
        <small>{{ summary.monthly_total_liters }} L</small>
      </article>
      <article class="summary-card">
        <span>All Time</span>
        <strong>{{ summary.all_time_total_ml }} ml</strong>
        <small>{{ summary.all_time_total_liters }} L</small>
      </article>
    </section>

    <section class="content-grid">
      <form class="panel form-panel" @submit.prevent="saveLog">
        <h2>{{ editingId ? 'Update Hydration Log' : 'Add Hydration Log' }}</h2>

        <label>
          Hydration Type
          <select v-model="form.hydration_type" required>
            <option v-for="type in hydrationTypes" :key="type" :value="type">
              {{ type }}
            </option>
          </select>
        </label>

        <label>
          Quantity ML
          <input v-model.number="form.quantity_ml" type="number" min="1" max="10000" required />
        </label>

        <label>
          Date
          <input v-model="form.log_date" type="date" required />
        </label>

        <label>
          Time
          <input v-model="form.log_time" type="time" />
        </label>

        <label>
          Notes
          <textarea v-model="form.notes" rows="3" placeholder="Optional notes"></textarea>
        </label>

        <div class="form-actions">
          <button class="primary-btn" type="submit" :disabled="saving">
            {{ saving ? 'Saving...' : editingId ? 'Update Log' : 'Add Log' }}
          </button>
          <button v-if="editingId" class="secondary-btn" type="button" @click="resetForm">
            Cancel
          </button>
        </div>

        <p v-if="message" class="message">{{ message }}</p>
        <p v-if="error" class="error">{{ error }}</p>
      </form>

      <section class="panel logs-panel">
        <div class="panel-title">
          <h2>Recent Hydration Logs</h2>
          <span>{{ logs.length }} records</span>
        </div>

        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Time</th>
                <th>Type</th>
                <th>Quantity</th>
                <th>Notes</th>
                <th class="actions-col">Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in logs" :key="log.id">
                <td>{{ formatDate(log.log_date) }}</td>
                <td>{{ log.log_time || '-' }}</td>
                <td>{{ log.hydration_type }}</td>
                <td>{{ log.quantity_ml }} ml</td>
                <td>{{ log.notes || '-' }}</td>
                <td class="row-actions">
                  <button type="button" @click="editLog(log)">Edit</button>
                  <button type="button" class="danger" @click="deleteLog(log.id)">Delete</button>
                </td>
              </tr>
              <tr v-if="!logs.length">
                <td colspan="6" class="empty">No hydration logs yet.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </section>

    <section class="charts-grid">
      <PieChart title="Daily Hydration by Type" :items="charts.daily" />
      <PieChart title="Weekly Hydration by Type" :items="charts.weekly" />
      <PieChart title="Monthly Hydration by Type" :items="charts.monthly" />
      <PieChart title="All-Time Hydration by Type" :items="charts.all_time" />
    </section>
  </main>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, reactive, ref } from 'vue'

type HydrationType = 'Water' | 'Coffee' | 'Tea' | 'Juice' | 'Soft Drink' | 'Soup' | 'Other'

type HydrationLog = {
  id: number
  hydration_type: HydrationType
  quantity_ml: number
  log_date: string
  log_time?: string
  notes?: string
}

type ChartItem = {
  hydration_type: HydrationType
  total_ml: number
}

const hydrationTypes: HydrationType[] = [
  'Water',
  'Coffee',
  'Tea',
  'Juice',
  'Soft Drink',
  'Soup',
  'Other',
]

const API_BASE =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  'http://localhost:8000/api/v1'

const logs = ref<HydrationLog[]>([])
const loading = ref(false)
const saving = ref(false)
const editingId = ref<number | null>(null)
const message = ref('')
const error = ref('')

function localDateValue(date = new Date()) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}`
}

const today = localDateValue()
const nowTime = new Date().toTimeString().slice(0, 5)

const form = reactive({
  hydration_type: 'Water' as HydrationType,
  quantity_ml: 250,
  log_date: today,
  log_time: nowTime,
  notes: '',
})

const summary = reactive({
  daily_total_ml: 0,
  weekly_total_ml: 0,
  monthly_total_ml: 0,
  all_time_total_ml: 0,
  daily_total_liters: 0,
  weekly_total_liters: 0,
  monthly_total_liters: 0,
  all_time_total_liters: 0,
})

const charts = reactive<Record<'daily' | 'weekly' | 'monthly' | 'all_time', ChartItem[]>>({
  daily: [],
  weekly: [],
  monthly: [],
  all_time: [],
})

function getLogAmountMl(log: any): number {
  return Number(log.quantity_ml ?? log.amount_ml ?? log.water_ml ?? log.intake_ml ?? log.ml ?? 0)
}

function getLogDateValue(log: any): string {
  return String(log.log_date || log.hydration_date || log.date || log.created_at || '').slice(0, 10)
}

function addDays(date: Date, days: number) {
  const copy = new Date(date)
  copy.setDate(copy.getDate() + days)
  return copy
}

function applySummaryFallbackFromLogs() {
  if (!logs.value.length || Number(summary.all_time_total_ml || 0) > 0) {
    return
  }

  const todayValue = localDateValue()
  const todayDate = new Date(`${todayValue}T00:00:00`)
  const weekStart = localDateValue(addDays(todayDate, -6))
  const monthStart = localDateValue(new Date(todayDate.getFullYear(), todayDate.getMonth(), 1))

  const totals = logs.value.reduce(
    (acc, log: any) => {
      const dateValue = getLogDateValue(log)
      const amount = getLogAmountMl(log)

      acc.all += amount

      if (dateValue === todayValue) acc.day += amount
      if (dateValue >= weekStart && dateValue <= todayValue) acc.week += amount
      if (dateValue >= monthStart && dateValue <= todayValue) acc.month += amount

      return acc
    },
    { day: 0, week: 0, month: 0, all: 0 },
  )

  Object.assign(summary, {
    daily_total_ml: totals.day,
    weekly_total_ml: totals.week,
    monthly_total_ml: totals.month,
    all_time_total_ml: totals.all,
    daily_total_liters: Number((totals.day / 1000).toFixed(2)),
    weekly_total_liters: Number((totals.week / 1000).toFixed(2)),
    monthly_total_liters: Number((totals.month / 1000).toFixed(2)),
    all_time_total_liters: Number((totals.all / 1000).toFixed(2)),
  })
}


function getToken(): string {
  return (
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('nix_token') ||
    ''
  )
}

async function apiRequest(path: string, options: RequestInit = {}) {
  const token = getToken()

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  const payload = await response.json().catch(() => ({}))

  if (!response.ok) {
    throw new Error(payload.message || 'Request failed.')
  }

  return payload
}

async function loadLogs() {
  const payload = await apiRequest('/health/hydration')
  logs.value = (payload.data || []).map((log: any) => ({
    ...log,
    hydration_type: log.hydration_type || log.drink_type || 'Water',
    quantity_ml: getLogAmountMl(log),
    log_time: log.log_time ? String(log.log_time).slice(0, 5) : '',
  }))
}

async function loadSummary() {
  const payload = await apiRequest('/health/hydration/summary')
  const data = payload.data || {}

  Object.assign(summary, {
    daily_total_ml: data.daily_total_ml ?? data.today_ml ?? 0,
    weekly_total_ml: data.weekly_total_ml ?? data.week_ml ?? 0,
    monthly_total_ml: data.monthly_total_ml ?? data.month_ml ?? 0,
    all_time_total_ml: data.all_time_total_ml ?? data.all_time_ml ?? 0,
    daily_total_liters: data.daily_total_liters ?? Number(((data.daily_total_ml ?? data.today_ml ?? 0) / 1000).toFixed(2)),
    weekly_total_liters: data.weekly_total_liters ?? Number(((data.weekly_total_ml ?? data.week_ml ?? 0) / 1000).toFixed(2)),
    monthly_total_liters: data.monthly_total_liters ?? Number(((data.monthly_total_ml ?? data.month_ml ?? 0) / 1000).toFixed(2)),
    all_time_total_liters: data.all_time_total_liters ?? Number(((data.all_time_total_ml ?? data.all_time_ml ?? 0) / 1000).toFixed(2)),
  })
}

async function loadCharts() {
  const payload = await apiRequest('/health/hydration/charts')
  Object.assign(charts, payload.data || {})
}

async function loadAll() {
  loading.value = true
  error.value = ''
  try {
    await Promise.all([loadLogs(), loadSummary(), loadCharts()])
    applySummaryFallbackFromLogs()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to load hydration data.'
  } finally {
    loading.value = false
  }
}

async function saveLog() {
  saving.value = true
  error.value = ''
  message.value = ''

  const payload = {
    hydration_type: form.hydration_type,
    drink_type: form.hydration_type,
    quantity_ml: form.quantity_ml,
    amount_ml: form.quantity_ml,
    water_ml: form.quantity_ml,
    log_date: form.log_date,
    log_time: form.log_time,
    notes: form.notes,
  }

  try {
    if (editingId.value) {
      await apiRequest(`/health/hydration/${editingId.value}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      })
      message.value = 'Hydration log updated successfully.'
    } else {
      await apiRequest('/health/hydration', {
        method: 'POST',
        body: JSON.stringify(payload),
      })
      message.value = 'Hydration log added successfully.'
    }

    resetForm()
    await loadAll()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to save hydration log.'
  } finally {
    saving.value = false
  }
}

function editLog(log: HydrationLog) {
  editingId.value = log.id
  form.hydration_type = log.hydration_type
  form.quantity_ml = log.quantity_ml
  form.log_date = String(log.log_date).slice(0, 10)
  form.log_time = log.log_time ? String(log.log_time).slice(0, 5) : ''
  form.notes = log.notes || ''
}

async function deleteLog(id: number) {
  if (!confirm('Delete this hydration log?')) return

  error.value = ''
  message.value = ''

  try {
    await apiRequest(`/health/hydration/${id}`, { method: 'DELETE' })
    message.value = 'Hydration log deleted successfully.'
    await loadAll()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to delete hydration log.'
  }
}

function resetForm() {
  editingId.value = null
  form.hydration_type = 'Water'
  form.quantity_ml = 250
  form.log_date = today
  form.log_time = new Date().toTimeString().slice(0, 5)
  form.notes = ''
}

function formatDate(value: string) {
  return String(value).slice(0, 10)
}

const PieChart = defineComponent({
  name: 'PieChart',
  props: {
    title: {
      type: String,
      required: true,
    },
    items: {
      type: Array as () => ChartItem[],
      required: true,
    },
  },
  setup(props) {
    const total = computed(() =>
      props.items.reduce((sum, item) => sum + Number(item.total_ml || 0), 0)
    )

    const gradient = computed(() => {
      if (!total.value) return 'conic-gradient(#d8dee9 0deg 360deg)'

      let start = 0
      const palette = ['#38bdf8', '#60a5fa', '#22c55e', '#f59e0b', '#ef4444', '#a855f7', '#94a3b8']

      return `conic-gradient(${props.items
        .map((item, index) => {
          const degrees = (Number(item.total_ml || 0) / total.value) * 360
          const end = start + degrees
          const segment = `${palette[index % palette.length]} ${start}deg ${end}deg`
          start = end
          return segment
        })
        .join(', ')})`
    })

    return () =>
      h('article', { class: 'panel chart-card' }, [
        h('h2', props.title),
        h('div', { class: 'chart-body' }, [
          h('div', {
            class: 'pie',
            style: { background: gradient.value },
          }),
          h('div', { class: 'legend' }, [
            props.items.map((item, index) =>
              h('div', { class: 'legend-row', key: item.hydration_type }, [
                h('span', { class: `dot dot-${index}` }),
                h('span', item.hydration_type),
                h('strong', `${item.total_ml || 0} ml`),
              ])
            ),
          ]),
        ]),
        h('p', { class: 'chart-total' }, `Total: ${total.value} ml`),
      ])
  },
})
</script>

<style scoped>
.hydration-page {
  padding: 24px;
  color: #0f172a;
}

.page-header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
  margin-bottom: 24px;
}

.eyebrow {
  color: #0284c7;
  font-size: 13px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin: 0 0 6px;
}

h1,
h2 {
  margin: 0;
}

.subtitle {
  margin: 8px 0 0;
  color: #64748b;
}

.summary-grid,
.charts-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.summary-card,
.panel {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.06);
}

.summary-card {
  padding: 18px;
}

.summary-card span {
  display: block;
  color: #64748b;
  font-size: 14px;
  margin-bottom: 8px;
}

.summary-card strong {
  display: block;
  font-size: 26px;
  color: #0f172a;
}

.summary-card small {
  color: #0284c7;
  font-weight: 700;
}

.content-grid {
  display: grid;
  grid-template-columns: 360px minmax(0, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

.panel {
  padding: 20px;
}

.form-panel {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  color: #334155;
  font-weight: 700;
  font-size: 14px;
}

input,
select,
textarea {
  color: #0f172a;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 10px 12px;
  font: inherit;
}

button {
  border: 0;
  border-radius: 12px;
  padding: 10px 14px;
  cursor: pointer;
  font-weight: 800;
}

.primary-btn,
.refresh-btn {
  background: #0284c7;
  color: white;
}

.secondary-btn {
  background: #e2e8f0;
  color: #0f172a;
}

.form-actions,
.row-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.panel-title {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.panel-title span {
  color: #64748b;
  font-weight: 700;
}

.table-wrap {
  overflow-x: auto;
  margin-top: 14px;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th,
td {
  border-bottom: 1px solid #e2e8f0;
  padding: 12px;
  text-align: left;
  vertical-align: top;
}

th {
  color: #475569;
  font-size: 13px;
  text-transform: uppercase;
}

.actions-col {
  width: 160px;
}

.row-actions button {
  background: #e0f2fe;
  color: #0369a1;
}

.row-actions .danger {
  background: #fee2e2;
  color: #b91c1c;
}

.empty {
  text-align: center;
  color: #64748b;
}

.message {
  color: #047857;
  font-weight: 700;
}

.error {
  color: #b91c1c;
  font-weight: 700;
}

.chart-card h2 {
  font-size: 18px;
  margin-bottom: 16px;
}

.chart-body {
  display: flex;
  align-items: center;
  gap: 18px;
}

.pie {
  width: 130px;
  height: 130px;
  border-radius: 50%;
  flex: 0 0 auto;
  box-shadow: inset 0 0 0 14px rgba(255, 255, 255, 0.35);
}

.legend {
  flex: 1;
  display: grid;
  gap: 8px;
}

.legend-row {
  display: grid;
  grid-template-columns: 14px 1fr auto;
  align-items: center;
  gap: 8px;
  font-size: 13px;
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #38bdf8;
}

.dot-1 { background: #60a5fa; }
.dot-2 { background: #22c55e; }
.dot-3 { background: #f59e0b; }
.dot-4 { background: #ef4444; }
.dot-5 { background: #a855f7; }
.dot-6 { background: #94a3b8; }

.chart-total {
  margin: 14px 0 0;
  color: #0284c7;
  font-weight: 800;
}

@media (max-width: 1200px) {
  .summary-grid,
  .charts-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .content-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 700px) {
  .hydration-page {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .summary-grid,
  .charts-grid {
    grid-template-columns: 1fr;
  }

  .chart-body {
    flex-direction: column;
    align-items: flex-start;
  }
}

/* Health follow-up readability fix: force readable text in light form fields */
.hydration-page input,
.hydration-page select,
.hydration-page textarea,
.hydration-page input:disabled,
.hydration-page select:disabled,
.hydration-page textarea:disabled,
.hydration-page input[readonly],
.hydration-page select[readonly],
.hydration-page textarea[readonly] {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
  caret-color: #2563eb !important;
  opacity: 1 !important;
  color-scheme: light !important;
}

.hydration-page input::placeholder,
.hydration-page textarea::placeholder {
  color: #64748b !important;
  -webkit-text-fill-color: #64748b !important;
  opacity: 1 !important;
}

.hydration-page select option,
.hydration-page option {
  background-color: #ffffff !important;
  color: #020617 !important;
  -webkit-text-fill-color: #020617 !important;
}

.hydration-page input:-webkit-autofill,
.hydration-page textarea:-webkit-autofill,
.hydration-page select:-webkit-autofill {
  -webkit-text-fill-color: #020617 !important;
  box-shadow: 0 0 0 1000px #ffffff inset !important;
  transition: background-color 9999s ease-out 0s !important;
}

.hydration-page input::selection,
.hydration-page textarea::selection,
.hydration-page select::selection {
  color: #ffffff !important;
  -webkit-text-fill-color: #ffffff !important;
  background-color: #2563eb !important;
}

.hydration-page input::-moz-selection,
.hydration-page textarea::-moz-selection,
.hydration-page select::-moz-selection {
  color: #ffffff !important;
  background-color: #2563eb !important;
}
</style>

<template>
  <div class="steps-page">
    <div class="page-header">
      <div>
        <h1>Steps & KM</h1>
        <p>Track daily steps, distance, and calories burned.</p>
      </div>

      <button class="primary-btn" @click="openCreateForm">
        Add Steps
      </button>
    </div>

    <div class="summary-grid">
      <div class="summary-card">
        <span>Today Steps</span>
        <strong>{{ formatNumber(summary.today.steps) }}</strong>
      </div>

      <div class="summary-card">
        <span>Weekly Steps</span>
        <strong>{{ formatNumber(summary.weekly.steps) }}</strong>
      </div>

      <div class="summary-card">
        <span>Monthly Steps</span>
        <strong>{{ formatNumber(summary.monthly.steps) }}</strong>
      </div>

      <div class="summary-card">
        <span>All-time Steps</span>
        <strong>{{ formatNumber(summary.all_time.steps) }}</strong>
      </div>

      <div class="summary-card">
        <span>Today KM</span>
        <strong>{{ formatKm(summary.today.kilometers) }}</strong>
      </div>

      <div class="summary-card">
        <span>Weekly KM</span>
        <strong>{{ formatKm(summary.weekly.kilometers) }}</strong>
      </div>

      <div class="summary-card">
        <span>Monthly KM</span>
        <strong>{{ formatKm(summary.monthly.kilometers) }}</strong>
      </div>

      <div class="summary-card">
        <span>All-time KM</span>
        <strong>{{ formatKm(summary.all_time.kilometers) }}</strong>
      </div>
    </div>

    <div v-if="showForm" class="form-card">
      <div class="form-header">
        <h2>{{ editingId ? 'Edit Steps Log' : 'Add Steps Log' }}</h2>
        <button class="ghost-btn" @click="closeForm">Close</button>
      </div>

      <form @submit.prevent="saveLog" class="steps-form">
        <label>
          Date
          <input v-model="form.log_date" type="date" required />
        </label>

        <label>
          Steps
          <input v-model.number="form.steps" type="number" min="0" required />
        </label>

        <label>
          Kilometers
          <input v-model.number="form.kilometers" type="number" min="0" step="0.01" />
        </label>

        <label>
          Calories Burned
          <input v-model.number="form.calories_burned" type="number" min="0" />
        </label>

        <label>
          Source
          <input v-model="form.source" type="text" placeholder="manual, watch, phone..." />
        </label>

        <label class="full-width">
          Notes
          <textarea v-model="form.notes" rows="3" placeholder="Optional notes"></textarea>
        </label>

        <div class="form-actions">
          <button type="submit" class="primary-btn" :disabled="loading">
            {{ editingId ? 'Update Log' : 'Save Log' }}
          </button>

          <button type="button" class="secondary-btn" @click="resetForm">
            Reset
          </button>
        </div>
      </form>
    </div>

    <div class="table-card">
      <div class="table-header">
        <h2>Steps History</h2>
        <button class="secondary-btn" @click="loadData" :disabled="loading">
          Refresh
        </button>
      </div>

      <p v-if="error" class="error-message">{{ error }}</p>

      <div v-if="loading" class="loading-message">
        Loading steps data...
      </div>

      <table v-else>
        <thead>
          <tr>
            <th>Date</th>
            <th>Steps</th>
            <th>KM</th>
            <th>Calories</th>
            <th>Source</th>
            <th>Notes</th>
            <th class="actions-col">Actions</th>
          </tr>
        </thead>

        <tbody>
          <tr v-if="logs.length === 0">
            <td colspan="7" class="empty-state">No steps logs found.</td>
          </tr>

          <tr v-for="log in logs" :key="log.id">
            <td>{{ formatDate(log.log_date) }}</td>
            <td>{{ formatNumber(log.steps) }}</td>
            <td>{{ formatKm(log.kilometers) }}</td>
            <td>{{ formatNumber(log.calories_burned) }}</td>
            <td>{{ log.source || '-' }}</td>
            <td>{{ log.notes || '-' }}</td>
            <td class="actions">
              <button class="small-btn" @click="editLog(log)">Edit</button>
              <button class="danger-btn" @click="deleteLog(log.id)">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'

type StepLog = {
  id: number
  log_date: string
  steps: number
  kilometers: number
  calories_burned: number
  source?: string | null
  notes?: string | null
}

type SummaryBlock = {
  steps: number
  kilometers: number
  calories_burned: number
}

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const logs = ref<StepLog[]>([])
const loading = ref(false)
const error = ref('')
const showForm = ref(false)
const editingId = ref<number | null>(null)

const summary = reactive<{
  today: SummaryBlock
  weekly: SummaryBlock
  monthly: SummaryBlock
  all_time: SummaryBlock
}>({
  today: { steps: 0, kilometers: 0, calories_burned: 0 },
  weekly: { steps: 0, kilometers: 0, calories_burned: 0 },
  monthly: { steps: 0, kilometers: 0, calories_burned: 0 },
  all_time: { steps: 0, kilometers: 0, calories_burned: 0 },
})

const form = reactive({
  log_date: new Date().toISOString().slice(0, 10),
  steps: 0,
  kilometers: 0,
  calories_burned: 0,
  source: 'manual',
  notes: '',
})

function getToken(): string {
  return localStorage.getItem('token')
    || localStorage.getItem('access_token')
    || localStorage.getItem('auth_token')
    || ''
}

async function apiFetch(path: string, options: RequestInit = {}) {
  const token = getToken()

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  })

  const payload = await response.json().catch(() => ({}))

  if (!response.ok) {
    throw new Error(payload.message || 'Request failed')
  }

  return payload
}

async function loadSummary() {
  const payload = await apiFetch('/health/steps/summary')
  Object.assign(summary, payload.data || {})
}

async function loadLogs() {
  const payload = await apiFetch('/health/steps')
  logs.value = payload.data?.data || payload.data || []
}

async function loadData() {
  loading.value = true
  error.value = ''

  try {
    await Promise.all([loadSummary(), loadLogs()])
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to load steps data'
  } finally {
    loading.value = false
  }
}

function openCreateForm() {
  resetForm()
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  resetForm()
}

function resetForm() {
  editingId.value = null
  form.log_date = new Date().toISOString().slice(0, 10)
  form.steps = 0
  form.kilometers = 0
  form.calories_burned = 0
  form.source = 'manual'
  form.notes = ''
}

function editLog(log: StepLog) {
  editingId.value = log.id
  form.log_date = String(log.log_date).slice(0, 10)
  form.steps = Number(log.steps || 0)
  form.kilometers = Number(log.kilometers || 0)
  form.calories_burned = Number(log.calories_burned || 0)
  form.source = log.source || 'manual'
  form.notes = log.notes || ''
  showForm.value = true
}

async function saveLog() {
  loading.value = true
  error.value = ''

  const payload = {
    log_date: form.log_date,
    steps: Number(form.steps || 0),
    kilometers: Number(form.kilometers || 0),
    calories_burned: Number(form.calories_burned || 0),
    source: form.source || 'manual',
    notes: form.notes || null,
  }

  try {
    if (editingId.value) {
      await apiFetch(`/health/steps/${editingId.value}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      })
    } else {
      await apiFetch('/health/steps', {
        method: 'POST',
        body: JSON.stringify(payload),
      })
    }

    closeForm()
    await loadData()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to save steps log'
  } finally {
    loading.value = false
  }
}

async function deleteLog(id: number) {
  const confirmed = window.confirm('Delete this steps log?')
  if (!confirmed) return

  loading.value = true
  error.value = ''

  try {
    await apiFetch(`/health/steps/${id}`, {
      method: 'DELETE',
    })

    await loadData()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to delete steps log'
  } finally {
    loading.value = false
  }
}

function formatNumber(value: number | string | null | undefined): string {
  return Number(value || 0).toLocaleString()
}

function formatKm(value: number | string | null | undefined): string {
  return `${Number(value || 0).toFixed(2)} km`
}

function formatDate(value: string): string {
  return String(value).slice(0, 10)
}

onMounted(loadData)
</script>

<style scoped>
.steps-page {
  padding: 24px;
}

.page-header,
.table-header,
.form-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
}

.page-header h1,
.form-header h2,
.table-header h2 {
  margin: 0;
}

.page-header p {
  margin: 6px 0 0;
  color: #64748b;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.summary-card,
.form-card,
.table-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.06);
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
  color: #0f172a;
  font-size: 28px;
}

.form-card,
.table-card {
  padding: 20px;
  margin-bottom: 24px;
}

.steps-form {
  display: grid;
  grid-template-columns: repeat(3, minmax(180px, 1fr));
  gap: 16px;
}

.steps-form label {
  display: flex;
  flex-direction: column;
  gap: 8px;
  color: #334155;
  font-weight: 600;
}

.steps-form input,
.steps-form textarea {
  border: 1px solid #cbd5e1;
  border-radius: 12px;
  padding: 10px 12px;
  font: inherit;
}

.full-width {
  grid-column: 1 / -1;
}

.form-actions {
  display: flex;
  gap: 10px;
  align-items: center;
}

.primary-btn,
.secondary-btn,
.ghost-btn,
.small-btn,
.danger-btn {
  border: 0;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 700;
  padding: 10px 14px;
}

.primary-btn {
  background: #2563eb;
  color: #ffffff;
}

.secondary-btn {
  background: #e2e8f0;
  color: #0f172a;
}

.ghost-btn {
  background: transparent;
  color: #475569;
}

.small-btn {
  background: #dbeafe;
  color: #1d4ed8;
  padding: 8px 10px;
}

.danger-btn {
  background: #fee2e2;
  color: #b91c1c;
  padding: 8px 10px;
}

.error-message {
  background: #fee2e2;
  color: #991b1b;
  border-radius: 12px;
  padding: 12px;
}

.loading-message,
.empty-state {
  color: #64748b;
  text-align: center;
  padding: 20px;
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
}

th {
  color: #475569;
  font-size: 13px;
  text-transform: uppercase;
}

.actions {
  display: flex;
  gap: 8px;
}

.actions-col {
  width: 150px;
}

@media (max-width: 900px) {
  .summary-grid,
  .steps-form {
    grid-template-columns: 1fr;
  }

  .page-header,
  .table-header,
  .form-header {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>

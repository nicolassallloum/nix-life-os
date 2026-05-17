<template>
  <div class="steps-page">
    <div class="page-header">
      <div>
        <h1>Steps Tracking</h1>
        <p>Track your daily steps, distance, and activity progress.</p>
      </div>

      <button class="refresh-btn" type="button" @click="loadStepLogs">
        Refresh
      </button>
    </div>

    <div v-if="errorMessage" class="alert alert-error">
      {{ errorMessage }}
    </div>

    <div v-if="successMessage" class="alert alert-success">
      {{ successMessage }}
    </div>

    <section class="stats-grid">
      <div class="stat-card">
        <span>Today Steps</span>
        <strong>{{ todaySteps.toLocaleString() }}</strong>
      </div>

      <div class="stat-card">
        <span>Goal</span>
        <strong>{{ todayGoal.toLocaleString() }}</strong>
      </div>

      <div class="stat-card">
        <span>Progress</span>
        <strong>{{ todayProgress }}%</strong>
      </div>

      <div class="stat-card">
        <span>Total Records</span>
        <strong>{{ stepLogs.length }}</strong>
      </div>
    </section>

    <section class="panel">
      <div class="panel-header">
        <div>
          <h2>{{ isEditing ? 'Edit Step Log' : 'Add Step Log' }}</h2>
          <p>
            {{ isEditing ? 'Update your selected step record.' : 'Record your steps for a selected date.' }}
          </p>
        </div>

        <button
          v-if="isEditing"
          class="secondary-btn"
          type="button"
          @click="resetForm"
        >
          Cancel Edit
        </button>
      </div>

      <form class="steps-form" @submit.prevent="saveStepLog">
        <div class="form-group">
          <label for="log_date">Date</label>
          <input
            id="log_date"
            v-model="form.log_date"
            type="date"
            required
          />
        </div>

        <div class="form-group">
          <label for="steps_count">Steps</label>
          <input
            id="steps_count"
            v-model.number="form.steps_count"
            type="number"
            min="0"
            max="200000"
            placeholder="Example: 8500"
            required
          />
        </div>

        <div class="form-group wide">
          <label for="notes">Notes</label>
          <input
            id="notes"
            v-model="form.notes"
            type="text"
            maxlength="1000"
            placeholder="Optional notes"
          />
        </div>

        <div class="form-actions">
          <button class="primary-btn" type="submit" :disabled="loading">
            {{ loading ? 'Saving...' : isEditing ? 'Update Steps' : 'Save Steps' }}
          </button>
        </div>
      </form>
    </section>

    <section class="panel">
      <div class="panel-header">
        <div>
          <h2>Recent Step Logs</h2>
          <p>Latest health activity records.</p>
        </div>

        <button class="link-btn" type="button" @click="loadStepLogs">
          Refresh
        </button>
      </div>

      <div v-if="loadingLogs" class="empty-state">
        Loading step logs...
      </div>

      <div v-else-if="stepLogs.length === 0" class="empty-state">
        No step logs found.
      </div>

      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Steps</th>
              <th>Distance KM</th>
              <th>Goal</th>
              <th>Progress</th>
              <th>Status</th>
              <th>Notes</th>
              <th class="actions-col">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr v-for="log in stepLogs" :key="log.id">
              <td>{{ formatDate(log.log_date) }}</td>
              <td>{{ Number(log.steps_count || 0).toLocaleString() }}</td>
              <td>{{ formatNumber(log.distance_km) }}</td>
              <td>{{ Number(log.goal_steps || 0).toLocaleString() }}</td>
              <td>{{ formatNumber(log.goal_percentage) }}%</td>
              <td>
                <span
                  class="badge"
                  :class="log.goal_completed ? 'badge-success' : 'badge-warning'"
                >
                  {{ log.goal_completed ? 'Completed' : 'In Progress' }}
                </span>
              </td>
              <td>{{ log.notes || '-' }}</td>
              <td class="actions">
                <button class="edit-btn" type="button" @click="editLog(log)">
                  Edit
                </button>

                <button class="delete-btn" type="button" @click="deleteLog(log.id)">
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  'http://127.0.0.1:8000/api/v1'

const loading = ref(false)
const loadingLogs = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const stepLogs = ref([])
const editingId = ref(null)

const form = reactive({
  log_date: new Date().toISOString().slice(0, 10),
  steps_count: '',
  notes: '',
})

const isEditing = computed(() => Boolean(editingId.value))

const todayLog = computed(() => {
  const today = new Date().toISOString().slice(0, 10)

  return stepLogs.value.find((log) => {
    return formatDate(log.log_date) === today
  })
})

const todaySteps = computed(() => Number(todayLog.value?.steps_count || 0))
const todayGoal = computed(() => Number(todayLog.value?.goal_steps || 10000))
const todayProgress = computed(() => {
  const value = Number(todayLog.value?.goal_percentage || 0)
  return Number.isFinite(value) ? value.toFixed(0) : 0
})

onMounted(() => {
  loadStepLogs()
})

function getToken() {
  return (
    localStorage.getItem('token') ||
    localStorage.getItem('auth_token') ||
    localStorage.getItem('access_token') ||
    localStorage.getItem('nix_token') ||
    sessionStorage.getItem('token') ||
    sessionStorage.getItem('auth_token') ||
    sessionStorage.getItem('access_token') ||
    ''
  )
}

async function apiRequest(endpoint, options = {}) {
  const token = getToken()

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  })

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const validationMessage = getValidationMessage(data)

    throw new Error(
      validationMessage ||
        data.message ||
        `Request failed with status ${response.status}`
    )
  }

  return data
}

function getValidationMessage(data) {
  if (!data?.errors) return ''

  const firstError = Object.values(data.errors)?.[0]

  if (Array.isArray(firstError)) {
    return firstError[0]
  }

  return typeof firstError === 'string' ? firstError : ''
}

async function loadStepLogs() {
  loadingLogs.value = true
  errorMessage.value = ''

  try {
    const response = await apiRequest('/health/steps')

    stepLogs.value = Array.isArray(response.data) ? response.data : []
  } catch (error) {
    errorMessage.value = error.message || 'Failed to load step logs.'
  } finally {
    loadingLogs.value = false
  }
}

async function saveStepLog() {
  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    if (!form.steps_count && form.steps_count !== 0) {
      errorMessage.value = 'The steps count field is required.'
      return
    }

    if (!form.log_date) {
      errorMessage.value = 'The log date field is required.'
      return
    }

    const payload = {
      steps_count: Number(form.steps_count),
      log_date: form.log_date,
      notes: form.notes || null,
    }

    if (isEditing.value) {
      await apiRequest(`/health/steps/${editingId.value}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      })

      successMessage.value = 'Step log updated successfully.'
    } else {
      await apiRequest('/health/steps', {
        method: 'POST',
        body: JSON.stringify(payload),
      })

      successMessage.value = 'Step log saved successfully.'
    }

    resetForm()
    await loadStepLogs()
  } catch (error) {
    errorMessage.value = error.message || 'Failed to save step log.'
  } finally {
    loading.value = false
  }
}

function editLog(log) {
  editingId.value = log.id
  form.log_date = formatDate(log.log_date)
  form.steps_count = Number(log.steps_count || 0)
  form.notes = log.notes || ''

  window.scrollTo({
    top: 0,
    behavior: 'smooth',
  })
}

async function deleteLog(id) {
  const confirmed = window.confirm('Are you sure you want to delete this step log?')

  if (!confirmed) return

  loading.value = true
  errorMessage.value = ''
  successMessage.value = ''

  try {
    await apiRequest(`/health/steps/${id}`, {
      method: 'DELETE',
    })

    successMessage.value = 'Step log deleted successfully.'

    if (editingId.value === id) {
      resetForm()
    }

    await loadStepLogs()
  } catch (error) {
    errorMessage.value = error.message || 'Failed to delete step log.'
  } finally {
    loading.value = false
  }
}

function resetForm() {
  editingId.value = null
  form.log_date = new Date().toISOString().slice(0, 10)
  form.steps_count = ''
  form.notes = ''
}

function formatDate(value) {
  if (!value) return '-'

  if (typeof value === 'string') {
    return value.slice(0, 10)
  }

  return new Date(value).toISOString().slice(0, 10)
}

function formatNumber(value) {
  const number = Number(value || 0)

  if (!Number.isFinite(number)) {
    return '0'
  }

  return number.toFixed(2)
}
</script>

<style scoped>
.steps-page {
  width: 100%;
  padding: 24px;
  color: #111827;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 20px;
}

.page-header h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 800;
  color: #0f172a;
}

.page-header p {
  margin: 4px 0 0;
  font-size: 14px;
  color: #475569;
}

.alert {
  width: 100%;
  padding: 12px 16px;
  margin-bottom: 16px;
  border-radius: 10px;
  font-size: 14px;
  font-weight: 600;
}

.alert-error {
  color: #991b1b;
  background: #fef2f2;
  border: 1px solid #fecaca;
}

.alert-success {
  color: #166534;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(160px, 1fr));
  gap: 14px;
  margin-bottom: 20px;
}

.stat-card {
  padding: 18px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 14px;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.04);
}

.stat-card span {
  display: block;
  margin-bottom: 10px;
  font-size: 13px;
  color: #64748b;
}

.stat-card strong {
  font-size: 24px;
  font-weight: 800;
  color: #0f172a;
}

.panel {
  padding: 20px;
  margin-bottom: 22px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 16px;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.04);
}

.panel-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 18px;
}

.panel-header h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 800;
  color: #0f172a;
}

.panel-header p {
  margin: 4px 0 0;
  font-size: 13px;
  color: #64748b;
}

.steps-form {
  display: grid;
  grid-template-columns: 1fr 1fr 2fr;
  gap: 14px;
  align-items: end;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 7px;
}

.form-group label {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

.form-group input {
  width: 100%;
  height: 42px;
  padding: 0 12px;
  font-size: 14px;
  color: #0f172a;
  background: #ffffff;
  border: 1px solid #cbd5e1;
  border-radius: 10px;
  outline: none;
}

.form-group input:focus {
  border-color: #4f46e5;
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.12);
}

.form-actions {
  grid-column: 1 / -1;
  display: flex;
  gap: 10px;
}

.primary-btn,
.secondary-btn,
.refresh-btn,
.edit-btn,
.delete-btn,
.link-btn {
  border: none;
  cursor: pointer;
  font-weight: 700;
  transition: all 0.2s ease;
}

.primary-btn {
  height: 42px;
  padding: 0 18px;
  color: #ffffff;
  background: #4f46e5;
  border-radius: 10px;
}

.primary-btn:hover {
  background: #4338ca;
}

.primary-btn:disabled {
  cursor: not-allowed;
  opacity: 0.65;
}

.secondary-btn {
  height: 38px;
  padding: 0 14px;
  color: #334155;
  background: #f1f5f9;
  border-radius: 10px;
}

.refresh-btn {
  height: 38px;
  padding: 0 14px;
  color: #ffffff;
  background: #0f172a;
  border-radius: 10px;
}

.link-btn {
  color: #4f46e5;
  background: transparent;
}

.table-wrap {
  width: 100%;
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead th {
  padding: 12px 10px;
  font-size: 12px;
  font-weight: 800;
  color: #475569;
  text-align: left;
  border-bottom: 1px solid #e5e7eb;
}

tbody td {
  padding: 13px 10px;
  font-size: 13px;
  color: #0f172a;
  border-bottom: 1px solid #f1f5f9;
}

tbody tr:hover {
  background: #f8fafc;
}

.actions-col {
  width: 160px;
}

.actions {
  display: flex;
  gap: 8px;
}

.edit-btn {
  padding: 7px 10px;
  color: #1d4ed8;
  background: #dbeafe;
  border-radius: 8px;
}

.delete-btn {
  padding: 7px 10px;
  color: #b91c1c;
  background: #fee2e2;
  border-radius: 8px;
}

.badge {
  display: inline-flex;
  align-items: center;
  padding: 5px 9px;
  font-size: 12px;
  font-weight: 800;
  border-radius: 999px;
}

.badge-success {
  color: #166534;
  background: #dcfce7;
}

.badge-warning {
  color: #92400e;
  background: #fef3c7;
}

.empty-state {
  padding: 28px;
  color: #64748b;
  text-align: center;
  background: #f8fafc;
  border: 1px dashed #cbd5e1;
  border-radius: 12px;
}

@media (max-width: 1100px) {
  .stats-grid {
    grid-template-columns: repeat(2, minmax(160px, 1fr));
  }

  .steps-form {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .steps-page {
    padding: 16px;
  }

  .page-header,
  .panel-header {
    flex-direction: column;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .actions {
    flex-direction: column;
  }
}
</style>
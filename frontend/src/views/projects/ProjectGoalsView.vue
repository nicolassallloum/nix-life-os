<template>
  <div class="page project-goals-page">
    <RouterLink class="back-link" :to="projectId ? `/projects/${projectId}` : '/projects/list'">
      ← Back to Project
    </RouterLink>

    <div class="page-header">
      <div>
        <h1>Project Goals</h1>
        <p>Create goals with targets, module links, and automatic progress updates.</p>
      </div>

      <button class="primary-btn" type="button" @click="openGoalForm" :disabled="saving || !activeProjectId">
        Add Goal
      </button>
    </div>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <section v-if="!projectId" class="content-card selector-card">
      <label>
        Select Project
        <select v-model="selectedProjectId" @change="loadGoals">
          <option value="">Choose project</option>
          <option v-for="project in projects" :key="project.id" :value="project.id">
            {{ project.project_name }}
          </option>
        </select>
      </label>
    </section>

    <div class="cards-grid">
      <div class="summary-card">
        <h3>Total Goals</h3>
        <strong>{{ goals.length }}</strong>
      </div>
      <div class="summary-card">
        <h3>Active</h3>
        <strong>{{ activeGoals }}</strong>
      </div>
      <div class="summary-card">
        <h3>Completed</h3>
        <strong>{{ completedGoals }}</strong>
      </div>
      <div class="summary-card">
        <h3>Avg Progress</h3>
        <strong>{{ avgProgress }}%</strong>
      </div>
    </div>

    <section class="content-card">
      <div class="section-header">
        <div>
          <h2>Goals</h2>
          <p>Manual goals and goals linked to modules are shown here.</p>
        </div>

        <button class="secondary-btn" type="button" @click="loadGoals" :disabled="loading || !activeProjectId">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="empty-state">Loading goals...</div>
      <div v-else-if="!activeProjectId" class="empty-state">Select a project first.</div>
      <div v-else-if="goals.length === 0" class="empty-state">No goals yet. Click Add Goal to create one.</div>

      <article v-for="goal in goals" :key="goal.id" class="goal-card">
        <div class="goal-main">
          <div>
            <h3>{{ goal.title }}</h3>
            <p>{{ goal.description || 'No description.' }}</p>
          </div>

          <div class="goal-meta">
            <span class="badge">{{ formatStatus(goal.status) }}</span>
            <span class="badge priority">{{ formatStatus(goal.priority) }}</span>
            <strong>{{ Number(goal.progress_percentage || 0).toFixed(0) }}%</strong>
          </div>
        </div>

        <div class="goal-details-grid">
          <span>Target: <strong>{{ formatNumber(goal.target_value) }} {{ goal.unit || '' }}</strong></span>
          <span>Current: <strong>{{ formatNumber(goal.current_value) }} {{ goal.unit || '' }}</strong></span>
          <span>Linked Module: <strong>{{ formatLinkedModule(goal.linked_module) }}</strong></span>
          <span>Metric: <strong>{{ formatStatus(goal.linked_metric || 'manual') }}</strong></span>
          <span>Start: <strong>{{ goal.start_date || '—' }}</strong></span>
          <span>Due: <strong>{{ goal.due_date || '—' }}</strong></span>
        </div>

        <div class="progress-bar">
          <div :style="{ width: `${Math.min(100, Number(goal.progress_percentage || 0))}%` }"></div>
        </div>

        <div class="actions">
          <button
            class="small-btn"
            type="button"
            @click="refreshGoal(goal.id)"
            :disabled="savingGoalId === goal.id || !goal.linked_module"
          >
            {{ savingGoalId === goal.id ? 'Syncing...' : 'Sync Progress' }}
          </button>

          <button
            class="danger-btn"
            type="button"
            @click="removeGoal(goal.id)"
            :disabled="savingGoalId === goal.id"
          >
            Delete
          </button>
        </div>
      </article>
    </section>

    <div v-if="showGoalForm" class="modal-backdrop" @click.self="closeGoalForm">
      <form class="modal-card" @submit.prevent="saveGoal">
        <div class="modal-header">
          <div>
            <h2>Create Goal</h2>
            <p>Enter the goal, target, and optional module link.</p>
          </div>

          <button class="icon-btn" type="button" @click="closeGoalForm">×</button>
        </div>

        <div class="form-grid">
          <label class="full">
            Goal Name
            <input v-model.trim="goalForm.title" type="text" placeholder="Example: Walk 1000 KM" required />
          </label>

          <label>
            Target
            <input v-model.number="goalForm.target_value" type="number" min="0" step="0.001" placeholder="Example: 1000" />
          </label>

          <label>
            Unit
            <input v-model.trim="goalForm.unit" type="text" placeholder="km, steps, %, points" />
          </label>

          <label>
            Linked Module
            <select v-model="goalForm.linked_module">
              <option value="manual">Manual Progress</option>
              <option value="health_steps">Steps Module</option>
            </select>
          </label>

          <label>
            Linked Metric
            <select v-model="goalForm.linked_metric" :disabled="goalForm.linked_module === 'manual'">
              <option value="manual">Manual</option>
              <option value="kilometers">Distance KM</option>
              <option value="steps">Steps Count</option>
            </select>
          </label>

          <label v-if="goalForm.linked_module === 'manual'">
            Current Value
            <input v-model.number="goalForm.current_value" type="number" min="0" step="0.001" placeholder="Example: 0" />
          </label>

          <label>
            Priority
            <select v-model="goalForm.priority">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="critical">Critical</option>
            </select>
          </label>

          <label>
            Status
            <select v-model="goalForm.status">
              <option value="not_started">Not Started</option>
              <option value="in_progress">In Progress</option>
              <option value="on_hold">On Hold</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </label>

          <label>
            Start Date
            <input v-model="goalForm.start_date" type="date" />
          </label>

          <label>
            Due Date
            <input v-model="goalForm.due_date" type="date" />
          </label>

          <label class="full">
            Description
            <textarea v-model.trim="goalForm.description" rows="3" placeholder="Optional notes about this goal"></textarea>
          </label>
        </div>

        <div class="modal-actions">
          <button class="secondary-btn" type="button" @click="closeGoalForm" :disabled="saving">Cancel</button>
          <button class="primary-btn" type="submit" :disabled="saving || !activeProjectId">
            {{ saving ? 'Saving...' : 'Save Goal' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { computed, onMounted, ref, watch } from 'vue'
import {
  createProjectGoal,
  deleteProjectGoal,
  getProjectGoals,
  getProjects,
  normalizeList,
  recalculateProjectGoal,
} from '@/services/projectService'

const route = useRoute()
const projectId = route.params.id ? String(route.params.id) : ''

const projects = ref<any[]>([])
const goals = ref<any[]>([])
const selectedProjectId = ref(projectId)
const loading = ref(false)
const saving = ref(false)
const savingGoalId = ref('')
const showGoalForm = ref(false)
const errorMessage = ref('')

const today = new Date().toISOString().slice(0, 10)

const goalForm = ref({
  title: '',
  description: '',
  target_value: 0,
  current_value: 0,
  unit: 'km',
  linked_module: 'manual',
  linked_metric: 'manual',
  status: 'not_started',
  priority: 'medium',
  start_date: today,
  due_date: '',
})

const activeProjectId = computed(() => projectId || selectedProjectId.value)

const activeGoals = computed(() => goals.value.filter((goal) => goal.status !== 'completed').length)
const completedGoals = computed(() => goals.value.filter((goal) => goal.status === 'completed').length)
const avgProgress = computed(() => {
  if (!goals.value.length) return 0
  return Math.round(goals.value.reduce((sum, goal) => sum + Number(goal.progress_percentage || 0), 0) / goals.value.length)
})

watch(
  () => goalForm.value.linked_module,
  (value) => {
    if (value === 'manual') {
      goalForm.value.linked_metric = 'manual'
    } else if (goalForm.value.linked_metric === 'manual') {
      goalForm.value.linked_metric = 'kilometers'
    }
  },
)

function resetGoalForm() {
  goalForm.value = {
    title: '',
    description: '',
    target_value: 0,
    current_value: 0,
    unit: 'km',
    linked_module: 'manual',
    linked_metric: 'manual',
    status: 'not_started',
    priority: 'medium',
    start_date: today,
    due_date: '',
  }
}

function openGoalForm() {
  resetGoalForm()
  showGoalForm.value = true
}

function closeGoalForm() {
  if (saving.value) return
  showGoalForm.value = false
}

function formatStatus(value: string) {
  return String(value || 'unknown').replaceAll('_', ' ')
}

function formatLinkedModule(value: string) {
  if (!value) return 'Manual'
  if (value === 'health_steps') return 'Steps Module'
  return formatStatus(value)
}

function formatNumber(value: any) {
  const numberValue = Number(value || 0)
  if (Number.isInteger(numberValue)) return numberValue.toString()
  return numberValue.toFixed(2)
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 })
  projects.value = normalizeList(response)

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id
  }
}

async function loadGoals() {
  if (!activeProjectId.value) return

  loading.value = true
  errorMessage.value = ''

  try {
    const response = await getProjectGoals(activeProjectId.value)
    goals.value = normalizeList(response)
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to load project goals.'
  } finally {
    loading.value = false
  }
}

async function saveGoal() {
  if (!activeProjectId.value) return

  saving.value = true
  errorMessage.value = ''

  try {
    await createProjectGoal(activeProjectId.value, {
      title: goalForm.value.title,
      description: goalForm.value.description || null,
      target_value: Number(goalForm.value.target_value || 0),
      current_value: goalForm.value.linked_module === 'manual' ? Number(goalForm.value.current_value || 0) : 0,
      unit: goalForm.value.unit || null,
      linked_module: goalForm.value.linked_module,
      linked_metric: goalForm.value.linked_metric,
      status: goalForm.value.status,
      priority: goalForm.value.priority,
      start_date: goalForm.value.start_date || null,
      due_date: goalForm.value.due_date || null,
    })

    showGoalForm.value = false
    resetGoalForm()
    await loadGoals()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to create goal.'
  } finally {
    saving.value = false
  }
}

async function refreshGoal(goalId: string) {
  if (!activeProjectId.value || !goalId) return

  savingGoalId.value = goalId
  errorMessage.value = ''

  try {
    await recalculateProjectGoal(activeProjectId.value, goalId)
    await loadGoals()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to sync goal progress.'
  } finally {
    savingGoalId.value = ''
  }
}

async function removeGoal(goalId: string) {
  if (!activeProjectId.value || !goalId) return
  if (!window.confirm('Delete this goal?')) return

  savingGoalId.value = goalId
  errorMessage.value = ''

  try {
    await deleteProjectGoal(activeProjectId.value, goalId)
    await loadGoals()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || error?.message || 'Failed to delete goal.'
  } finally {
    savingGoalId.value = ''
  }
}

onMounted(async () => {
  if (!projectId) {
    await loadProjects()
  }

  await loadGoals()
})
</script>

<style scoped>
.page {
  min-height: 100vh;
  padding: 24px;
  color: #e5e7eb;
}

.back-link {
  display: inline-block;
  margin-bottom: 16px;
  color: #93c5fd;
  font-weight: 800;
  text-decoration: none;
}

.page-header,
.section-header,
.goal-main,
.actions,
.modal-header,
.modal-actions {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  align-items: center;
}

.page-header {
  margin-bottom: 24px;
}

.page-header h1,
.section-header h2,
.modal-header h2,
.goal-card h3 {
  margin: 0;
  color: #f8fafc;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 900;
}

.page-header p,
.section-header p,
.goal-card p {
  color: #94a3b8;
}

.primary-btn,
.secondary-btn,
.small-btn,
.danger-btn,
.icon-btn {
  border: none;
  padding: 10px 16px;
  border-radius: 12px;
  font-weight: 800;
  cursor: pointer;
}

.primary-btn {
  background: #2563eb;
  color: #ffffff;
}

.secondary-btn,
.small-btn,
.icon-btn {
  background: #1e293b;
  color: #e5e7eb;
  border: 1px solid #334155;
}

.danger-btn {
  background: #7f1d1d;
  color: #fee2e2;
}

button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

.summary-card,
.content-card,
.goal-card,
.modal-card {
  background: #0f172a;
  border: 1px solid #334155;
  border-radius: 18px;
  padding: 20px;
  box-shadow: 0 16px 40px rgba(0, 0, 0, 0.24);
}

.summary-card h3 {
  margin: 0 0 8px;
  color: #94a3b8;
  font-size: 13px;
}

.summary-card strong {
  font-size: 28px;
  color: #f8fafc;
}

.selector-card {
  margin-bottom: 20px;
}

.selector-card label,
.form-grid label {
  display: grid;
  gap: 8px;
  color: #cbd5e1;
  font-weight: 800;
}

.goal-card {
  margin-top: 14px;
}

.goal-meta,
.goal-details-grid {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
}

.goal-details-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(160px, 1fr));
  margin-top: 16px;
  color: #cbd5e1;
}

.goal-details-grid strong {
  color: #f8fafc;
}

.badge {
  background: #312e81;
  color: #c7d2fe;
  border-radius: 999px;
  padding: 5px 10px;
  font-size: 12px;
  font-weight: 800;
  text-transform: capitalize;
}

.priority {
  background: #164e63;
  color: #a5f3fc;
}

.progress-bar {
  height: 10px;
  background: #1e293b;
  border-radius: 999px;
  overflow: hidden;
  margin-top: 14px;
}

.progress-bar div {
  height: 100%;
  background: #2563eb;
}

.empty-state {
  padding: 18px;
  border-radius: 14px;
  background: #111827;
  color: #94a3b8;
  border: 1px dashed #334155;
}

.alert.error {
  margin-bottom: 16px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #7f1d1d;
  color: #fee2e2;
  border: 1px solid #b91c1c;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 80;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(2, 6, 23, 0.75);
}

.modal-card {
  width: min(880px, 100%);
  max-height: 92vh;
  overflow: auto;
}

.icon-btn {
  width: 40px;
  height: 40px;
  padding: 0;
  font-size: 26px;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(220px, 1fr));
  gap: 16px;
  margin-top: 18px;
}

.form-grid .full {
  grid-column: 1 / -1;
}

.form-grid input,
.form-grid select,
.form-grid textarea,
.selector-card select {
  width: 100%;
  border: 1px solid #334155;
  border-radius: 12px;
  padding: 11px 12px;
  color: #f8fafc !important;
  background: #111827 !important;
}

.form-grid select option,
.selector-card select option {
  color: #f8fafc !important;
  background: #111827 !important;
}

.form-grid input::placeholder,
.form-grid textarea::placeholder {
  color: #64748b;
}

.modal-actions {
  justify-content: flex-end;
  margin-top: 20px;
}

@media (max-width: 900px) {
  .cards-grid,
  .goal-details-grid,
  .form-grid {
    grid-template-columns: 1fr;
  }

  .page-header,
  .section-header,
  .goal-main,
  .modal-header,
  .modal-actions {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>

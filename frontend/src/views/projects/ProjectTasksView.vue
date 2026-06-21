<template>
  <div class="page">
    <RouterLink class="back-link" :to="projectId ? `/projects/${projectId}` : '/projects/list'">
      ← Back to Project
    </RouterLink>

    <div class="page-header">
      <div>
        <h1>Project Tasks</h1>
        <p>Create tasks and task steps, then automatically update project progress.</p>
      </div>
      <button class="primary-btn" @click="createDemoTask" :disabled="saving || !activeProjectId">
        {{ saving ? 'Creating...' : 'Add Task' }}
      </button>
    </div>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <section v-if="!projectId" class="content-card selector-card">
      <label>Select Project</label>
      <select v-model="selectedProjectId" @change="loadTasks">
        <option value="">Choose project</option>
        <option v-for="project in projects" :key="project.id" :value="project.id">
          {{ project.project_name }}
        </option>
      </select>
    </section>

    <div class="cards-grid">
      <div class="summary-card">
        <h3>Total Tasks</h3>
        <strong>{{ tasks.length }}</strong>
      </div>
      <div class="summary-card">
        <h3>Open</h3>
        <strong>{{ openTasks }}</strong>
      </div>
      <div class="summary-card">
        <h3>Done</h3>
        <strong>{{ doneTasks }}</strong>
      </div>
      <div class="summary-card">
        <h3>Avg Progress</h3>
        <strong>{{ avgProgress }}%</strong>
      </div>
    </div>

    <section class="content-card">
      <div class="section-header">
        <h2>Tasks</h2>
        <button class="secondary-btn" @click="loadTasks" :disabled="loading || !activeProjectId">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="empty-state">Loading tasks...</div>
      <div v-else-if="!activeProjectId" class="empty-state">Select a project first.</div>
      <div v-else-if="tasks.length === 0" class="empty-state">No tasks yet.</div>

      <article v-for="task in tasks" :key="task.id" class="task-card">
        <div class="task-main">
          <div>
            <h3>{{ task.task_title || task.title }}</h3>
            <p>{{ task.task_description || task.description || 'No description.' }}</p>
          </div>

          <div class="task-meta">
            <span class="badge">{{ task.status }}</span>
            <span class="badge priority">{{ task.priority }}</span>
            <strong>{{ Number(task.progress_percentage || 0).toFixed(0) }}%</strong>
          </div>
        </div>

        <div class="progress-bar">
          <div :style="{ width: `${Math.min(100, Number(task.progress_percentage || 0))}%` }"></div>
        </div>

        <div class="actions">
          <button
            v-if="!isTaskDone(task)"
            class="done-btn"
            @click="markTaskDone(task)"
            :disabled="savingDone === task.id"
          >
            {{ savingDone === task.id ? 'Saving...' : 'Done' }}
          </button>

          <button
            v-else
            class="small-btn"
            @click="reopenTask(task.id)"
            :disabled="savingStep === task.id"
          >
            {{ savingStep === task.id ? 'Saving...' : 'Reopen' }}
          </button>

          <button class="small-btn" @click="loadSteps(task.id)">View Steps</button>

          <button class="small-btn" @click="createDemoStep(task.id)" :disabled="savingStep === task.id">
            {{ savingStep === task.id ? 'Adding...' : 'Add Done Step' }}
          </button>
        </div>

        <div v-if="selectedTaskId === task.id" class="steps-panel">
          <h4>Task Steps</h4>
          <div v-if="steps.length === 0" class="empty-state compact">No steps yet.</div>
          <div v-for="step in steps" :key="step.id" class="line-item">
            <strong>{{ step.title }}</strong>
            <span>{{ step.status }} · {{ Number(step.progress_percentage || 0).toFixed(0) }}%</span>
          </div>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { computed, onMounted, ref } from 'vue'
import {
  createProjectTask,
  createProjectTaskStep,
  completeProjectTask,
  reopenProjectTask,
  getProjectTaskSteps,
  getProjectTasks,
  getProjects,
  updateProjectTask,
  normalizeList,
} from '@/services/projectService'

const route = useRoute()
const projectId = route.params.id ? String(route.params.id) : ''

const projects = ref<any[]>([])
const tasks = ref<any[]>([])
const steps = ref<any[]>([])
const selectedProjectId = ref(projectId)
const selectedTaskId = ref('')
const loading = ref(false)
const saving = ref(false)
const savingStep = ref('')
const savingDone = ref('')
const errorMessage = ref('')

const activeProjectId = computed(() => projectId || selectedProjectId.value)

const openTasks = computed(() => tasks.value.filter((task) => !isTaskDone(task)).length)
const doneTasks = computed(() => tasks.value.filter((task) => isTaskDone(task)).length)
const avgProgress = computed(() => {
  if (!tasks.value.length) return 0
  return Math.round(tasks.value.reduce((sum, task) => sum + Number(task.progress_percentage || 0), 0) / tasks.value.length)
})

function makeTimestamp() {
  return new Date()
    .toISOString()
    .slice(0, 19)
    .replaceAll('-', '')
    .replaceAll(':', '')
    .replaceAll('T', '')
}

async function loadProjects() {
  const response = await getProjects({ per_page: 100 })
  projects.value = normalizeList(response)

  if (!selectedProjectId.value && projects.value.length > 0) {
    selectedProjectId.value = projects.value[0].id
  }
}

async function loadTasks() {
  if (!activeProjectId.value) return

  loading.value = true
  errorMessage.value = ''

  try {
    const response = await getProjectTasks(activeProjectId.value)
    tasks.value = normalizeList(response)
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to load project tasks.'
  } finally {
    loading.value = false
  }
}

async function createDemoTask() {
  if (!activeProjectId.value) return

  saving.value = true
  errorMessage.value = ''

  try {
    const stamp = makeTimestamp()
    await createProjectTask(activeProjectId.value, {
      title: `New Project Task ${stamp}`,
      description: 'Created from the Project Tasks screen.',
      status: 'todo',
      priority: 'medium',
      due_date: new Date().toISOString().slice(0, 10),
    })
    await loadTasks()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to create task.'
  } finally {
    saving.value = false
  }
}


function isTaskDone(task: any) {
  return ['done', 'completed'].includes(String(task?.status || '').toLowerCase())
}

async function markTaskDone(task: any) {
  if (!activeProjectId.value || !task?.id) return

  savingDone.value = task.id
  errorMessage.value = ''

  try {
    await completeProjectTask(activeProjectId.value, task.id)
    await loadTasks()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to mark task as done.'
  } finally {
    savingDone.value = ''
  }
}

async function loadSteps(taskId: string) {
  if (!activeProjectId.value) return

  selectedTaskId.value = taskId
  const response = await getProjectTaskSteps(activeProjectId.value, taskId)
  steps.value = normalizeList(response)
}

async function reopenTask(taskId: string) {
  if (!activeProjectId.value) return

  savingStep.value = taskId
  errorMessage.value = ''

  try {
    await reopenProjectTask(activeProjectId.value, taskId)
    await loadTasks()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to reopen task.'
  } finally {
    savingStep.value = ''
  }
}

async function createDemoStep(taskId: string) {
  if (!activeProjectId.value) return

  savingStep.value = taskId
  errorMessage.value = ''

  try {
    const stamp = makeTimestamp()
    await createProjectTaskStep(activeProjectId.value, taskId, {
      title: `Completed Step ${stamp}`,
      description: 'Created from the Project Tasks screen.',
      status: 'done',
      due_date: new Date().toISOString().slice(0, 10),
    })

    await loadSteps(taskId)
    await loadTasks()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to create task step.'
  } finally {
    savingStep.value = ''
  }
}

onMounted(async () => {
  if (!projectId) {
    await loadProjects()
  }

  await loadTasks()
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
.task-main,
.actions,
.line-item {
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
.task-card h3,
.steps-panel h4 {
  margin: 0;
  color: #f8fafc;
}

.page-header h1 {
  font-size: 28px;
  font-weight: 900;
}

.page-header p,
.task-card p {
  color: #94a3b8;
}

.primary-btn,
.secondary-btn,
.small-btn,
.done-btn {
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

.done-btn {
  background: #16a34a;
  color: #ffffff;
}

.secondary-btn,
.small-btn {
  background: #1e293b;
  color: #e5e7eb;
  border: 1px solid #334155;
}

.done-btn:disabled,
.primary-btn:disabled,
.secondary-btn:disabled,
.small-btn:disabled {
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
.task-card {
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
  display: grid;
  gap: 8px;
}

.selector-card label {
  display: grid;
  gap: 8px;
  color: #cbd5e1;
  font-weight: 800;
}

.selector-card select {
  padding: 11px;
  border: 1px solid #334155;
  border-radius: 12px;
  color: #f8fafc !important;
  background: #111827 !important;
}

.selector-card select option {
  color: #f8fafc !important;
  background: #111827 !important;
}

.task-card {
  margin-top: 14px;
}

.task-meta {
  display: flex;
  gap: 8px;
  align-items: center;
  flex-wrap: wrap;
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
  margin: 14px 0;
}

.progress-bar div {
  height: 100%;
  background: #2563eb;
}

.steps-panel {
  margin-top: 14px;
  padding: 14px;
  border-radius: 14px;
  background: #111827;
  border: 1px solid #334155;
}

.line-item {
  padding: 10px 0;
  border-top: 1px solid #334155;
}

.line-item span {
  color: #94a3b8;
}

.empty-state {
  padding: 18px;
  border-radius: 14px;
  background: #111827;
  color: #94a3b8;
  border: 1px dashed #334155;
}

.compact {
  padding: 12px;
}

.alert.error {
  margin-bottom: 16px;
  padding: 12px 14px;
  border-radius: 12px;
  background: #7f1d1d;
  color: #fee2e2;
  border: 1px solid #b91c1c;
}

@media (max-width: 900px) {
  .cards-grid {
    grid-template-columns: 1fr;
  }

  .page-header,
  .section-header,
  .task-main,
  .line-item {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>

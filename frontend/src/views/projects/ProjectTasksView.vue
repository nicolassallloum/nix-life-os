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
  getProjectTaskSteps,
  getProjectTasks,
  getProjects,
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
const errorMessage = ref('')

const activeProjectId = computed(() => projectId || selectedProjectId.value)

const openTasks = computed(() => tasks.value.filter((task) => task.status !== 'done').length)
const doneTasks = computed(() => tasks.value.filter((task) => task.status === 'done').length)
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

async function loadSteps(taskId: string) {
  if (!activeProjectId.value) return

  selectedTaskId.value = taskId
  const response = await getProjectTaskSteps(activeProjectId.value, taskId)
  steps.value = normalizeList(response)
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
.page { padding: 24px; }
.back-link { display: inline-block; margin-bottom: 16px; color: #2563eb; font-weight: 700; text-decoration: none; }
.page-header, .section-header, .task-main, .actions, .line-item { display: flex; justify-content: space-between; gap: 16px; align-items: center; }
.page-header { margin-bottom: 24px; }
.page-header h1 { margin: 0; font-size: 28px; font-weight: 800; color: #111827; }
.page-header p, .task-card p { color: #6b7280; }
.primary-btn, .secondary-btn, .small-btn { border: none; padding: 10px 16px; border-radius: 12px; font-weight: 700; cursor: pointer; }
.primary-btn { background: #2563eb; color: white; }
.secondary-btn, .small-btn { background: #f3f4f6; color: #111827; }
.cards-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 20px; }
.summary-card, .content-card, .task-card { background: white; border: 1px solid #e5e7eb; border-radius: 18px; padding: 20px; box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06); }
.summary-card h3 { margin: 0 0 8px; color: #6b7280; font-size: 13px; }
.summary-card strong { font-size: 28px; color: #111827; }
.selector-card { margin-bottom: 20px; display: grid; gap: 8px; }
.selector-card select { padding: 11px; border: 1px solid #d1d5db; border-radius: 12px; }
.task-card { margin-top: 14px; }
.task-card h3 { margin: 0; }
.task-meta { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.badge { background: #eef2ff; color: #3730a3; border-radius: 999px; padding: 5px 10px; font-size: 12px; font-weight: 700; text-transform: capitalize; }
.priority { background: #ecfeff; color: #155e75; }
.progress-bar { height: 10px; background: #e5e7eb; border-radius: 999px; overflow: hidden; margin: 14px 0; }
.progress-bar div { height: 100%; background: #2563eb; }
.steps-panel { margin-top: 14px; padding: 14px; border-radius: 14px; background: #f8fafc; }
.line-item { padding: 10px 0; border-top: 1px solid #e5e7eb; }
.line-item span { color: #6b7280; }
.empty-state { padding: 18px; border-radius: 14px; background: #f8fafc; color: #64748b; }
.compact { padding: 12px; }
.alert.error { margin-bottom: 16px; padding: 12px 14px; border-radius: 12px; background: #fef2f2; color: #991b1b; }
@media (max-width: 900px) { .cards-grid { grid-template-columns: 1fr; } .page-header, .section-header, .task-main, .line-item { flex-direction: column; align-items: flex-start; } }
</style>

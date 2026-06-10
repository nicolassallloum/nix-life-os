<template>
  <div class="page">
    <RouterLink class="back-link" :to="projectId ? `/projects/${projectId}` : '/projects/list'">
      ← Back to Project
    </RouterLink>

    <div class="page-header">
      <div>
        <h1>Project Goals</h1>
        <p>Create and monitor project goals with priorities, due dates, and progress.</p>
      </div>
      <button class="primary-btn" @click="createDemoGoal" :disabled="saving || !activeProjectId">
        {{ saving ? 'Creating...' : 'Add Goal' }}
      </button>
    </div>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <section v-if="!projectId" class="content-card selector-card">
      <label>Select Project</label>
      <select v-model="selectedProjectId" @change="loadGoals">
        <option value="">Choose project</option>
        <option v-for="project in projects" :key="project.id" :value="project.id">
          {{ project.project_name }}
        </option>
      </select>
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
        <h2>Goals</h2>
        <button class="secondary-btn" @click="loadGoals" :disabled="loading || !activeProjectId">
          {{ loading ? 'Loading...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="empty-state">Loading goals...</div>
      <div v-else-if="!activeProjectId" class="empty-state">Select a project first.</div>
      <div v-else-if="goals.length === 0" class="empty-state">No goals yet.</div>

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

        <div class="date-row">
          <span>Start: {{ goal.start_date || '—' }}</span>
          <span>Due: {{ goal.due_date || '—' }}</span>
        </div>

        <div class="progress-bar">
          <div :style="{ width: `${Math.min(100, Number(goal.progress_percentage || 0))}%` }"></div>
        </div>
      </article>
    </section>
  </div>
</template>

<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { computed, onMounted, ref } from 'vue'
import { createProjectGoal, getProjectGoals, getProjects, normalizeList } from '@/services/projectService'

const route = useRoute()
const projectId = route.params.id ? String(route.params.id) : ''

const projects = ref<any[]>([])
const goals = ref<any[]>([])
const selectedProjectId = ref(projectId)
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref('')

const activeProjectId = computed(() => projectId || selectedProjectId.value)

const activeGoals = computed(() => goals.value.filter((goal) => goal.status !== 'completed').length)
const completedGoals = computed(() => goals.value.filter((goal) => goal.status === 'completed').length)
const avgProgress = computed(() => {
  if (!goals.value.length) return 0
  return Math.round(goals.value.reduce((sum, goal) => sum + Number(goal.progress_percentage || 0), 0) / goals.value.length)
})

function makeTimestamp() {
  return new Date()
    .toISOString()
    .slice(0, 19)
    .replaceAll('-', '')
    .replaceAll(':', '')
    .replaceAll('T', '')
}

function formatStatus(value: string) {
  return String(value || 'unknown').replaceAll('_', ' ')
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
    errorMessage.value = error?.response?.data?.message || 'Failed to load project goals.'
  } finally {
    loading.value = false
  }
}

async function createDemoGoal() {
  if (!activeProjectId.value) return

  saving.value = true
  errorMessage.value = ''

  try {
    const stamp = makeTimestamp()
    await createProjectGoal(activeProjectId.value, {
      title: `New Project Goal ${stamp}`,
      description: 'Created from the Project Goals screen.',
      status: 'in_progress',
      priority: 'medium',
      progress_percentage: 25,
      start_date: new Date().toISOString().slice(0, 10),
      due_date: new Date().toISOString().slice(0, 10),
    })
    await loadGoals()
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to create goal.'
  } finally {
    saving.value = false
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
.page { padding: 24px; }
.back-link { display: inline-block; margin-bottom: 16px; color: #2563eb; font-weight: 700; text-decoration: none; }
.page-header, .section-header, .goal-main, .date-row { display: flex; justify-content: space-between; gap: 16px; align-items: center; }
.page-header { margin-bottom: 24px; }
.page-header h1 { margin: 0; font-size: 28px; font-weight: 800; color: #111827; }
.page-header p, .goal-card p, .date-row { color: #6b7280; }
.primary-btn, .secondary-btn { border: none; padding: 10px 16px; border-radius: 12px; font-weight: 700; cursor: pointer; }
.primary-btn { background: #2563eb; color: white; }
.secondary-btn { background: #f3f4f6; color: #111827; }
.cards-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 20px; }
.summary-card, .content-card, .goal-card { background: white; border: 1px solid #e5e7eb; border-radius: 18px; padding: 20px; box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06); }
.summary-card h3 { margin: 0 0 8px; color: #6b7280; font-size: 13px; }
.summary-card strong { font-size: 28px; color: #111827; }
.selector-card { margin-bottom: 20px; display: grid; gap: 8px; }
.selector-card select { padding: 11px; border: 1px solid #d1d5db; border-radius: 12px; }
.goal-card { margin-top: 14px; }
.goal-card h3 { margin: 0; }
.goal-meta { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.badge { background: #eef2ff; color: #3730a3; border-radius: 999px; padding: 5px 10px; font-size: 12px; font-weight: 700; text-transform: capitalize; }
.priority { background: #ecfeff; color: #155e75; }
.progress-bar { height: 10px; background: #e5e7eb; border-radius: 999px; overflow: hidden; margin-top: 14px; }
.progress-bar div { height: 100%; background: #2563eb; }
.empty-state { padding: 18px; border-radius: 14px; background: #f8fafc; color: #64748b; }
.alert.error { margin-bottom: 16px; padding: 12px 14px; border-radius: 12px; background: #fef2f2; color: #991b1b; }
@media (max-width: 900px) { .cards-grid { grid-template-columns: 1fr; } .page-header, .section-header, .goal-main, .date-row { flex-direction: column; align-items: flex-start; } }
</style>

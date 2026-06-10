<template>
  <div class="page">
    <RouterLink class="back-link" to="/projects/list">← Back to Projects</RouterLink>

    <div v-if="errorMessage" class="alert error">{{ errorMessage }}</div>

    <section v-if="project" class="hero-card">
      <div>
        <h1>{{ project.project_name }}</h1>
        <p>{{ project.description || 'No description provided.' }}</p>
      </div>
      <div class="hero-meta">
        <span class="badge">{{ formatStatus(project.status) }}</span>
        <span class="badge priority">{{ formatStatus(project.priority) }}</span>
        <strong>{{ Number(project.progress_percentage || 0).toFixed(0) }}%</strong>
      </div>
    </section>

    <div class="cards-grid">
      <div class="summary-card">
        <h3>Start Date</h3>
        <strong>{{ project?.start_date || '—' }}</strong>
      </div>
      <div class="summary-card">
        <h3>Due Date</h3>
        <strong>{{ project?.target_end_date || '—' }}</strong>
      </div>
      <div class="summary-card">
        <h3>Tasks</h3>
        <strong>{{ tasks.length }}</strong>
      </div>
      <div class="summary-card">
        <h3>Goals</h3>
        <strong>{{ goals.length }}</strong>
      </div>
    </div>

    <div class="grid-two">
      <section class="content-card">
        <div class="section-header">
          <h2>Tasks</h2>
          <RouterLink class="small-btn" :to="`/projects/${projectId}/tasks`">Open Tasks</RouterLink>
        </div>
        <div v-if="tasks.length === 0" class="empty-state">No tasks yet.</div>
        <div v-for="task in tasks" :key="task.id" class="line-item">
          <strong>{{ task.task_title || task.title }}</strong>
          <span>{{ task.status }} · {{ Number(task.progress_percentage || 0).toFixed(0) }}%</span>
        </div>
      </section>

      <section class="content-card">
        <div class="section-header">
          <h2>Goals</h2>
          <RouterLink class="small-btn" :to="`/projects/${projectId}/goals`">Open Goals</RouterLink>
        </div>
        <div v-if="goals.length === 0" class="empty-state">No goals yet.</div>
        <div v-for="goal in goals" :key="goal.id" class="line-item">
          <strong>{{ goal.title }}</strong>
          <span>{{ goal.status }} · {{ Number(goal.progress_percentage || 0).toFixed(0) }}%</span>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { onMounted, ref } from 'vue'
import { getProject, getProjectGoals, getProjectTasks, normalizeList } from '@/services/projectService'

const route = useRoute()
const projectId = String(route.params.id)

const project = ref<any>(null)
const tasks = ref<any[]>([])
const goals = ref<any[]>([])
const errorMessage = ref('')

function formatStatus(value: string) {
  return String(value || 'unknown').replaceAll('_', ' ')
}

async function loadPage() {
  errorMessage.value = ''

  try {
    const [projectResponse, taskResponse, goalResponse] = await Promise.all([
      getProject(projectId),
      getProjectTasks(projectId),
      getProjectGoals(projectId),
    ])

    project.value = projectResponse.data
    tasks.value = normalizeList(taskResponse)
    goals.value = normalizeList(goalResponse)
  } catch (error: any) {
    errorMessage.value = error?.response?.data?.message || 'Failed to load project details.'
  }
}

onMounted(loadPage)
</script>

<style scoped>
.page { padding: 24px; }
.back-link, .small-btn { display: inline-block; margin-bottom: 16px; color: #2563eb; font-weight: 700; text-decoration: none; }
.hero-card, .summary-card, .content-card { background: white; border: 1px solid #e5e7eb; border-radius: 18px; padding: 20px; box-shadow: 0 8px 25px rgba(15, 23, 42, 0.06); }
.hero-card { display: flex; justify-content: space-between; gap: 16px; margin-bottom: 20px; }
.hero-card h1 { margin: 0; color: #111827; }
.hero-card p { color: #6b7280; }
.hero-meta { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.cards-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 20px; }
.summary-card h3 { margin: 0 0 8px; color: #6b7280; font-size: 13px; }
.summary-card strong { color: #111827; font-size: 20px; }
.grid-two { display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; }
.section-header { display: flex; justify-content: space-between; align-items: center; gap: 12px; }
.badge { background: #eef2ff; color: #3730a3; border-radius: 999px; padding: 5px 10px; font-size: 12px; font-weight: 700; text-transform: capitalize; }
.priority { background: #ecfeff; color: #155e75; }
.line-item { padding: 12px 0; border-top: 1px solid #e5e7eb; display: flex; justify-content: space-between; gap: 12px; }
.line-item span { color: #6b7280; }
.empty-state { padding: 18px; border-radius: 14px; background: #f8fafc; color: #64748b; }
.alert.error { margin-bottom: 16px; padding: 12px 14px; border-radius: 12px; background: #fef2f2; color: #991b1b; }
@media (max-width: 900px) { .cards-grid, .grid-two { grid-template-columns: 1fr; } .hero-card { flex-direction: column; } }
</style>

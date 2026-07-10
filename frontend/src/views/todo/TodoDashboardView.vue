<template>
  <div class="todo-page">
    <div class="todo-page__header">
      <div>
        <h1>To-Do Dashboard</h1>
        <p>Track task progress, project completion, schedules, and total points.</p>
      </div>

      <RouterLink to="/todo/tasks/create" class="todo-button todo-button--primary">
        Create Task
      </RouterLink>
    </div>

    <TodoNotification :type="notification.type" :message="notification.message" @dismiss="clearNotification" />

    <TodoLoadingState v-if="loading" message="Loading dashboard..." />

    <template v-else>
      <section class="todo-panel">
        <div class="todo-summary-grid">
          <article v-for="card in dashboardCards" :key="card.label" class="todo-summary-card">
            <span>{{ card.label }}</span>
            <strong>{{ card.value }}</strong>
          </article>
        </div>

        <TodoProgressBar
          :value="completionPercentage"
          label="Overall task completion"
          :meta="`${stats.finishedTasks} of ${stats.totalTasks} tasks finished`"
        />
      </section>

      <div class="todo-dashboard-grid">
        <section class="todo-panel">
          <div class="todo-panel__header">
            <div>
              <h2>Project Progress Summary</h2>
              <p>Active and completed project progress.</p>
            </div>

            <RouterLink to="/todo/projects" class="todo-link">View projects</RouterLink>
          </div>

          <TodoEmptyState
            v-if="projectSummaries.length === 0"
            title="No projects"
            message="No project progress data found yet."
          />

          <div v-else class="todo-project-list">
            <TodoProjectCard
              v-for="project in projectSummaries"
              :key="project.id"
              :project="project"
              :show-actions="false"
            />
          </div>
        </section>

        <section class="todo-panel">
          <div class="todo-panel__header">
            <div>
              <h2>Points Summary</h2>
              <p>Points earned from completed tasks.</p>
            </div>
          </div>

          <div class="todo-points-card">
            <span>Total Points</span>
            <strong>{{ stats.totalPoints }}</strong>
          </div>

          <TodoProgressBar
            :value="pointsProgress"
            label="Points pace"
            :meta="`${stats.totalPoints} earned points`"
            tone="success"
          />

          <div class="todo-points-list">
            <div><span>Monthly Tasks</span><strong>{{ stats.monthlyTasks }}</strong></div>
            <div><span>Weekly Tasks</span><strong>{{ stats.weeklyTasks }}</strong></div>
            <div><span>Daily Tasks</span><strong>{{ stats.dailyTasks }}</strong></div>
            <div><span>General Tasks</span><strong>{{ stats.generalTasks }}</strong></div>
          </div>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/services/api'
import TodoEmptyState from '@/components/todo/TodoEmptyState.vue'
import TodoLoadingState from '@/components/todo/TodoLoadingState.vue'
import TodoNotification from '@/components/todo/TodoNotification.vue'
import TodoProgressBar from '@/components/todo/TodoProgressBar.vue'
import TodoProjectCard from '@/components/todo/TodoProjectCard.vue'
import {
  clampPercentage,
  getApiMessage,
  normalizeProjectStatus,
  numberValue,
  type TodoProjectLike,
} from '@/components/todo/todoUtils'

type TodoDashboardStats = {
  totalTasks: number
  finishedTasks: number
  pendingTasks: number
  inProgressTasks: number
  completionPercentage: number
  totalPoints: number
  monthlyTasks: number
  weeklyTasks: number
  dailyTasks: number
  generalTasks: number
  activeProjects: number
  completedProjects: number
}

const loading = ref(false)
const rawDashboard = ref<Record<string, any> | null>(null)
const notification = reactive<{ type: 'success' | 'error' | 'info'; message: string }>({
  type: 'info',
  message: '',
})

const defaultStats: TodoDashboardStats = {
  totalTasks: 0,
  finishedTasks: 0,
  pendingTasks: 0,
  inProgressTasks: 0,
  completionPercentage: 0,
  totalPoints: 0,
  monthlyTasks: 0,
  weeklyTasks: 0,
  dailyTasks: 0,
  generalTasks: 0,
  activeProjects: 0,
  completedProjects: 0,
}

const notify = (type: 'success' | 'error' | 'info', message: string) => {
  notification.type = type
  notification.message = message
}

const clearNotification = () => {
  notification.message = ''
}

const dashboardPayload = computed(() => {
  const payload = rawDashboard.value

  return payload?.data || payload?.dashboard || payload?.summary || payload || {}
})

const stats = computed<TodoDashboardStats>(() => {
  const payload: any = dashboardPayload.value
  const source = payload.stats || payload.summary || payload
  const totalTasks = numberValue(source.totalTasks ?? source.total_tasks)
  const finishedTasks = numberValue(source.finishedTasks ?? source.finished_tasks ?? source.completedTasks ?? source.completed_tasks)
  const calculatedPercentage = totalTasks > 0 ? (finishedTasks / totalTasks) * 100 : 0

  return {
    totalTasks,
    finishedTasks,
    pendingTasks: numberValue(source.pendingTasks ?? source.pending_tasks),
    inProgressTasks: numberValue(source.inProgressTasks ?? source.in_progress_tasks),
    completionPercentage: clampPercentage(source.completionPercentage ?? source.completion_percentage ?? calculatedPercentage),
    totalPoints: numberValue(source.totalPoints ?? source.total_points ?? source.points),
    monthlyTasks: numberValue(source.monthlyTasks ?? source.monthly_tasks),
    weeklyTasks: numberValue(source.weeklyTasks ?? source.weekly_tasks),
    dailyTasks: numberValue(source.dailyTasks ?? source.daily_tasks),
    generalTasks: numberValue(source.generalTasks ?? source.general_tasks),
    activeProjects: numberValue(source.activeProjects ?? source.active_projects),
    completedProjects: numberValue(source.completedProjects ?? source.completed_projects),
  }
})

const completionPercentage = computed(() => clampPercentage(stats.value.completionPercentage))
const pointsProgress = computed(() => clampPercentage(Math.min(stats.value.totalPoints, 100)))

const dashboardCards = computed(() => [
  { label: 'Total Tasks', value: stats.value.totalTasks },
  { label: 'Finished Tasks', value: stats.value.finishedTasks },
  { label: 'Pending Tasks', value: stats.value.pendingTasks },
  { label: 'In Progress', value: stats.value.inProgressTasks },
  { label: 'Completion', value: `${completionPercentage.value}%` },
  { label: 'Total Points', value: stats.value.totalPoints },
  { label: 'Active Projects', value: stats.value.activeProjects },
  { label: 'Completed Projects', value: stats.value.completedProjects },
])

const projectSummaries = computed<TodoProjectLike[]>(() => {
  const payload: any = dashboardPayload.value
  const projects = payload.projects || payload.projectProgress || payload.project_progress || payload.project_summaries || []

  if (!Array.isArray(projects)) return []

  return projects.map((project: any, index: number) => {
    const totalTasks = numberValue(project.totalTasks ?? project.total_tasks)
    const finishedTasks = numberValue(project.finishedTasks ?? project.finished_tasks ?? project.completedTasks ?? project.completed_tasks)
    const calculated = totalTasks > 0 ? (finishedTasks / totalTasks) * 100 : 0

    return {
      id: project.id ?? index,
      name: project.name ?? project.title ?? `Project ${index + 1}`,
      description: project.description ?? '',
      status: normalizeProjectStatus(project.status),
      totalTasks,
      finishedTasks,
      completionPercentage: clampPercentage(project.completionPercentage ?? project.completion_percentage ?? calculated),
      points: numberValue(project.points ?? project.totalPoints ?? project.total_points),
    }
  })
})

const loadDashboard = async () => {
  loading.value = true
  clearNotification()

  try {
    const response = await api.get('/todo/dashboard')
    rawDashboard.value = response.data
  } catch (error) {
    rawDashboard.value = { data: { stats: defaultStats, projects: [] } }
    notify('error', getApiMessage(error, 'API failure. Failed to load dashboard.'))
  } finally {
    loading.value = false
  }
}

onMounted(loadDashboard)
</script>

<style scoped>
.todo-page {
  display: grid;
  gap: 24px;
}

.todo-page__header,
.todo-panel__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.todo-page__header h1,
.todo-panel__header h2 {
  margin: 0;
  color: var(--nix-text, #0f172a);
  font-weight: 900;
}

.todo-page__header h1 {
  font-size: 1.6rem;
}

.todo-panel__header h2 {
  font-size: 1.05rem;
}

.todo-page__header p,
.todo-panel__header p {
  margin: 6px 0 0;
  color: var(--nix-text-muted, #64748b);
}

.todo-panel {
  display: grid;
  gap: 18px;
  padding: 20px;
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 20px;
  box-shadow: var(--nix-shadow-sm, 0 1px 2px rgba(15, 23, 42, 0.05));
}

.todo-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.todo-summary-card,
.todo-points-card {
  min-width: 0;
  padding: 14px;
  background: rgba(148, 163, 184, 0.08);
  border-radius: 16px;
}

.todo-summary-card span,
.todo-points-card span,
.todo-points-list span {
  display: block;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.82rem;
  font-weight: 800;
}

.todo-summary-card strong,
.todo-points-card strong,
.todo-points-list strong {
  display: block;
  margin-top: 6px;
  color: var(--nix-text, #0f172a);
  font-weight: 900;
}

.todo-summary-card strong {
  font-size: 1.3rem;
}

.todo-points-card strong {
  font-size: 2.2rem;
}

.todo-dashboard-grid {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(280px, 1fr);
  gap: 18px;
}

.todo-project-list,
.todo-points-list {
  display: grid;
  gap: 12px;
}

.todo-points-list div {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.todo-link {
  color: #0891b2;
  font-size: 0.9rem;
  font-weight: 900;
  text-decoration: none;
}

.todo-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 42px;
  padding: 10px 16px;
  border-radius: 14px;
  font-size: 0.9rem;
  font-weight: 900;
  text-decoration: none;
}

.todo-button--primary {
  color: #0f172a;
  background: #06b6d4;
  border: 1px solid #06b6d4;
}

@media (max-width: 1100px) {
  .todo-summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .todo-dashboard-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .todo-page__header,
  .todo-panel__header {
    display: grid;
  }

  .todo-summary-grid {
    grid-template-columns: 1fr;
  }

  .todo-button {
    width: 100%;
  }
}
</style>

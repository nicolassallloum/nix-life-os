cd /u01/nix-life-os/frontend
cat > src/views/todo/TodoDashboardView.vue <<'EOF'
<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
          To-Do Dashboard
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Track task progress, project completion, schedules, and total points.
        </p>
      </div>

      <RouterLink
        to="/todo/tasks/create"
        class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400"
      >
        + Create Task
      </RouterLink>
    </div>

    <div
      v-if="errorMessage"
      class="rounded-xl border border-amber-300/40 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-400/20 dark:bg-amber-500/10 dark:text-amber-200"
    >
      {{ errorMessage }}
    </div>

    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <section
        v-for="card in dashboardCards"
        :key="card.label"
        class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
      >
        <div class="flex items-start justify-between gap-3">
          <div>
            <p class="text-sm font-medium text-gray-500 dark:text-gray-400">
              {{ card.label }}
            </p>
            <p class="mt-2 text-2xl font-black text-gray-900 dark:text-white">
              {{ card.value }}
            </p>
          </div>

          <span class="rounded-xl bg-cyan-50 px-3 py-2 text-xl dark:bg-cyan-500/10">
            {{ card.icon }}
          </span>
        </div>
      </section>
    </div>

    <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            Completion Progress
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Finished tasks compared to total tasks.
          </p>
        </div>

        <p class="text-2xl font-black text-cyan-600 dark:text-cyan-300">
          {{ completionPercentage }}%
        </p>
      </div>

      <div class="mt-4 h-4 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
        <div
          class="h-full rounded-full bg-cyan-500 transition-all"
          :style="{ width: `${completionPercentage}%` }"
        />
      </div>

      <div class="mt-3 flex flex-wrap gap-3 text-sm text-gray-600 dark:text-gray-300">
        <span>Finished: {{ stats.finishedTasks }}</span>
        <span>Pending: {{ stats.pendingTasks }}</span>
        <span>In Progress: {{ stats.inProgressTasks }}</span>
      </div>
    </section>

    <div class="grid grid-cols-1 gap-4 xl:grid-cols-3">
      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800 xl:col-span-2">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-bold text-gray-900 dark:text-white">
              Project Progress Summary
            </h2>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Active and completed project progress.
            </p>
          </div>

          <RouterLink
            to="/todo/projects"
            class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
          >
            View projects
          </RouterLink>
        </div>

        <div v-if="loading" class="mt-5 text-sm text-gray-600 dark:text-gray-300">
          Loading project summary...
        </div>

        <div v-else-if="projectSummaries.length === 0" class="mt-5 rounded-xl border border-dashed border-gray-300 p-5 text-sm text-gray-600 dark:border-gray-600 dark:text-gray-300">
          No project progress data found yet.
        </div>

        <div v-else class="mt-5 space-y-4">
          <article
            v-for="project in projectSummaries"
            :key="project.id"
            class="rounded-xl border border-gray-100 p-4 dark:border-gray-700"
          >
            <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h3 class="font-bold text-gray-900 dark:text-white">
                  {{ project.name }}
                </h3>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ project.finishedTasks }} / {{ project.totalTasks }} tasks finished · {{ project.points }} points
                </p>
              </div>

              <RouterLink
                :to="`/todo/projects/${project.id}`"
                class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
              >
                Details
              </RouterLink>
            </div>

            <div class="mt-3 h-3 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
              <div
                class="h-full rounded-full bg-cyan-500"
                :style="{ width: `${project.completionPercentage}%` }"
              />
            </div>

            <p class="mt-2 text-right text-xs font-bold text-gray-500 dark:text-gray-400">
              {{ project.completionPercentage }}%
            </p>
          </article>
        </div>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 class="text-lg font-bold text-gray-900 dark:text-white">
          Points Summary
        </h2>
        <p class="text-sm text-gray-600 dark:text-gray-300">
          Points earned from completed tasks.
        </p>

        <div class="mt-5 rounded-2xl bg-cyan-50 p-5 dark:bg-cyan-500/10">
          <p class="text-sm font-medium text-cyan-700 dark:text-cyan-200">
            Total Points
          </p>
          <p class="mt-2 text-4xl font-black text-cyan-700 dark:text-cyan-200">
            {{ stats.totalPoints }}
          </p>
        </div>

        <div class="mt-5 space-y-3 text-sm text-gray-600 dark:text-gray-300">
          <div class="flex justify-between gap-3">
            <span>Monthly Tasks</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.monthlyTasks }}</strong>
          </div>
          <div class="flex justify-between gap-3">
            <span>Weekly Tasks</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.weeklyTasks }}</strong>
          </div>
          <div class="flex justify-between gap-3">
            <span>Daily Tasks</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.dailyTasks }}</strong>
          </div>
          <div class="flex justify-between gap-3">
            <span>General Tasks</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.generalTasks }}</strong>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import api from '@/services/api'

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

type ProjectSummary = {
  id: number | string
  name: string
  totalTasks: number
  finishedTasks: number
  completionPercentage: number
  points: number
}

const loading = ref(false)
const errorMessage = ref('')
const rawDashboard = ref<Record<string, any> | null>(null)

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

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const dashboardPayload = computed(() => {
  const payload = rawDashboard.value

  if (!payload) {
    return {}
  }

  return payload.data || payload.dashboard || payload.summary || payload
})

const stats = computed<TodoDashboardStats>(() => {
  const payload: any = dashboardPayload.value
  const source = payload.stats || payload.summary || payload

  const totalTasks = numberValue(source.totalTasks ?? source.total_tasks)
  const finishedTasks = numberValue(source.finishedTasks ?? source.finished_tasks ?? source.completedTasks ?? source.completed_tasks)
  const pendingTasks = numberValue(source.pendingTasks ?? source.pending_tasks)
  const inProgressTasks = numberValue(source.inProgressTasks ?? source.in_progress_tasks)
  const calculatedPercentage = totalTasks > 0 ? Math.round((finishedTasks / totalTasks) * 100) : 0

  return {
    totalTasks,
    finishedTasks,
    pendingTasks,
    inProgressTasks,
    completionPercentage: numberValue(source.completionPercentage ?? source.completion_percentage) || calculatedPercentage,
    totalPoints: numberValue(source.totalPoints ?? source.total_points ?? source.points),
    monthlyTasks: numberValue(source.monthlyTasks ?? source.monthly_tasks),
    weeklyTasks: numberValue(source.weeklyTasks ?? source.weekly_tasks),
    dailyTasks: numberValue(source.dailyTasks ?? source.daily_tasks),
    generalTasks: numberValue(source.generalTasks ?? source.general_tasks),
    activeProjects: numberValue(source.activeProjects ?? source.active_projects),
    completedProjects: numberValue(source.completedProjects ?? source.completed_projects),
  }
})

const completionPercentage = computed(() => {
  return Math.min(100, Math.max(0, Math.round(stats.value.completionPercentage)))
})

const dashboardCards = computed(() => [
  { label: 'Total Tasks', value: stats.value.totalTasks, icon: '📋' },
  { label: 'Finished Tasks', value: stats.value.finishedTasks, icon: '✅' },
  { label: 'Pending Tasks', value: stats.value.pendingTasks, icon: '⏳' },
  { label: 'In-progress Tasks', value: stats.value.inProgressTasks, icon: '🔄' },
  { label: 'Completion %', value: `${completionPercentage.value}%`, icon: '📊' },
  { label: 'Total Points', value: stats.value.totalPoints, icon: '⭐' },
  { label: 'Monthly Tasks', value: stats.value.monthlyTasks, icon: '🗓️' },
  { label: 'Weekly Tasks', value: stats.value.weeklyTasks, icon: '📆' },
  { label: 'Daily Tasks', value: stats.value.dailyTasks, icon: '☀️' },
  { label: 'General Tasks', value: stats.value.generalTasks, icon: '📝' },
  { label: 'Active Projects', value: stats.value.activeProjects, icon: '📌' },
  { label: 'Completed Projects', value: stats.value.completedProjects, icon: '🏁' },
])

const projectSummaries = computed<ProjectSummary[]>(() => {
  const payload: any = dashboardPayload.value
  const projects = payload.projects || payload.projectProgress || payload.project_progress || payload.project_summaries || []

  if (!Array.isArray(projects)) {
    return []
  }

  return projects.map((project: any, index: number) => {
    const totalTasks = numberValue(project.totalTasks ?? project.total_tasks)
    const finishedTasks = numberValue(project.finishedTasks ?? project.finished_tasks ?? project.completedTasks ?? project.completed_tasks)
    const calculatedPercentage = totalTasks > 0 ? Math.round((finishedTasks / totalTasks) * 100) : 0

    return {
      id: project.id ?? index,
      name: project.name ?? project.title ?? `Project ${index + 1}`,
      totalTasks,
      finishedTasks,
      completionPercentage: Math.min(
        100,
        Math.max(
          0,
          numberValue(project.completionPercentage ?? project.completion_percentage) || calculatedPercentage,
        ),
      ),
      points: numberValue(project.points ?? project.totalPoints ?? project.total_points),
    }
  })
})

const loadDashboard = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/todo/dashboard')
    rawDashboard.value = response.data
  } catch (error) {
    rawDashboard.value = {
      data: {
        stats: defaultStats,
        projects: [],
      },
    }

    errorMessage.value = 'Dashboard API is not available yet. Showing empty To-Do dashboard structure.'
    console.warn('[To-Do Dashboard] Failed to load dashboard summary.', error)
  } finally {
    loading.value = false
  }
}

onMounted(loadDashboard)
</script>
EOF
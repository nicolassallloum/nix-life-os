<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
          To-Do
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Manage projects, tasks, schedules, completion progress, and points.
        </p>
      </div>

      <div class="flex flex-wrap gap-2">
        <RouterLink
          to="/todo/tasks/create"
          class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400"
        >
          + Create Task
        </RouterLink>

        <RouterLink
          to="/todo/projects"
          class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700"
        >
          Projects
        </RouterLink>
      </div>
    </div>

    <div
      v-if="errorMessage"
      class="rounded-xl border border-amber-300/40 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-400/20 dark:bg-amber-500/10 dark:text-amber-200"
    >
      {{ errorMessage }}
    </div>

    <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            Dashboard Summary
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Quick overview of tasks, completion, projects, and points.
          </p>
        </div>

        <RouterLink
          to="/todo/dashboard"
          class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
        >
          Open dashboard
        </RouterLink>
      </div>

      <div class="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article
          v-for="card in summaryCards"
          :key="card.label"
          class="rounded-xl border border-gray-100 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-900/40"
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
        </article>
      </div>

      <div class="mt-5">
        <div class="flex items-center justify-between text-sm">
          <span class="font-semibold text-gray-700 dark:text-gray-300">Completion</span>
          <span class="font-black text-cyan-600 dark:text-cyan-300">{{ completionPercentage }}%</span>
        </div>

        <div class="mt-2 h-4 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
          <div
            class="h-full rounded-full bg-cyan-500 transition-all"
            :style="{ width: `${completionPercentage}%` }"
          />
        </div>
      </div>
    </section>

    <div class="grid grid-cols-1 gap-4 xl:grid-cols-3">
      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800 xl:col-span-2">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h2 class="text-lg font-bold text-gray-900 dark:text-white">
              Projects
            </h2>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Active project progress and related task totals.
            </p>
          </div>

          <RouterLink
            to="/todo/projects"
            class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
          >
            Manage projects
          </RouterLink>
        </div>

        <div v-if="loading" class="mt-5 text-sm text-gray-600 dark:text-gray-300">
          Loading projects...
        </div>

        <div
          v-else-if="projectSummaries.length === 0"
          class="mt-5 rounded-xl border border-dashed border-gray-300 p-5 text-sm text-gray-600 dark:border-gray-600 dark:text-gray-300"
        >
          No projects found yet.
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
                  {{ project.status }} · {{ project.finishedTasks }} / {{ project.totalTasks }} tasks · {{ project.points }} points
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
            <span>Finished Tasks</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.finishedTasks }}</strong>
          </div>
          <div class="flex justify-between gap-3">
            <span>Active Projects</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.activeProjects }}</strong>
          </div>
          <div class="flex justify-between gap-3">
            <span>Completed Projects</span>
            <strong class="text-gray-900 dark:text-white">{{ stats.completedProjects }}</strong>
          </div>
        </div>
      </section>
    </div>

    <div class="grid grid-cols-1 gap-4 xl:grid-cols-2">
      <TaskSection
        title="General Task List"
        subtitle="Tasks without a daily, weekly, or monthly schedule."
        :tasks="groupedTasks.general"
        empty-message="No general tasks found."
        route="/todo/tasks"
      />

      <TaskSection
        title="Monthly Tasks"
        subtitle="Tasks planned for the current or upcoming month."
        :tasks="groupedTasks.monthly"
        empty-message="No monthly tasks found."
        route="/todo/tasks"
      />

      <TaskSection
        title="Weekly Tasks"
        subtitle="Tasks planned for this week."
        :tasks="groupedTasks.weekly"
        empty-message="No weekly tasks found."
        route="/todo/tasks"
      />

      <TaskSection
        title="Daily Tasks"
        subtitle="Tasks planned for today."
        :tasks="groupedTasks.daily"
        empty-message="No daily tasks found."
        route="/todo/tasks"
      />

      <TaskSection
        title="Completed Tasks"
        subtitle="Recently finished tasks and awarded points."
        :tasks="groupedTasks.completed"
        empty-message="No completed tasks found."
        route="/todo/tasks"
        class="xl:col-span-2"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import api from '@/services/api'

type TodoStats = {
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

type TodoTask = {
  id: number | string
  title: string
  status: string
  priority: string
  type: string
  points: number
  projectName: string
}

type ProjectSummary = {
  id: number | string
  name: string
  status: string
  totalTasks: number
  finishedTasks: number
  completionPercentage: number
  points: number
}

const TaskSection = defineComponent({
  name: 'TaskSection',
  props: {
    title: {
      type: String,
      required: true,
    },
    subtitle: {
      type: String,
      required: true,
    },
    tasks: {
      type: Array as () => TodoTask[],
      required: true,
    },
    emptyMessage: {
      type: String,
      required: true,
    },
    route: {
      type: String,
      required: true,
    },
  },
  setup(props) {
    return () =>
      h(
        'section',
        {
          class:
            'rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800',
        },
        [
          h('div', { class: 'flex items-center justify-between gap-3' }, [
            h('div', null, [
              h('h2', { class: 'text-lg font-bold text-gray-900 dark:text-white' }, props.title),
              h('p', { class: 'text-sm text-gray-600 dark:text-gray-300' }, props.subtitle),
            ]),
            h(
              RouterLink,
              {
                to: props.route,
                class: 'text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300',
              },
              () => 'View all',
            ),
          ]),

          props.tasks.length === 0
            ? h(
                'div',
                {
                  class:
                    'mt-5 rounded-xl border border-dashed border-gray-300 p-5 text-sm text-gray-600 dark:border-gray-600 dark:text-gray-300',
                },
                props.emptyMessage,
              )
            : h(
                'div',
                { class: 'mt-5 space-y-3' },
                props.tasks.slice(0, 5).map((task) =>
                  h(
                    'article',
                    {
                      key: task.id,
                      class:
                        'rounded-xl border border-gray-100 p-4 dark:border-gray-700',
                    },
                    [
                      h('div', { class: 'flex items-start justify-between gap-3' }, [
                        h('div', { class: 'min-w-0' }, [
                          h(
                            'h3',
                            {
                              class:
                                'truncate font-bold text-gray-900 dark:text-white',
                            },
                            task.title,
                          ),
                          h(
                            'p',
                            {
                              class:
                                'mt-1 text-sm text-gray-500 dark:text-gray-400',
                            },
                            `${task.projectName || 'No project'} · ${task.status} · ${task.priority}`,
                          ),
                        ]),
                        h(
                          'span',
                          {
                            class:
                              'shrink-0 rounded-full bg-cyan-50 px-3 py-1 text-xs font-black text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-200',
                          },
                          `${task.points} pts`,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
        ],
      )
  },
})

const loading = ref(false)
const errorMessage = ref('')
const rawDashboard = ref<Record<string, any> | null>(null)

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const defaultStats: TodoStats = {
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

const dashboardPayload = computed(() => {
  const payload = rawDashboard.value

  if (!payload) {
    return {}
  }

  return payload.data || payload.dashboard || payload.summary || payload
})

const stats = computed<TodoStats>(() => {
  const payload: any = dashboardPayload.value
  const source = payload.stats || payload.summary || payload

  const totalTasks = numberValue(source.totalTasks ?? source.total_tasks)
  const finishedTasks = numberValue(source.finishedTasks ?? source.finished_tasks ?? source.completedTasks ?? source.completed_tasks)
  const calculatedPercentage = totalTasks > 0 ? Math.round((finishedTasks / totalTasks) * 100) : 0

  return {
    totalTasks,
    finishedTasks,
    pendingTasks: numberValue(source.pendingTasks ?? source.pending_tasks),
    inProgressTasks: numberValue(source.inProgressTasks ?? source.in_progress_tasks),
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

const summaryCards = computed(() => [
  { label: 'Total Tasks', value: stats.value.totalTasks, icon: '📋' },
  { label: 'Finished Tasks', value: stats.value.finishedTasks, icon: '✅' },
  { label: 'Pending Tasks', value: stats.value.pendingTasks, icon: '⏳' },
  { label: 'In-progress', value: stats.value.inProgressTasks, icon: '🔄' },
  { label: 'Monthly Tasks', value: stats.value.monthlyTasks, icon: '🗓️' },
  { label: 'Weekly Tasks', value: stats.value.weeklyTasks, icon: '📆' },
  { label: 'Daily Tasks', value: stats.value.dailyTasks, icon: '☀️' },
  { label: 'General Tasks', value: stats.value.generalTasks, icon: '📝' },
])

const normalizeTask = (task: any, index: number): TodoTask => {
  return {
    id: task.id ?? index,
    title: task.title ?? task.name ?? `Task ${index + 1}`,
    status: task.status ?? 'pending',
    priority: task.priority ?? 'normal',
    type: task.type ?? task.task_type ?? task.schedule_type ?? 'general',
    points: numberValue(task.points),
    projectName: task.projectName ?? task.project_name ?? task.project?.name ?? '',
  }
}

const allTasks = computed<TodoTask[]>(() => {
  const payload: any = dashboardPayload.value
  const tasks = payload.tasks || payload.recentTasks || payload.recent_tasks || []

  if (!Array.isArray(tasks)) {
    return []
  }

  return tasks.map(normalizeTask)
})

const groupedTasks = computed(() => {
  const isCompleted = (task: TodoTask) => ['done', 'finished', 'completed'].includes(String(task.status).toLowerCase())
  const typeOf = (task: TodoTask) => String(task.type || 'general').toLowerCase()

  return {
    general: allTasks.value.filter((task) => !isCompleted(task) && ['general', 'none'].includes(typeOf(task))),
    monthly: allTasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('month')),
    weekly: allTasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('week')),
    daily: allTasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('day')),
    completed: allTasks.value.filter(isCompleted),
  }
})

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
      status: project.status ?? 'active',
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

const loadMainPage = async () => {
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
        tasks: [],
      },
    }

    errorMessage.value = 'To-Do API is not available yet. Showing empty To-Do module structure.'
    console.warn('[To-Do Main] Failed to load overview data.', error)
  } finally {
    loading.value = false
  }
}

onMounted(loadMainPage)
</script>

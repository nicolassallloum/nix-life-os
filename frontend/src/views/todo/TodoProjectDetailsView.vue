<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <RouterLink
          to="/todo/projects"
          class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
        >
          ← Back to Projects
        </RouterLink>

        <h1 class="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
          {{ project.name || 'Project Details' }}
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          View project information, progress, points, and related tasks.
        </p>
      </div>

      <RouterLink
        :to="`/todo/tasks?project_id=${project.id}`"
        class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400"
      >
        View Project Tasks
      </RouterLink>
    </div>

    <div
      v-if="errorMessage"
      class="rounded-xl border border-red-300/40 bg-red-50 p-4 text-sm text-red-800 dark:border-red-400/20 dark:bg-red-500/10 dark:text-red-200"
    >
      {{ errorMessage }}
    </div>

    <section
      v-if="loading"
      class="rounded-2xl border border-gray-200 bg-white p-5 text-sm text-gray-600 shadow-sm dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
    >
      Loading project details...
    </section>

    <template v-else>
      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <div class="flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <h2 class="text-xl font-black text-gray-900 dark:text-white">
                {{ project.name || 'Untitled Project' }}
              </h2>

              <span
                class="rounded-full px-3 py-1 text-xs font-black"
                :class="statusClass(project.status)"
              >
                {{ formatStatus(project.status) }}
              </span>
            </div>

            <p class="mt-3 max-w-4xl text-sm leading-6 text-gray-600 dark:text-gray-300">
              {{ project.description || 'No description added.' }}
            </p>
          </div>

          <div class="grid grid-cols-1 gap-2 text-sm text-gray-600 dark:text-gray-300 sm:grid-cols-2 xl:min-w-80">
            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                Start Date
              </p>
              <p class="mt-1 font-black text-gray-900 dark:text-white">
                {{ formatDate(project.startDate) }}
              </p>
            </div>

            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                End Date
              </p>
              <p class="mt-1 font-black text-gray-900 dark:text-white">
                {{ formatDate(project.endDate) }}
              </p>
            </div>
          </div>
        </div>
      </section>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <section
          v-for="card in metricCards"
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
              Project Completion
            </h2>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Finished related tasks compared to total related tasks.
            </p>
          </div>

          <p class="text-2xl font-black text-cyan-600 dark:text-cyan-300">
            {{ project.completionPercentage }}%
          </p>
        </div>

        <div class="mt-4 h-4 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
          <div
            class="h-full rounded-full bg-cyan-500 transition-all"
            :style="{ width: `${project.completionPercentage}%` }"
          />
        </div>

        <div class="mt-3 flex flex-wrap gap-3 text-sm text-gray-600 dark:text-gray-300">
          <span>Total Tasks: {{ project.totalTasks }}</span>
          <span>Finished Tasks: {{ project.finishedTasks }}</span>
          <span>Total Points: {{ project.points }}</span>
        </div>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-bold text-gray-900 dark:text-white">
              Related Tasks
            </h2>
            <p class="text-sm text-gray-600 dark:text-gray-300">
              Tasks linked to this project.
            </p>
          </div>

          <RouterLink
            :to="`/todo/tasks/create?project_id=${project.id}`"
            class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400"
          >
            + Add Task
          </RouterLink>
        </div>

        <div
          v-if="tasks.length === 0"
          class="mt-5 rounded-xl border border-dashed border-gray-300 p-6 text-center text-sm text-gray-600 dark:border-gray-600 dark:text-gray-300"
        >
          No related tasks found for this project.
        </div>

        <div v-else class="mt-5 overflow-hidden rounded-xl border border-gray-100 dark:border-gray-700">
          <div class="hidden grid-cols-12 gap-3 bg-gray-50 px-4 py-3 text-xs font-black uppercase tracking-wide text-gray-500 dark:bg-gray-900/50 dark:text-gray-400 md:grid">
            <div class="col-span-4">Task</div>
            <div class="col-span-2">Type</div>
            <div class="col-span-2">Status</div>
            <div class="col-span-2">Priority</div>
            <div class="col-span-1">Points</div>
            <div class="col-span-1 text-right">Action</div>
          </div>

          <article
            v-for="task in tasks"
            :key="task.id"
            class="grid grid-cols-1 gap-3 border-t border-gray-100 px-4 py-4 dark:border-gray-700 md:grid-cols-12 md:items-center"
          >
            <div class="md:col-span-4">
              <h3 class="font-bold text-gray-900 dark:text-white">
                {{ task.title }}
              </h3>
              <p class="mt-1 line-clamp-2 text-sm text-gray-500 dark:text-gray-400">
                {{ task.description || 'No description.' }}
              </p>
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                Due: {{ formatDate(task.dueDate) }}
              </p>
            </div>

            <div class="text-sm text-gray-600 dark:text-gray-300 md:col-span-2">
              {{ formatStatus(task.type) }}
            </div>

            <div class="md:col-span-2">
              <span
                class="rounded-full px-3 py-1 text-xs font-black"
                :class="taskStatusClass(task.status)"
              >
                {{ formatStatus(task.status) }}
              </span>
            </div>

            <div class="text-sm text-gray-600 dark:text-gray-300 md:col-span-2">
              {{ formatStatus(task.priority) }}
            </div>

            <div class="text-sm font-black text-gray-900 dark:text-white md:col-span-1">
              {{ task.points }}
            </div>

            <div class="md:col-span-1 md:text-right">
              <RouterLink
                :to="`/todo/tasks/${task.id}/edit`"
                class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
              >
                Edit
              </RouterLink>
            </div>
          </article>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import api from '@/services/api'

type TodoProject = {
  id: number | string
  name: string
  description: string
  status: string
  startDate: string
  endDate: string
  totalTasks: number
  finishedTasks: number
  completionPercentage: number
  points: number
}

type TodoTask = {
  id: number | string
  title: string
  description: string
  type: string
  status: string
  priority: string
  points: number
  dueDate: string
}

const route = useRoute()

const loading = ref(false)
const errorMessage = ref('')
const project = ref<TodoProject>({
  id: route.params.id as string,
  name: '',
  description: '',
  status: 'active',
  startDate: '',
  endDate: '',
  totalTasks: 0,
  finishedTasks: 0,
  completionPercentage: 0,
  points: 0,
})
const tasks = ref<TodoTask[]>([])

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const clampPercentage = (value: number): number => {
  return Math.min(100, Math.max(0, Math.round(value)))
}

const normalizeTask = (task: any, index: number): TodoTask => {
  return {
    id: task.id ?? index,
    title: task.title ?? task.name ?? `Task ${index + 1}`,
    description: task.description ?? '',
    type: task.task_type ?? task.type ?? task.schedule_type ?? 'general',
    status: task.status ?? 'pending',
    priority: task.priority ?? 'medium',
    points: numberValue(task.points),
    dueDate: task.due_date ?? task.dueDate ?? '',
  }
}

const normalizeProject = (rawProject: any): TodoProject => {
  const relatedTasks: TodoTask[] = Array.isArray(rawProject.tasks)
    ? rawProject.tasks.map(normalizeTask)
    : []

  const totalTasks = numberValue(
    rawProject.totalTasks ??
      rawProject.total_tasks ??
      rawProject.tasks_count ??
      relatedTasks.length,
  )

  const finishedTasks = numberValue(
    rawProject.finishedTasks ??
      rawProject.finished_tasks ??
      rawProject.completedTasks ??
      rawProject.completed_tasks ??
      relatedTasks.filter((task: TodoTask) => task.status === 'finished' || task.status === 'completed').length,
  )

  const calculatedPercentage = totalTasks > 0 ? Math.round((finishedTasks / totalTasks) * 100) : 0

  return {
    id: rawProject.id ?? route.params.id,
    name: rawProject.name ?? rawProject.title ?? 'Untitled Project',
    description: rawProject.description ?? '',
    status: rawProject.status ?? 'active',
    startDate: rawProject.startDate ?? rawProject.start_date ?? '',
    endDate: rawProject.endDate ?? rawProject.end_date ?? '',
    totalTasks,
    finishedTasks,
    completionPercentage: clampPercentage(
      numberValue(rawProject.completionPercentage ?? rawProject.completion_percentage) || calculatedPercentage,
    ),
    points: numberValue(
      rawProject.points ??
        rawProject.project_points ??
        rawProject.totalProjectPoints ??
        rawProject.total_project_points ??
        rawProject.totalPoints ??
        rawProject.total_points,
    ),
  }
}

const metricCards = computed(() => [
  { label: 'Total Tasks', value: project.value.totalTasks, icon: '📋' },
  { label: 'Finished Tasks', value: project.value.finishedTasks, icon: '✅' },
  { label: 'Completion', value: `${project.value.completionPercentage}%`, icon: '📊' },
  { label: 'Project Points', value: project.value.points, icon: '⭐' },
])

const extractProjectPayload = (payload: any) => {
  return payload?.data?.project || payload?.data || payload?.project || payload
}

const extractTasksPayload = (payload: any, projectPayload: any): TodoTask[] => {
  const source =
    projectPayload?.tasks ||
    payload?.data?.tasks ||
    payload?.tasks ||
    []

  if (!Array.isArray(source)) {
    return []
  }

  return source.map(normalizeTask)
}

const loadProject = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get(`/todo/projects/${route.params.id}`)
    const projectPayload = extractProjectPayload(response.data)

    project.value = normalizeProject(projectPayload)
    tasks.value = extractTasksPayload(response.data, projectPayload)
  } catch (error) {
    project.value = {
      ...project.value,
      id: route.params.id as string,
    }
    tasks.value = []
    errorMessage.value = 'Project details API is not available yet or failed to load.'
    console.warn('[To-Do Project Details] Failed to load project details.', error)
  } finally {
    loading.value = false
  }
}

const formatStatus = (value: string): string => {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
}

const statusClass = (status: string): string => {
  const normalized = String(status || '').toLowerCase()

  if (normalized === 'completed') {
    return 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-200'
  }

  if (normalized === 'paused' || normalized === 'archived') {
    return 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-200'
  }

  return 'bg-cyan-50 text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-200'
}

const taskStatusClass = (status: string): string => {
  const normalized = String(status || '').toLowerCase()

  if (normalized === 'finished' || normalized === 'completed') {
    return 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-200'
  }

  if (normalized === 'in_progress') {
    return 'bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-200'
  }

  return 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-200'
}

const formatDate = (value: string): string => {
  return value || 'No date'
}

onMounted(loadProject)
</script>

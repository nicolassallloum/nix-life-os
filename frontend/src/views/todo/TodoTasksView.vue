<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
          To-Do Tasks
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Manage general, monthly, weekly, daily, and completed tasks.
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
      v-if="successMessage"
      class="rounded-xl border border-emerald-300/40 bg-emerald-50 p-4 text-sm text-emerald-800 dark:border-emerald-400/20 dark:bg-emerald-500/10 dark:text-emerald-200"
    >
      {{ successMessage }}
    </div>

    <div
      v-if="errorMessage"
      class="rounded-xl border border-red-300/40 bg-red-50 p-4 text-sm text-red-800 dark:border-red-400/20 dark:bg-red-500/10 dark:text-red-200"
    >
      {{ errorMessage }}
    </div>

    <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            Filters
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Search and filter tasks by project, status, and priority.
          </p>
        </div>

        <button
          type="button"
          class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
          @click="resetFilters"
        >
          Reset Filters
        </button>
      </div>

      <div class="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-4">
        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Search
          </label>
          <input
            v-model.trim="filters.search"
            type="search"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Search task name..."
            @keyup.enter="loadTasks"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Project
          </label>
          <select
            v-model="filters.project_id"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="">All projects</option>
            <option
              v-for="project in projects"
              :key="project.id"
              :value="project.id"
            >
              {{ project.name }}
            </option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Status
          </label>
          <select
            v-model="filters.status"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="">All statuses</option>
            <option value="pending">Pending</option>
            <option value="in_progress">In Progress</option>
            <option value="completed">Completed</option>
            <option value="finished">Finished</option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Priority
          </label>
          <select
            v-model="filters.priority"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="">All priorities</option>
            <option value="low">Low</option>
            <option value="normal">Normal</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
            <option value="urgent">Urgent</option>
          </select>
        </div>
      </div>

      <div class="mt-5 flex flex-wrap gap-2">
        <button
          type="button"
          :disabled="loading"
          class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-60"
          @click="loadTasks"
        >
          {{ loading ? 'Loading...' : 'Apply Filters' }}
        </button>

        <button
          type="button"
          :disabled="loading"
          class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
          @click="refreshAll"
        >
          Refresh
        </button>
      </div>
    </section>

    <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <article
          v-for="card in summaryCards"
          :key="card.label"
          class="rounded-xl bg-gray-50 p-4 dark:bg-gray-900/50"
        >
          <p class="text-sm font-medium text-gray-500 dark:text-gray-400">
            {{ card.label }}
          </p>
          <p class="mt-2 text-2xl font-black text-gray-900 dark:text-white">
            {{ card.value }}
          </p>
        </article>
      </div>
    </section>

    <div v-if="loading" class="rounded-2xl border border-gray-200 bg-white p-5 text-sm text-gray-600 shadow-sm dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300">
      Loading tasks...
    </div>

    <div v-else class="grid grid-cols-1 gap-4 xl:grid-cols-2">
      <TaskGroupSection
        title="General Tasks"
        subtitle="Tasks without daily, weekly, or monthly schedule."
        :tasks="groupedTasks.general"
        empty-message="No general tasks found."
        @finish="finishTask"
        @delete="deleteTask"
      />

      <TaskGroupSection
        title="Monthly Tasks"
        subtitle="Tasks planned for the month."
        :tasks="groupedTasks.monthly"
        empty-message="No monthly tasks found."
        @finish="finishTask"
        @delete="deleteTask"
      />

      <TaskGroupSection
        title="Weekly Tasks"
        subtitle="Tasks planned for the week."
        :tasks="groupedTasks.weekly"
        empty-message="No weekly tasks found."
        @finish="finishTask"
        @delete="deleteTask"
      />

      <TaskGroupSection
        title="Daily Tasks"
        subtitle="Tasks planned for the day."
        :tasks="groupedTasks.daily"
        empty-message="No daily tasks found."
        @finish="finishTask"
        @delete="deleteTask"
      />

      <TaskGroupSection
        title="Completed Tasks"
        subtitle="Finished tasks and earned points."
        :tasks="groupedTasks.completed"
        empty-message="No completed tasks found."
        class="xl:col-span-2"
        completed-section
        @finish="finishTask"
        @delete="deleteTask"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import api from '@/services/api'

type TodoProject = {
  id: number | string
  name: string
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
  projectId: number | string | null
  projectName: string
}

type TaskFilters = {
  search: string
  project_id: string | number
  status: string
  priority: string
}

const TaskGroupSection = defineComponent({
  name: 'TaskGroupSection',
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
    completedSection: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['finish', 'delete'],
  setup(props, { emit }) {
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

    const formatStatus = (value: string): string => {
      return String(value || '')
        .replace(/_/g, ' ')
        .replace(/\b\w/g, (letter) => letter.toUpperCase())
    }

    return () =>
      h(
        'section',
        {
          class:
            'rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800',
        },
        [
          h('div', { class: 'flex flex-col gap-2 md:flex-row md:items-center md:justify-between' }, [
            h('div', null, [
              h('h2', { class: 'text-lg font-bold text-gray-900 dark:text-white' }, props.title),
              h('p', { class: 'text-sm text-gray-600 dark:text-gray-300' }, props.subtitle),
            ]),
            h('span', { class: 'rounded-full bg-cyan-50 px-3 py-1 text-xs font-black text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-200' }, `${props.tasks.length} tasks`),
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
                props.tasks.map((task) =>
                  h(
                    'article',
                    {
                      key: task.id,
                      class:
                        'rounded-xl border border-gray-100 p-4 dark:border-gray-700',
                    },
                    [
                      h('div', { class: 'flex flex-col gap-3 md:flex-row md:items-start md:justify-between' }, [
                        h('div', { class: 'min-w-0' }, [
                          h('h3', { class: 'font-bold text-gray-900 dark:text-white' }, task.title),
                          h('p', { class: 'mt-1 line-clamp-2 text-sm text-gray-500 dark:text-gray-400' }, task.description || 'No description.'),
                          h('div', { class: 'mt-3 flex flex-wrap gap-2 text-xs font-bold text-gray-500 dark:text-gray-400' }, [
                            h('span', null, task.projectName || 'No project'),
                            h('span', null, `Type: ${formatStatus(task.type)}`),
                            h('span', null, `Priority: ${formatStatus(task.priority)}`),
                            h('span', null, `Due: ${task.dueDate || 'No date'}`),
                          ]),
                        ]),

                        h('div', { class: 'flex shrink-0 flex-wrap items-center gap-2 md:justify-end' }, [
                          h(
                            'span',
                            {
                              class:
                                `rounded-full px-3 py-1 text-xs font-black ${taskStatusClass(task.status)}`,
                            },
                            formatStatus(task.status),
                          ),
                          h(
                            'span',
                            {
                              class:
                                'rounded-full bg-cyan-50 px-3 py-1 text-xs font-black text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-200',
                            },
                            `${task.points} pts`,
                          ),
                        ]),
                      ]),

                      h('div', { class: 'mt-4 flex flex-wrap gap-2' }, [
                        h(
                          RouterLink,
                          {
                            to: `/todo/tasks/${task.id}/edit`,
                            class:
                              'rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700',
                          },
                          () => 'Edit',
                        ),

                        props.completedSection
                          ? null
                          : h(
                              'button',
                              {
                                type: 'button',
                                class:
                                  'rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm font-bold text-emerald-700 transition hover:bg-emerald-100 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-200 dark:hover:bg-emerald-500/20',
                                onClick: () => emit('finish', task),
                              },
                              'Finish',
                            ),

                        h(
                          'button',
                          {
                            type: 'button',
                            class:
                              'rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-bold text-red-700 transition hover:bg-red-100 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-200 dark:hover:bg-red-500/20',
                            onClick: () => emit('delete', task),
                          },
                          'Delete',
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

const route = useRoute()

const loading = ref(false)
const projectsLoading = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const tasks = ref<TodoTask[]>([])
const projects = ref<TodoProject[]>([])

const filters = reactive<TaskFilters>({
  search: '',
  project_id: '',
  status: '',
  priority: '',
})

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const normalizeTask = (task: any, index: number): TodoTask => {
  return {
    id: task.id ?? index,
    title: task.title ?? task.name ?? `Task ${index + 1}`,
    description: task.description ?? '',
    type: task.task_type ?? task.type ?? task.schedule_type ?? 'general',
    status: task.status ?? 'pending',
    priority: task.priority ?? 'normal',
    points: numberValue(task.points),
    dueDate: task.due_date ?? task.dueDate ?? '',
    projectId: task.project_id ?? task.projectId ?? task.project?.id ?? null,
    projectName: task.project_name ?? task.projectName ?? task.project?.name ?? '',
  }
}

const normalizeProject = (project: any, index: number): TodoProject => {
  return {
    id: project.id ?? index,
    name: project.name ?? project.title ?? `Project ${index + 1}`,
  }
}

const extractTasks = (payload: any): TodoTask[] => {
  const source =
    payload?.data?.data ||
    payload?.data?.tasks ||
    payload?.data ||
    payload?.tasks ||
    payload

  if (!Array.isArray(source)) {
    return []
  }

  return source.map(normalizeTask)
}

const extractProjects = (payload: any): TodoProject[] => {
  const source =
    payload?.data?.data ||
    payload?.data?.projects ||
    payload?.data ||
    payload?.projects ||
    payload

  if (!Array.isArray(source)) {
    return []
  }

  return source.map(normalizeProject)
}

const isCompleted = (task: TodoTask): boolean => {
  return ['done', 'finished', 'completed'].includes(String(task.status).toLowerCase())
}

const typeOf = (task: TodoTask): string => {
  return String(task.type || 'general').toLowerCase()
}

const groupedTasks = computed(() => {
  return {
    general: tasks.value.filter((task) => !isCompleted(task) && ['general', 'none'].includes(typeOf(task))),
    monthly: tasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('month')),
    weekly: tasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('week')),
    daily: tasks.value.filter((task) => !isCompleted(task) && typeOf(task).includes('day')),
    completed: tasks.value.filter(isCompleted),
  }
})

const summaryCards = computed(() => [
  { label: 'Total Tasks', value: tasks.value.length },
  { label: 'General', value: groupedTasks.value.general.length },
  { label: 'Monthly', value: groupedTasks.value.monthly.length },
  { label: 'Weekly', value: groupedTasks.value.weekly.length },
  { label: 'Daily', value: groupedTasks.value.daily.length },
])

const clearMessages = () => {
  errorMessage.value = ''
  successMessage.value = ''
}

const showSuccess = (message: string) => {
  successMessage.value = message

  window.setTimeout(() => {
    successMessage.value = ''
  }, 2500)
}

const buildTaskParams = () => {
  const params: Record<string, string | number> = {}

  if (filters.search) {
    params.search = filters.search
  }

  if (filters.project_id) {
    params.project_id = filters.project_id
  }

  if (filters.status) {
    params.status = filters.status
  }

  if (filters.priority) {
    params.priority = filters.priority
  }

  return params
}

const loadTasks = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/todo/tasks', {
      params: buildTaskParams(),
    })
    tasks.value = extractTasks(response.data)
  } catch (error) {
    tasks.value = []
    errorMessage.value = 'Tasks API is not available yet or failed to load.'
    console.warn('[To-Do Tasks] Failed to load tasks.', error)
  } finally {
    loading.value = false
  }
}

const loadProjects = async () => {
  projectsLoading.value = true

  try {
    const response = await api.get('/todo/projects')
    projects.value = extractProjects(response.data)
  } catch (error) {
    projects.value = []
    console.warn('[To-Do Tasks] Failed to load projects filter.', error)
  } finally {
    projectsLoading.value = false
  }
}

const refreshAll = async () => {
  await Promise.all([loadTasks(), loadProjects()])
}

const resetFilters = async () => {
  filters.search = ''
  filters.project_id = ''
  filters.status = ''
  filters.priority = ''

  await loadTasks()
}

const finishTask = async (task: TodoTask) => {
  clearMessages()

  try {
    try {
      await api.patch(`/todo/tasks/${task.id}/finish`)
    } catch {
      await api.put(`/todo/tasks/${task.id}`, {
        status: 'completed',
      })
    }

    showSuccess('Task finished successfully.')
    await loadTasks()
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task finish failed.'
    console.warn('[To-Do Tasks] Failed to finish task.', error)
  }
}

const deleteTask = async (task: TodoTask) => {
  const confirmed = window.confirm(`Delete task "${task.title}"?`)

  if (!confirmed) {
    return
  }

  clearMessages()

  try {
    await api.delete(`/todo/tasks/${task.id}`)
    showSuccess('Task deleted successfully.')
    await loadTasks()
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task delete failed.'
    console.warn('[To-Do Tasks] Failed to delete task.', error)
  }
}

onMounted(async () => {
  if (route.query.project_id) {
    filters.project_id = String(route.query.project_id)
  }

  if (route.query.status) {
    filters.status = String(route.query.status)
  }

  if (route.query.priority) {
    filters.priority = String(route.query.priority)
  }

  await refreshAll()
})
</script>

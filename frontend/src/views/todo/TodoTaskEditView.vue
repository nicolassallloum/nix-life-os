<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <RouterLink
          to="/todo/tasks"
          class="text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
        >
          ← Back to Tasks
        </RouterLink>

        <h1 class="mt-2 text-2xl font-bold text-gray-900 dark:text-white">
          Edit Task
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Update task details, schedule, status, priority, project, and points.
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

    <section
      v-if="loading"
      class="rounded-2xl border border-gray-200 bg-white p-5 text-sm text-gray-600 shadow-sm dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
    >
      Loading task...
    </section>

    <section
      v-else
      class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
    >
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            Task Information
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Edit the selected To-Do task.
          </p>
        </div>

        <span
          class="rounded-full px-3 py-1 text-xs font-black"
          :class="statusClass(form.status)"
        >
          {{ formatStatus(form.status) }}
        </span>
      </div>

      <form class="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-2" @submit.prevent="updateTask">
        <div class="xl:col-span-2">
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Task Title
          </label>
          <input
            v-model.trim="form.title"
            type="text"
            required
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Task title"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Project
          </label>
          <select
            v-model="form.project_id"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="">No project</option>
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
            Task Type
          </label>
          <select
            v-model="form.task_type"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="general">General Task</option>
            <option value="monthly">Monthly Task</option>
            <option value="weekly">Weekly Task</option>
            <option value="daily">Daily Task</option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Status
          </label>
          <select
            v-model="form.status"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
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
            v-model="form.priority"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="low">Low</option>
            <option value="normal">Normal</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
            <option value="urgent">Urgent</option>
          </select>
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Points
          </label>
          <input
            v-model.number="form.points"
            type="number"
            min="0"
            step="1"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="0"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Due Date
          </label>
          <input
            v-model="form.due_date"
            type="date"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Start Date
          </label>
          <input
            v-model="form.start_date"
            type="date"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            End Date
          </label>
          <input
            v-model="form.end_date"
            type="date"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          />
        </div>

        <div class="xl:col-span-2">
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Description
          </label>
          <textarea
            v-model.trim="form.description"
            rows="5"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Write task details..."
          />
        </div>

        <div class="xl:col-span-2 rounded-2xl bg-gray-50 p-4 dark:bg-gray-900/50">
          <h3 class="font-bold text-gray-900 dark:text-white">
            Task Summary
          </h3>
          <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">
            {{ schedulePreview }}
          </p>
        </div>

        <div class="flex flex-wrap gap-2 xl:col-span-2">
          <button
            type="submit"
            :disabled="saving"
            class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {{ saving ? 'Saving...' : 'Update Task' }}
          </button>

          <button
            type="button"
            :disabled="saving"
            class="inline-flex items-center justify-center rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm font-bold text-emerald-700 transition hover:bg-emerald-100 disabled:cursor-not-allowed disabled:opacity-60 dark:border-emerald-500/30 dark:bg-emerald-500/10 dark:text-emerald-200 dark:hover:bg-emerald-500/20"
            @click="markFinished"
          >
            Mark Finished
          </button>

          <RouterLink
            to="/todo/tasks"
            class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
          >
            Cancel
          </RouterLink>

          <button
            type="button"
            :disabled="deleting"
            class="inline-flex items-center justify-center rounded-xl border border-red-200 bg-red-50 px-4 py-2 text-sm font-bold text-red-700 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-200 dark:hover:bg-red-500/20"
            @click="deleteTask"
          >
            {{ deleting ? 'Deleting...' : 'Delete Task' }}
          </button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/services/api'

type TodoProject = {
  id: number | string
  name: string
}

type TaskForm = {
  title: string
  description: string
  project_id: number | string
  task_type: string
  status: string
  priority: string
  points: number
  due_date: string
  start_date: string
  end_date: string
}

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const saving = ref(false)
const deleting = ref(false)
const errorMessage = ref('')
const successMessage = ref('')
const projects = ref<TodoProject[]>([])

const form = reactive<TaskForm>({
  title: '',
  description: '',
  project_id: '',
  task_type: 'general',
  status: 'pending',
  priority: 'normal',
  points: 0,
  due_date: '',
  start_date: '',
  end_date: '',
})

const taskId = computed(() => String(route.params.id || ''))

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const dateValue = (value: unknown): string => {
  if (!value) {
    return ''
  }

  return String(value).slice(0, 10)
}

const normalizeProject = (project: any, index: number): TodoProject => {
  return {
    id: project.id ?? index,
    name: project.name ?? project.title ?? `Project ${index + 1}`,
  }
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

const extractTask = (payload: any): any => {
  return payload?.data?.task || payload?.data || payload?.task || payload
}

const hydrateForm = (task: any) => {
  form.title = task.title ?? task.name ?? ''
  form.description = task.description ?? ''
  form.project_id = task.project_id ?? task.projectId ?? task.project?.id ?? ''
  form.task_type = task.task_type ?? task.type ?? task.schedule_type ?? 'general'
  form.status = task.status ?? 'pending'
  form.priority = task.priority ?? 'normal'
  form.points = numberValue(task.points)
  form.due_date = dateValue(task.due_date ?? task.dueDate)
  form.start_date = dateValue(task.start_date ?? task.startDate)
  form.end_date = dateValue(task.end_date ?? task.endDate)
}

const buildPayload = () => {
  return {
    title: form.title,
    name: form.title,
    description: form.description || null,
    project_id: form.project_id || null,
    task_type: form.task_type,
    type: form.task_type,
    schedule_type: form.task_type,
    status: form.status,
    priority: form.priority,
    points: Number(form.points) || 0,
    due_date: form.due_date || null,
    start_date: form.start_date || null,
    end_date: form.end_date || null,
  }
}

const schedulePreview = computed(() => {
  if (form.task_type === 'daily') {
    return `Daily task${form.due_date ? ` due on ${form.due_date}` : ' with no due date yet'}.`
  }

  if (form.task_type === 'weekly') {
    return `Weekly task${form.start_date || form.end_date ? ` from ${form.start_date || 'no start date'} to ${form.end_date || 'no end date'}` : ' with no week range yet'}.`
  }

  if (form.task_type === 'monthly') {
    return `Monthly task${form.start_date || form.end_date ? ` from ${form.start_date || 'no start date'} to ${form.end_date || 'no end date'}` : ' with no month range yet'}.`
  }

  return 'General task with no schedule bucket.'
})

const clearMessages = () => {
  errorMessage.value = ''
  successMessage.value = ''
}

const loadProjects = async () => {
  try {
    const response = await api.get('/todo/projects')
    projects.value = extractProjects(response.data)
  } catch (error) {
    projects.value = []
    console.warn('[To-Do Edit Task] Failed to load projects.', error)
  }
}

const loadTask = async () => {
  loading.value = true
  clearMessages()

  try {
    const response = await api.get(`/todo/tasks/${taskId.value}`)
    hydrateForm(extractTask(response.data))
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task details API is not available yet or failed to load.'
    console.warn('[To-Do Edit Task] Failed to load task.', error)
  } finally {
    loading.value = false
  }
}

const updateTask = async () => {
  if (!form.title.trim()) {
    errorMessage.value = 'Task title is required.'
    return
  }

  saving.value = true
  clearMessages()

  try {
    await api.put(`/todo/tasks/${taskId.value}`, buildPayload())
    successMessage.value = 'Task updated successfully.'

    window.setTimeout(() => {
      router.push('/todo/tasks')
    }, 500)
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task update failed.'
    console.warn('[To-Do Edit Task] Failed to update task.', error)
  } finally {
    saving.value = false
  }
}

const markFinished = async () => {
  form.status = 'completed'
  await updateTask()
}

const deleteTask = async () => {
  const confirmed = window.confirm(`Delete task "${form.title || taskId.value}"?`)

  if (!confirmed) {
    return
  }

  deleting.value = true
  clearMessages()

  try {
    await api.delete(`/todo/tasks/${taskId.value}`)
    successMessage.value = 'Task deleted successfully.'

    window.setTimeout(() => {
      router.push('/todo/tasks')
    }, 500)
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task delete failed.'
    console.warn('[To-Do Edit Task] Failed to delete task.', error)
  } finally {
    deleting.value = false
  }
}

const formatStatus = (value: string): string => {
  return String(value || '')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (letter: string) => letter.toUpperCase())
}

const statusClass = (status: string): string => {
  const normalized = String(status || '').toLowerCase()

  if (normalized === 'finished' || normalized === 'completed') {
    return 'bg-emerald-50 text-emerald-700 dark:bg-emerald-500/10 dark:text-emerald-200'
  }

  if (normalized === 'in_progress') {
    return 'bg-blue-50 text-blue-700 dark:bg-blue-500/10 dark:text-blue-200'
  }

  return 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-200'
}

onMounted(async () => {
  await Promise.all([loadProjects(), loadTask()])
})
</script>
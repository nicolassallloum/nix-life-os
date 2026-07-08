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
          Create Task
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Add a new task and assign it to general, monthly, weekly, or daily planning.
        </p>
      </div>

      <RouterLink
        to="/todo/projects"
        class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:hover:bg-gray-700"
      >
        Manage Projects
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
      <div>
        <h2 class="text-lg font-bold text-gray-900 dark:text-white">
          Task Information
        </h2>
        <p class="text-sm text-gray-600 dark:text-gray-300">
          Fill the task details, points, schedule type, and linked project.
        </p>
      </div>

      <form class="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-2" @submit.prevent="submitTask">
        <div class="xl:col-span-2">
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Task Title
          </label>
          <input
            v-model.trim="form.title"
            type="text"
            required
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Example: Finish To-Do frontend page"
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
            Schedule Preview
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
            {{ saving ? 'Creating...' : 'Create Task' }}
          </button>

          <button
            type="button"
            class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
            @click="resetForm"
          >
            Reset
          </button>

          <RouterLink
            to="/todo/tasks"
            class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
          >
            Cancel
          </RouterLink>
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

const saving = ref(false)
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

const schedulePreview = computed(() => {
  const type = form.task_type

  if (type === 'daily') {
    return `Daily task${form.due_date ? ` due on ${form.due_date}` : ' with no due date yet'}.`
  }

  if (type === 'weekly') {
    return `Weekly task${form.start_date || form.end_date ? ` from ${form.start_date || 'no start date'} to ${form.end_date || 'no end date'}` : ' with no week range yet'}.`
  }

  if (type === 'monthly') {
    return `Monthly task${form.start_date || form.end_date ? ` from ${form.start_date || 'no start date'} to ${form.end_date || 'no end date'}` : ' with no month range yet'}.`
  }

  return 'General task with no schedule bucket.'
})

const clearMessages = () => {
  errorMessage.value = ''
  successMessage.value = ''
}

const resetForm = () => {
  form.title = ''
  form.description = ''
  form.project_id = route.query.project_id ? String(route.query.project_id) : ''
  form.task_type = 'general'
  form.status = 'pending'
  form.priority = 'normal'
  form.points = 0
  form.due_date = ''
  form.start_date = ''
  form.end_date = ''
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

const loadProjects = async () => {
  try {
    const response = await api.get('/todo/projects')
    projects.value = extractProjects(response.data)
  } catch (error) {
    projects.value = []
    console.warn('[To-Do Create Task] Failed to load projects.', error)
  }
}

const submitTask = async () => {
  if (!form.title.trim()) {
    errorMessage.value = 'Task title is required.'
    return
  }

  saving.value = true
  clearMessages()

  try {
    await api.post('/todo/tasks', buildPayload())

    successMessage.value = 'Task created successfully.'

    window.setTimeout(() => {
      router.push('/todo/tasks')
    }, 500)
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Task creation failed.'
    console.warn('[To-Do Create Task] Failed to create task.', error)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  resetForm()
  await loadProjects()
})
</script>

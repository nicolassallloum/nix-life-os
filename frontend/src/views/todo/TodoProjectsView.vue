<template>
  <div class="space-y-6">
    <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
          To-Do Projects
        </h1>
        <p class="text-gray-600 dark:text-gray-300">
          Create, update, delete, and track project progress, tasks, and points.
        </p>
      </div>

      <button
        type="button"
        class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-60"
        @click="openCreateForm"
      >
        + Create Project
      </button>
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
      v-if="showForm"
      class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800"
    >
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            {{ editingProject ? 'Update Project' : 'Create Project' }}
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            Add project details and status.
          </p>
        </div>

        <button
          type="button"
          class="text-sm font-bold text-gray-600 hover:text-gray-900 dark:text-gray-300 dark:hover:text-white"
          @click="closeForm"
        >
          Cancel
        </button>
      </div>

      <form class="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-2" @submit.prevent="submitProject">
        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Project Name
          </label>
          <input
            v-model.trim="form.name"
            type="text"
            required
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Example: Nix Life OS To-Do Module"
          />
        </div>

        <div>
          <label class="mb-1 block text-sm font-bold text-gray-700 dark:text-gray-300">
            Status
          </label>
          <select
            v-model="form.status"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
          >
            <option value="active">Active</option>
            <option value="completed">Completed</option>
            <option value="paused">Paused</option>
            <option value="archived">Archived</option>
          </select>
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
            rows="4"
            class="w-full rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-gray-900 outline-none transition focus:border-cyan-400 dark:border-gray-700 dark:bg-gray-900 dark:text-white"
            placeholder="Write project description..."
          />
        </div>

        <div class="flex flex-wrap gap-2 xl:col-span-2">
          <button
            type="submit"
            :disabled="saving"
            class="inline-flex items-center justify-center rounded-xl bg-cyan-500 px-4 py-2 text-sm font-bold text-slate-950 transition hover:bg-cyan-400 disabled:cursor-not-allowed disabled:opacity-60"
          >
            {{ saving ? 'Saving...' : editingProject ? 'Update Project' : 'Create Project' }}
          </button>

          <button
            type="button"
            class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
            @click="resetForm"
          >
            Reset
          </button>
        </div>
      </form>
    </section>

    <section class="rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            Projects List
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-300">
            {{ projects.length }} project{{ projects.length === 1 ? '' : 's' }} found.
          </p>
        </div>

        <button
          type="button"
          :disabled="loading"
          class="inline-flex items-center justify-center rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-60 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
          @click="loadProjects"
        >
          {{ loading ? 'Refreshing...' : 'Refresh' }}
        </button>
      </div>

      <div v-if="loading" class="mt-5 text-sm text-gray-600 dark:text-gray-300">
        Loading projects...
      </div>

      <div
        v-else-if="projects.length === 0"
        class="mt-5 rounded-xl border border-dashed border-gray-300 p-6 text-center text-sm text-gray-600 dark:border-gray-600 dark:text-gray-300"
      >
        No To-Do projects found yet.
      </div>

      <div v-else class="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-2">
        <article
          v-for="project in projects"
          :key="project.id"
          class="rounded-2xl border border-gray-100 p-5 dark:border-gray-700"
        >
          <div class="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div class="min-w-0">
              <div class="flex flex-wrap items-center gap-2">
                <h3 class="truncate text-lg font-black text-gray-900 dark:text-white">
                  {{ project.name }}
                </h3>

                <span
                  class="rounded-full px-3 py-1 text-xs font-black"
                  :class="statusClass(project.status)"
                >
                  {{ formatStatus(project.status) }}
                </span>
              </div>

              <p class="mt-2 line-clamp-2 text-sm text-gray-600 dark:text-gray-300">
                {{ project.description || 'No description added.' }}
              </p>

              <p class="mt-2 text-xs font-medium text-gray-500 dark:text-gray-400">
                {{ formatDate(project.startDate) }} → {{ formatDate(project.endDate) }}
              </p>
            </div>

            <RouterLink
              :to="`/todo/projects/${project.id}`"
              class="shrink-0 text-sm font-bold text-cyan-600 hover:text-cyan-500 dark:text-cyan-300"
            >
              Details
            </RouterLink>
          </div>

          <div class="mt-5 grid grid-cols-2 gap-3 md:grid-cols-4">
            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold text-gray-500 dark:text-gray-400">Total Tasks</p>
              <p class="mt-1 text-xl font-black text-gray-900 dark:text-white">{{ project.totalTasks }}</p>
            </div>

            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold text-gray-500 dark:text-gray-400">Finished</p>
              <p class="mt-1 text-xl font-black text-gray-900 dark:text-white">{{ project.finishedTasks }}</p>
            </div>

            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold text-gray-500 dark:text-gray-400">Complete</p>
              <p class="mt-1 text-xl font-black text-gray-900 dark:text-white">{{ project.completionPercentage }}%</p>
            </div>

            <div class="rounded-xl bg-gray-50 p-3 dark:bg-gray-900/50">
              <p class="text-xs font-bold text-gray-500 dark:text-gray-400">Points</p>
              <p class="mt-1 text-xl font-black text-gray-900 dark:text-white">{{ project.points }}</p>
            </div>
          </div>

          <div class="mt-4 h-3 overflow-hidden rounded-full bg-gray-100 dark:bg-gray-700">
            <div
              class="h-full rounded-full bg-cyan-500"
              :style="{ width: `${project.completionPercentage}%` }"
            />
          </div>

          <div class="mt-5 flex flex-wrap gap-2">
            <button
              type="button"
              class="rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
              @click="openEditForm(project)"
            >
              Edit
            </button>

            <RouterLink
              :to="`/todo/tasks?project_id=${project.id}`"
              class="rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm font-bold text-gray-800 transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white dark:hover:bg-gray-700"
            >
              View Tasks
            </RouterLink>

            <button
              type="button"
              :disabled="deletingId === project.id"
              class="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-bold text-red-700 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-200 dark:hover:bg-red-500/20"
              @click="deleteProject(project)"
            >
              {{ deletingId === project.id ? 'Deleting...' : 'Delete' }}
            </button>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
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

type ProjectForm = {
  name: string
  description: string
  status: string
  start_date: string
  end_date: string
}

const loading = ref(false)
const saving = ref(false)
const deletingId = ref<number | string | null>(null)
const showForm = ref(false)
const editingProject = ref<TodoProject | null>(null)
const projects = ref<TodoProject[]>([])
const errorMessage = ref('')
const successMessage = ref('')

const form = reactive<ProjectForm>({
  name: '',
  description: '',
  status: 'active',
  start_date: '',
  end_date: '',
})

const numberValue = (value: unknown): number => {
  const parsed = Number(value)

  return Number.isFinite(parsed) ? parsed : 0
}

const clampPercentage = (value: number): number => {
  return Math.min(100, Math.max(0, Math.round(value)))
}

const normalizeProject = (project: any, index: number): TodoProject => {
  const totalTasks = numberValue(project.totalTasks ?? project.total_tasks)
  const finishedTasks = numberValue(project.finishedTasks ?? project.finished_tasks ?? project.completedTasks ?? project.completed_tasks)
  const calculatedPercentage = totalTasks > 0 ? Math.round((finishedTasks / totalTasks) * 100) : 0

  return {
    id: project.id ?? index,
    name: project.name ?? project.title ?? `Project ${index + 1}`,
    description: project.description ?? '',
    status: project.status ?? 'active',
    startDate: project.startDate ?? project.start_date ?? '',
    endDate: project.endDate ?? project.end_date ?? '',
    totalTasks,
    finishedTasks,
    completionPercentage: clampPercentage(
      numberValue(project.completionPercentage ?? project.completion_percentage) || calculatedPercentage,
    ),
    points: numberValue(project.points ?? project.project_points ?? project.totalProjectPoints ?? project.total_project_points ?? project.totalPoints ?? project.total_points),
  }
}

const extractProjects = (payload: any): TodoProject[] => {
  const source = payload?.data?.data || payload?.data?.projects || payload?.data || payload?.projects || payload

  if (!Array.isArray(source)) {
    return []
  }

  return source.map(normalizeProject)
}

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

const resetForm = () => {
  form.name = ''
  form.description = ''
  form.status = 'active'
  form.start_date = ''
  form.end_date = ''
}

const openCreateForm = () => {
  clearMessages()
  editingProject.value = null
  resetForm()
  showForm.value = true
}

const openEditForm = (project: TodoProject) => {
  clearMessages()
  editingProject.value = project
  form.name = project.name
  form.description = project.description
  form.status = project.status
  form.start_date = project.startDate || ''
  form.end_date = project.endDate || ''
  showForm.value = true

  window.scrollTo({
    top: 0,
    behavior: 'smooth',
  })
}

const closeForm = () => {
  showForm.value = false
  editingProject.value = null
  resetForm()
}

const loadProjects = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    const response = await api.get('/todo/projects')
    projects.value = extractProjects(response.data)
  } catch (error) {
    projects.value = []
    errorMessage.value = 'Projects API is not available yet or failed to load.'
    console.warn('[To-Do Projects] Failed to load projects.', error)
  } finally {
    loading.value = false
  }
}

const submitProject = async () => {
  if (!form.name.trim()) {
    errorMessage.value = 'Project name is required.'
    return
  }

  saving.value = true
  clearMessages()

  const payload = {
    name: form.name,
    description: form.description || null,
    status: form.status,
    start_date: form.start_date || null,
    end_date: form.end_date || null,
  }

  try {
    if (editingProject.value) {
      await api.put(`/todo/projects/${editingProject.value.id}`, payload)
      showSuccess('Project updated successfully.')
    } else {
      await api.post('/todo/projects', payload)
      showSuccess('Project created successfully.')
    }

    closeForm()
    await loadProjects()
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Project save failed.'
    console.warn('[To-Do Projects] Failed to save project.', error)
  } finally {
    saving.value = false
  }
}

const deleteProject = async (project: TodoProject) => {
  const confirmed = window.confirm(`Delete project "${project.name}"?`)

  if (!confirmed) {
    return
  }

  deletingId.value = project.id
  clearMessages()

  try {
    await api.delete(`/todo/projects/${project.id}`)
    showSuccess('Project deleted successfully.')
    await loadProjects()
  } catch (error: any) {
    errorMessage.value =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Project delete failed.'
    console.warn('[To-Do Projects] Failed to delete project.', error)
  } finally {
    deletingId.value = null
  }
}

const formatStatus = (status: string): string => {
  return String(status || 'active')
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

const formatDate = (value: string): string => {
  if (!value) {
    return 'No date'
  }

  return value
}

onMounted(loadProjects)
</script>

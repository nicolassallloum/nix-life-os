<template>
  <div class="space-y-6 p-4">
    <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Projects</h1>
        <p class="text-sm text-gray-500">Manage your projects and linked tasks.</p>
      </div>

      <div class="flex flex-wrap gap-2">
        <button class="btn-primary">
          Add Project
        </button>

        <button class="btn-secondary" @click="openTaskModal(null)">
          Add Task
        </button>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
      <div class="dashboard-card">
        <p class="card-label">Total Tasks</p>
        <h3 class="card-value">{{ taskSummary.total }}</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Open Tasks</p>
        <h3 class="card-value">{{ taskSummary.open }}</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Completed Tasks</p>
        <h3 class="card-value">{{ taskSummary.completed }}</h3>
      </div>

      <div class="dashboard-card">
        <p class="card-label">Overdue Tasks</p>
        <h3 class="card-value">{{ taskSummary.overdue }}</h3>
      </div>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
      <div
        v-for="project in projects"
        :key="project.id"
        class="rounded-2xl bg-white p-5 shadow"
      >
        <h2 class="text-lg font-bold text-gray-900">
          {{ project.name || project.title }}
        </h2>

        <p class="mt-1 text-sm text-gray-500">
          {{ project.description || 'No description' }}
        </p>

        <div class="mt-4 flex flex-wrap gap-2">
          <button class="small-btn">
            View Details
          </button>

          <button class="small-btn" @click="openTaskModal(project.id)">
            Add Task
          </button>

          <button class="small-btn" @click="loadProjectTasks(project.id)">
            View Tasks
          </button>
        </div>
      </div>
    </div>

    <TaskModal
      :show="showTaskModal"
      :projects="projects"
      :selected-project-id="selectedProjectId"
      @close="showTaskModal = false"
      @saved="refreshTasks"
    />
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import TaskModal from '@/components/projects/TaskModal.vue'
import { projectTaskService } from '@/services/projectTaskService'
import apiClient from '@/services/apiClient'

const showTaskModal = ref(false)
const selectedProjectId = ref<number | null>(null)

const projects = ref<any[]>([])
const tasks = ref<any[]>([])

const taskSummary = reactive({
  total: 0,
  open: 0,
  completed: 0,
  overdue: 0,
})

function openTaskModal(projectId: number | null) {
  selectedProjectId.value = projectId
  showTaskModal.value = true
}

async function loadProjects() {
  /**
   * Adjust this endpoint if your existing projects endpoint is different.
   */
  const response = await apiClient.get('/projects')
  projects.value = response.data.data?.data || response.data.data || []
}

async function refreshTasks() {
  const response = await projectTaskService.list()
  const paginated = response.data.data

  tasks.value = paginated.data || []

  taskSummary.total = paginated.total || tasks.value.length
  taskSummary.open = tasks.value.filter((t) => t.status !== 'done').length
  taskSummary.completed = tasks.value.filter((t) => t.status === 'done').length

  const today = new Date().toISOString().slice(0, 10)
  taskSummary.overdue = tasks.value.filter((t) => {
    return t.due_date && t.due_date < today && t.status !== 'done'
  }).length
}

async function loadProjectTasks(projectId: number) {
  const response = await projectTaskService.listByProject(projectId)
}

onMounted(async () => {
  await loadProjects()
  await refreshTasks()
})
</script>

<style scoped>
.btn-primary {
  border-radius: 0.75rem;
  background: #2563eb;
  padding: 0.6rem 1rem;
  font-weight: 600;
  color: white;
}

.btn-secondary,
.small-btn {
  border-radius: 0.75rem;
  background: #f3f4f6;
  padding: 0.6rem 1rem;
  font-weight: 600;
  color: #111827;
}

.dashboard-card {
  border-radius: 1rem;
  background: white;
  padding: 1.25rem;
  box-shadow: 0 6px 20px rgba(15, 23, 42, 0.08);
}

.card-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.card-value {
  margin-top: 0.25rem;
  font-size: 1.5rem;
  font-weight: 800;
  color: #111827;
}
</style>

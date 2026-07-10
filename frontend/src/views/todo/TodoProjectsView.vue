<template>
  <div class="todo-page">
    <div class="todo-page__header">
      <div>
        <h1>To-Do Projects</h1>
        <p>Create, update, delete, and track project progress, tasks, and points.</p>
      </div>

      <button type="button" class="todo-button todo-button--primary" @click="openCreateForm">
        Create Project
      </button>
    </div>

    <TodoNotification :type="notification.type" :message="notification.message" @dismiss="clearNotification" />

    <section v-if="showForm" class="todo-panel">
      <div class="todo-panel__header">
        <div>
          <h2>{{ editingProject ? 'Update Project' : 'Create Project' }}</h2>
          <p>Add project details and status.</p>
        </div>

        <button type="button" class="todo-button todo-button--secondary" @click="closeForm">
          Cancel
        </button>
      </div>

      <form class="todo-form-grid todo-form-grid--project" novalidate @submit.prevent="submitProject">
        <label class="todo-field">
          <span>Project Name</span>
          <input v-model.trim="form.name" type="text" class="todo-control" placeholder="Nix Life OS To-Do Module" />
          <small v-if="validationErrors.name">{{ validationErrors.name }}</small>
        </label>

        <label class="todo-field">
          <span>Status</span>
          <select v-model="form.status" class="todo-control">
            <option value="active">Active</option>
            <option value="completed">Completed</option>
            <option value="paused">Paused</option>
          </select>
          <small v-if="validationErrors.status">{{ validationErrors.status }}</small>
        </label>

        <label class="todo-field">
          <span>Start Date</span>
          <input v-model="form.start_date" type="date" class="todo-control" />
          <small v-if="validationErrors.start_date">{{ validationErrors.start_date }}</small>
        </label>

        <label class="todo-field">
          <span>End Date</span>
          <input v-model="form.end_date" type="date" class="todo-control" />
          <small v-if="validationErrors.end_date">{{ validationErrors.end_date }}</small>
        </label>

        <label class="todo-field todo-field--full">
          <span>Description</span>
          <textarea v-model.trim="form.description" rows="4" class="todo-control todo-control--textarea" placeholder="Write project description"></textarea>
        </label>

        <div class="todo-actions todo-field--full">
          <button type="submit" class="todo-button todo-button--primary" :disabled="saving">
            {{ saving ? (editingProject ? 'Updating...' : 'Creating...') : editingProject ? 'Update Project' : 'Create Project' }}
          </button>
          <button type="button" class="todo-button todo-button--secondary" :disabled="saving" @click="resetForm">
            Reset
          </button>
        </div>
      </form>
    </section>

    <section class="todo-panel">
      <div class="todo-panel__header">
        <div>
          <h2>Projects List</h2>
          <p>{{ projects.length }} project{{ projects.length === 1 ? '' : 's' }} found.</p>
        </div>

        <button type="button" class="todo-button todo-button--secondary" :disabled="loading" @click="loadProjects">
          {{ loading ? 'Refreshing...' : 'Refresh' }}
        </button>
      </div>

      <TodoLoadingState v-if="loading" message="Loading projects..." compact />

      <TodoEmptyState
        v-else-if="projects.length === 0"
        title="No projects"
        message="No To-Do projects found yet."
      />

      <div v-else class="todo-project-grid">
        <TodoProjectCard
          v-for="project in projects"
          :key="project.id"
          :project="project"
          :deleting="deletingId === project.id"
          @edit="openEditForm"
          @delete="requestDeleteProject"
        />
      </div>
    </section>

    <TodoConfirmDialog
      :open="Boolean(projectPendingDelete)"
      title="Delete project"
      message="Are you sure you want to delete this project?"
      :loading="Boolean(deletingId)"
      @cancel="projectPendingDelete = null"
      @confirm="deleteProject"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import api from '@/services/api'
import TodoConfirmDialog from '@/components/todo/TodoConfirmDialog.vue'
import TodoEmptyState from '@/components/todo/TodoEmptyState.vue'
import TodoLoadingState from '@/components/todo/TodoLoadingState.vue'
import TodoNotification from '@/components/todo/TodoNotification.vue'
import TodoProjectCard from '@/components/todo/TodoProjectCard.vue'
import {
  clampPercentage,
  extractList,
  getApiMessage,
  mapValidationErrors,
  normalizeProjectStatus,
  numberValue,
  projectStatuses,
  type TodoProjectLike,
} from '@/components/todo/todoUtils'

type TodoProject = TodoProjectLike & {
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
const projectPendingDelete = ref<TodoProject | null>(null)
const projects = ref<TodoProject[]>([])
const validationErrors = reactive<Record<string, string>>({})
const notification = reactive<{ type: 'success' | 'error' | 'info'; message: string }>({
  type: 'info',
  message: '',
})

const form = reactive<ProjectForm>({
  name: '',
  description: '',
  status: 'active',
  start_date: '',
  end_date: '',
})

const notify = (type: 'success' | 'error' | 'info', message: string) => {
  notification.type = type
  notification.message = message

  if (type === 'success') {
    window.setTimeout(clearNotification, 2600)
  }
}

const clearNotification = () => {
  notification.message = ''
}

const clearValidationErrors = () => {
  Object.keys(validationErrors).forEach((key) => {
    delete validationErrors[key]
  })
}

const normalizeProject = (project: any, index: number): TodoProject => {
  const totalTasks = numberValue(project.totalTasks ?? project.total_tasks)
  const finishedTasks = numberValue(project.finishedTasks ?? project.finished_tasks ?? project.completedTasks ?? project.completed_tasks)
  const calculated = totalTasks > 0 ? (finishedTasks / totalTasks) * 100 : 0

  return {
    id: project.id ?? index,
    name: project.name ?? project.title ?? `Project ${index + 1}`,
    description: project.description ?? '',
    status: normalizeProjectStatus(project.status),
    startDate: project.startDate ?? project.start_date ?? '',
    endDate: project.endDate ?? project.end_date ?? '',
    totalTasks,
    finishedTasks,
    completionPercentage: clampPercentage(project.completionPercentage ?? project.completion_percentage ?? calculated),
    points: numberValue(project.points ?? project.totalProjectPoints ?? project.total_project_points ?? project.totalPoints ?? project.total_points),
  }
}

const resetForm = () => {
  form.name = ''
  form.description = ''
  form.status = 'active'
  form.start_date = ''
  form.end_date = ''
  clearValidationErrors()
}

const openCreateForm = () => {
  clearNotification()
  editingProject.value = null
  resetForm()
  showForm.value = true
}

const openEditForm = (project: TodoProjectLike) => {
  const normalized = normalizeProject(project, 0)
  clearNotification()
  editingProject.value = normalized
  form.name = normalized.name
  form.description = normalized.description
  form.status = normalized.status
  form.start_date = normalized.startDate || ''
  form.end_date = normalized.endDate || ''
  clearValidationErrors()
  showForm.value = true
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const closeForm = () => {
  showForm.value = false
  editingProject.value = null
  resetForm()
}

const validateProject = () => {
  clearValidationErrors()

  if (!form.name.trim()) {
    validationErrors.name = 'Project name is required.'
  }

  if (!projectStatuses.includes(form.status as any)) {
    validationErrors.status = 'Project status must be Active, Completed, or Paused.'
  }

  if (form.start_date && Number.isNaN(Date.parse(form.start_date))) {
    validationErrors.start_date = 'Start date must be a valid date.'
  }

  if (form.end_date && Number.isNaN(Date.parse(form.end_date))) {
    validationErrors.end_date = 'End date must be a valid date.'
  }

  if (form.start_date && form.end_date && form.end_date < form.start_date) {
    validationErrors.end_date = 'End date must be on or after the start date.'
  }

  return Object.keys(validationErrors).length === 0
}

const loadProjects = async () => {
  loading.value = true
  clearNotification()

  try {
    const response = await api.get('/todo/projects')
    projects.value = extractList<any>(response.data, 'projects').map(normalizeProject)
  } catch (error) {
    projects.value = []
    notify('error', getApiMessage(error, 'API failure. Failed to load projects.'))
  } finally {
    loading.value = false
  }
}

const submitProject = async () => {
  if (!validateProject()) {
    notify('error', 'Validation errors. Please fix the highlighted project fields.')
    return
  }

  saving.value = true
  clearNotification()

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
      notify('success', 'Project updated.')
    } else {
      await api.post('/todo/projects', payload)
      notify('success', 'Project created.')
    }

    closeForm()
    await loadProjects()
  } catch (error: any) {
    Object.assign(validationErrors, mapValidationErrors(error))
    notify('error', getApiMessage(error, editingProject.value ? 'Failed update. Project update failed.' : 'API failure. Project creation failed.'))
  } finally {
    saving.value = false
  }
}

const requestDeleteProject = (project: TodoProjectLike) => {
  projectPendingDelete.value = normalizeProject(project, 0)
}

const deleteProject = async () => {
  if (!projectPendingDelete.value) return

  deletingId.value = projectPendingDelete.value.id
  clearNotification()

  try {
    await api.delete(`/todo/projects/${projectPendingDelete.value.id}`)
    projectPendingDelete.value = null
    notify('success', 'Project deleted.')
    await loadProjects()
  } catch (error) {
    notify('error', getApiMessage(error, 'Failed delete. Project delete failed.'))
  } finally {
    deletingId.value = null
  }
}

onMounted(loadProjects)
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

.todo-form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
}

.todo-field {
  display: grid;
  gap: 7px;
}

.todo-field--full {
  grid-column: 1 / -1;
}

.todo-field span {
  color: var(--nix-text, #0f172a);
  font-size: 0.86rem;
  font-weight: 900;
}

.todo-field small {
  color: #dc2626;
  font-size: 0.8rem;
  font-weight: 800;
}

.todo-control {
  width: 100%;
  min-height: 44px;
  padding: 10px 12px;
  color: #0f172a !important;
  -webkit-text-fill-color: #0f172a !important;
  caret-color: #0891b2;
  background: #ffffff;
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 14px;
  outline: none;
}

.todo-control--textarea {
  min-height: 118px;
  resize: vertical;
}

.todo-control:focus {
  border-color: #06b6d4;
  box-shadow: 0 0 0 4px rgba(6, 182, 212, 0.14);
}

.todo-actions,
.todo-project-grid {
  display: grid;
  gap: 14px;
}

.todo-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.todo-project-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
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

.todo-button:disabled {
  cursor: not-allowed;
  opacity: 0.62;
}

.todo-button--primary {
  color: #0f172a;
  background: #06b6d4;
  border: 1px solid #06b6d4;
}

.todo-button--secondary {
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
}

:global(.dark) .todo-control {
  color: #f8fafc !important;
  -webkit-text-fill-color: #f8fafc !important;
  background: #0f172a;
  border-color: #334155;
}

@media (max-width: 1040px) {
  .todo-project-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 680px) {
  .todo-page__header,
  .todo-panel__header,
  .todo-form-grid {
    display: grid;
    grid-template-columns: 1fr;
  }

  .todo-actions,
  .todo-button {
    width: 100%;
  }
}
</style>

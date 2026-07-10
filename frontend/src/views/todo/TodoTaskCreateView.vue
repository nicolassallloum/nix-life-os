<template>
  <div class="todo-page">
    <div class="todo-page__header">
      <div>
        <RouterLink to="/todo/tasks" class="todo-link">Back to Tasks</RouterLink>
        <h1>Create Task</h1>
        <p>Add a new task and assign it to general, monthly, weekly, or daily planning.</p>
      </div>

      <RouterLink to="/todo/projects" class="todo-button todo-button--secondary">
        Manage Projects
      </RouterLink>
    </div>

    <TodoNotification :type="notification.type" :message="notification.message" @dismiss="clearNotification" />

    <section class="todo-panel">
      <div class="todo-panel__header">
        <div>
          <h2>Task Information</h2>
          <p>Fill the task details, points, schedule type, and linked project.</p>
        </div>
        <TodoBadge kind="type" :value="form.task_type" />
      </div>

      <form class="todo-form-grid" novalidate @submit.prevent="submitTask">
        <label class="todo-field todo-field--full">
          <span>Task Name</span>
          <input v-model.trim="form.title" type="text" class="todo-control" placeholder="Finish To-Do frontend page" />
          <small v-if="validationErrors.title">{{ validationErrors.title }}</small>
        </label>

        <label class="todo-field">
          <span>Project</span>
          <select v-model="form.project_id" class="todo-control">
            <option value="">No project</option>
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.name }}
            </option>
          </select>
          <small v-if="validationErrors.project_id">{{ validationErrors.project_id }}</small>
        </label>

        <label class="todo-field">
          <span>Task Type</span>
          <select v-model="form.task_type" class="todo-control">
            <option value="general">General</option>
            <option value="monthly">Monthly</option>
            <option value="weekly">Weekly</option>
            <option value="daily">Daily</option>
          </select>
          <small v-if="validationErrors.task_type">{{ validationErrors.task_type }}</small>
        </label>

        <label class="todo-field">
          <span>Status</span>
          <select v-model="form.status" class="todo-control">
            <option value="pending">Pending</option>
            <option value="in_progress">In Progress</option>
            <option value="finished">Finished</option>
          </select>
          <small v-if="validationErrors.status">{{ validationErrors.status }}</small>
        </label>

        <label class="todo-field">
          <span>Priority</span>
          <select v-model="form.priority" class="todo-control">
            <option value="low">Low Priority</option>
            <option value="medium">Medium Priority</option>
            <option value="high">High Priority</option>
          </select>
          <small v-if="validationErrors.priority">{{ validationErrors.priority }}</small>
        </label>

        <label class="todo-field">
          <span>Points</span>
          <input v-model.number="form.points" type="number" min="0" step="1" class="todo-control" placeholder="0" />
          <small v-if="validationErrors.points">{{ validationErrors.points }}</small>
        </label>

        <label class="todo-field">
          <span>Due Date</span>
          <input v-model="form.due_date" type="date" class="todo-control" />
          <small v-if="validationErrors.due_date">{{ validationErrors.due_date }}</small>
        </label>

        <label class="todo-field todo-field--full">
          <span>Description</span>
          <textarea v-model.trim="form.description" rows="5" class="todo-control todo-control--textarea" placeholder="Write task details"></textarea>
        </label>

        <div class="todo-preview todo-field--full">
          <h3>Schedule Preview</h3>
          <p>{{ schedulePreview }}</p>
        </div>

        <div class="todo-actions todo-field--full">
          <button type="submit" class="todo-button todo-button--primary" :disabled="saving">
            {{ saving ? 'Creating...' : 'Create Task' }}
          </button>
          <button type="button" class="todo-button todo-button--secondary" :disabled="saving" @click="resetForm">
            Reset
          </button>
          <RouterLink to="/todo/tasks" class="todo-button todo-button--secondary">
            Cancel
          </RouterLink>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import api from '@/services/api'
import TodoBadge from '@/components/todo/TodoBadge.vue'
import TodoNotification from '@/components/todo/TodoNotification.vue'
import {
  extractList,
  getApiMessage,
  mapValidationErrors,
  normalizeTaskPriority,
  normalizeTaskStatus,
  normalizeTaskType,
  numberValue,
  taskPriorities,
  taskStatuses,
  taskTypes,
} from '@/components/todo/todoUtils'

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
}

const route = useRoute()
const router = useRouter()
const saving = ref(false)
const projects = ref<TodoProject[]>([])
const validationErrors = reactive<Record<string, string>>({})
const notification = reactive<{ type: 'success' | 'error' | 'info'; message: string }>({
  type: 'info',
  message: '',
})

const form = reactive<TaskForm>({
  title: '',
  description: '',
  project_id: '',
  task_type: 'general',
  status: 'pending',
  priority: 'medium',
  points: 0,
  due_date: '',
})

const notify = (type: 'success' | 'error' | 'info', message: string) => {
  notification.type = type
  notification.message = message
}

const clearNotification = () => {
  notification.message = ''
}

const clearValidationErrors = () => {
  Object.keys(validationErrors).forEach((key) => {
    delete validationErrors[key]
  })
}

const normalizeProject = (project: any, index: number): TodoProject => ({
  id: project.id ?? index,
  name: project.name ?? project.title ?? `Project ${index + 1}`,
})

const schedulePreview = computed(() => {
  if (form.task_type === 'daily') {
    return `Daily task${form.due_date ? ` due on ${form.due_date}` : ' with no due date yet'}.`
  }

  if (form.task_type === 'weekly') {
    return 'Weekly task grouped in the weekly planning list.'
  }

  if (form.task_type === 'monthly') {
    return 'Monthly task grouped in the monthly planning list.'
  }

  return 'General task with no schedule bucket.'
})

const resetForm = () => {
  form.title = ''
  form.description = ''
  form.project_id = route.query.project_id ? String(route.query.project_id) : ''
  form.task_type = 'general'
  form.status = 'pending'
  form.priority = 'medium'
  form.points = 0
  form.due_date = ''
  clearValidationErrors()
}

const validateTask = () => {
  clearValidationErrors()

  if (!form.title.trim()) validationErrors.title = 'Task name is required.'
  if (!taskTypes.includes(form.task_type as any)) validationErrors.task_type = 'Task type must be General, Monthly, Weekly, or Daily.'
  if (!taskStatuses.includes(form.status as any)) validationErrors.status = 'Task status must be Pending, In Progress, or Finished.'
  if (!taskPriorities.includes(form.priority as any)) validationErrors.priority = 'Priority must be Low, Medium, or High.'
  if (!Number.isFinite(Number(form.points)) || Number(form.points) < 0) validationErrors.points = 'Points must be a numeric value of 0 or greater.'
  if (form.due_date && Number.isNaN(Date.parse(form.due_date))) validationErrors.due_date = 'Due date must be a valid date.'

  if (form.project_id && !projects.value.some((project) => String(project.id) === String(form.project_id))) {
    validationErrors.project_id = 'Project ID is not valid.'
  }

  return Object.keys(validationErrors).length === 0
}

const buildPayload = () => ({
  title: form.title,
  description: form.description || null,
  project_id: form.project_id || null,
  task_type: normalizeTaskType(form.task_type),
  status: normalizeTaskStatus(form.status),
  priority: normalizeTaskPriority(form.priority),
  points: numberValue(form.points),
  due_date: form.due_date || null,
})

const loadProjects = async () => {
  try {
    const response = await api.get('/todo/projects')
    projects.value = extractList<any>(response.data, 'projects').map(normalizeProject)
  } catch (error) {
    projects.value = []
    notify('error', getApiMessage(error, 'API failure. Failed to load projects.'))
  }
}

const submitTask = async () => {
  if (!validateTask()) {
    notify('error', 'Validation errors. Please fix the highlighted task fields.')
    return
  }

  saving.value = true
  clearNotification()

  try {
    await api.post('/todo/tasks', buildPayload())
    notify('success', 'Task created.')
    window.setTimeout(() => router.push('/todo/tasks'), 500)
  } catch (error: any) {
    Object.assign(validationErrors, mapValidationErrors(error))
    notify('error', getApiMessage(error, 'API failure. Task creation failed.'))
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  resetForm()
  await loadProjects()
})
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
  margin-top: 8px;
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

.todo-link {
  color: #0891b2;
  font-size: 0.9rem;
  font-weight: 900;
  text-decoration: none;
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
  min-height: 130px;
  resize: vertical;
}

.todo-control:focus {
  border-color: #06b6d4;
  box-shadow: 0 0 0 4px rgba(6, 182, 212, 0.14);
}

.todo-preview {
  padding: 16px;
  background: rgba(148, 163, 184, 0.08);
  border-radius: 16px;
}

.todo-preview h3 {
  margin: 0;
  color: var(--nix-text, #0f172a);
  font-size: 0.95rem;
  font-weight: 900;
}

.todo-preview p {
  margin: 6px 0 0;
  color: var(--nix-text-muted, #64748b);
}

.todo-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
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

@media (max-width: 700px) {
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

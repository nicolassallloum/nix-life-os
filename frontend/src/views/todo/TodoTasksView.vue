<template>
  <div class="todo-page">
    <div class="todo-page__header">
      <div>
        <h1>To-Do Tasks</h1>
        <p>Manage general, monthly, weekly, daily, and completed tasks.</p>
      </div>

      <RouterLink to="/todo/tasks/create" class="todo-button todo-button--primary">
        Create Task
      </RouterLink>
    </div>

    <TodoNotification :type="notification.type" :message="notification.message" @dismiss="clearNotification" />

    <section class="todo-panel">
      <div class="todo-panel__header">
        <div>
          <h2>Filters</h2>
          <p>Search and filter tasks by project, status, and priority.</p>
        </div>

        <button type="button" class="todo-button todo-button--secondary" @click="resetFilters">
          Reset Filters
        </button>
      </div>

      <div class="todo-form-grid">
        <label class="todo-field">
          <span>Search</span>
          <input v-model.trim="filters.search" type="search" class="todo-control" placeholder="Search task name" @keyup.enter="loadTasks" />
        </label>

        <label class="todo-field">
          <span>Project</span>
          <select v-model="filters.project_id" class="todo-control">
            <option value="">All projects</option>
            <option v-for="project in projects" :key="project.id" :value="project.id">
              {{ project.name }}
            </option>
          </select>
        </label>

        <label class="todo-field">
          <span>Status</span>
          <select v-model="filters.status" class="todo-control">
            <option value="">All statuses</option>
            <option value="pending">Pending</option>
            <option value="in_progress">In Progress</option>
            <option value="finished">Finished</option>
          </select>
        </label>

        <label class="todo-field">
          <span>Priority</span>
          <select v-model="filters.priority" class="todo-control">
            <option value="">All priorities</option>
            <option value="low">Low Priority</option>
            <option value="medium">Medium Priority</option>
            <option value="high">High Priority</option>
          </select>
        </label>
      </div>

      <div class="todo-actions">
        <button type="button" class="todo-button todo-button--primary" :disabled="loading" @click="loadTasks">
          {{ loading ? 'Loading...' : 'Apply Filters' }}
        </button>
        <button type="button" class="todo-button todo-button--secondary" :disabled="loading || projectsLoading" @click="refreshAll">
          {{ loading || projectsLoading ? 'Refreshing...' : 'Refresh' }}
        </button>
      </div>
    </section>

    <section class="todo-panel">
      <div class="todo-summary-grid">
        <article v-for="card in summaryCards" :key="card.label" class="todo-summary-card">
          <span>{{ card.label }}</span>
          <strong>{{ card.value }}</strong>
        </article>
      </div>
      <TodoProgressBar
        class="todo-summary-progress"
        :value="completionPercentage"
        label="Overall task completion"
        :meta="`${groupedTasks.completed.length} of ${tasks.length} tasks finished`"
      />
    </section>

    <TodoLoadingState v-if="loading" message="Loading tasks..." />

    <div v-else class="todo-task-grid">
      <TaskGroupSection
        title="General Tasks"
        subtitle="Tasks without daily, weekly, or monthly schedule."
        :tasks="groupedTasks.general"
        empty-title="No tasks"
        empty-message="No general tasks found."
        :completing-id="completingId"
        :deleting-id="deletingId"
        @finish="finishTask"
        @delete="requestDeleteTask"
      />

      <TaskGroupSection
        title="Monthly Tasks"
        subtitle="Tasks planned for the month."
        :tasks="groupedTasks.monthly"
        empty-title="No monthly tasks"
        empty-message="No monthly tasks found."
        :completing-id="completingId"
        :deleting-id="deletingId"
        @finish="finishTask"
        @delete="requestDeleteTask"
      />

      <TaskGroupSection
        title="Weekly Tasks"
        subtitle="Tasks planned for the week."
        :tasks="groupedTasks.weekly"
        empty-title="No weekly tasks"
        empty-message="No weekly tasks found."
        :completing-id="completingId"
        :deleting-id="deletingId"
        @finish="finishTask"
        @delete="requestDeleteTask"
      />

      <TaskGroupSection
        title="Daily Tasks"
        subtitle="Tasks planned for the day."
        :tasks="groupedTasks.daily"
        empty-title="No daily tasks"
        empty-message="No daily tasks found."
        :completing-id="completingId"
        :deleting-id="deletingId"
        @finish="finishTask"
        @delete="requestDeleteTask"
      />

      <TaskGroupSection
        title="Completed Tasks"
        subtitle="Finished tasks and earned points."
        :tasks="groupedTasks.completed"
        empty-title="No completed tasks"
        empty-message="No completed tasks found."
        completed-section
        :deleting-id="deletingId"
        @delete="requestDeleteTask"
      />
    </div>

    <TodoConfirmDialog
      :open="Boolean(taskPendingDelete)"
      title="Delete task"
      message="Are you sure you want to delete this task?"
      :loading="Boolean(deletingId)"
      @cancel="taskPendingDelete = null"
      @confirm="deleteTask"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, reactive, ref } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import api from '@/services/api'
import TodoConfirmDialog from '@/components/todo/TodoConfirmDialog.vue'
import TodoEmptyState from '@/components/todo/TodoEmptyState.vue'
import TodoLoadingState from '@/components/todo/TodoLoadingState.vue'
import TodoNotification from '@/components/todo/TodoNotification.vue'
import TodoProgressBar from '@/components/todo/TodoProgressBar.vue'
import TodoTaskCard from '@/components/todo/TodoTaskCard.vue'
import {
  extractList,
  getApiMessage,
  isCompletedTask,
  normalizeTaskPriority,
  normalizeTaskStatus,
  normalizeTaskType,
  numberValue,
  type TodoTaskLike,
} from '@/components/todo/todoUtils'

type TodoProject = {
  id: number | string
  name: string
}

type TodoTask = TodoTaskLike & {
  description: string
  task_type: string
  status: string
  priority: string
  points: number
  due_date: string
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
    title: { type: String, required: true },
    subtitle: { type: String, required: true },
    tasks: { type: Array as () => TodoTask[], required: true },
    emptyTitle: { type: String, required: true },
    emptyMessage: { type: String, required: true },
    completedSection: { type: Boolean, default: false },
    completingId: { type: [String, Number, null], default: null },
    deletingId: { type: [String, Number, null], default: null },
  },
  emits: ['finish', 'delete'],
  setup(props, { emit }) {
    return () =>
      h('section', { class: 'todo-panel todo-task-section' }, [
        h('div', { class: 'todo-panel__header' }, [
          h('div', null, [
            h('h2', null, props.title),
            h('p', null, props.subtitle),
          ]),
          h('span', { class: 'todo-count-pill' }, `${props.tasks.length} tasks`),
        ]),
        props.tasks.length === 0
          ? h(TodoEmptyState, {
              title: props.emptyTitle,
              message: props.emptyMessage,
            })
          : h(
              'div',
              { class: 'todo-task-list' },
              props.tasks.map((task) =>
                h(TodoTaskCard, {
                  key: task.id,
                  task,
                  showActions: true,
                  completing: props.completingId === task.id,
                  deleting: props.deletingId === task.id,
                  onFinish: props.completedSection ? undefined : () => emit('finish', task),
                  onDelete: () => emit('delete', task),
                }),
              ),
            ),
      ])
  },
})

const route = useRoute()
const loading = ref(false)
const projectsLoading = ref(false)
const tasks = ref<TodoTask[]>([])
const projects = ref<TodoProject[]>([])
const completingId = ref<number | string | null>(null)
const deletingId = ref<number | string | null>(null)
const taskPendingDelete = ref<TodoTask | null>(null)
const notification = reactive<{ type: 'success' | 'error' | 'info'; message: string }>({
  type: 'info',
  message: '',
})

const filters = reactive<TaskFilters>({
  search: '',
  project_id: '',
  status: '',
  priority: '',
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

const normalizeProject = (project: any, index: number): TodoProject => ({
  id: project.id ?? index,
  name: project.name ?? project.title ?? `Project ${index + 1}`,
})

const normalizeTask = (task: any, index: number): TodoTask => ({
  id: task.id ?? index,
  title: task.title ?? task.name ?? `Task ${index + 1}`,
  description: task.description ?? '',
  task_type: normalizeTaskType(task.task_type ?? task.type ?? task.schedule_type),
  status: normalizeTaskStatus(task.status),
  priority: normalizeTaskPriority(task.priority),
  points: numberValue(task.points),
  due_date: task.due_date ?? task.dueDate ?? '',
  projectId: task.project_id ?? task.projectId ?? task.project?.id ?? null,
  projectName: task.project_name ?? task.projectName ?? task.project?.name ?? '',
})

const isCompleted = (task: TodoTask): boolean => isCompletedTask(task.status)
const typeOf = (task: TodoTask): string => String(task.task_type || 'general').toLowerCase()

const groupedTasks = computed(() => ({
  general: tasks.value.filter((task) => !isCompleted(task) && typeOf(task) === 'general'),
  monthly: tasks.value.filter((task) => !isCompleted(task) && typeOf(task) === 'monthly'),
  weekly: tasks.value.filter((task) => !isCompleted(task) && typeOf(task) === 'weekly'),
  daily: tasks.value.filter((task) => !isCompleted(task) && typeOf(task) === 'daily'),
  completed: tasks.value.filter(isCompleted),
}))

const completionPercentage = computed(() => (tasks.value.length ? Math.round((groupedTasks.value.completed.length / tasks.value.length) * 100) : 0))

const summaryCards = computed(() => [
  { label: 'Total Tasks', value: tasks.value.length },
  { label: 'General', value: groupedTasks.value.general.length },
  { label: 'Monthly', value: groupedTasks.value.monthly.length },
  { label: 'Weekly', value: groupedTasks.value.weekly.length },
  { label: 'Daily', value: groupedTasks.value.daily.length },
  { label: 'Completed', value: groupedTasks.value.completed.length },
])

const buildTaskParams = () => {
  const params: Record<string, string | number> = {}

  if (filters.search) params.search = filters.search
  if (filters.project_id) params.project_id = filters.project_id
  if (filters.status) params.status = filters.status
  if (filters.priority) params.priority = filters.priority

  return params
}

const loadTasks = async () => {
  loading.value = true
  clearNotification()

  try {
    const response = await api.get('/todo/tasks', { params: buildTaskParams() })
    const loadedTasks = extractList<any>(response.data, 'tasks').map(normalizeTask)
    tasks.value = filters.search
      ? loadedTasks.filter((task) => task.title.toLowerCase().includes(filters.search.toLowerCase()))
      : loadedTasks
  } catch (error) {
    tasks.value = []
    notify('error', getApiMessage(error, 'API failure. Failed to load tasks.'))
  } finally {
    loading.value = false
  }
}

const loadProjects = async () => {
  projectsLoading.value = true

  try {
    const response = await api.get('/todo/projects')
    projects.value = extractList<any>(response.data, 'projects').map(normalizeProject)
  } catch (error) {
    projects.value = []
    notify('error', getApiMessage(error, 'API failure. Failed to load project filter options.'))
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
  completingId.value = task.id
  clearNotification()

  try {
    await api.patch(`/todo/tasks/${task.id}/status`, { status: 'finished' })
    notify('success', 'Task completed.')
    await loadTasks()
  } catch (error) {
    notify('error', getApiMessage(error, 'Failed update. Task completion failed.'))
  } finally {
    completingId.value = null
  }
}

const requestDeleteTask = (task: TodoTask) => {
  taskPendingDelete.value = task
}

const deleteTask = async () => {
  if (!taskPendingDelete.value) return

  deletingId.value = taskPendingDelete.value.id
  clearNotification()

  try {
    await api.delete(`/todo/tasks/${taskPendingDelete.value.id}`)
    taskPendingDelete.value = null
    notify('success', 'Task deleted.')
    await loadTasks()
  } catch (error) {
    notify('error', getApiMessage(error, 'Failed delete. Task delete failed.'))
  } finally {
    deletingId.value = null
  }
}

onMounted(async () => {
  if (route.query.project_id) filters.project_id = String(route.query.project_id)
  if (route.query.status) filters.status = normalizeTaskStatus(route.query.status)
  if (route.query.priority) filters.priority = normalizeTaskPriority(route.query.priority)

  await refreshAll()
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

.todo-form-grid,
.todo-summary-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.todo-field {
  display: grid;
  gap: 7px;
}

.todo-field span {
  color: var(--nix-text, #0f172a);
  font-size: 0.86rem;
  font-weight: 900;
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

.todo-control:focus {
  border-color: #06b6d4;
  box-shadow: 0 0 0 4px rgba(6, 182, 212, 0.14);
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

.todo-summary-card {
  min-width: 0;
  padding: 14px;
  background: rgba(148, 163, 184, 0.08);
  border-radius: 16px;
}

.todo-summary-card span {
  display: block;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.82rem;
  font-weight: 800;
}

.todo-summary-card strong {
  display: block;
  margin-top: 6px;
  color: var(--nix-text, #0f172a);
  font-size: 1.3rem;
  font-weight: 900;
}

.todo-summary-progress {
  margin-top: 2px;
}

.todo-task-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.todo-task-section:last-child {
  grid-column: 1 / -1;
}

.todo-task-list {
  display: grid;
  gap: 12px;
}

.todo-count-pill {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  padding: 5px 10px;
  color: #155e75;
  background: #ecfeff;
  border-radius: 999px;
  font-size: 0.78rem;
  font-weight: 900;
  white-space: nowrap;
}

:global(.dark) .todo-control {
  color: #f8fafc !important;
  -webkit-text-fill-color: #f8fafc !important;
  background: #0f172a;
  border-color: #334155;
}

:global(.dark) .todo-count-pill {
  color: #a5f3fc;
  background: rgba(6, 182, 212, 0.14);
}

@media (max-width: 1180px) {
  .todo-form-grid,
  .todo-summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .todo-task-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .todo-page__header,
  .todo-panel__header {
    display: grid;
  }

  .todo-form-grid,
  .todo-summary-grid,
  .todo-actions {
    grid-template-columns: 1fr;
  }

  .todo-form-grid,
  .todo-summary-grid,
  .todo-actions,
  .todo-button {
    width: 100%;
  }
}
</style>

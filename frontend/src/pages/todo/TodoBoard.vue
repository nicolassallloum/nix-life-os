<template>
  <main class="todo-board-page">
    <header class="todo-board-header">
      <div>
        <p class="todo-board-eyebrow">To-Do Module</p>
        <h1>Task Organization</h1>
      </div>
      <button type="button" class="todo-board-button" :disabled="loading || syncing" @click="fetchBoard">
        {{ loading ? 'Refreshing...' : syncing ? 'Saving...' : 'Refresh' }}
      </button>
    </header>

    <TodoNotification :type="notification.type" :message="notification.message" @dismiss="clearNotification" />
    <TodoPointsSummary :points="pointsSummary" />
    <TodoLoadingState v-if="loading" message="Loading task board..." />

    <section v-else class="todo-sections">
      <article
        v-for="section in sectionList"
        :key="section.type"
        class="todo-section"
        :class="{
          'todo-section--active': activeDropZone === section.type,
          'todo-section--saving': syncing && savingSection === section.type,
        }"
      >
        <header class="todo-section-header">
          <div>
            <h2>{{ section.label }}</h2>
            <span>{{ sections[section.type].length }} tasks</span>
          </div>
          <strong>{{ number(pointsFor(section.type)) }} pts</strong>
        </header>

        <div v-if="syncing && savingSection === section.type" class="todo-saving">
          Saving task order...
        </div>

        <draggable
          v-model="sections[section.type]"
          :data-section="section.type"
          item-key="id"
          group="todo-sections"
          class="task-dropzone"
          ghost-class="task-card--ghost"
          drag-class="task-card--dragging"
          :move="canMoveTask"
          :disabled="syncing"
          @start="activeDropZone = section.type"
          @end="activeDropZone = ''"
          @change="event => onSectionChange(section.type, event)"
        >
          <template #item="{ element }">
            <TodoTaskCard :task="normalizeBoardTask(element)" :show-actions="false" dragging />
          </template>

          <template #footer>
            <TodoEmptyState
              v-if="!sections[section.type].length"
              :title="emptyTitle(section.type)"
              message="Drop tasks here."
            />
          </template>
        </draggable>
      </article>
    </section>
  </main>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import draggable from 'vuedraggable'
import TodoEmptyState from '@/components/todo/TodoEmptyState.vue'
import TodoLoadingState from '@/components/todo/TodoLoadingState.vue'
import TodoNotification from '@/components/todo/TodoNotification.vue'
import TodoPointsSummary from '@/components/todo/TodoPointsSummary.vue'
import TodoTaskCard from '@/components/todo/TodoTaskCard.vue'
import {
  getApiMessage,
  normalizeTaskPriority,
  normalizeTaskStatus,
  normalizeTaskType,
  numberValue,
} from '@/components/todo/todoUtils'
import api from '@/services/api'

const sectionList = [
  { type: 'general', label: 'General Tasks' },
  { type: 'monthly', label: 'Monthly Tasks' },
  { type: 'weekly', label: 'Weekly Tasks' },
  { type: 'daily', label: 'Daily Tasks' },
]

const sections = reactive({
  general: [],
  monthly: [],
  weekly: [],
  daily: [],
})

const pointsSummary = ref({
  total_completed_points: 0,
  general_points: 0,
  monthly_points: 0,
  weekly_points: 0,
  daily_points: 0,
  project_points: [],
})

const loading = ref(false)
const syncing = ref(false)
const savingSection = ref('')
const activeDropZone = ref('')
const notification = reactive({ type: 'info', message: '' })
let lastGoodState = null

const clearNotification = () => {
  notification.message = ''
}

const notify = (type, message) => {
  notification.type = type
  notification.message = message

  if (type === 'success') {
    window.setTimeout(clearNotification, 2600)
  }
}

const cloneState = () => JSON.parse(JSON.stringify({ sections, pointsSummary: pointsSummary.value }))

const restoreState = state => {
  if (!state) return
  for (const section of sectionList) {
    sections[section.type] = state.sections[section.type] || []
  }
  pointsSummary.value = state.pointsSummary || pointsSummary.value
}

const normalizeBoardTask = task => ({
  id: task.id,
  title: task.title || task.name || 'Untitled task',
  description: task.description || '',
  task_type: normalizeTaskType(task.task_type || task.type),
  status: normalizeTaskStatus(task.status),
  priority: normalizeTaskPriority(task.priority),
  points: numberValue(task.points),
  due_date: task.due_date || task.dueDate || '',
  projectName: task.project_name || task.projectName || task.project?.name || '',
})

const applyPayload = payload => {
  const data = payload?.data || payload || {}
  const grouped = data.tasks || data.grouped_tasks || data

  for (const section of sectionList) {
    sections[section.type] = Array.isArray(grouped[section.type])
      ? grouped[section.type].map(normalizeBoardTask)
      : []
  }

  pointsSummary.value = data.points_summary || data.pointsSummary || pointsSummary.value
  lastGoodState = cloneState()
}

const fetchBoard = async () => {
  loading.value = true
  clearNotification()

  try {
    const { data } = await api.get('/todo/tasks/grouped')
    applyPayload(data)
  } catch (exception) {
    notify('error', getApiMessage(exception, 'Network error. Unable to load tasks.'))
  } finally {
    loading.value = false
  }
}

const onSectionChange = async (targetType, event) => {
  if (syncing.value) return

  const addedTask = event.added?.element
  const movedTask = event.moved?.element

  if (!addedTask && !movedTask) return

  syncing.value = true
  savingSection.value = targetType
  clearNotification()

  try {
    if (addedTask) {
      await api.patch(`/todo/tasks/${addedTask.id}/move`, {
        task_type: targetType,
        sort_order: event.added.newIndex,
      })
      notify('success', 'Task moved.')
    } else if (movedTask) {
      await api.patch('/todo/tasks/reorder', {
        tasks: sections[targetType].map((task, index) => ({
          id: task.id,
          sort_order: index,
        })),
      })
      notify('success', 'Task reordered.')
    }

    lastGoodState = cloneState()
  } catch (exception) {
    restoreState(lastGoodState)
    notify('error', getApiMessage(exception, 'Failed drag-and-drop save. Previous task order was restored.'))
  } finally {
    syncing.value = false
    savingSection.value = ''
  }
}

const canMoveTask = event => {
  if (syncing.value) return false

  const from = event.from?.dataset?.section
  const to = event.to?.dataset?.section

  activeDropZone.value = to || ''

  if (!from || !to) return false
  if (from === to) return true
  if (to === 'general') return true

  const allowed = {
    general: ['monthly', 'weekly', 'daily'],
    monthly: ['weekly'],
    weekly: ['daily'],
    daily: [],
  }

  return allowed[from]?.includes(to) || false
}

const emptyTitle = type => {
  if (type === 'monthly') return 'No monthly tasks'
  if (type === 'weekly') return 'No weekly tasks'
  if (type === 'daily') return 'No daily tasks'

  return 'No tasks'
}

const pointsFor = type => pointsSummary.value?.[`${type}_points`] || 0
const number = value => new Intl.NumberFormat().format(Number(value || 0))

onMounted(fetchBoard)
</script>

<style scoped>
.todo-board-page {
  display: grid;
  gap: 20px;
}

.todo-board-header,
.todo-section-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.todo-board-eyebrow {
  margin: 0 0 4px;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.todo-board-header h1 {
  margin: 0;
  color: var(--nix-text, #0f172a);
  font-size: 1.6rem;
  font-weight: 900;
}

.todo-board-button {
  min-height: 42px;
  padding: 10px 16px;
  color: #0f172a;
  background: #06b6d4;
  border: 1px solid #06b6d4;
  border-radius: 14px;
  font-weight: 900;
}

.todo-board-button:disabled {
  cursor: not-allowed;
  opacity: 0.62;
}

.todo-sections {
  display: grid;
  grid-template-columns: repeat(4, minmax(240px, 1fr));
  gap: 16px;
}

.todo-section {
  display: grid;
  align-content: start;
  gap: 12px;
  min-height: 360px;
  padding: 16px;
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 20px;
  box-shadow: var(--nix-shadow-sm, 0 1px 2px rgba(15, 23, 42, 0.05));
  transition:
    border-color 0.18s ease,
    box-shadow 0.18s ease;
}

.todo-section--active {
  border-color: #06b6d4;
  box-shadow: 0 0 0 4px rgba(6, 182, 212, 0.14);
}

.todo-section--saving {
  opacity: 0.78;
}

.todo-section-header h2 {
  margin: 0;
  color: var(--nix-text, #0f172a);
  font-size: 1rem;
  font-weight: 900;
}

.todo-section-header span,
.todo-section-header strong {
  color: var(--nix-text-muted, #64748b);
  font-size: 0.82rem;
  font-weight: 900;
}

.todo-saving {
  padding: 10px 12px;
  color: #155e75;
  background: #ecfeff;
  border-radius: 12px;
  font-size: 0.86rem;
  font-weight: 900;
}

.task-dropzone {
  display: grid;
  align-content: start;
  gap: 12px;
  min-height: 260px;
}

.task-card--ghost {
  opacity: 0.45;
}

.task-card--dragging {
  cursor: grabbing;
}

:global(.dark) .todo-saving {
  color: #a5f3fc;
  background: rgba(6, 182, 212, 0.14);
}

@media (max-width: 1280px) {
  .todo-sections {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 760px) {
  .todo-board-header,
  .todo-section-header {
    display: grid;
  }

  .todo-sections {
    grid-template-columns: 1fr;
  }

  .todo-board-button {
    width: 100%;
  }
}
</style>

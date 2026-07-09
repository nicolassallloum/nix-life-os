<template>
  <main class="todo-board-page">
    <header class="todo-board-header">
      <div>
        <p class="eyebrow">To-Do Module</p>
        <h1>Task Organization</h1>
      </div>
      <button type="button" class="refresh-btn" :disabled="loading" @click="fetchBoard">
        {{ loading ? 'Refreshing...' : 'Refresh' }}
      </button>
    </header>

    <TodoPointsSummary :points="pointsSummary" />

    <p v-if="error" class="todo-error">{{ error }}</p>

    <section class="todo-sections">
      <article v-for="section in sectionList" :key="section.type" class="todo-section">
        <header class="todo-section-header">
          <div>
            <h2>{{ section.label }}</h2>
            <span>{{ sections[section.type].length }} tasks</span>
          </div>
          <strong>{{ number(pointsFor(section.type)) }} pts</strong>
        </header>

        <draggable
          v-model="sections[section.type]"
          :data-section="section.type"
          item-key="id"
          group="todo-sections"
          class="task-dropzone"
          ghost-class="task-card--ghost"
          drag-class="task-card--dragging"
          :move="canMoveTask"
          @change="event => onSectionChange(section.type, event)"
        >
          <template #item="{ element }">
            <div class="task-card">
              <div class="task-main">
                <strong>{{ element.title }}</strong>
                <p v-if="element.description">{{ element.description }}</p>
              </div>

              <div class="task-meta">
                <span class="task-pill">{{ readableStatus(element.status) }}</span>
                <span class="task-pill">{{ readableType(element.task_type) }}</span>
                <span v-if="element.due_date" class="task-pill">Due {{ element.due_date }}</span>
                <span v-if="element.project_name" class="task-pill">{{ element.project_name }}</span>
                <span class="task-points">{{ number(element.points) }} pts</span>
              </div>
            </div>
          </template>

          <template #footer>
            <div v-if="!sections[section.type].length" class="empty-dropzone">
              Drop tasks here
            </div>
          </template>
        </draggable>
      </article>
    </section>
  </main>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import draggable from 'vuedraggable'
import TodoPointsSummary from '@/components/todo/TodoPointsSummary.vue'
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
const error = ref('')
let lastGoodState = null

const cloneState = () => JSON.parse(JSON.stringify({ sections, pointsSummary: pointsSummary.value }))

const restoreState = state => {
  if (!state) return
  for (const section of sectionList) {
    sections[section.type] = state.sections[section.type] || []
  }
  pointsSummary.value = state.pointsSummary || pointsSummary.value
}

const applyPayload = payload => {
  const grouped = payload.tasks || payload.grouped_tasks || {}
  for (const section of sectionList) {
    sections[section.type] = grouped[section.type] || []
  }
  pointsSummary.value = payload.points_summary || payload.pointsSummary || pointsSummary.value
  lastGoodState = cloneState()
}

const fetchBoard = async () => {
  loading.value = true
  error.value = ''

  try {
    const { data } = await api.get('/todo/tasks/grouped')
    applyPayload(data)
  } catch (exception) {
    error.value = exception?.response?.data?.message || 'Unable to load tasks.'
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
  error.value = ''

  try {
    if (addedTask) {
      const { data } = await api.patch(`/todo/tasks/${addedTask.id}/move`, {
        task_type: targetType,
        sort_order: event.added.newIndex,
      })
      applyPayload(data)
      return
    }

    if (movedTask) {
      const { data } = await api.patch('/todo/tasks/reorder', {
        task_type: targetType,
        tasks: sections[targetType].map((task, index) => ({
          id: task.id,
          sort_order: index,
        })),
      })
      applyPayload(data)
    }
  } catch (exception) {
    restoreState(lastGoodState)
    error.value = exception?.response?.data?.message || 'Unable to save task movement.'
  } finally {
    syncing.value = false
  }
}

const canMoveTask = event => {
  const from = event.from?.dataset?.section
  const to = event.to?.dataset?.section

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

const pointsFor = type => pointsSummary.value?.[`${type}_points`] || 0
const number = value => new Intl.NumberFormat().format(Number(value || 0))
const readableType = type => `${type || 'general'}`.replace('_', ' ')
const readableStatus = status => `${status || 'pending'}`.replace('_', ' ')

onMounted(fetchBoard)
</script>

<style scoped>
.todo-board-page {
  display: grid;
  gap: 1.25rem;
}

.todo-board-header,
.todo-section-header,
.task-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.eyebrow {
  margin: 0 0 0.25rem;
  font-size: 0.78rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  opacity: 0.7;
}

.refresh-btn {
  border: 0;
  border-radius: 999px;
  padding: 0.65rem 1rem;
  cursor: pointer;
}

.todo-sections {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1rem;
}

.todo-section {
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 20px;
  padding: 1rem;
  min-height: 360px;
  background: rgba(15, 23, 42, 0.06);
}

.todo-section-header {
  margin-bottom: 0.75rem;
}

.todo-section-header h2 {
  margin: 0;
  font-size: 1rem;
}

.task-dropzone {
  display: grid;
  gap: 0.75rem;
  min-height: 260px;
}

.task-card,
.empty-dropzone {
  border: 1px solid rgba(148, 163, 184, 0.25);
  border-radius: 16px;
  padding: 0.85rem;
  background: rgba(255, 255, 255, 0.08);
}

.task-card {
  cursor: grab;
}

.task-card--ghost {
  opacity: 0.45;
}

.task-card--dragging {
  cursor: grabbing;
}

.task-main p {
  margin: 0.35rem 0 0;
  opacity: 0.8;
}

.task-meta {
  justify-content: flex-start;
  flex-wrap: wrap;
  margin-top: 0.75rem;
}

.task-pill,
.task-points {
  border-radius: 999px;
  padding: 0.25rem 0.55rem;
  background: rgba(148, 163, 184, 0.16);
  font-size: 0.76rem;
}

.task-points {
  font-weight: 700;
}

.empty-dropzone {
  display: grid;
  place-items: center;
  min-height: 96px;
  border-style: dashed;
  opacity: 0.7;
}

.todo-error {
  padding: 0.75rem 1rem;
  border-radius: 12px;
  background: rgba(239, 68, 68, 0.12);
}
</style>

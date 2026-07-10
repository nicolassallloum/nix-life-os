<template>
  <article class="todo-project-card">
    <div class="todo-project-card__header">
      <div class="todo-project-card__main">
        <div class="todo-project-card__title-row">
          <h3>{{ project.name }}</h3>
          <TodoBadge kind="project" :value="project.status" />
        </div>
        <p>{{ project.description || 'No description added.' }}</p>
      </div>

      <RouterLink class="todo-project-card__details" :to="`/todo/projects/${project.id}`">
        Details
      </RouterLink>
    </div>

    <TodoProgressBar
      :value="completion"
      label="Project completion"
      :meta="`${finishedTasks} of ${totalTasks} tasks finished`"
      tone="info"
    />

    <div class="todo-project-card__metrics">
      <div>
        <span>Total Tasks</span>
        <strong>{{ totalTasks }}</strong>
      </div>
      <div>
        <span>Finished</span>
        <strong>{{ finishedTasks }}</strong>
      </div>
      <div>
        <span>Complete</span>
        <strong>{{ completion }}%</strong>
      </div>
      <div>
        <span>Points</span>
        <strong>{{ points }}</strong>
      </div>
    </div>

    <div class="todo-project-card__dates">
      <span>{{ formatDate(project.startDate || project.start_date) }}</span>
      <span>to</span>
      <span>{{ formatDate(project.endDate || project.end_date) }}</span>
    </div>

    <div v-if="showActions" class="todo-project-card__actions">
      <button type="button" class="todo-project-card__button todo-project-card__button--secondary" @click="$emit('edit', project)">
        Edit
      </button>
      <RouterLink class="todo-project-card__button todo-project-card__button--secondary" :to="`/todo/tasks?project_id=${project.id}`">
        View Tasks
      </RouterLink>
      <button
        type="button"
        class="todo-project-card__button todo-project-card__button--danger"
        :disabled="deleting"
        @click="$emit('delete', project)"
      >
        {{ deleting ? 'Deleting...' : 'Delete' }}
      </button>
    </div>
  </article>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import TodoBadge from './TodoBadge.vue'
import TodoProgressBar from './TodoProgressBar.vue'
import {
  clampPercentage,
  formatDate,
  numberValue,
  type TodoProjectLike,
} from './todoUtils'

const props = withDefaults(
  defineProps<{
    project: TodoProjectLike
    showActions?: boolean
    deleting?: boolean
  }>(),
  {
    showActions: true,
    deleting: false,
  },
)

defineEmits<{
  edit: [project: TodoProjectLike]
  delete: [project: TodoProjectLike]
}>()

const totalTasks = computed(() => numberValue(props.project.totalTasks ?? props.project.total_tasks))
const finishedTasks = computed(() => numberValue(props.project.finishedTasks ?? props.project.finished_tasks ?? props.project.completedTasks ?? props.project.completed_tasks))
const completion = computed(() => {
  const calculated = totalTasks.value > 0 ? (finishedTasks.value / totalTasks.value) * 100 : 0

  return clampPercentage(props.project.completionPercentage ?? props.project.completion_percentage ?? calculated)
})
const points = computed(() => numberValue(props.project.points ?? props.project.totalProjectPoints ?? props.project.total_project_points ?? props.project.totalPoints ?? props.project.total_points))
</script>

<style scoped>
.todo-project-card {
  display: grid;
  gap: 16px;
  padding: 18px;
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 18px;
  box-shadow: var(--nix-shadow-sm, 0 1px 2px rgba(15, 23, 42, 0.05));
}

.todo-project-card__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
}

.todo-project-card__main {
  min-width: 0;
}

.todo-project-card__title-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.todo-project-card h3 {
  min-width: 0;
  margin: 0;
  overflow-wrap: anywhere;
  color: var(--nix-text, #0f172a);
  font-size: 1.05rem;
  font-weight: 900;
}

.todo-project-card p {
  display: -webkit-box;
  margin: 8px 0 0;
  overflow: hidden;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.9rem;
  line-height: 1.5;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.todo-project-card__details {
  color: #0891b2;
  font-size: 0.86rem;
  font-weight: 900;
  text-decoration: none;
}

.todo-project-card__metrics {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.todo-project-card__metrics div {
  min-width: 0;
  padding: 12px;
  background: rgba(148, 163, 184, 0.08);
  border-radius: 14px;
}

.todo-project-card__metrics span {
  display: block;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.76rem;
  font-weight: 800;
}

.todo-project-card__metrics strong {
  display: block;
  margin-top: 5px;
  color: var(--nix-text, #0f172a);
  font-size: 1.15rem;
  font-weight: 900;
}

.todo-project-card__dates,
.todo-project-card__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.todo-project-card__dates {
  color: var(--nix-text-muted, #64748b);
  font-size: 0.82rem;
  font-weight: 800;
}

.todo-project-card__button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 38px;
  padding: 8px 12px;
  border-radius: 12px;
  font-size: 0.86rem;
  font-weight: 900;
  text-decoration: none;
}

.todo-project-card__button:disabled {
  cursor: not-allowed;
  opacity: 0.62;
}

.todo-project-card__button--secondary {
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
}

.todo-project-card__button--danger {
  color: #991b1b;
  background: #fee2e2;
  border: 1px solid #fecaca;
}

:global(.dark) .todo-project-card__button--danger {
  color: #fecaca;
  background: rgba(239, 68, 68, 0.14);
  border-color: rgba(252, 165, 165, 0.22);
}

@media (max-width: 760px) {
  .todo-project-card__header {
    display: grid;
  }

  .todo-project-card__metrics {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 520px) {
  .todo-project-card__actions {
    display: grid;
  }
}
</style>

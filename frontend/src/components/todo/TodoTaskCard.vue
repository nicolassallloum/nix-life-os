<template>
  <article class="todo-task-card" :class="{ 'todo-task-card--dragging': dragging, 'todo-task-card--disabled': disabled }">
    <div class="todo-task-card__body">
      <div class="todo-task-card__main">
        <div class="todo-task-card__title-row">
          <h3>{{ task.title }}</h3>
          <TodoBadge kind="status" :value="task.status" />
        </div>
        <p>{{ task.description || 'No description added.' }}</p>
      </div>

      <div class="todo-task-card__badges">
        <TodoBadge kind="type" :value="task.task_type || task.type" />
        <TodoBadge kind="priority" :value="task.priority" />
        <TodoBadge v-if="task.projectName || task.project_name || task.project?.name" :label="projectName" tone="neutral" />
        <TodoBadge :label="`${numberValue(task.points)} pts`" tone="info" />
      </div>
    </div>

    <div class="todo-task-card__meta">
      <span>Due: {{ formatDate(task.dueDate || task.due_date) }}</span>
      <span v-if="task.projectId || task.project_id">Project ID: {{ task.projectId || task.project_id }}</span>
    </div>

    <div v-if="showActions" class="todo-task-card__actions">
      <RouterLink class="todo-task-card__button todo-task-card__button--secondary" :to="`/todo/tasks/${task.id}/edit`">
        Edit
      </RouterLink>
      <button
        v-if="!completed"
        type="button"
        class="todo-task-card__button todo-task-card__button--success"
        :disabled="disabled || completing"
        @click="$emit('finish', task)"
      >
        {{ completing ? 'Completing...' : 'Finish' }}
      </button>
      <button
        type="button"
        class="todo-task-card__button todo-task-card__button--danger"
        :disabled="disabled || deleting"
        @click="$emit('delete', task)"
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
import {
  formatDate,
  isCompletedTask,
  numberValue,
  type TodoTaskLike,
} from './todoUtils'

const props = withDefaults(
  defineProps<{
    task: TodoTaskLike
    showActions?: boolean
    completing?: boolean
    deleting?: boolean
    disabled?: boolean
    dragging?: boolean
  }>(),
  {
    showActions: true,
    completing: false,
    deleting: false,
    disabled: false,
    dragging: false,
  },
)

defineEmits<{
  finish: [task: TodoTaskLike]
  delete: [task: TodoTaskLike]
}>()

const completed = computed(() => isCompletedTask(props.task.status))
const projectName = computed(() => props.task.projectName || props.task.project_name || props.task.project?.name || 'No project')
</script>

<style scoped>
.todo-task-card {
  display: grid;
  gap: 12px;
  padding: 16px;
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
  border-radius: 18px;
  box-shadow: var(--nix-shadow-sm, 0 1px 2px rgba(15, 23, 42, 0.05));
}

.todo-task-card--dragging {
  cursor: grabbing;
  opacity: 0.86;
  transform: rotate(0.2deg);
}

.todo-task-card--disabled {
  opacity: 0.68;
}

.todo-task-card__body {
  display: grid;
  gap: 12px;
}

.todo-task-card__title-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.todo-task-card h3 {
  min-width: 0;
  margin: 0;
  overflow-wrap: anywhere;
  color: var(--nix-text, #0f172a);
  font-size: 1rem;
  font-weight: 900;
}

.todo-task-card p {
  display: -webkit-box;
  margin: 6px 0 0;
  overflow: hidden;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.9rem;
  line-height: 1.5;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.todo-task-card__badges,
.todo-task-card__meta,
.todo-task-card__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.todo-task-card__meta {
  color: var(--nix-text-muted, #64748b);
  font-size: 0.8rem;
  font-weight: 700;
}

.todo-task-card__button {
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

.todo-task-card__button:disabled {
  cursor: not-allowed;
  opacity: 0.62;
}

.todo-task-card__button--secondary {
  color: var(--nix-text, #0f172a);
  background: var(--nix-surface, #ffffff);
  border: 1px solid var(--nix-border, #e2e8f0);
}

.todo-task-card__button--success {
  color: #166534;
  background: #dcfce7;
  border: 1px solid #bbf7d0;
}

.todo-task-card__button--danger {
  color: #991b1b;
  background: #fee2e2;
  border: 1px solid #fecaca;
}

:global(.dark) .todo-task-card__button--success {
  color: #bbf7d0;
  background: rgba(34, 197, 94, 0.14);
  border-color: rgba(134, 239, 172, 0.22);
}

:global(.dark) .todo-task-card__button--danger {
  color: #fecaca;
  background: rgba(239, 68, 68, 0.14);
  border-color: rgba(252, 165, 165, 0.22);
}

@media (max-width: 640px) {
  .todo-task-card__title-row {
    display: grid;
  }

  .todo-task-card__actions {
    display: grid;
    grid-template-columns: 1fr;
  }
}
</style>

<template>
  <div class="todo-progress">
    <div class="todo-progress__header">
      <span>{{ label }}</span>
      <strong>{{ safeValue }}%</strong>
    </div>
    <div class="todo-progress__track" role="progressbar" :aria-valuenow="safeValue" aria-valuemin="0" aria-valuemax="100">
      <div class="todo-progress__bar" :class="barClass" :style="{ width: `${safeValue}%` }"></div>
    </div>
    <p v-if="meta" class="todo-progress__meta">{{ meta }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { clampPercentage, type TodoTone } from './todoUtils'

const props = withDefaults(
  defineProps<{
    value: number
    label?: string
    meta?: string
    tone?: TodoTone
  }>(),
  {
    label: 'Progress',
    meta: '',
    tone: 'info',
  },
)

const safeValue = computed(() => clampPercentage(props.value))
const barClass = computed(() => `todo-progress__bar--${props.tone}`)
</script>

<style scoped>
.todo-progress {
  display: grid;
  gap: 8px;
}

.todo-progress__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  color: var(--nix-text, #0f172a);
  font-size: 0.9rem;
  font-weight: 800;
}

.todo-progress__header strong {
  color: #0891b2;
}

.todo-progress__track {
  height: 10px;
  overflow: hidden;
  background: #e2e8f0;
  border-radius: 999px;
}

.todo-progress__bar {
  height: 100%;
  border-radius: inherit;
  transition: width 0.2s ease;
}

.todo-progress__bar--neutral {
  background: #64748b;
}

.todo-progress__bar--info {
  background: #06b6d4;
}

.todo-progress__bar--success {
  background: #22c55e;
}

.todo-progress__bar--warning {
  background: #f59e0b;
}

.todo-progress__bar--danger {
  background: #ef4444;
}

.todo-progress__meta {
  margin: 0;
  color: var(--nix-text-muted, #64748b);
  font-size: 0.82rem;
}

:global(.dark) .todo-progress__header {
  color: #f8fafc;
}

:global(.dark) .todo-progress__header strong {
  color: #67e8f9;
}

:global(.dark) .todo-progress__track {
  background: #334155;
}
</style>

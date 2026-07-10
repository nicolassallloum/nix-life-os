<template>
  <span class="todo-badge" :class="toneClass">
    {{ resolvedLabel }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  taskBadgeLabel,
  taskBadgeTone,
  type TodoTone,
} from './todoUtils'

const props = withDefaults(
  defineProps<{
    kind?: 'type' | 'status' | 'priority' | 'project' | 'custom'
    value?: string | number | null
    label?: string
    tone?: TodoTone
  }>(),
  {
    kind: 'custom',
    value: '',
    label: '',
    tone: 'neutral',
  },
)

const resolvedLabel = computed(() => {
  if (props.label) return props.label
  if (props.kind === 'custom') return String(props.value || '')

  return taskBadgeLabel(props.kind, props.value)
})

const resolvedTone = computed(() => {
  if (props.kind === 'custom') return props.tone

  return taskBadgeTone(props.kind, props.value)
})

const toneClass = computed(() => `todo-badge--${resolvedTone.value}`)
</script>

<style scoped>
.todo-badge {
  display: inline-flex;
  align-items: center;
  min-height: 26px;
  padding: 5px 10px;
  border: 1px solid transparent;
  border-radius: 999px;
  font-size: 0.76rem;
  font-weight: 900;
  line-height: 1;
  white-space: nowrap;
}

.todo-badge--neutral {
  color: #334155;
  background: #f1f5f9;
  border-color: #e2e8f0;
}

.todo-badge--info {
  color: #155e75;
  background: #ecfeff;
  border-color: #a5f3fc;
}

.todo-badge--success {
  color: #166534;
  background: #dcfce7;
  border-color: #bbf7d0;
}

.todo-badge--warning {
  color: #92400e;
  background: #fef3c7;
  border-color: #fde68a;
}

.todo-badge--danger {
  color: #991b1b;
  background: #fee2e2;
  border-color: #fecaca;
}

:global(.dark) .todo-badge--neutral {
  color: #cbd5e1;
  background: rgba(148, 163, 184, 0.14);
  border-color: rgba(148, 163, 184, 0.24);
}

:global(.dark) .todo-badge--info {
  color: #a5f3fc;
  background: rgba(6, 182, 212, 0.14);
  border-color: rgba(103, 232, 249, 0.22);
}

:global(.dark) .todo-badge--success {
  color: #bbf7d0;
  background: rgba(34, 197, 94, 0.14);
  border-color: rgba(134, 239, 172, 0.22);
}

:global(.dark) .todo-badge--warning {
  color: #fde68a;
  background: rgba(245, 158, 11, 0.14);
  border-color: rgba(252, 211, 77, 0.22);
}

:global(.dark) .todo-badge--danger {
  color: #fecaca;
  background: rgba(239, 68, 68, 0.14);
  border-color: rgba(252, 165, 165, 0.22);
}
</style>
